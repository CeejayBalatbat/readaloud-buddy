import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../agent/agent.dart';
import 'speech_service.dart';
import 'speech_timing.dart';
import 'transcript_tracker.dart';

/// The bits of the speech_to_text plugin we use, so the service logic can
/// be tested with a fake engine.
abstract class SttEngine {
  /// Returns false if the mic permission was refused or no recognizer exists.
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String error, bool permanent) onError,
  });
  Future<bool> get hasPermission;
  Future<void> listen({
    required String localeId,
    required bool onDevice,
    required void Function(String words, bool isFinal, double? confidence) onResult,
    void Function(double rmsDb)? onSoundLevel,
  });
  Future<void> cancel();

  /// Locale ids the phone's recognizer offers, e.g. "en_US", "fil_PH".
  /// May be empty when the phone doesn't say.
  Future<List<String>> locales();
}

/// speech_to_text keeps one recognizer for the whole app, so this engine
/// is shared too and just forwards events to whoever started it last.
class SpeechToTextEngine implements SttEngine {
  SpeechToTextEngine._();
  static final instance = SpeechToTextEngine._();

  final _stt = SpeechToText();
  bool _ready = false;
  void Function(String)? _onStatus;
  void Function(String, bool)? _onError;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String error, bool permanent) onError,
  }) async {
    _onStatus = onStatus;
    _onError = onError;
    if (_ready) return true;
    _ready = await _stt.initialize(
      onStatus: (s) => _onStatus?.call(s),
      onError: (e) => _onError?.call(e.errorMsg, e.permanent),
      // Wait at most this long for Android's final result after a stop.
      finalTimeout: const Duration(milliseconds: 800),
    );
    return _ready;
  }

  @override
  Future<bool> get hasPermission => _stt.hasPermission;

  @override
  Future<void> listen({
    required String localeId,
    required bool onDevice,
    required void Function(String words, bool isFinal, double? confidence) onResult,
    void Function(double rmsDb)? onSoundLevel,
  }) =>
      _stt.listen(
        onSoundLevelChange: onSoundLevel,
        onResult: (SpeechRecognitionResult r) => onResult(
          r.recognizedWords,
          r.finalResult,
          r.hasConfidenceRating ? r.confidence : null,
        ),
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          onDevice: onDevice,
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );

  @override
  Future<void> cancel() => _stt.cancel();

  @override
  Future<List<String>> locales() async =>
      [for (final l in await _stt.locales()) l.localeId];
}

/// Phone speech recognition (AGENT_SPEC "Speech recognition"): Android's
/// recognizer via speech_to_text, on-device first and online as a fallback,
/// with partial results. Android stops listening after a silence; while a
/// story is open we start again automatically (the hint timer is separate
/// and keeps running).
class AndroidSpeechService implements SpeechService {
  AndroidSpeechService({
    SttEngine? engine,
    this.restartDelay = const Duration(milliseconds: 250),
    this.errorRetryDelay = const Duration(seconds: 1),
    Duration Function()? now,
    void Function(void Function() callback)? onNextFrame,
  })  : _engine = engine ?? SpeechToTextEngine.instance,
        _now = now ?? _stopwatch(),
        _onNextFrame = onNextFrame ?? _afterNextFrame;

  static Duration Function() _stopwatch() {
    final w = Stopwatch()..start();
    return () => w.elapsed;
  }

  static void _afterNextFrame(void Function() callback) =>
      SchedulerBinding.instance.addPostFrameCallback((_) => callback());

  final SttEngine _engine;
  final Duration Function() _now;
  final void Function(void Function()) _onNextFrame;

  /// Speech-to-screen delay, word by word (see [WordTiming]).
  final timer = SpeechTimer();
  final Duration restartDelay;
  final Duration errorRetryDelay;

  static const localeIds = {'EN': 'en-US', 'FIL': 'fil-PH'};

  /// Whether the phone's recognizer can do [language] ("EN"/"FIL"). For
  /// Filipino it looks for fil-PH (or tl-PH, the older Tagalog code).
  /// When the phone lists no locales at all, the answer is unknown and we
  /// say yes: the recognizer then reports an error if it really can't.
  static Future<bool> supportsLanguage(SttEngine engine, String language) async {
    if (language == 'EN') return true;
    final ok = await engine.initialize(onStatus: (_) {}, onError: (_, _) {});
    if (!ok) return false;
    final ids = [
      for (final id in await engine.locales()) id.toLowerCase().replaceAll('_', '-'),
    ];
    if (ids.isEmpty) return true;
    final codes = language == 'FIL' ? ['fil', 'tl'] : [language.toLowerCase()];
    return ids.any((id) => codes.any((c) => id == c || id.startsWith('$c-')));
  }

  final _words = StreamController<HeardWord>.broadcast(sync: true);
  final _voice = StreamController<void>.broadcast(sync: true);
  final _state = ValueNotifier(const SpeechState());
  final _tracker = TranscriptTracker();
  final _matcher = const WordMatcher();

  String _language = 'EN';
  bool _wanted = false; // a story is open and not paused
  bool _sessionOpen = false;
  bool _onDevice = true;
  bool _muted = false;
  String? _expected;
  Timer? _restart;
  int _generation = 0; // ignores results from an old listen session
  String? _held; // first half of a hyphenated word (araw-araw)

  /// Real errors in a row (not "nothing said"); reset by any result.
  int _failures = 0;
  static const maxFailures = 3;

  @override
  Stream<HeardWord> get words => _words.stream;

  @override
  Stream<void> get voice => _voice.stream;

  @override
  bool get hearsSilence => true;

  @override
  ValueListenable<SpeechState> get state => _state;

  @override
  bool get isListening => _state.value.status == MicStatus.listening;

  @override
  set expectedWord(String? word) => _expected = word;

  @override
  void mute(bool muted) => _muted = muted;

  @override
  Future<void> start({required String language}) async {
    _language = language;
    _wanted = true;
    _failures = 0;
    _set(status: MicStatus.starting);
    final ok = await _engine.initialize(onStatus: _onStatus, onError: _onError);
    if (!_wanted) return;
    if (!ok) {
      _wanted = false;
      _set(status: await _engine.hasPermission ? MicStatus.unavailable : MicStatus.noPermission);
      return;
    }
    await _listen();
  }

  @override
  Future<void> stop() async {
    _wanted = false;
    _restart?.cancel();
    _generation++;
    _sessionOpen = false;
    _set(status: MicStatus.off);
    await _engine.cancel();
  }

  Future<void> _listen() async {
    if (!_wanted || _sessionOpen) return;
    _sessionOpen = true;
    _tracker.reset();
    timer.newUtterance();
    final gen = ++_generation;
    _set(status: MicStatus.starting, onDevice: _onDevice, transcript: '');
    try {
      await _engine.listen(
        localeId: localeIds[_language] ?? 'en-US',
        onDevice: _onDevice,
        onResult: (text, isFinal, confidence) {
          if (gen == _generation) _onResult(text, isFinal, confidence);
        },
        onSoundLevel: (rms) {
          if (gen == _generation && !_muted) timer.soundLevel(rms, _now());
        },
      );
      if (gen == _generation && _wanted) {
        timer.listening(_now());
        _set(status: MicStatus.listening);
      }
    } catch (e) {
      _sessionOpen = false;
      _set(lastError: '$e');
      _scheduleRestart(errorRetryDelay);
    }
  }

  void _onResult(String text, bool isFinal, double? confidence) {
    _failures = 0;
    // New text = the recognizer heard more speech. (The final result often
    // repeats the last partial; that is not new speech.)
    if (!_muted && text.trim().isNotEmpty && text != _state.value.transcript) {
      _voice.add(null);
    }
    _set(transcript: text);
    final at = _now();
    timer.result(TranscriptTracker.split(text).length, at);
    var passedOn = false;
    _tracker.update(
      text,
      isFinal: isFinal,
      muted: _muted,
      emit: (w) {
        timer.passedOn(_tracker.emitted - 1, w, at);
        passedOn = true;
        _emit(w, isFinal ? confidence : null);
      },
      acceptEarly: (w) {
        final expected = _expected;
        return expected != null && _matcher.matches(expected, w, _language);
      },
    );
    if (passedOn) _onNextFrame(_measureScreen);
  }

  /// Passes [w] on. Recognizers write hyphenated words as two ("araw
  /// araw"), so when the expected word has a hyphen and [w] is its first
  /// half, it is held and joined with the next word.
  void _emit(String w, double? confidence) {
    final held = _held;
    if (held != null) {
      _held = null;
      _words.add(HeardWord('$held-$w', confidence: confidence));
      return;
    }
    final expected = _expected;
    if (expected != null && expected.contains('-')) {
      final e = WordMatcher.normalize(expected), h = WordMatcher.normalize(w);
      if (h.isNotEmpty && h.length < e.length && e.startsWith(h)) {
        _held = w;
        return;
      }
    }
    _words.add(HeardWord(w, confidence: confidence));
  }

  void _measureScreen() {
    for (final t in timer.painted(_now())) {
      debugPrint('[speed] $t');
    }
    _set(speed: timer.summary());
  }

  void _onStatus(String status) {
    if (status == SpeechToText.listeningStatus) {
      if (_wanted) _set(status: MicStatus.listening);
      return;
    }
    // notListening / done / doneNoResult: Android stopped (often silence).
    _sessionOpen = false;
    timer.stopped(_now());
    if (_wanted) _scheduleRestart(restartDelay);
  }

  void _onError(String error, bool permanent) {
    _set(lastError: error);
    _sessionOpen = false;
    switch (error) {
      case 'error_permission':
      case 'error_insufficient_permissions':
        _wanted = false;
        _set(status: MicStatus.noPermission);
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        if (_onDevice) {
          // No on-device model for this language: fall back to online.
          _onDevice = false;
          _scheduleRestart(restartDelay);
        } else {
          _wanted = false;
          _set(status: MicStatus.unavailable);
        }
      case 'error_no_match':
      case 'error_speech_timeout':
        // Normal: nothing was said. Listen again.
        if (_wanted) _scheduleRestart(restartDelay);
      default:
        // e.g. no network for the online recognizer: try a few times, then
        // tell the child's grown-up (tapping the mic tries again).
        if (++_failures >= maxFailures) {
          _wanted = false;
          _set(status: MicStatus.unavailable);
        } else if (_wanted) {
          _scheduleRestart(errorRetryDelay);
        }
    }
  }

  void _scheduleRestart(Duration delay) {
    if (_restart?.isActive ?? false) return;
    _restart = Timer(delay, () {
      if (!_wanted || _sessionOpen) return;
      _set(restarts: _state.value.restarts + 1);
      _listen();
    });
  }

  void _set({
    MicStatus? status,
    bool? onDevice,
    String? transcript,
    int? restarts,
    String? lastError,
    SpeedSummary? speed,
  }) {
    _state.value = _state.value.copyWith(
      status: status,
      onDevice: onDevice,
      transcript: transcript,
      restarts: restarts,
      lastError: lastError,
      speed: speed,
    );
  }

  @override
  void dispose() {
    _wanted = false;
    _restart?.cancel();
    _words.close();
    _voice.close();
    _state.dispose();
  }
}
