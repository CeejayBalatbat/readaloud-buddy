import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent_config.dart';
import '../data/database_providers.dart';
import '../data/repositories/settings_repository.dart';
import 'device_info.dart';
import 'fake_speech_service.dart';
import 'fallback_speech_service.dart';
import 'filipino_model.dart';
import 'speech_service.dart';
import 'tts_service.dart';
import 'vosk_health.dart';
import 'vosk_speech_service.dart';

enum SpeechMode {
  /// The microphone with Vosk, offline: English with the bundled model,
  /// Filipino with the downloaded one (tap-to-read until it is set up).
  vosk,

  /// Tap a word to "read" it, for every story. A hidden developer/demo
  /// option (long-press "How Buddy listens" in Settings).
  tap,
}

/// How Buddy listens, saved in the settings table (default: Vosk). Old
/// saved values (e.g. the removed phone recognizer) read as Vosk.
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

/// Shown on the reading screen when Vosk failed and the story switched to
/// tap-to-read.
const voskOffNote =
    "Offline listening isn't working on this phone, so tap each word as you read it.";
const filipinoOffNote =
    "Filipino listening is too heavy for this phone, so tap each word as you read it.";

/// The speech service for a story language ("EN" / "FIL"): Vosk, or
/// tap-to-read in the developer tap mode, for Filipino until its model is
/// set up, and whenever Vosk failed for that language.
final speechServiceProvider = Provider.family<SpeechService, String>((ref, language) {
  final mode = ref.watch(speechModeProvider).value ?? SpeechMode.vosk;
  final filipino = language == 'FIL';
  final note = filipino ? filipinoOffNote : voskOffNote;
  final modelPath = filipino ? ref.watch(filipinoModelProvider).path : null;
  final SpeechService service;
  if (mode == SpeechMode.tap || (filipino && modelPath == null)) {
    service = FakeSpeechService();
  } else if (ref.read(voskHealthProvider(language)).value != null) {
    // Vosk was turned off for this language (an error, a crash or too
    // heavy): tap to read. (Read, not watched: recording a failure
    // mid-story must not dispose the service that story is using.)
    service = FallbackSpeechService.alreadyFailed(fallback: FakeSpeechService.new, note: note);
  } else {
    // Any error Vosk reports switches the story to tap-to-read on the spot.
    // (The notifier is read now: Vosk also reports "stopped" while this
    // provider is being disposed, when ref can't be used.)
    final health = ref.read(voskHealthProvider(language).notifier);
    final missing = ref.watch(voskMissingWordsProvider).value ?? const VoskMissingWords();
    const config = AgentConfig();
    final device = ref.read(deviceInfoProvider);
    service = FallbackSpeechService(
      primary: filipino
          ? VoskSpeechService(
              engine: VoskFlutterEngine.filipino(modelPath!),
              language: 'FIL',
              missingWords: missing.filipino,
              onRunning: health.running,
              beforeLoad: () => checkFreeMemory(device, config.filMinFreeMemoryMb),
              loadTimeout: Duration(seconds: config.filMaxLoadSeconds),
              maxRecognizerMs: config.filMaxRecognizerMs,
            )
          : VoskSpeechService(
              missingWords: missing.english,
              onRunning: health.running,
            ),
      fallback: FakeSpeechService.new,
      onFailed: health.fail,
      note: note,
    );
  }
  ref.onDispose(service.dispose);
  return service;
});

/// Refuses to load a big model when the phone is short of memory (Android
/// would otherwise close the app).
Future<void> checkFreeMemory(DeviceInfo device, int needMb) async {
  final m = await device.memory();
  if (m != null && m.freeMb < needMb) {
    throw StateError('not enough free memory (${m.freeMb} MB free, needs about $needMb MB). '
        'Closing other apps may help.');
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) => FlutterTtsService());

/// Story words the offline models don't know (loaded at app start).
final voskMissingWordsProvider = FutureProvider<VoskMissingWords>((ref) => loadVoskMissingWords());
