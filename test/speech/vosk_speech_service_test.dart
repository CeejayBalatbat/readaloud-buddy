import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/speech/mic_permission.dart';
import 'package:readaloud_buddy/speech/speech_service.dart';
import 'package:readaloud_buddy/speech/vosk_speech_service.dart';

/// Stands in for Vosk: records calls, lets tests push results. Like the
/// real Vosk it refuses a grammar change mid-utterance (on the phone that
/// aborts the whole app).
class FakeVosk implements VoskEngine {
  final calls = <String>[];
  List<String>? loadedWith;
  bool fail = false;

  /// Audio heard since the last utterance ended.
  bool midUtterance = false;
  String pending = '';
  final _partials = StreamController<String>.broadcast(sync: true);
  final _results = StreamController<String>.broadcast(sync: true);

  void partial(String text) {
    midUtterance = true;
    pending = text;
    _partials.add(jsonEncode({'partial': text}));
  }

  void result(String text, [List<(String, double)> starts = const []]) {
    midUtterance = false;
    pending = '';
    _results.add(_resultJson(text, starts));
  }

  static String _resultJson(String text, List<(String, double)> starts) => jsonEncode({
        'text': text,
        'result': [
          for (final (w, s) in starts) {'word': w, 'start': s, 'end': s + 0.3, 'conf': 1.0},
        ],
      });

  @override
  Future<void> load(List<String> grammar) async {
    if (fail) throw StateError('model missing');
    loadedWith = grammar;
    calls.add('load');
  }

  @override
  Future<void> setGrammar(List<String> grammar) async {
    if (midUtterance) throw StateError("Can't add grammar to already running recognizer");
    calls.add('grammar ${grammar.join(' ')}');
  }

  @override
  Future<String> finalResult() async {
    calls.add('final');
    final text = pending;
    midUtterance = false;
    pending = '';
    return _resultJson(text, const []);
  }

  @override
  Future<void> reset() async {
    calls.add('reset');
    midUtterance = false;
    pending = '';
  }
  @override
  Future<void> start() async => calls.add('start');
  @override
  Future<void> stop() async => calls.add('stop');
  @override
  Future<void> setPause(bool paused) async => calls.add(paused ? 'pause' : 'unpause');
  @override
  Stream<String> get partials => _partials.stream;
  @override
  Stream<String> get results => _results.stream;
}

/// Microphone permission for the test.
class Mic implements MicPermission {
  Mic({this.allowed = true});
  final bool allowed;
  @override
  Future<bool> request() async => allowed;
}

void main() {
  late FakeVosk engine;
  late VoskSpeechService s;
  late List<HeardWord> heard;
  late int voices;
  var now = Duration.zero;
  late List<void Function()> frames;

  VoskSpeechService make({bool mic = true, Set<String> missing = const {}}) => VoskSpeechService(
        engine: engine,
        permissions: Mic(allowed: mic),
        missingWords: missing,
        grammarSwapDelay: Duration.zero,
        now: () => now,
        onNextFrame: frames.add,
      );

  setUp(() {
    engine = FakeVosk();
    now = Duration.zero;
    frames = [];
    s = make();
    heard = [];
    voices = 0;
    s.words.listen(heard.add);
    s.voice.listen((_) => voices++);
  });

  List<String> texts() => [for (final h in heard) h.text];
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('grammar mode: only the page\'s words + [unk], lowercase, once each', () async {
    s.vocabulary = ['Sam', 'has', 'a', 'cat.', 'The', 'cat'];
    await s.start(language: 'EN');
    expect(engine.loadedWith, ['a', 'cat', 'has', 'sam', 'the', '[unk]']);
    expect(s.state.value.status, MicStatus.listening);
    expect(s.state.value.engine, 'Vosk offline');
    expect(s.state.value.onDevice, isTrue);
  });

  test('words the model doesn\'t know are left out of the grammar', () {
    expect(VoskSpeechService.grammarFor(['Jen', 'ran', "Let's"], {'jen'}),
        ['let\'s', 'ran', '[unk]']);
  });

  test('no microphone permission / missing model: says so', () async {
    final noMic = make(mic: false);
    await noMic.start(language: 'EN');
    expect(noMic.state.value.status, MicStatus.noPermission);

    engine.fail = true;
    final broken = make();
    await broken.start(language: 'EN');
    expect(broken.state.value.status, MicStatus.unavailable);
    expect(broken.state.value.lastError, contains('model missing'));
  });

  test('partial results: the expected word is passed on right away', () async {
    await s.start(language: 'EN');
    s.expectedWord = 'Sam';
    engine.partial('sam');
    expect(texts(), ['sam']);
    s.expectedWord = 'has';
    engine.partial('sam has');
    engine.partial('sam has a');
    expect(texts(), ['sam', 'has']);
    engine.result('sam has a cat');
    expect(texts(), ['sam', 'has', 'a', 'cat']);
    // A new utterance starts counting from its own first word.
    engine.partial('the');
    engine.result('the cat');
    expect(texts(), ['sam', 'has', 'a', 'cat', 'the', 'cat']);
  });

  test('continuous: one start for the whole story, no restarts', () async {
    await s.start(language: 'EN');
    for (var i = 0; i < 5; i++) {
      engine.result('sam');
    }
    expect(engine.calls.where((c) => c == 'start'), hasLength(1));
    await s.stop();
    expect(engine.calls.last, 'stop');
    expect(s.state.value.status, MicStatus.off);
  });

  test('[unk] = speaking (hint timer), but never a misread', () async {
    await s.start(language: 'EN');
    s.expectedWord = 'cat';
    engine.partial('[unk]');
    expect(voices, 1);
    expect(heard, isEmpty);
    engine.result('[unk] cat');
    expect(texts(), ['cat']);
  });

  test('a word the model can\'t hear: [unk] there counts as unsure', () async {
    final jen = make(missing: {'jen'});
    final got = <HeardWord>[];
    jen.words.listen(got.add);
    await jen.start(language: 'EN');
    jen.expectedWord = 'Jen';
    engine.result('[unk]');
    expect(got.single.text, 'Jen');
    expect(got.single.confidence, 0); // below 0.5 → unsure, never counted
  });

  test('a new page swaps the grammar while paused', () async {
    s.vocabulary = ['Sam', 'has'];
    await s.start(language: 'EN');
    engine.calls.clear();
    s.vocabulary = ['The', 'cat'];
    await settle();
    await settle();
    expect(engine.calls, ['pause', 'final', 'grammar cat the [unk]', 'unpause']);
    engine.calls.clear();
    s.vocabulary = ['cat', 'The']; // same words: nothing to do
    await settle();
    expect(engine.calls, isEmpty);
  });

  test('while Buddy speaks, audio is dropped and results ignored', () async {
    await s.start(language: 'EN');
    engine.calls.clear();
    s.mute(true);
    await settle();
    engine.result('sam');
    expect(heard, isEmpty);
    s.mute(false);
    await settle();
    expect(engine.calls, ['pause', 'unpause']);
  });

  group('speed meter', () {
    Duration ms(int v) => Duration(milliseconds: v);

    test('"said" = the word\'s start time in the audio', () async {
      await s.start(language: 'EN'); // audio starts at 0
      s.expectedWord = 'sam';
      now = ms(900);
      engine.partial('sam'); // first seen at 0.9 s
      now = ms(930);
      for (final f in frames) {
        f();
      }
      now = ms(1500);
      engine.result('sam', [('sam', 0.3)]); // Vosk: "sam" started at 0.3 s
      final t = s.timer.samples.single;
      expect(t.recognizerMs, 600);
      expect(t.settlingMs, 0);
      expect(t.screenMs, 30);
      expect(s.state.value.speed!.totalMs, 630);
    });

    test('time while paused is not audio time', () async {
      await s.start(language: 'EN');
      now = ms(1000);
      s.mute(true); // audio stops at 1.0 s of audio
      await settle();
      now = ms(3000);
      s.mute(false); // resumes: audio 1.0 s = clock 3.0 s
      await settle();
      s.expectedWord = 'cat';
      now = ms(3500);
      engine.partial('cat');
      engine.result('cat', [('cat', 1.2)]); // 0.2 s after resuming = 3.2 s
      expect(s.timer.samples.single.recognizerMs, 300);
    });
  });

  group('the phone crash (KaldiFatalError in SetGrm)', () {
    test('a page turn mid-utterance: words are kept, no grammar change mid-utterance',
        () async {
      s.vocabulary = ['Sam', 'has', 'a', 'cat'];
      await s.start(language: 'EN');
      s.expectedWord = 'sam';
      engine.partial('sam has'); // the child is still talking
      s.vocabulary = ['The', 'cat']; // page turn
      for (var i = 0; i < 4; i++) {
        await settle();
      }
      expect(s.state.value.status, MicStatus.listening); // no failure
      expect(engine.calls, containsAllInOrder(['final', 'grammar cat the [unk]']));
      expect(texts(), ['sam', 'has']); // the flushed words still count
    });

    test('a new story after one that stopped mid-utterance', () async {
      await s.start(language: 'EN');
      engine.partial('sam');
      await s.stop();
      engine.calls.clear();
      s.vocabulary = ['The', 'cat'];
      await s.start(language: 'EN');
      expect(s.state.value.status, MicStatus.listening);
      expect(engine.calls, ['load', 'reset', 'grammar cat the [unk]', 'start']);
    });
  });
}
