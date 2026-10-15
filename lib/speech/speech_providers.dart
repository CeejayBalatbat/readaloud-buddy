import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_providers.dart';
import '../data/repositories/settings_repository.dart';
import 'android_speech_service.dart';
import 'fake_speech_service.dart';
import 'speech_service.dart';
import 'tts_service.dart';

enum SpeechMode {
  /// The microphone and the phone's speech recognizer.
  voice,

  /// Tap a word to "read" it (testing and demos without speaking).
  tap,
}

/// Story languages the voice mode handles so far. Other languages use
/// tap-to-read until their recognizer is added.
const voiceLanguages = {'EN'};

/// Voice or tap, saved in the settings table (default: voice).
class SpeechModeNotifier extends AsyncNotifier<SpeechMode> {
  @override
  Future<SpeechMode> build() async {
    final v = await ref.watch(settingsRepositoryProvider).get(SettingKeys.speechMode);
    return v == SpeechMode.tap.name ? SpeechMode.tap : SpeechMode.voice;
  }

  Future<void> set(SpeechMode mode) async {
    await ref.read(settingsRepositoryProvider).set(SettingKeys.speechMode, mode.name);
    state = AsyncData(mode);
  }
}

final speechModeProvider =
    AsyncNotifierProvider<SpeechModeNotifier, SpeechMode>(SpeechModeNotifier.new);

/// The speech service for a story language ("EN" / "FIL").
final speechServiceProvider = Provider.family<SpeechService, String>((ref, language) {
  final mode = ref.watch(speechModeProvider).value ?? SpeechMode.voice;
  final SpeechService service =
      mode == SpeechMode.voice && voiceLanguages.contains(language)
          ? AndroidSpeechService()
          : FakeSpeechService();
  ref.onDispose(service.dispose);
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) => FlutterTtsService());
