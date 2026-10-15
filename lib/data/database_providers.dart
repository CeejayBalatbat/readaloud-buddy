import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'repositories/learner_repository.dart';
import 'repositories/progress_repository.dart';
import 'repositories/session_repository.dart';
import 'repositories/settings_repository.dart';

/// The one database for the whole app, stored on the phone as
/// `readaloud_buddy.sqlite`. Tests override this with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'readaloud_buddy'));
  ref.onDispose(db.close);
  return db;
});

final learnerRepositoryProvider = Provider(
  (ref) => LearnerRepository(ref.watch(appDatabaseProvider)),
);

final sessionRepositoryProvider = Provider(
  (ref) => SessionRepository(ref.watch(appDatabaseProvider)),
);

final progressRepositoryProvider = Provider(
  (ref) => ProgressRepository(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);
