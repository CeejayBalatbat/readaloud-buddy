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
  /// learner's new level are written together: either all or nothing.
  Future<String> saveStory({
    required String learnerId,
    required String storyId,
    required DateTime startedAt,
    required SessionScores scores,
    required PhilIriLevel level,
    required LevelDecision decision,
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
          decision: decision.move,
          levelBefore: decision.levelBefore,
          levelAfter: decision.levelAfter,
          words: words,
        );
        await (_db.update(_db.learners)..where((l) => l.id.equals(learnerId)))
            .write(LearnersCompanion(currentLevel: Value(decision.levelAfter)));
        return id;
      });

  /// Saves one placement passage (read at [passageLevel]). Placement makes
  /// no level decision; set the start level with LearnerRepository.setLevel
  /// when the placement check is done.
  Future<String> savePlacementPassage({
    required String learnerId,
    required String storyId,
    required DateTime startedAt,
    required SessionScores scores,
    required PhilIriLevel level,
    required int passageLevel,
    required List<WordOutcome> words,
  }) =>
      _db.transaction(() => _insert(
            learnerId: learnerId,
            storyId: storyId,
            type: SessionType.placement,
            startedAt: startedAt,
            scores: scores,
            level: level,
            decision: null,
            levelBefore: passageLevel,
            levelAfter: passageLevel,
            words: words,
          ));

  Future<String> _insert({
    required String learnerId,
    required String storyId,
    required SessionType type,
    required DateTime startedAt,
    required SessionScores scores,
    required PhilIriLevel level,
    required LevelMove? decision,
    required int levelBefore,
    required int levelAfter,
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
          agentDecision: Value(decision),
          levelBefore: levelBefore,
          levelAfter: levelAfter,
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

  /// Rebuilds the agent's [LevelState]: the learner's current level plus
  /// only the results since the last level change (AGENT_SPEC §5). If no
  /// story has changed the level yet, the placement passage read at the
  /// starting level counts as the first result.
  Future<LevelState> levelState(String learnerId) async {
    final learner = await (_db.select(_db.learners)
          ..where((l) => l.id.equals(learnerId)))
        .getSingle();
    final level = learner.currentLevel;
    final sessions = await recent(learnerId);
    final results = <PhilIriLevel>[]; // newest first while walking back
    for (final s in sessions) {
      if (s.type == SessionType.placement) {
        // Placement is the start of the history: use its passage at the
        // starting level (if any), then stop.
        final atLevel = sessions
            .where((p) => p.type == SessionType.placement)
            .where((p) => p.levelBefore == level)
            .firstOrNull;
        if (atLevel != null) results.add(atLevel.philiriLevel);
        break;
      }
      if (s.agentDecision != LevelMove.stay) break; // last level change
      results.add(s.philiriLevel);
    }
    return LevelState(level: level, resultsAtLevel: results.reversed.toList());
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
