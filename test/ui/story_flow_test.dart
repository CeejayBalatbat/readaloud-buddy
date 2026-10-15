import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/app/buddy_brain.dart';
import 'package:readaloud_buddy/data/repositories/learner_repository.dart';
import 'package:readaloud_buddy/data/repositories/session_repository.dart';
import 'package:readaloud_buddy/ui/screens/questions_screen.dart';
import 'package:readaloud_buddy/app/current_learner.dart';
import 'package:readaloud_buddy/ui/screens/home_shell.dart';

import 'test_app.dart';

void main() {
  final kite = TestApp.story('S06');

  /// Lets database work (real async) finish, then redraws.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> answer(WidgetTester tester, String text) async {
    await tester.tap(find.bySemanticsLabel(text));
    await tester.pump();
  }

  testWidgets('questions: one try each, Buddy gives feedback', (tester) async {
    final app = TestApp();
    int? score;
    await app.pump(tester, QuestionsScreen(story: kite, onDone: (c) => score = c));
    expect(find.text('Story questions · 1 of 3'), findsOneWidget);
    expect(find.text('Why did the kite go up high?'), findsOneWidget);
    expect(app.tts.spoken.first, 'Why did the kite go up high?');

    await answer(tester, 'The wind was strong');
    expect(find.text('Yes! The wind was strong. 🎉'), findsOneWidget);
    await app.screenshot(tester, 's07_right');
    await tester.tap(find.text('Next question →'));
    await tester.pump();

    expect(find.text('Story questions · 2 of 3'), findsOneWidget);
    final q2 = kite.questions[1];
    final wrong = q2.choices.firstWhere((c) => !c.correct).text;
    await answer(tester, wrong);
    expect(find.text('Good try! The answer is: ${q2.answer}.'), findsOneWidget);
    // A second tap does not change the answer.
    await answer(tester, q2.answer);
    expect(find.text('Good try! The answer is: ${q2.answer}.'), findsOneWidget);
    await app.screenshot(tester, 's07_wrong');
    await tester.tap(find.text('Next question →'));
    await tester.pump();

    await answer(tester, kite.questions[2].answer);
    await tester.tap(find.text('See how I did →'));
    expect(score, 2);
  });

  testWidgets('read a story, answer, and see Buddy\'s plan', (tester) async {
    final app = TestApp();
    final mia = await tester.runAsync(() => LearnerRepository(app.db)
        .create(nickname: 'Mia', grade: 2, languages: 'EN', currentLevel: 2));
    await tester.runAsync(() => app.container.read(currentLearnerProvider.notifier).select(mia!.id));
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Stories'));
    await settle(tester);

    await tester.tap(find.text('The Big Red Kite'));
    await settle(tester);
    expect(find.text('Help'), findsOneWidget);

    for (final w in kite.words) {
      app.speech.hear(w.word);
      await tester.pump();
    }
    await settle(tester);
    expect(find.text('Story questions · 1 of 3'), findsOneWidget);

    for (final q in kite.questions) {
      await answer(tester, q.answer);
      await tester.tap(find.textContaining('→'));
      await settle(tester);
    }

    expect(find.text('Great reading, Mia!'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text("BUDDY'S PLAN"), findsOneWidget);
    expect(find.textContaining("move up to Level 3"), findsOneWidget);
    expect(find.text('Next story →'), findsOneWidget);
    await app.screenshot(tester, 's08_results');

    // The session really was saved, with the agent's decision.
    final saved = await tester.runAsync(() => SessionRepository(app.db).recent(mia!.id));
    expect(saved!.single.philiriLevel, PhilIriLevel.independent);
    expect(saved.single.agentDecision, LevelMove.stay);

    // Buddy's brain shows the decision too.
    await tester.longPress(find.text("BUDDY'S PLAN"));
    await settle(tester);
    expect(find.text('LAST STORY DECISION (§3–§5)'), findsOneWidget);
    final brain = app.container.read(buddyBrainProvider).last!;
    expect(brain.philiri.overall, PhilIriLevel.independent);
    await app.screenshot(tester, 'brain_decision');
    await tester.tapAt(const Offset(195, 40));
    await settle(tester);

    await tester.tap(find.text('Next story →'));
    await settle(tester);
    expect(find.text('Pick a story'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
