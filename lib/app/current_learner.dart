import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_providers.dart';
import '../data/db/app_database.dart';
import '../data/repositories/settings_repository.dart';

/// The reader using the app right now (several can share one phone).
/// Null when nobody has been set up yet.
class CurrentLearner extends AsyncNotifier<Learner?> {
  @override
  Future<Learner?> build() async {
    final learners = ref.watch(learnerRepositoryProvider);
    final id = await ref
        .watch(settingsRepositoryProvider)
        .get(SettingKeys.activeLearnerId);
    if (id != null) {
      final learner = await learners.byId(id);
      if (learner != null) return learner;
    }
    final all = await learners.all();
    return all.isEmpty ? null : all.first;
  }

  /// Switch to another reader.
  Future<void> select(String learnerId) async {
    await ref
        .read(settingsRepositoryProvider)
        .set(SettingKeys.activeLearnerId, learnerId);
    ref.invalidateSelf();
    await future;
  }

  /// Reload after the learner's row changed (level, stars, ...).
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

final currentLearnerProvider =
    AsyncNotifierProvider<CurrentLearner, Learner?>(CurrentLearner.new);
