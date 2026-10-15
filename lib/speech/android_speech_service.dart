import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../agent/agent.dart';
import 'speech_service.dart';
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
  });
  Future<void> cancel();
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
  }) =>
      _stt.listen(
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
  }) : _engine = engine ?? SpeechToTextEngine.instance;

  final SttEngine _engine;
  final Duration restartDelay;
  final Duration errorRetryDelay;

  static const localeIds = {'EN': 'en-US', 'FIL': 'fil-PH'};

  final _words = StreamController<HeardWord>.broadcast(sync: true);
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

  /// Real errors in a row (not "nothing said"); reset by any result.
  int _failures = 0;
  static const maxFailures = 3;

  @override
  Stream<HeardWord> get words => _words.stream;

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
    final gen = ++_generation;
    _set(status: MicStatus.starting, onDevice: _onDevice, transcript: '');
    try {
      await _engine.listen(
        localeId: localeIds[_language] ?? 'en-US',
        onDevice: _onDevice,
        onResult: (text, isFinal, confidence) {
          if (gen == _generation) _onResult(text, isFinal, confidence);
        },
      );
      if (gen == _generation && _wanted) _set(status: MicStatus.listening);
    } catch (e) {
      _sessionOpen = false;
      _set(lastError: '$e');
      _scheduleRestart(errorRetryDelay);
    }
  }

  void _onResult(String text, bool isFinal, double? confidence) {
    _failures = 0;
    _set(transcript: text);
    _tracker.update(
      text,
      isFinal: isFinal,
      muted: _muted,
      emit: (w) => _words.add(HeardWord(w, confidence: isFinal ? confidence : null)),
      acceptEarly: (w) {
        final expected = _expected;
        return expected != null && _matcher.matches(expected, w, _language);
      },
    );
  }

  void _onStatus(String status) {
    if (status == SpeechToText.listeningStatus) {
      if (_wanted) _set(status: MicStatus.listening);
      return;
    }
    // notListening / done / doneNoResult: Android stopped (often silence).
    _sessionOpen = false;
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
  }) {
    _state.value = _state.value.copyWith(
      status: status,
      onDevice: onDevice,
      transcript: transcript,
      restarts: restarts,
      lastError: lastError,
    );
  }

  @override
  void dispose() {
    _wanted = false;
    _restart?.cancel();
    _words.close();
    _state.dispose();
  }
}
