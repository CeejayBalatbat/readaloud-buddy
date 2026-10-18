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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await _toReadingScore(m);
        },
        beforeOpen: (details) async {
          // SQLite ignores foreign keys unless this is switched on, so
          // deleting a learner would leave their sessions behind.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Version 2: fixed levels 1–4 became the reading score (AGENT_SPEC §5).
  /// Old levels map to the middle of their old range: 1 → 10, 2 → 30,
  /// 3 → 50, 4 → 70 (book difficulty the same way). Sessions saved before
  /// had no prediction.
  Future<void> _toReadingScore(Migrator m) async {
    const score = '(current_level - 1) * 20 + 10';
    await m.alterTable(TableMigration(learners, columnTransformer: {
      learners.readingScore: const CustomExpression<double>(score),
    }, newColumns: [
      learners.predictionBias,
    ]));
    await m.alterTable(TableMigration(sessions, columnTransformer: {
      sessions.bookDifficulty: const CustomExpression<double>('(level_before - 1) * 20 + 10'),
      sessions.scoreBefore: const CustomExpression<double>('(level_before - 1) * 20 + 10'),
      sessions.scoreAfter: const CustomExpression<double>('(level_after - 1) * 20 + 10'),
    }, newColumns: [
      sessions.predictedAccuracy,
    ]));
  }
}
