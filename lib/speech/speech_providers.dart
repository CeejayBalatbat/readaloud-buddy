import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_speech_service.dart';
import 'speech_service.dart';
import 'tts_service.dart';

/// Phase 3 uses tap-to-read. Phase 4 swaps in the real recognizer here.
final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = FakeSpeechService();
  ref.onDispose(service.dispose);
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) => FlutterTtsService());
