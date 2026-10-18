import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_providers.dart';
import '../data/repositories/settings_repository.dart';
import 'fake_speech_service.dart';
import 'fallback_speech_service.dart';
import 'speech_service.dart';
import 'tts_service.dart';
import 'vosk_health.dart';
import 'vosk_speech_service.dart';

enum SpeechMode {
  /// The microphone with Vosk, offline, listening only for the page's
  /// words. The normal (and only listed) mode. Filipino stories use
  /// tap-to-read, as there is no small Filipino Vosk model.
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

/// The speech service for a story language ("EN" / "FIL"): Vosk for
/// English, tap-to-read for Filipino and in the developer tap mode.
final speechServiceProvider = Provider.family<SpeechService, String>((ref, language) {
  final mode = ref.watch(speechModeProvider).value ?? SpeechMode.vosk;
  final SpeechService service;
  if (mode == SpeechMode.tap || language != 'EN') {
    service = FakeSpeechService();
  } else if (ref.read(voskHealthProvider).value != null) {
    // Vosk was turned off on this phone (an error or a crash): tap to read.
    // (Read, not watched: recording a failure mid-story must not dispose
    // the service that story is using.)
    service = FallbackSpeechService.alreadyFailed(
      fallback: FakeSpeechService.new,
      note: voskOffNote,
    );
  } else {
    // Any error Vosk reports switches the story to tap-to-read on the spot.
    // (The notifier is read now: Vosk also reports "stopped" while this
    // provider is being disposed, when ref can't be used.)
    final health = ref.read(voskHealthProvider.notifier);
    service = FallbackSpeechService(
      primary: VoskSpeechService(
        missingWords: ref.watch(voskMissingWordsProvider).value ?? const {},
        onRunning: health.running,
      ),
      fallback: FakeSpeechService.new,
      onFailed: health.fail,
      note: voskOffNote,
    );
  }
  ref.onDispose(service.dispose);
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) => FlutterTtsService());

/// Story words the offline model doesn't know (loaded at app start).
final voskMissingWordsProvider = FutureProvider<Set<String>>((ref) => loadVoskMissingWords());
