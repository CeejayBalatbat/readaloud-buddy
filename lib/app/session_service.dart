import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent.dart';
import '../data/database_providers.dart';
import '../data/db/app_database.dart';
import '../data/repositories/learner_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/story.dart';

/// Everything the Results screen (and Buddy's brain) needs after a story.
class StoryOutcome {
  const StoryOutcome({
    required this.sessionId,
    required this.scores,
    required this.philiri,
    required this.decision,
    required this.levelAfter,
    required this.plan,
    required this.stars,
    required this.newTrickyWords,
    required this.flags,
  });

  final String sessionId;
  final SessionScores scores;
  final PhilIriResult philiri;
  final LevelDecision decision;
  final LevelState levelAfter;
  final String plan;
  final int stars; // 1–3
  final List<String> newTrickyWords;
  final List<String> flags;
}

/// Stars for a finished story: every finished story earns at least one.
int starsFor(PhilIriLevel level) => switch (level) {
      PhilIriLevel.independent => 3,
      PhilIriLevel.instructional => 2,
      PhilIriLevel.frustration => 1,
    };

/// Runs the agent's after-story steps and saves the results (AGENT_SPEC
/// §3–§10). Everything is written in one transaction: all or nothing.
class SessionService {
  SessionService(this._db, {this.config = const AgentConfig()})
      : _learners = LearnerRepository(_db),
        _sessions = SessionRepository(_db),
        _progress = ProgressRepository(_db);

  final AppDatabase _db;
  final AgentConfig config;
  final LearnerRepository _learners;
  final SessionRepository _sessions;
  final ProgressRepository _progress;

  Future<StoryOutcome> finishStory({
    required Learner learner,
    required Story story,
    required List<WordOutcome> outcomes,
    required double readingSeconds,
    required int questionsCorrect,
    required List<HintAttempt> hintAttempts,
    required DateTime startedAt,
  }) =>
      _db.transaction(() async {
        // §3 scores and §4 Phil-IRI level.
        final scores = SessionScores.fromResults(
          outcomes,
          readingSeconds: readingSeconds,
          questionsCorrect: questionsCorrect,
          questionsTotal: story.questions.length,
        );
        final philiri = PhilIriClassifier(config).classify(
          accuracy: scores.accuracy,
          comprehension: scores.comprehension,
        );

        // §5 level decision, from the streak since the last level change.
        final state = await _sessions.levelState(learner.id);
        final (decision, next) = state.apply(philiri.overall, config);
        final sessionId = await _sessions.saveStory(
          learnerId: learner.id,
          storyId: story.id,
          startedAt: startedAt,
          scores: scores,
          level: philiri.overall,
          decision: decision,
          words: outcomes,
        );

        // §7 sound mastery.
        final mastery = await _progress.loadMastery(learner.id)
          ..recordWords(outcomes);
        await _progress.saveMastery(learner.id, mastery);

        // §8 tricky words.
        final tricky = await _progress.loadTrickyWords(learner.id);
        final changes = tricky.recordActivity(outcomes);
        await _progress.saveTrickyWords(learner.id, tricky);

        // §2 hint learning.
        final hints = await _progress.loadHintStats(learner.id)
          ..recordAll(hintAttempts);
        await _progress.saveHintStats(learner.id, hints);
        final startHint = hints.startLevel(config);
        if (startHint != learner.startHintLevel) {
          await _learners.setStartHintLevel(learner.id, startHint);
        }

        // §10 teacher flag.
        final flags = TeacherFlagger(config).reasons(
          sessions: await _sessions.summaries(learner.id),
          mastery: mastery,
        );
        await _progress.addFlags(learner.id, flags);

        final stars = starsFor(philiri.overall);
        await _learners.addStars(learner.id, stars);

        return StoryOutcome(
          sessionId: sessionId,
          scores: scores,
          philiri: philiri,
          decision: decision,
          levelAfter: next,
          plan: buddyPlanFor(
            result: philiri.overall,
            decision: decision,
            next: next,
            config: config,
          ),
          stars: stars,
          newTrickyWords: [for (final w in changes.added) w.word],
          flags: flags,
        );
      });
}

final sessionServiceProvider =
    Provider((ref) => SessionService(ref.watch(appDatabaseProvider)));
