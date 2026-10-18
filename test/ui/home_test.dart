import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/app/buddy_brain.dart';
import 'package:readaloud_buddy/app/current_learner.dart';
import 'package:readaloud_buddy/app/hint_mode.dart';
import 'package:readaloud_buddy/app/home_data.dart';
import 'package:readaloud_buddy/data/repositories/learner_repository.dart';
import 'package:readaloud_buddy/data/repositories/session_repository.dart';
import 'package:readaloud_buddy/data/repositories/settings_repository.dart';
import 'package:readaloud_buddy/main.dart';
import 'package:readaloud_buddy/ui/screens/home_shell.dart';

import 'test_app.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  group('helpers', () {
    test('streak counts days in a row up to today (or yesterday)', () {
      final now = DateTime(2026, 10, 15, 15);
      expect(streakDays([], now), 0);
      expect(streakDays([DateTime(2026, 10, 15, 9)], now), 1);
      expect(
          streakDays([
            DateTime(2026, 10, 15, 9),
            DateTime(2026, 10, 14, 18),
            DateTime(2026, 10, 13, 8),
            DateTime(2026, 10, 11, 8), // gap: not counted
          ], now),
          3);
      // Not read yet today: yesterday's streak still shows.
      expect(streakDays([DateTime(2026, 10, 14), DateTime(2026, 10, 13)], now), 2);
    });

    test('Filipino greeting follows the time of day', () {
      expect(filipinoGreeting(DateTime(2026, 1, 1, 8)), 'Magandang umaga,');
      expect(filipinoGreeting(DateTime(2026, 1, 1, 12, 30)), 'Magandang tanghali,');
      expect(filipinoGreeting(DateTime(2026, 1, 1, 15)), 'Magandang hapon,');
      expect(filipinoGreeting(DateTime(2026, 1, 1, 20)), 'Magandang gabi,');
    });
  });

  testWidgets('a new phone starts with reader setup', (tester) async {
    final app = TestApp();
    await app.pump(tester, const AppStart());
    await settle(tester);
    expect(find.text("Let's set up a reader"), findsOneWidget);
    expect(find.text('Start reading check'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Mia');
    await tester.tap(find.text('Grade 2'));
    await tester.tap(find.text('English'));
    await tester.tap(find.text('Filipino'));
    await tester.pump();
    expect(find.textContaining("Mia's voice is"), findsOneWidget);
    await app.screenshot(tester, 's01_before_consent');

    // Nothing happens until the parent agrees.
    await tester.tap(find.text('Start reading check'));
    await settle(tester);
    expect(find.text("Let's set up a reader"), findsOneWidget);

    await tester.tap(find.textContaining('I agree'));
    await tester.pump();
    await app.screenshot(tester, 's01_setup');
    await tester.tap(find.text('Start reading check'));
    await settle(tester);

    final mia = await tester.runAsync(() => LearnerRepository(app.db).all());
    expect(mia!.single.nickname, 'Mia');
    expect(mia.single.grade, 2);
    expect(mia.single.languages, 'EN,FIL');
    final consent = await tester.runAsync(
        () => SettingsRepository(app.db).get(SettingKeys.consentDate));
    expect(consent, isNotNull);

    // --- Reading check (s02): level 1 and 2 read well, level 3 is hard.
    expect(find.text('Reading check · 1 of 3'), findsOneWidget);
    expect(find.textContaining("Hi Mia! Read this to me out loud."), findsOneWidget);
    await app.screenshot(tester, 's02_placement');

    Future<void> readPassage({required bool hard}) async {
      final c = find.byType(Scaffold);
      expect(c, findsOneWidget);
      final brain = app.container.read(buddyBrainProvider).reading!;
      for (var i = 0; i < brain.tokens.length; i++) {
        app.speech.hear(hard && i.isEven ? 'zzxq' : brain.tokens[i].replaceAll(RegExp(r'[^\w]'), ''));
        await tester.pump();
      }
      await settle(tester);
    }

    await readPassage(hard: false);
    expect(find.text('Reading check · 2 of 3'), findsOneWidget);
    expect(find.text("Nice! Here's another one."), findsOneWidget);
    await readPassage(hard: false);
    expect(find.text('Reading check · 3 of 3'), findsOneWidget);
    await readPassage(hard: true);

    expect(find.text('All done, Mia!'), findsOneWidget);
    final placed = await tester.runAsync(() => LearnerRepository(app.db).all());
    // Between the 2nd passage (read well, difficulty 39) and the 3rd
    // (too hard, difficulty 58): the two evidences averaged (§6).
    final score = placed!.single.readingScore;
    expect(score, inExclusiveRange(25, 55));
    await app.screenshot(tester, 's02_done');

    await tester.tap(find.text("📖 Let's read!"));
    await settle(tester);
    expect(find.text('Mia!'), findsOneWidget); // Home
    await tester.tap(find.text('Stories'));
    await settle(tester);
    // The child sees a rank, never the score.
    expect(find.text('${const ReadingScorer().profileOf(score).rank} reader'), findsOneWidget);
  });

  testWidgets('closing the reading check keeps the default score and goes home',
      (tester) async {
    final app = TestApp();
    await app.pump(tester, const AppStart());
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Jojo');
    await tester.tap(find.text('Grade 1'));
    await tester.tap(find.text('Filipino'));
    await tester.tap(find.textContaining('I agree'));
    await tester.pump();
    await tester.tap(find.text('Start reading check'));
    await settle(tester);
    // A Filipino reader: first, set up Filipino listening (5c) or not now.
    expect(find.text('Filipino listening'), findsOneWidget);
    await app.screenshot(tester, 's05c_filipino_setup');
    await tester.tap(find.text('Not now (read by tapping)'));
    await settle(tester);
    expect(find.text('Reading check · 1 of 3'), findsOneWidget);
    expect(find.textContaining('Hi Jojo!'), findsOneWidget);

    await tester.tap(find.text('✕'));
    await settle(tester);
    expect(find.text('Jojo!'), findsOneWidget);
    final jojo = await tester.runAsync(() => LearnerRepository(app.db).all());
    expect(jojo!.single.readingScore, 10); // startScoreDefault
  });

  testWidgets('home shows greeting, stars, streak, minutes and Read!',
      (tester) async {
    final app = TestApp();
    await tester.runAsync(() async {
      final mia = await LearnerRepository(app.db)
          .create(nickname: 'Mia', grade: 2, languages: 'EN', readingScore: 30);
      await LearnerRepository(app.db).addStars(mia.id, 124);
      final sessions = SessionRepository(app.db);
      for (final (day, secs) in [
        (15, 240.0), (15, 130.0), (14, 300.0), (13, 300.0), // this week
        (1, 60.0), (1, 60.0), (1, 60.0), (1, 60.0), (1, 60.0), // earlier: 9 stories
      ]) {
        await sessions.saveStory(
          learnerId: mia.id,
          storyId: 'S06',
          startedAt: DateTime(2026, 10, day, 9),
          scores: SessionScores(
            wordsTotal: 45, wordsCorrect: 44, hesitations: 0, miscues: 1, skips: 0,
            unsureWords: 0, hintsGiven: 0, readingSeconds: secs,
            questionsCorrect: 2, questionsTotal: 3,
          ),
          level: PhilIriLevel.instructional,
          bookDifficulty: 38,
          score: const ScoreUpdate(
            before: 30,
            after: 30,
            evidence: ScoreEvidence(difficulty: 38, accuracyPart: 0, fluencyPart: 0, value: 30),
          ),
          predictedAccuracy: 0.95,
          predictionBias: 1.6,
          words: const [],
        );
      }
      await app.container.read(currentLearnerProvider.notifier).select(mia.id);
    });
    await app.pump(tester, const HomeShell());
    await settle(tester);

    expect(find.text('Magandang hapon,'), findsOneWidget);
    expect(find.text('Mia!'), findsOneWidget);
    expect(find.text('⭐ 124'), findsOneWidget);
    expect(find.text('🔥 3 days'), findsOneWidget);
    // 9 stories: one leaf, 1 more for the next.
    expect(find.text('Little Buddy · 1 leaf'), findsOneWidget);
    expect(find.text('🌿'), findsOneWidget); // one leaf drawn on Buddy
    expect(find.text('6/10'), findsOneWidget); // 370 s today = 6 minutes
    expect(find.text('6 of 10 minutes. Almost there!'), findsOneWidget);
    expect(find.text('1 more story until Buddy gets a new leaf'), findsOneWidget);
    await app.screenshot(tester, 's03_home');

    await tester.tap(find.text('📖 Read!'));
    await settle(tester);
    expect(find.text('Pick a story'), findsOneWidget);
  });

  testWidgets('the shelf shows Buddy\'s picks with a reason', (tester) async {
    final app = TestApp();
    await tester.runAsync(() async {
      final mia = await LearnerRepository(app.db)
          .create(nickname: 'Mia', grade: 2, languages: 'EN,FIL', readingScore: 30);
      await app.container.read(currentLearnerProvider.notifier).select(mia.id);
    });
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Stories'));
    await settle(tester);

    expect(find.text('🌿 Sprout reader'), findsOneWidget); // score 30
    expect(find.textContaining('Level'), findsNothing);
    expect(find.text('BUDDY PICKED THESE'), findsOneWidget);
    expect(find.textContaining('These stories have more'), findsOneWidget);
    // Up to 3 just-right books + 1 easy one; nothing read yet, so all new.
    expect(find.text('New'), findsNWidgets(4));
    await app.screenshot(tester, 's04_shelf');
  });

  testWidgets('settings lists readers and switches between them',
      (tester) async {
    final app = TestApp();
    await tester.runAsync(() async {
      final repo = LearnerRepository(app.db);
      final mia = await repo.create(nickname: 'Mia', grade: 2, languages: 'EN');
      await repo.create(nickname: 'Jojo', grade: 1, languages: 'FIL');
      await app.container.read(currentLearnerProvider.notifier).select(mia.id);
    });
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(find.text('Reading now'), findsOneWidget);
    await tester.tap(find.text('Switch'));
    await settle(tester);
    expect(app.container.read(currentLearnerProvider).value!.nickname, 'Jojo');
  });

  testWidgets('parent can set Hints to "Only when I tap Help"', (tester) async {
    final app = TestApp();
    await tester.runAsync(() async {
      final mia = await LearnerRepository(app.db)
          .create(nickname: 'Mia', grade: 2, languages: 'EN');
      await app.container.read(currentLearnerProvider.notifier).select(mia.id);
    });
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    final helpOnly = find.text('Only when I tap Help');
    await tester.scrollUntilVisible(helpOnly, 300);
    await settle(tester);
    expect(app.container.read(hintModeProvider).value, HintMode.automatic);
    await tester.tap(helpOnly);
    await settle(tester);
    expect(app.container.read(hintModeProvider).value, HintMode.helpOnly);
    final saved = await tester.runAsync(
        () => SettingsRepository(app.db).get(SettingKeys.hintMode));
    expect(saved, 'helpOnly');
  });
}
