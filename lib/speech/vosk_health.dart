import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_providers.dart';
import '../data/repositories/settings_repository.dart';

/// How the app's previous run ended (Android 11+ only).
class AppExit {
  const AppExit({required this.reason, required this.timestamp, this.description = ''});

  /// ApplicationExitInfo reason: 3 = killed for low memory, 4 = Java
  /// crash, 5 = native crash, 6 = not responding (ANR, a freeze).
  final int reason;
  final DateTime timestamp;
  final String description;

  bool get isCrash => reason == 3 || reason == 4 || reason == 5 || reason == 6;
}

abstract class ExitInfo {
  /// null when Android can't say (before Android 11, or no record).
  Future<AppExit?> lastExit();
}

class PlatformExitInfo implements ExitInfo {
  const PlatformExitInfo();
  static const _channel = MethodChannel('readaloud/app_exit');

  @override
  Future<AppExit?> lastExit() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('lastExit');
      if (m == null) return null;
      return AppExit(
        reason: m['reason'] as int,
        timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
        description: m['description'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

final exitInfoProvider = Provider<ExitInfo>((ref) => const PlatformExitInfo());

/// Whether the offline recognizer (Vosk) for a language ("EN" or "FIL")
/// works on this phone. Holds the reason it was turned off, or null while
/// it is fine. Each language is protected on its own: the big Filipino
/// model can fail on a phone where English works.
///
/// Errors Vosk reports are caught where they happen ([fail]). A crash
/// inside Vosk's native code can't be caught, so the app marks Vosk as
/// running ([running]) and, at the next start, if the mark is still there
/// and Android says the last run crashed, records the failure. Either way
/// stories then use tap-to-read until a grown-up taps "Try offline again"
/// in Settings ([retry]).
class VoskHealth extends AsyncNotifier<String?> {
  VoskHealth(this.language);

  final String language;

  static const crashReason = 'The offline recognizer stopped the app last time.';

  String get _activeKey => SettingKeys.vosk(language).$1;
  String get _failedKey => SettingKeys.vosk(language).$2;

  @override
  Future<String?> build() async {
    final settings = ref.watch(settingsRepositoryProvider);
    final failed = await settings.get(_failedKey);
    final active = await settings.get(_activeKey);
    if (active == null) return failed;
    // The app ended while Vosk was running.
    await settings.remove(_activeKey);
    final since = DateTime.fromMillisecondsSinceEpoch(int.tryParse(active) ?? 0);
    final exit = await ref.watch(exitInfoProvider).lastExit();
    // Unknown (older Android) counts as a crash: better tap-to-read than
    // a child's app closing again.
    final crashed = exit == null || (exit.isCrash && !exit.timestamp.isBefore(since));
    if (!crashed) return failed;
    await settings.set(_failedKey, crashReason);
    return crashReason;
  }

  /// Vosk's native code is (or stops being) in use.
  Future<void> running(bool on) async {
    final settings = ref.read(settingsRepositoryProvider);
    if (on) {
      await settings.set(_activeKey, '${DateTime.now().millisecondsSinceEpoch}');
    } else {
      await settings.remove(_activeKey);
    }
  }

  Future<void> fail(String reason) async {
    await ref.read(settingsRepositoryProvider).set(_failedKey, reason);
    state = AsyncData(reason);
  }

  Future<void> retry() async {
    await ref.read(settingsRepositoryProvider).remove(_failedKey);
    state = const AsyncData(null);
  }
}

/// Per language: `voskHealthProvider('EN')`, `voskHealthProvider('FIL')`.
final voskHealthProvider =
    AsyncNotifierProvider.family<VoskHealth, String?, String>(VoskHealth.new);
