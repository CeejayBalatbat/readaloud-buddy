import 'dart:async';

import 'package:flutter/foundation.dart';

import 'speech_service.dart';

/// Tap-to-read stand-in for the microphone, so every screen can be tried
/// without speaking. The reading screen calls [hear] when a word is
/// tapped (read it) or long-pressed (misread it).
class FakeSpeechService implements SpeechService {
  /// Tests can pass `hearsSilence: true` to act like a real microphone.
  FakeSpeechService({this.hearsSilence = false});

  @override
  final bool hearsSilence;

  final _controller = StreamController<HeardWord>.broadcast();
  final _voice = StreamController<void>.broadcast();
  final _state = ValueNotifier(const SpeechState());
  bool _listening = false;
  bool _muted = false;

  /// A "word" that never matches a story word, used for misreads.
  static const misreadWord = 'zzxq';

  @override
  Stream<HeardWord> get words => _controller.stream;

  @override
  Stream<void> get voice => _voice.stream;

  @override
  ValueListenable<SpeechState> get state => _state;

  @override
  bool get isListening => _listening;

  @override
  Future<void> start({required String language}) async {
    _listening = true;
    _state.value = const SpeechState(status: MicStatus.listening);
  }

  @override
  Future<void> stop() async {
    _listening = false;
    _state.value = const SpeechState();
  }

  @override
  set expectedWord(String? word) {}

  @override
  void mute(bool muted) => _muted = muted;

  /// Pretend the child said [word]. Ignored while not listening.
  void hear(String word, {double? confidence}) {
    if (!_listening || _muted) return;
    _state.value = _state.value.copyWith(transcript: word);
    _voice.add(null);
    _controller.add(HeardWord(word, confidence: confidence));
  }

  /// Pretend the child is saying something that isn't a word yet
  /// ("thr… thr…").
  void speak() {
    if (!_listening || _muted) return;
    _voice.add(null);
  }

  @override
  void dispose() {
    _controller.close();
    _voice.close();
    _state.dispose();
  }
}
