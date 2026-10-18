import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent.dart';
import '../data/database_providers.dart';
import '../data/db/app_database.dart';
import '../data/repositories/learner_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/story.dart';
import '../data/story_providers.dart';
import 'home_data.dart';

/// Everything the Results screen (and Buddy's brain) needs after a story.
class StoryOutcome {
  const StoryOutcome({
    required this.sessionId,
    required this.scores,
    required this.philiri,
    required this.score,
    required this.predictedAccuracy,
    required this.biasBefore,
    required this.biasAfter,
    required this.plan,
    required this.stars,
    required this.newTrickyWords,
    required this.flags,
    this.newLeaf = false,
  });

  final String sessionId;
  final SessionScores scores;
  final PhilIriResult philiri;

  /// The reading score before and after, with this reading's evidence (§5).
  final ScoreUpdate score;

  /// What Buddy predicted the word accuracy would be (§9), and the
  /// prediction correction before and after learning from the error.
  final double predictedAccuracy;
  final double biasBefore;
  final double biasAfter;
  final String plan;
  final int stars; // 1–3
  final List<String> newTrickyWords;
  final List<String> flags;

  /// This story earned Buddy a new leaf (every [storiesPerLeaf] stories).
  final bool newLeaf;
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
  SessionService(this._db, {required this.predictor, this.config = const AgentConfig()})
      : _learners = LearnerRepository(_db),
        _sessions = SessionRepository(_db),
        _progress = ProgressRepository(_db);

  final AppDatabase _db;
  final AgentConfig config;
  final AccuracyPredictor predictor;
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
        // Fresh from the database: the score and bias from before this story.
        final current = await _learners.byId(learner.id) ?? learner;
        final mastery = await _progress.loadMastery(learner.id);
        final biasBefore = current.bias(config);

        // §9 what Buddy expected, with the mastery from before the reading.
        final predicted = predictor.accuracy(story, mastery,
            score: current.readingScore, bias: biasBefore);

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

        // §7 sound mastery.
        mastery.recordWords(outcomes);
        await _progress.saveMastery(learner.id, mastery);

        // §5 reading score, §9 learning from the prediction error.
        final scorer = ReadingScorer(config);
        final update = scorer.update(
          current.readingScore,
          scorer.evidence(
            difficulty: story.difficulty,
            accuracy: scores.accuracy,
            wcpm: scores.wcpm,
            comprehension: scores.comprehension,
            bookMastery: ReadingScorer.bookMastery(story, mastery),
          ),
        );
        // A story with nothing scored (every word unsure) teaches nothing.
        final biasAfter = scores.wordsTotal == 0
            ? biasBefore
            : predictor.updatedBias(biasBefore, predicted: predicted, actual: scores.accuracy);
        final sessionId = await _sessions.saveStory(
          learnerId: learner.id,
          storyId: story.id,
          startedAt: startedAt,
          scores: scores,
          level: philiri.overall,
          bookDifficulty: story.difficulty,
          score: update,
          predictedAccuracy: predicted,
          predictionBias: biasAfter,
          words: outcomes,
        );

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
        final storiesRead = (await _sessions.recent(learner.id))
            .where((s) => s.type == SessionType.story)
            .length;

        return StoryOutcome(
          sessionId: sessionId,
          scores: scores,
          philiri: philiri,
          score: update,
          predictedAccuracy: predicted,
          biasBefore: biasBefore,
          biasAfter: biasAfter,
          plan: scorer.buddyPlan(update, philiri.overall),
          stars: stars,
          newTrickyWords: [for (final w in changes.added) w.word],
          flags: flags,
          newLeaf: BuddyGrowth(storiesRead).justGotLeaf,
        );
      });
}

/// What a finished "Build the word" game changed.
class GameOutcome {
  const GameOutcome({required this.stars, required this.wordsLearned});

  /// Stars earned for playing (rewards are for practice, not speed).
  final int stars;

  /// Words that left the tricky-word list (built cleanly the 2nd time).
  final List<String> wordsLearned;
}

extension GameSaving on SessionService {
  /// Saves a finished game (screen 9): clean builds count as clean reads
  /// for the tricky-word list (§8), and playing earns one star.
  Future<GameOutcome> finishGame({
    required Learner learner,
    required List<(GameWord, bool clean)> results,
  }) =>
      _db.transaction(() async {
        final tricky = await _progress.loadTrickyWords(learner.id);
        final changes = tricky.recordActivity(WordGame.outcomesFor(results));
        await _progress.saveTrickyWords(learner.id, tricky);
        final stars = results.isEmpty ? 0 : gameStars;
        if (stars > 0) await _learners.addStars(learner.id, stars);
        return GameOutcome(
          stars: stars,
          wordsLearned: [for (final w in changes.removed) w.word],
        );
      });
}

/// Stars for finishing a game.
const gameStars = 1;

/// A short reading-check passage: the opening sentences of a story.
class PlacementPassage {
  const PlacementPassage(this.story, this.words);
  final Story story;
  final List<StoryWord> words;
}

/// The opening of [story] (AGENT_SPEC §6), cut to whole sentences of about
/// [maxWords].
PlacementPassage placementPassage(Story story, {int maxWords = 25}) {
  final tokens = story.text.split(RegExp(r'\s+'));
  var end = 0;
  for (var i = 0; i < tokens.length; i++) {
    if (RegExp(r'[.!?]["”’]?$').hasMatch(tokens[i])) {
      if (i + 1 > maxWords && end > 0) break;
      end = i + 1;
    }
  }
  if (end == 0) end = tokens.length;
  return PlacementPassage(story, story.words.sublist(0, end));
}

/// What Buddy learned from one reading-check passage. No score is shown to
/// the child.
class PassageOutcome {
  const PassageOutcome({required this.scores, required this.passage});
  final SessionScores scores;
  final CheckPassage passage;
}

extension PlacementSaving on SessionService {
  /// Saves one reading-check passage and records it in [check]. The check
  /// has no questions, so the passage is classified by word accuracy alone
  /// (§4) and its evidence has no comprehension or mastery part (§6).
  /// Sound mastery, tricky words and hint stats learn from it too; the
  /// starting score is set once the whole check is done.
  Future<PassageOutcome> savePlacementPassage({
    required Learner learner,
    required ReadingCheck check,
    required PlacementPassage passage,
    required List<WordOutcome> outcomes,
    required double readingSeconds,
    required List<HintAttempt> hintAttempts,
    required DateTime startedAt,
  }) =>
      _db.transaction(() async {
        final scores = SessionScores.fromResults(
          outcomes,
          readingSeconds: readingSeconds,
          questionsCorrect: 0,
          questionsTotal: 0,
        );
        final result =
            check.record(passage.story, accuracy: scores.accuracy, wcpm: scores.wcpm);
        await _sessions.savePlacementPassage(
          learnerId: learner.id,
          storyId: passage.story.id,
          startedAt: startedAt,
          scores: scores,
          level: result.wordLevel,
          bookDifficulty: passage.story.difficulty,
          evidence: result.evidence.value,
          words: outcomes,
        );
        final mastery = await _progress.loadMastery(learner.id)
          ..recordWords(outcomes);
        await _progress.saveMastery(learner.id, mastery);
        final tricky = await _progress.loadTrickyWords(learner.id)
          ..recordActivity(outcomes);
        await _progress.saveTrickyWords(learner.id, tricky);
        final hints = await _progress.loadHintStats(learner.id)
          ..recordAll(hintAttempts);
        await _progress.saveHintStats(learner.id, hints);
        return PassageOutcome(scores: scores, passage: result);
      });

  /// Sets the starting reading score when the check is done (or closed).
  Future<void> finishPlacement(Learner learner, ReadingCheck check) =>
      _learners.setReadingScore(learner.id, check.startScore);
}

/// Needs the predictor (sound patterns), loaded at app start.
final sessionServiceProvider = Provider((ref) => SessionService(
      ref.watch(appDatabaseProvider),
      predictor: ref.watch(predictorProvider).requireValue,
    ));
