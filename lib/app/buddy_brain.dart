import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent.dart';
import '../data/database_providers.dart';
import '../data/db/app_database.dart';
import 'current_learner.dart';
import 'reading_controller.dart';
import '../speech/fallback_speech_service.dart';
import '../speech/speech_service.dart';

/// What Buddy perceives while a story is being read.
class BrainReading {
  const BrainReading({
    required this.title,
    required this.tokens,
    required this.outcomes,
    required this.currentIndex,
    required this.hintLevel,
    required this.readingSeconds,
    this.speech = const SpeechState(),
    this.tapMode = false,
  });

  factory BrainReading.of(ReadingController c) => BrainReading(
        speech: c.speech.state.value,
        tapMode: tapToRead(c.speech) != null,
        title: c.story.title,
        tokens: c.tokens,
        outcomes: c.outcomes,
        currentIndex: c.isFinished ? null : c.currentIndex,
        hintLevel: c.tracker.currentHintLevel,
        readingSeconds: c.readingSeconds,
      );

  final String title;
  final List<String> tokens;
  final List<WordOutcome> outcomes;
  final int? currentIndex;
  final int hintLevel;
  final double readingSeconds;

  /// What the recognizer is doing and what it heard last.
  final SpeechState speech;
  final bool tapMode;
}

/// What Buddy decided after the last story or reading-check passage.
class BrainDecision {
  const BrainDecision({
    required this.title,
    required this.scores,
    required this.philiri,
    required this.bookDifficulty,
    this.score,
    this.evidence,
    this.predictedAccuracy,
    this.biasBefore,
    this.biasAfter,
    this.plan,
    this.newTrickyWords = const [],
    this.flags = const [],
    this.isPlacement = false,
  });

  final String title;
  final SessionScores scores;
  final PhilIriResult philiri;
  final double bookDifficulty;

  /// The reading score before → after (stories only, §5).
  final ScoreUpdate? score;

  /// What this reading says about the child (§5; for a reading-check
  /// passage, §6).
  final ScoreEvidence? evidence;

  /// Predicted word accuracy and the prediction correction (stories, §9).
  final double? predictedAccuracy;
  final double? biasBefore;
  final double? biasAfter;
  final String? plan;
  final List<String> newTrickyWords;
  final List<String> flags;
  final bool isPlacement;
}

class BrainState {
  const BrainState({this.reading, this.last});
  final BrainReading? reading;
  final BrainDecision? last;
}

/// Live store for the "Buddy's brain" debug panel.
class BuddyBrain extends Notifier<BrainState> {
  @override
  BrainState build() => const BrainState();

  void showReading(ReadingController c) =>
      state = BrainState(reading: BrainReading.of(c), last: state.last);

  void showDecision(BrainDecision d) =>
      state = BrainState(reading: state.reading, last: d);
}

final buddyBrainProvider =
    NotifierProvider<BuddyBrain, BrainState>(BuddyBrain.new);

/// What Buddy has learned about the current reader (from the database).
class LearnerInsights {
  const LearnerInsights({
    required this.learner,
    required this.mastery,
    required this.hintStats,
    required this.trickyWords,
    required this.flags,
  });

  final Learner learner;
  final SoundMastery mastery;
  final HintStats hintStats;
  final List<String> trickyWords;
  final List<String> flags;

  /// Practised sounds, weakest first.
  List<MapEntry<String, double>> get weakestSounds {
    final seen = mastery.all.entries
        .where((e) => mastery.observationsOf(e.key) > 0)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return seen;
  }
}

final learnerInsightsProvider =
    FutureProvider.autoDispose<LearnerInsights?>((ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  if (learner == null) return null;
  final progress = ref.watch(progressRepositoryProvider);
  return LearnerInsights(
    learner: learner,
    mastery: await progress.loadMastery(learner.id),
    hintStats: await progress.loadHintStats(learner.id),
    trickyWords: [
      for (final t in await progress.trickyWordEntries(learner.id)) t.word,
    ],
    flags: [for (final f in await progress.unseenFlags(learner.id)) f.reason],
  );
});
