import 'package:drift/drift.dart';

import '../../agent/agent.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

/// The app's local SQLite database (docs/DATA_MODEL.md).
///
/// The real app opens it with `driftDatabase(...)` (see
/// database_providers.dart); tests pass `NativeDatabase.memory()`.
/// After changing a table, run:
///   dart run build_runner build
@DriftDatabase(
  tables: [
    Learners,
    Sessions,
    WordEvents,
    MasteryEntries,
    TrickyWordEntries,
    HintStatEntries,
    Flags,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // SQLite ignores foreign keys unless this is switched on, so
          // deleting a learner would leave their sessions behind.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
