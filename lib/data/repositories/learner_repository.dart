import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../agent/agent.dart';
import '../db/app_database.dart';

const allowedLanguages = {'EN', 'FIL', 'EN,FIL'};

/// Save and load readers. A learner is stored by nickname + generated id
/// only (privacy rule in docs/ARCHITECTURE.md).
class LearnerRepository {
  LearnerRepository(this._db, {DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  Future<Learner> create({
    required String nickname,
    required int grade,
    required String languages,
    String? classCode,
    double? readingScore,
  }) async {
    final name = nickname.trim();
    if (name.isEmpty) throw ArgumentError.value(nickname, 'nickname');
    if (grade < 0 || grade > 3) throw ArgumentError.value(grade, 'grade');
    if (!allowedLanguages.contains(languages)) {
      throw ArgumentError.value(languages, 'languages');
    }
    final learner = Learner(
      id: _uuid.v4(),
      nickname: name,
      grade: grade,
      languages: languages,
      classCode: classCode,
      readingScore: readingScore ?? const AgentConfig().startScoreDefault,
      dyslexiaMode: false,
      textScale: 1.0,
      highContrast: false,
      readAloud: true,
      startHintLevel: 1,
      stars: 0,
      createdAt: _now(),
    );
    await _db.into(_db.learners).insert(learner);
    return learner;
  }

  Future<Learner?> byId(String id) =>
      (_db.select(_db.learners)..where((l) => l.id.equals(id)))
          .getSingleOrNull();

  /// All readers on this phone, oldest first.
  Future<List<Learner>> all() => _allQuery().get();
  Stream<List<Learner>> watchAll() => _allQuery().watch();

  SimpleSelectStatement<$LearnersTable, Learner> _allQuery() =>
      _db.select(_db.learners)
        ..orderBy([
          (l) => OrderingTerm(expression: l.createdAt),
          (l) => OrderingTerm(expression: l.rowId), // same-second tie-break
        ]);

  /// Saves every field of [learner] (e.g. after the settings screen).
  Future<void> update(Learner learner) =>
      _db.update(_db.learners).replace(learner);

  /// The starting score from the reading check (AGENT_SPEC §6).
  Future<void> setReadingScore(String id, double score) =>
      (_db.update(_db.learners)..where((l) => l.id.equals(id)))
          .write(LearnersCompanion(readingScore: Value(score)));

  Future<void> setStartHintLevel(String id, int level) =>
      (_db.update(_db.learners)..where((l) => l.id.equals(id)))
          .write(LearnersCompanion(startHintLevel: Value(level)));

  Future<void> addStars(String id, int stars) => _db.customUpdate(
        'UPDATE learners SET stars = stars + ? WHERE id = ?',
        variables: [Variable.withInt(stars), Variable.withString(id)],
        updates: {_db.learners},
      );

  /// Deletes the reader and (via foreign keys) all of their data.
  Future<void> delete(String id) =>
      (_db.delete(_db.learners)..where((l) => l.id.equals(id))).go();
}

extension LearnerX on Learner {
  /// ["EN"], ["FIL"] or ["EN", "FIL"] for story selection.
  List<String> get languageList => languages.split(',');

  /// The accuracy predictions' correction (§9).
  double bias([AgentConfig config = const AgentConfig()]) =>
      predictionBias ?? config.predictionBiasStart;

  /// Seconds before each hint step for this reader.
  double hintWait([AgentConfig config = const AgentConfig()]) =>
      config.hintWaitFor(dyslexiaMode: dyslexiaMode, parentSetSec: hintWaitSec);
}
