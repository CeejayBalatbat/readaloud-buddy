import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/speech/android_speech_service.dart';
import 'package:readaloud_buddy/speech/speech_service.dart';

/// Stands in for the speech_to_text plugin.
class FakeEngine implements SttEngine {
  bool initOk = true;
  bool permission = true;
  final listens = <(String localeId, bool onDevice)>[];
  int cancels = 0;
  late void Function(String) status;
  late void Function(String, bool) error;
  late void Function(String, bool, double?) result;
  void Function(double)? sound;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String error, bool permanent) onError,
  }) async {
    status = onStatus;
    error = onError;
    return initOk;
  }

  @override
  Future<bool> get hasPermission async => permission;

  @override
  Future<void> listen({
    required String localeId,
    required bool onDevice,
    required void Function(String, bool, double?) onResult,
    void Function(double)? onSoundLevel,
  }) async {
    listens.add((localeId, onDevice));
    result = onResult;
    sound = onSoundLevel;
  }

  @override
  Future<void> cancel() async => cancels++;
}

void main() {
  late FakeEngine engine;
  late AndroidSpeechService s;
  late List<HeardWord> heard;
  var now = Duration.zero;
  late List<void Function()> frames; // run = "the next frame was drawn"

  setUp(() {
    engine = FakeEngine();
    now = Duration.zero;
    frames = [];
    s = AndroidSpeechService(
      engine: engine,
      restartDelay: const Duration(milliseconds: 5),
      errorRetryDelay: const Duration(milliseconds: 5),
      now: () => now,
      onNextFrame: frames.add,
    );
    heard = [];
    s.words.listen(heard.add);
  });
  tearDown(() => s.dispose());

  Future<void> later() => Future<void>.delayed(const Duration(milliseconds: 30));
  List<String> texts() => [for (final h in heard) h.text];

  test('listens in English, on the phone first, with partial results',
      () async {
    await s.start(language: 'EN');
    expect(engine.listens, [('en-US', true)]);
    expect(s.state.value.status, MicStatus.listening);
    engine.result('Sam has', false, null);
    engine.result('Sam has a cat', true, 0.9);
    expect(texts(), ['Sam', 'has', 'a', 'cat']);
    expect(heard.first.confidence, isNull); // partial: no confidence
    expect(heard.last.confidence, 0.9); // final result's confidence
    expect(s.state.value.transcript, 'Sam has a cat');
  });

  test('the expected word is passed on without waiting for the next word',
      () async {
    await s.start(language: 'EN');
    s.expectedWord = 'Sam';
    engine.result('sam', false, null);
    expect(texts(), ['sam']);
  });

  test('restarts automatically when Android stops on silence', () async {
    await s.start(language: 'EN');
    engine.result('Sam', true, null);
    engine.status('notListening');
    engine.status('done');
    await later();
    expect(engine.listens, hasLength(2)); // one restart, not two
    expect(s.state.value.restarts, 1);
    engine.result('has', true, null); // a new utterance starts at word 0
    expect(texts(), ['Sam', 'has']);
  });

  test('"no match" just listens again', () async {
    await s.start(language: 'EN');
    engine.error('error_no_match', false);
    await later();
    expect(engine.listens, hasLength(2));
  });

  test('falls back to online when there is no on-device model', () async {
    await s.start(language: 'EN');
    engine.error('error_language_not_supported', true);
    await later();
    expect(engine.listens.last, ('en-US', false));
    expect(s.state.value.onDevice, isFalse);
  });

  test('a refused microphone shows noPermission and stops trying', () async {
    engine.initOk = false;
    engine.permission = false;
    await s.start(language: 'EN');
    expect(s.state.value.status, MicStatus.noPermission);
    expect(engine.listens, isEmpty);
  });

  test('stop (pause or leaving the story) does not restart', () async {
    await s.start(language: 'EN');
    await s.stop();
    engine.status('done');
    await later();
    expect(engine.listens, hasLength(1));
    expect(engine.cancels, 1);
    expect(s.state.value.status, MicStatus.off);
  });

  test("while muted, Buddy's own voice is not taken as reading", () async {
    await s.start(language: 'EN');
    s.mute(true);
    engine.result('thr ough', false, null);
    s.mute(false);
    engine.result('thr ough through', true, null);
    expect(texts(), ['through']);
  });

  test('gives up after 3 real errors in a row and says the mic is not ready',
      () async {
    await s.start(language: 'EN');
    for (var i = 0; i < 3; i++) {
      engine.error('error_network', false);
      await later();
    }
    expect(s.state.value.status, MicStatus.unavailable);
    final tries = engine.listens.length;
    await later();
    expect(engine.listens.length, tries); // stopped retrying
    await s.start(language: 'EN'); // tapping the mic tries again
    expect(s.state.value.status, MicStatus.listening);
  });

  test('Filipino uses the fil-PH recognizer', () async {
    await s.start(language: 'FIL');
    expect(engine.listens.single.$1, 'fil-PH');
  });

  group('speed meter', () {
    Duration ms(int v) => Duration(milliseconds: v);

    test('splits each word into recognizer, settling and screen time',
        () async {
      await s.start(language: 'EN');
      s.expectedWord = 'Sam';
      now = ms(1000);
      engine.sound!(1); // quiet
      now = ms(1100);
      engine.sound!(6); // starts speaking
      now = ms(1700);
      engine.result('Sam', false, null); // accepted early
      now = ms(1730);
      for (final f in frames) {
        f();
      }
      final t = s.timer.samples.single;
      expect(t.word, 'Sam');
      expect(t.recognizerMs, 600);
      expect(t.settlingMs, 0);
      expect(t.screenMs, 30);
      expect(t.totalMs, 630);
      expect(s.state.value.speed!.totalMs, 630);
    });

    test('a word that is not the expected one waits to settle', () async {
      await s.start(language: 'EN');
      s.expectedWord = 'Sam';
      now = ms(100);
      engine.sound!(6);
      now = ms(500);
      engine.result('sun', false, null); // not "Sam": wait
      expect(heard, isEmpty);
      now = ms(1400);
      engine.result('sun', true, null); // final
      final t = s.timer.samples.single;
      expect(t.recognizerMs, 400);
      expect(t.settlingMs, 900);
    });

    test('measures how long the mic is off during a restart', () async {
      await s.start(language: 'EN');
      now = ms(2000);
      engine.status('done');
      now = ms(2400);
      await later(); // restart fires
      expect(s.timer.summary().restartGapMs, 400);
    });
  });
}
