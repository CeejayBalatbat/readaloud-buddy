import 'package:drift/drift.dart';

import '../../agent/agent.dart';
import '../db/app_database.dart';

/// Save and load what Buddy has learned about a learner: sound mastery,
/// tricky words, hint success rates and teacher flags.
class ProgressRepository {
  ProgressRepository(this._db, {DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  // ---- Sound mastery (§7) ----

  Future<SoundMastery> loadMastery(String learnerId) async {
    final rows = await (_db.select(_db.masteryEntries)
          ..where((m) => m.learnerId.equals(learnerId)))
        .get();
    return SoundMastery(
      mastery: {for (final r in rows) r.patternCode: r.mastery},
      observations: {for (final r in rows) r.patternCode: r.observations},
    );
  }

  /// Writes only the patterns whose value changed, so `updated_at` shows
  /// when each sound was last practised.
  Future<void> saveMastery(String learnerId, SoundMastery mastery) =>
      _db.transaction(() async {
        final before = await loadMastery(learnerId);
        final now = _now();
        await _db.batch((b) {
          for (final MapEntry(key: code, value: m) in mastery.all.entries) {
            final obs = mastery.observationsOf(code);
            if (before.all[code] == m && before.observationsOf(code) == obs) {
              continue;
            }
            b.insert(
              _db.masteryEntries,
              MasteryEntriesCompanion.insert(
                learnerId: learnerId,
                patternCode: code,
                mastery: m,
                observations: obs,
                updatedAt: now,
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
      });

  // ---- Tricky words (§8) ----

  Future<TrickyWords> loadTrickyWords(String learnerId) async =>
      TrickyWords(words: [
        for (final r in await _trickyRows(learnerId))
          TrickyWord(
            word: r.word,
            patternCode: r.patternCode,
            cleanReads: r.cleanReads,
          ),
      ]);

  /// The tricky-word rows (with `addedAt`) for the Results screen.
  Future<List<TrickyWordEntry>> trickyWordEntries(String learnerId) =>
      _trickyRows(learnerId);

  Future<List<TrickyWordEntry>> _trickyRows(String learnerId) =>
      (_db.select(_db.trickyWordEntries)
            ..where((t) => t.learnerId.equals(learnerId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.addedAt),
              (t) => OrderingTerm(expression: t.rowId),
            ]))
          .get();

  /// Replaces the learner's list with [tricky]. Words already on the list
  /// keep their original `added_at`.
  Future<void> saveTrickyWords(String learnerId, TrickyWords tricky) =>
      _db.transaction(() async {
        final addedAt = {
          for (final r in await _trickyRows(learnerId)) r.word: r.addedAt,
        };
        await (_db.delete(_db.trickyWordEntries)
              ..where((t) => t.learnerId.equals(learnerId)))
            .go();
        final now = _now();
        await _db.batch((b) => b.insertAll(_db.trickyWordEntries, [
              for (final w in tricky.words)
                TrickyWordEntriesCompanion.insert(
                  learnerId: learnerId,
                  word: w.word,
                  patternCode: w.patternCode,
                  addedAt: addedAt[w.word] ?? now,
                  cleanReads: Value(w.cleanReads),
                ),
            ]));
      });

  // ---- Hint learning (§2) ----

  Future<HintStats> loadHintStats(String learnerId) async {
    final rows = await (_db.select(_db.hintStatEntries)
          ..where((h) => h.learnerId.equals(learnerId)))
        .get();
    return HintStats({for (final r in rows) r.hintLevel: (r.uses, r.successes)});
  }

  Future<void> saveHintStats(String learnerId, HintStats stats) =>
      _db.batch((b) {
        for (final MapEntry(key: level, value: (uses, ok))
            in stats.counts.entries) {
          b.insert(
            _db.hintStatEntries,
            HintStatEntriesCompanion.insert(
              learnerId: learnerId,
              hintLevel: level,
              uses: uses,
              successes: ok,
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

  // ---- Teacher flags (§10) ----

  /// Adds each reason as a flag, unless the same reason is already waiting
  /// unseen.
  Future<void> addFlags(String learnerId, List<String> reasons) =>
      _db.transaction(() async {
        final waiting = {for (final f in await unseenFlags(learnerId)) f.reason};
        for (final r in reasons.where((r) => !waiting.contains(r))) {
          await _db.into(_db.flags).insert(FlagsCompanion.insert(
                learnerId: learnerId,
                reason: r,
                createdAt: _now(),
              ));
        }
      });

  Future<List<TeacherFlag>> unseenFlags(String learnerId) =>
      (_db.select(_db.flags)
            ..where((f) => f.learnerId.equals(learnerId) & f.seen.equals(false))
            ..orderBy([(f) => OrderingTerm(expression: f.createdAt)]))
          .get();

  Future<void> markFlagsSeen(String learnerId) =>
      (_db.update(_db.flags)..where((f) => f.learnerId.equals(learnerId)))
          .write(const FlagsCompanion(seen: Value(true)));
}
