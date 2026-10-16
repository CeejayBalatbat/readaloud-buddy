import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_providers.dart';
import '../data/repositories/settings_repository.dart';

/// How Buddy gives feedback while the child reads (AGENT_SPEC §2).
enum FeedbackMode {
  /// Read first, review after each page: no colors or timed hints while
  /// reading; missed words are practised when the page is done.
  review,

  /// Live colors on every word and timed hints (the Hints setting).
  live,
}

/// The parent's feedback setting, saved in the settings table (default:
/// review).
class FeedbackModeNotifier extends AsyncNotifier<FeedbackMode> {
  @override
  Future<FeedbackMode> build() async {
    final v = await ref.watch(settingsRepositoryProvider).get(SettingKeys.feedbackMode);
    return v == FeedbackMode.live.name ? FeedbackMode.live : FeedbackMode.review;
  }

  Future<void> set(FeedbackMode mode) async {
    await ref.read(settingsRepositoryProvider).set(SettingKeys.feedbackMode, mode.name);
    state = AsyncData(mode);
  }
}

final feedbackModeProvider =
    AsyncNotifierProvider<FeedbackModeNotifier, FeedbackMode>(FeedbackModeNotifier.new);
