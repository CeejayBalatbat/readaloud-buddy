import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../agent/agent.dart';
import '../db/app_database.dart';

/// A saved session together with its word-by-word results.
class SessionRecord {
  const SessionRecord(this.session, this.words);
  final ReadingSession session;
  final List<WordEvent> words; // ordered by position
}

/// Save and load reading sessions and their word events.
class SessionRepository {
  SessionRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Saves a finished story reading. The session, its word events and the
  /// learner's new reading score and prediction correction are written
  /// together: either all or nothing.
  Future<String> saveStory({
    required String learnerId,
    required String storyId,
    required DateTime startedAt,
    required SessionScores scores,
    required PhilIriLevel level,
    required double bookDifficulty,
    required ScoreUpdate score,
    required double predictedAccuracy,
    required double predictionBias,
    required List<WordOutcome> words,
  }) =>
      _db.transaction(() async {
        final id = await _insert(
          learnerId: learnerId,
          storyId: storyId,
          type: SessionType.story,
          startedAt: startedAt,
          scores: scores,
          level: level,
          bookDifficulty: bookDifficulty,
          scoreBefore: score.before,
          scoreAfter: score.after,
          predictedAccuracy: predictedAccuracy,
          words: words,
        );
        await (_db.update(_db.learners)..where((l) => l.id.equals(learnerId))).write(
            LearnersCompanion(
                readingScore: Value(score.after), predictionBias: Value(predictionBias)));
        return id;
      });

  /// Saves one reading-check passage (§6). Its score columns hold the
  /// passage's evidence; set the starting score with
  /// LearnerRepository.setReadingScore when the check is done.
  Future<String> savePlacementPassage({
    required String learnerId,
    required String storyId,
    required DateTime startedAt,
    required SessionScores scores,
    required PhilIriLevel level,
    required double bookDifficulty,
    required double evidence,
    required List<WordOutcome> words,
  }) =>
      _db.transaction(() => _insert(
            learnerId: learnerId,
            storyId: storyId,
            type: SessionType.placement,
            startedAt: startedAt,
            scores: scores,
            level: level,
            bookDifficulty: bookDifficulty,
            scoreBefore: evidence,
            scoreAfter: evidence,
            predictedAccuracy: null,
            words: words,
          ));

  Future<String> _insert({
    required String learnerId,
    required String storyId,
    required SessionType type,
    required DateTime startedAt,
    required SessionScores scores,
    required PhilIriLevel level,
    required double bookDifficulty,
    required double scoreBefore,
    required double scoreAfter,
    required double? predictedAccuracy,
    required List<WordOutcome> words,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.sessions).insert(SessionsCompanion.insert(
          id: id,
          learnerId: learnerId,
          storyId: storyId,
          type: type,
          startedAt: startedAt,
          readingSeconds: scores.readingSeconds,
          wordsTotal: scores.wordsTotal,
          wordsCorrect: scores.wordsCorrect,
          questionsTotal: scores.questionsTotal,
          questionsCorrect: scores.questionsCorrect,
          hesitations: scores.hesitations,
          miscues: scores.miscues,
          skips: scores.skips,
          unsureWords: scores.unsureWords,
          hintsGiven: scores.hintsGiven,
          accuracy: scores.accuracy,
          wcpm: scores.wcpm,
          comprehension: scores.comprehension,
          philiriLevel: level,
          bookDifficulty: bookDifficulty,
          scoreBefore: scoreBefore,
          scoreAfter: scoreAfter,
          predictedAccuracy: Value(predictedAccuracy),
        ));
    await _db.batch((b) => b.insertAll(_db.wordEvents, [
          for (final w in words)
            WordEventsCompanion.insert(
              sessionId: id,
              position: w.position,
              word: w.word,
              primaryPattern: w.primaryPattern,
              result: w.result,
              responseMs: w.responseMs,
              hintLevel: w.hintLevel,
            ),
        ]));
    return id;
  }

  Future<SessionRecord?> byId(String id) async {
    final session = await (_db.select(_db.sessions)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (session == null) return null;
    final words = await (_db.select(_db.wordEvents)
          ..where((w) => w.sessionId.equals(id))
          ..orderBy([(w) => OrderingTerm(expression: w.position)]))
        .get();
    return SessionRecord(session, words);
  }

  /// The learner's sessions, newest first.
  Future<List<ReadingSession>> recent(String learnerId, {int? limit}) {
    final q = _db.select(_db.sessions)
      ..where((s) => s.learnerId.equals(learnerId))
      ..orderBy([
        (s) => OrderingTerm(expression: s.startedAt, mode: OrderingMode.desc),
      ]);
    if (limit != null) q.limit(limit);
    return q.get();
  }

  /// Stories of the latest sessions, newest first (for story selection).
  Future<List<String>> recentStoryIds(String learnerId, {int limit = 3}) async =>
      [for (final s in await recent(learnerId, limit: limit)) s.storyId];

  /// The best accuracy of every story the learner has read (not
  /// reading-check passages), for the "read again" pick (§9).
  Future<Map<String, double>> bestAccuracies(String learnerId) async {
    final best = <String, double>{};
    for (final s in await recent(learnerId)) {
      if (s.type != SessionType.story) continue;
      final b = best[s.storyId];
      if (b == null || s.accuracy > b) best[s.storyId] = s.accuracy;
    }
    return best;
  }

  /// Oldest → newest summaries for the teacher flag. Patterns practised are
  /// the primary patterns of the session's words.
  Future<List<SessionSummary>> summaries(String learnerId) async {
    final sessions = (await recent(learnerId)).reversed.toList();
    if (sessions.isEmpty) return const [];
    final events = await (_db.select(_db.wordEvents)
          ..where((w) => w.sessionId.isIn([for (final s in sessions) s.id])))
        .get();
    final patterns = <String, Set<String>>{};
    for (final e in events) {
      if (e.result == WordResult.unsure) continue;
      (patterns[e.sessionId] ??= {}).add(e.primaryPattern);
    }
    return [
      for (final s in sessions)
        SessionSummary(
          level: s.philiriLevel,
          patternsPracticed: patterns[s.id] ?? const {},
        ),
    ];
  }
}
