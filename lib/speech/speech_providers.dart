import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_providers.dart';
import '../data/repositories/settings_repository.dart';
import 'android_speech_service.dart';
import 'fake_speech_service.dart';
import 'speech_service.dart';
import 'tts_service.dart';
import 'fallback_speech_service.dart';
import 'vosk_health.dart';
import 'vosk_speech_service.dart';

enum SpeechMode {
  /// The microphone with Vosk, offline, listening only for the page's
  /// words (default). Filipino stories use the phone's recognizer, as
  /// there is no small Filipino Vosk model.
  vosk,

  /// The microphone and the phone's (Android) speech recognizer.
  voice,

  /// Tap a word to "read" it (testing and demos without speaking).
  tap,
}

/// Microphone modes (not tap-to-read).
bool usesMic(SpeechMode m) => m != SpeechMode.tap;

/// How Buddy listens, saved in the settings table (default: Vosk).
class SpeechModeNotifier extends AsyncNotifier<SpeechMode> {
  @override
  Future<SpeechMode> build() async {
    final v = await ref.watch(settingsRepositoryProvider).get(SettingKeys.speechMode);
    return SpeechMode.values.where((m) => m.name == v).firstOrNull ?? SpeechMode.vosk;
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
  final mode = container.read(speechModeProvider).value ?? SpeechMode.vosk;
  if (usesMic(mode) && language != 'EN') {
    await container.read(voiceLanguageProvider(language).future);
  }
}

/// The speech service for a story language ("EN" / "FIL"): the microphone
/// when chosen and the phone supports the language, else tap-to-read.
final speechServiceProvider = Provider.family<SpeechService, String>((ref, language) {
  final mode = ref.watch(speechModeProvider).value ?? SpeechMode.vosk;
  final phoneCanHear =
      language == 'EN' || ref.watch(voiceLanguageProvider(language)).value == true;
  final SpeechService service = switch (mode) {
    // Offline first; any Vosk failure falls back to the phone recognizer.
    // (Read, not watched: recording a failure mid-story must not dispose
    // the service that story is using.)
    SpeechMode.vosk when language == 'EN' =>
      ref.read(voskHealthProvider).value != null
          ? FallbackSpeechService.alreadyFailed(fallback: AndroidSpeechService.new)
          : FallbackSpeechService(
              primary: VoskSpeechService(
                missingWords: ref.watch(voskMissingWordsProvider).value ?? const {},
                onRunning: (on) => ref.read(voskHealthProvider.notifier).running(on),
              ),
              fallback: AndroidSpeechService.new,
              onFailed: (reason) => ref.read(voskHealthProvider.notifier).fail(reason),
            ),
    SpeechMode.tap => FakeSpeechService(),
    _ when phoneCanHear => AndroidSpeechService(),
    _ => FakeSpeechService(),
  };
  ref.onDispose(service.dispose);
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) => FlutterTtsService());

/// Story words the offline model doesn't know (loaded at app start).
final voskMissingWordsProvider = FutureProvider<Set<String>>((ref) => loadVoskMissingWords());
