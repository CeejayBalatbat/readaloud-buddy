import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vosk_flutter/vosk_flutter.dart' as vosk;

import '../agent/agent.dart';
import 'mic_permission.dart';
import 'speech_service.dart';
import 'speech_timing.dart';
import 'transcript_tracker.dart';

/// The bits of Vosk we use, so the service logic can be tested with a fake.
abstract class VoskEngine {
  /// Loads the model, recognizer and microphone service (once per app).
  /// Throws when the model is missing or broken.
  Future<void> load(List<String> grammar);

  /// Only these words (+ "[unk]") can be heard (grammar mode). Vosk
  /// crashes if this is called mid-utterance: call [finalResult] or
  /// [reset] first (while paused).
  Future<void> setGrammar(List<String> grammar);

  /// Ends the current utterance and returns its final result JSON (like
  /// [results]).
  Future<String> finalResult();

  /// Drops the current utterance.
  Future<void> reset();
  Future<void> start();
  Future<void> stop();

  /// While paused the microphone keeps running but audio is dropped.
  Future<void> setPause(bool paused);

  /// JSON: {"partial": "sam has"}.
  Stream<String> get partials;

  /// JSON: {"text": "sam has a", "result": [{"word", "start", "end", "conf"}]}.
  Stream<String> get results;
}

/// The real engine: the vendored vosk_flutter plugin with the bundled small
/// English model. One recognizer and one microphone service for the app.
class VoskFlutterEngine implements VoskEngine {
  VoskFlutterEngine._();
  static final instance = VoskFlutterEngine._();

  static const modelAsset = 'assets/models/vosk-model-small-en-us-0.15.zip';
  static const sampleRate = 16000;

  vosk.Recognizer? _recognizer;
  vosk.SpeechService? _service;
  Future<void>? _loading;

  @override
  Future<void> load(List<String> grammar) => _loading ??= _load(grammar).catchError((Object e) {
        _loading = null; // let a later story try again
        throw e;
      });

  Future<void> _load(List<String> grammar) async {
    final plugin = vosk.VoskFlutterPlugin.instance();
    // Unzips to app storage the first time (a few seconds), then reuses it.
    final path = await vosk.ModelLoader().loadFromAssets(modelAsset);
    final model = await plugin.createModel(path);
    final recognizer = await plugin.createRecognizer(
      model: model,
      sampleRate: sampleRate,
      grammar: grammar,
    );
    await recognizer.setWords(words: true); // word start times for the speed meter
    _recognizer = recognizer;
    _service = await plugin.initSpeechService(recognizer);
  }

  @override
  Future<void> setGrammar(List<String> grammar) async => _recognizer?.setGrammar(grammar);
  @override
  Future<String> finalResult() async => await _recognizer?.getFinalResult() ?? '{}';
  @override
  Future<void> reset() async => _recognizer?.reset();
  @override
  Future<void> start() async => _service?.start();
  @override
  Future<void> stop() async => _service?.stop();
  @override
  Future<void> setPause(bool paused) async => _service?.setPause(paused: paused);
  @override
  Stream<String> get partials => _service?.onPartial() ?? const Stream.empty();
  @override
  Stream<String> get results => _service?.onResult() ?? const Stream.empty();
}

/// Story words the model doesn't know (assets/data/vosk_vocab.json, made
/// by tools/check_vosk_vocab.py).
Future<Set<String>> loadVoskMissingWords() async {
  try {
    final j = jsonDecode(await rootBundle.loadString('assets/data/vosk_vocab.json'));
    return {for (final w in (j as Map<String, dynamic>)['missing'] as List) w as String};
  } catch (_) {
    return const {};
  }
}

/// Offline speech recognition with Vosk, the only recognizer (English
/// stories; Filipino stories use tap-to-read for now).
///
/// - **Grammar mode:** listens only for the words on the current page (see
///   [vocabulary]) plus "[unk]", so it is fast and never "autocorrects" a
///   child into another word.
/// - **Continuous:** one microphone session for the whole story; Vosk
///   splits utterances itself, so there are no stop/restart gaps.
/// - "[unk]" (speech that is none of the page's words) counts as the child
///   speaking (it keeps the hint timer going) but is not scored as a
///   misread, so coughs and "um"s never count against the child. For the
///   few story words the model doesn't know ([missingWords]), "[unk]" at
///   that word counts as an `unsure` read (never against the child, §1).
class VoskSpeechService implements SpeechService {
  VoskSpeechService({
    VoskEngine? engine,
    MicPermission? permissions,
    this.missingWords = const {},
    this.grammarSwapDelay = const Duration(milliseconds: 100),
    this.onRunning,
    Duration Function()? now,
    void Function(void Function() callback)? onNextFrame,
  })  : _engine = engine ?? VoskFlutterEngine.instance,
        _permissions = permissions ?? const PlatformMicPermission(),
        _now = now ?? _stopwatch(),
        _onNextFrame = onNextFrame ??
            ((cb) => SchedulerBinding.instance.addPostFrameCallback((_) => cb()));

  static Duration Function() _stopwatch() {
    final w = Stopwatch()..start();
    return () => w.elapsed;
  }

  static const unk = '[unk]';

  final VoskEngine _engine;
  final MicPermission _permissions;
  final Set<String> missingWords;

  /// Vosk decodes on its own audio thread; the grammar is swapped while
  /// paused, after this wait, so it never changes mid-decode.
  final Duration grammarSwapDelay;

  /// Told when Vosk's native code starts/stops being used, so a crash in
  /// it can be noticed at the next app start (see VoskHealth).
  final Future<void> Function(bool running)? onRunning;
  final Duration Function() _now;
  final void Function(void Function()) _onNextFrame;

  /// Speech-to-screen delay, word by word (see [WordTiming]).
  final timer = SpeechTimer();

  final _words = StreamController<HeardWord>.broadcast(sync: true);
  final _voice = StreamController<void>.broadcast(sync: true);
  final _state = ValueNotifier(const SpeechState(engine: 'Vosk offline'));
  final _tracker = TranscriptTracker();
  final _matcher = const WordMatcher();
  final _subs = <StreamSubscription<String>>[];

  bool _wanted = false;
  bool _running = false; // reported to [onRunning]
  bool _disposed = false;
  bool _listening = false;
  bool _muted = false;
  bool _paused = false; // audio dropped (muted or swapping the grammar)
  String? _expected;
  List<String> _grammar = const [unk];
  Future<void> _queue = Future.value(); // grammar swaps and pauses, in order

  // Maps Vosk's audio time (seconds of audio fed, which keeps counting
  // across utterances) to our clock: audio is fed while running and not
  // paused.
  double _audioFed = 0;
  Duration? _runningSince;

  @override
  Stream<HeardWord> get words => _words.stream;
  @override
  Stream<void> get voice => _voice.stream;
  @override
  bool get hearsSilence => true;
  @override
  ValueListenable<SpeechState> get state => _state;
  @override
  bool get isListening => _listening;

  @override
  set expectedWord(String? word) => _expected = word;

  /// Normalized page words + "[unk]", without words the model doesn't know.
  static List<String> grammarFor(Iterable<String> words, Set<String> missing) {
    final set = <String>{};
    for (final w in words) {
      final n = w.toLowerCase().replaceAll(RegExp(r"[^\p{L}\p{N}']", unicode: true), '');
      if (n.isNotEmpty && !missing.contains(n)) set.add(n);
    }
    return [...set.toList()..sort(), unk];
  }

  @override
  set vocabulary(List<String> words) {
    final grammar = grammarFor(words, missingWords);
    if (listEquals(grammar, _grammar)) return;
    _grammar = grammar;
    if (_listening) _serial(() => _swapGrammar(grammar));
  }

  @override
  Future<void> start({required String language}) async {
    _wanted = true;
    _set(status: MicStatus.starting);
    try {
      if (!await _permissions.request()) {
        _wanted = false;
        _set(status: MicStatus.noPermission);
        return;
      }
      await _setRunning(true);
      await _engine.load(_grammar);
      if (!_wanted) return;
      // The recognizer is shared across stories: drop the last story's
      // leftovers so the grammar can change (see VoskEngine.setGrammar).
      await _engine.reset();
      await _engine.setGrammar(_grammar);
      _subs
        ..add(_engine.partials.listen(_onPartial))
        ..add(_engine.results.listen(_onResult));
      _tracker.reset();
      timer.newUtterance();
      await _engine.start();
      _listening = true;
      _resume();
      if (_muted) await _pause();
      _set(status: MicStatus.listening, onDevice: true);
    } catch (e) {
      _fail(e);
    }
  }

  /// Any Vosk error: stop using it and say it's unavailable (the app then
  /// switches the story to tap-to-read).
  void _fail(Object e) {
    _wanted = false;
    _listening = false;
    _hold();
    unawaited(_setRunning(false));
    _set(status: MicStatus.unavailable, lastError: 'Vosk: $e');
  }

  @override
  Future<void> stop() async {
    _wanted = false;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    if (_listening) {
      _listening = false;
      _hold();
      try {
        await _engine.stop();
      } catch (_) {}
    }
    await _setRunning(false);
    _set(status: MicStatus.off);
  }

  /// While Buddy speaks, Vosk drops the audio so his voice isn't heard.
  @override
  void mute(bool muted) {
    if (_muted == muted) return;
    _muted = muted;
    if (_listening) _serial(() => muted ? _pause() : _unpause());
  }

  /// Tells [onRunning] only about changes, so stopping (or disposing) a
  /// service that never ran reports nothing.
  Future<void> _setRunning(bool on) async {
    if (_running == on) return;
    _running = on;
    await onRunning?.call(on);
  }

  void _serial(Future<void> Function() step) =>
      _queue = _queue.then((_) => step()).catchError(_fail);

  Future<void> _swapGrammar(List<String> grammar) async {
    final wasPaused = _paused;
    if (!wasPaused) await _pause();
    await Future<void>.delayed(grammarSwapDelay); // let the current buffer finish
    // End the utterance first (Vosk can't change grammar mid-utterance),
    // keeping the words in it.
    final last = await _engine.finalResult();
    if (!_muted) _onResult(last);
    await _engine.setGrammar(grammar);
    if (!wasPaused && !_muted) await _unpause();
  }

  Future<void> _pause() async {
    if (_paused) return;
    _paused = true;
    _hold();
    await _engine.setPause(true);
  }

  Future<void> _unpause() async {
    if (!_paused) return;
    await _engine.setPause(false);
    _paused = false;
    _resume();
  }

  void _hold() {
    final since = _runningSince;
    if (since != null) _audioFed += (_now() - since).inMicroseconds / 1e6;
    _runningSince = null;
  }

  void _resume() => _runningSince ??= _paused ? null : _now();

  /// Our clock time for Vosk audio time [seconds], if it is in the current
  /// running stretch.
  Duration? _wallFor(double seconds) {
    final since = _runningSince;
    if (since == null || seconds < _audioFed) return null;
    return since + Duration(microseconds: ((seconds - _audioFed) * 1e6).round());
  }

  void _onPartial(String json) {
    if (_muted) return;
    final text = _field(json, 'partial');
    if (text.isNotEmpty && text != _state.value.transcript) _voice.add(null);
    _feed(text, isFinal: false);
  }

  void _onResult(String json) {
    if (_muted) return;
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final text = (j['text'] as String? ?? '').trim();
    _feed(text, isFinal: true);
    // Word start times → exact "said" times for the speed meter.
    final words = (j['result'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    for (final (i, w) in words.indexed) {
      final at = _wallFor((w['start'] as num).toDouble());
      if (at != null) timer.spokenAt(i, at);
    }
    _report();
    // Vosk starts a new utterance after every final result.
    _tracker.reset();
    timer.newUtterance();
  }

  static String _field(String json, String key) {
    try {
      return ((jsonDecode(json) as Map<String, dynamic>)[key] as String? ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  void _feed(String text, {required bool isFinal}) {
    _set(transcript: text);
    final at = _now();
    timer.result(TranscriptTracker.split(text).length, at);
    var passedOn = false;
    _tracker.update(
      text,
      isFinal: isFinal,
      emit: (w) {
        final heard = _heard(w);
        if (heard == null) return; // "[unk]": speech, but not a word on the page
        timer.passedOn(_tracker.emitted - 1, heard.text, at);
        passedOn = true;
        _words.add(heard);
      },
      acceptEarly: (w) {
        final expected = _expected;
        return w != unk && expected != null && _matcher.matches(expected, w, 'EN');
      },
    );
    if (passedOn) _onNextFrame(_measureScreen);
  }

  /// What a recognized token means for the reading.
  HeardWord? _heard(String token) {
    if (token != unk) return HeardWord(token);
    final expected = _expected;
    // The model can't hear this word, so "[unk]" here is probably it:
    // counted as unsure, never against the child.
    if (expected != null && missingWords.contains(WordMatcher.normalize(expected))) {
      return HeardWord(expected, confidence: 0);
    }
    return null;
  }

  void _measureScreen() {
    timer.painted(_now());
    _report();
  }

  void _report() {
    for (final t in timer.takeComplete()) {
      debugPrint('[speed] Vosk $t');
    }
    _set(speed: timer.summary());
  }

  void _set({MicStatus? status, bool? onDevice, String? transcript, String? lastError, SpeedSummary? speed}) {
    if (_disposed) return; // stop() finishes after dispose()
    _state.value = _state.value.copyWith(
      status: status,
      onDevice: onDevice,
      transcript: transcript,
      lastError: lastError,
      speed: speed,
    );
  }

  @override
  void dispose() {
    stop();
    _disposed = true;
    _words.close();
    _voice.close();
    _state.dispose();
  }
}
