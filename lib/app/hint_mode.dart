import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_providers.dart';
import '../data/repositories/settings_repository.dart';

enum HintMode {
  /// Buddy gives hints by himself when the child is stuck (AGENT_SPEC §2).
  automatic,

  /// Hints only come when the child taps Help.
  helpOnly,
}

/// The parent's hint setting, saved in the settings table (default:
/// automatic).
class HintModeNotifier extends AsyncNotifier<HintMode> {
  @override
  Future<HintMode> build() async {
    final v = await ref.watch(settingsRepositoryProvider).get(SettingKeys.hintMode);
    return v == HintMode.helpOnly.name ? HintMode.helpOnly : HintMode.automatic;
  }

  Future<void> set(HintMode mode) async {
    await ref.read(settingsRepositoryProvider).set(SettingKeys.hintMode, mode.name);
    state = AsyncData(mode);
  }
}

final hintModeProvider =
    AsyncNotifierProvider<HintModeNotifier, HintMode>(HintModeNotifier.new);
