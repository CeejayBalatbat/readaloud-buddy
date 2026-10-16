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

/// The phone's speech recognizer (tests replace it).
final sttEngineProvider = Provider<SttEngine>((ref) => SpeechToTextEngine.instance);

/// Whether the phone can recognize a story language. English always;
/// Filipino only if the recognizer offers fil-PH. Checked once, the first
/// time a Filipino story opens in microphone mode (it asks for the mic).
final voiceLanguageProvider = FutureProvider.family<bool, String>((ref, language) async {
  try {
    return await AndroidSpeechService.supportsLanguage(ref.watch(sttEngineProvider), language);
  } catch (_) {
    return false;
  }
});

/// Before opening a story: makes sure we know whether its language can use
/// the microphone, so [speechServiceProvider] picks the right service.
Future<void> prepareVoice(ProviderContainer container, String language) async {
  final mode = container.read(speechModeProvider).value ?? SpeechMode.voice;
  if (mode == SpeechMode.voice && language != 'EN') {
    await container.read(voiceLanguageProvider(language).future);
  }
}

/// The speech service for a story language ("EN" / "FIL"): the microphone
/// when chosen and the phone supports the language, else tap-to-read.
final speechServiceProvider = Provider.family<SpeechService, String>((ref, language) {
  final mode = ref.watch(speechModeProvider).value ?? SpeechMode.voice;
  final voice = mode == SpeechMode.voice &&
      (language == 'EN' || ref.watch(voiceLanguageProvider(language)).value == true);
  final SpeechService service = voice ? AndroidSpeechService() : FakeSpeechService();
  ref.onDispose(service.dispose);
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) => FlutterTtsService());
