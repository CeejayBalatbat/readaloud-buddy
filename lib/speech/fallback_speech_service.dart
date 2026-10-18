import 'dart:async';

import 'package:flutter/foundation.dart';

import 'fake_speech_service.dart';
import 'speech_service.dart';

/// Runs a [primary] recognizer (Vosk) and, if it reports a failure, swaps
/// to a [fallback] (tap-to-read) on the spot: the reading goes on, the
/// screen shows [note], and [onFailed] records why so later stories don't
/// try the primary again.
///
/// A missing microphone permission is not a recognizer failure (the child
/// or a grown-up can still allow it), so it doesn't trigger a swap.
class FallbackSpeechService implements SpeechService {
  FallbackSpeechService({
    required SpeechService primary,
    required SpeechService Function() fallback,
    required this.onFailed,
    this.note = defaultNote,
  })  : _current = primary,
        _makeFallback = fallback {
    _attach();
  }

  /// Starts on the fallback straight away (the primary failed before).
  FallbackSpeechService.alreadyFailed({
    required SpeechService Function() fallback,
    this.note = defaultNote,
  })  : _current = fallback(),
        _makeFallback = fallback,
        onFailed = _noop,
        _switched = true {
    _attach();
  }

  static void _noop(String _) {}

  static const defaultNote = "Offline listening isn't working on this phone.";

  final SpeechService Function() _makeFallback;
  final void Function(String reason) onFailed;
  final String note;

  SpeechService _current;
  bool _switched = false;
  bool _disposed = false;
  String? _language; // set while a story wants to listen
  String? _expected;
  List<String> _vocabulary = const [];
  bool _muted = false;

  final _words = StreamController<HeardWord>.broadcast(sync: true);
  final _voice = StreamController<void>.broadcast(sync: true);
  final _state = ValueNotifier(const SpeechState());
  StreamSubscription<HeardWord>? _wordSub;
  StreamSubscription<void>? _voiceSub;

  /// True once the fallback is in use.
  bool get usingFallback => _switched;

  /// The service in use right now (the primary or the fallback).
  SpeechService get current => _current;

  void _attach() {
    _wordSub = _current.words.listen(_words.add);
    _voiceSub = _current.voice.listen(_voice.add);
    _current.state.addListener(_onState);
    _onState();
  }

  void _detach() {
    _wordSub?.cancel();
    _voiceSub?.cancel();
    _current.state.removeListener(_onState);
  }

  void _onState() {
    final s = _current.state.value;
    if (!_switched && s.status == MicStatus.unavailable) {
      _swap(s.lastError ?? 'The offline recognizer is not available.');
      return;
    }
    _state.value = _switched ? s.copyWith(notice: note) : s;
  }

  /// Leaves the failed primary and carries on with the fallback.
  void _swap(String reason) {
    if (_disposed) return;
    _switched = true;
    onFailed(reason);
    final failed = _current;
    _detach();
    // The primary may be in a bad state: stop it without letting its
    // errors reach the child.
    unawaited(Future(() async {
      try {
        await failed.stop();
      } catch (_) {}
      try {
        failed.dispose();
      } catch (_) {}
    }));
    _current = _makeFallback();
    _attach();
    _current
      ..expectedWord = _expected
      ..vocabulary = _vocabulary
      ..mute(_muted);
    final language = _language;
    if (language != null) unawaited(_current.start(language: language));
  }

  @override
  Stream<HeardWord> get words => _words.stream;
  @override
  Stream<void> get voice => _voice.stream;
  @override
  bool get hearsSilence => _current.hearsSilence;
  @override
  ValueListenable<SpeechState> get state => _state;
  @override
  bool get isListening => _current.isListening;

  @override
  set expectedWord(String? word) => _current.expectedWord = _expected = word;

  @override
  set vocabulary(List<String> words) => _current.vocabulary = _vocabulary = words;

  @override
  void mute(bool muted) => _current.mute(_muted = muted);

  @override
  Future<void> start({required String language}) async {
    _language = language;
    try {
      await _current.start(language: language);
    } catch (e) {
      if (!_switched) _swap('$e');
    }
  }

  @override
  Future<void> stop() async {
    _language = null;
    try {
      await _current.stop();
    } catch (e) {
      if (!_switched) _swap('$e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _detach();
    _current.dispose();
    _words.close();
    _voice.close();
    _state.dispose();
  }
}

/// The tap-to-read service behind [s], if the child reads by tapping (tap
/// mode, a Filipino story, or Vosk switched off). Null with a microphone.
FakeSpeechService? tapToRead(SpeechService s) => switch (s) {
      FakeSpeechService() => s,
      FallbackSpeechService(current: final FakeSpeechService fake) => fake,
      _ => null,
    };
