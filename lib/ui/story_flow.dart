import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent.dart';
import '../app/buddy_brain.dart';
import '../app/current_learner.dart';
import '../app/session_service.dart';
import '../data/db/app_database.dart';
import '../data/repositories/learner_repository.dart';
import '../app/home_data.dart';
import '../data/story.dart';
import '../speech/speech_providers.dart';
import 'screens/questions_screen.dart';
import 'screens/read_along_screen.dart';
import 'screens/results_screen.dart';

/// One story from start to finish: read-along (s05/s06) → questions (s07)
/// → Buddy runs the agent and saves everything → results (s08).
Future<void> startStory(BuildContext context, Story story) async {
  final container = ProviderScope.containerOf(context);
  final navigator = Navigator.of(context);
  final learner = await _learner(container);
  // Filipino: find out once whether the phone can recognize it.
  await prepareVoice(container, story.language);
  final startedAt = DateTime.now();

  void showResults(StoryOutcome outcome) {
    navigator.pushReplacement(MaterialPageRoute<void>(
      builder: (_) => ResultsScreen(
        nickname: learner.nickname,
        outcome: outcome,
        onNextStory: () => navigator.pop(),
      ),
    ));
  }

  void askQuestions(ReadingResult reading) {
    navigator.pushReplacement(MaterialPageRoute<void>(
      builder: (_) => QuestionsScreen(
        story: story,
        readAloud: learner.readAloud,
        onDone: (correct) async {
          final outcome = await container.read(sessionServiceProvider).finishStory(
                learner: learner,
                story: story,
                outcomes: reading.outcomes,
                readingSeconds: reading.seconds,
                questionsCorrect: correct,
                hintAttempts: reading.hints,
                startedAt: startedAt,
              );
          container.read(buddyBrainProvider.notifier).showDecision(BrainDecision(
                title: story.title,
                scores: outcome.scores,
                philiri: outcome.philiri,
                decision: outcome.decision,
                plan: outcome.plan,
                resultsAtLevel: outcome.levelAfter.resultsAtLevel,
                newTrickyWords: outcome.newTrickyWords,
                flags: outcome.flags,
              ));
          await container.read(currentLearnerProvider.notifier).reload();
          container.invalidate(learnerInsightsProvider);
          refreshAfterReading(container);
          showResults(outcome);
        },
      ),
    ));
  }

  await navigator.push(MaterialPageRoute<void>(
    builder: (_) => ReadAlongScreen(
      story: story,
      hintWaitSec: learner.hintWait(),
      startHintLevel: learner.startHintLevel,
      readAloud: learner.readAloud,
      onFinished: (c) => askQuestions(ReadingResult(
        outcomes: c.outcomes,
        seconds: c.readingSeconds,
        hints: c.tracker.hintAttempts,
      )),
    ),
  ));
}

/// What the read-along hands to the questions step.
class ReadingResult {
  const ReadingResult({required this.outcomes, required this.seconds, required this.hints});
  final List<WordOutcome> outcomes;
  final double seconds;
  final List<HintAttempt> hints;
}

/// The current reader (setup always comes first, so there is one).
Future<Learner> _learner(ProviderContainer container) async {
  final current = await container.read(currentLearnerProvider.future);
  if (current == null) throw StateError('No reader is set up yet');
  return current;
}
