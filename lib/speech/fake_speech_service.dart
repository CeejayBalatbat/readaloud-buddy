import 'dart:async';

import 'speech_service.dart';

/// Tap-to-read stand-in for the microphone, so every screen can be tried
/// without speaking. The reading screen calls [hear] when a word is
/// tapped (read it) or long-pressed (misread it).
class FakeSpeechService implements SpeechService {
  final _controller = StreamController<HeardWord>.broadcast();
  bool _listening = false;

  /// A "word" that never matches a story word, used for misreads.
  static const misreadWord = 'zzxq';

  @override
  Stream<HeardWord> get words => _controller.stream;

  @override
  bool get isListening => _listening;

  @override
  Future<void> start({required String language}) async => _listening = true;

  @override
  Future<void> stop() async => _listening = false;

  /// Pretend the child said [word]. Ignored while not listening.
  void hear(String word, {double? confidence}) {
    if (_listening) _controller.add(HeardWord(word, confidence: confidence));
  }

  @override
  void dispose() => _controller.close();
}
