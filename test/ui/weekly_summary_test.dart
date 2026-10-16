import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/app/current_learner.dart';
import 'package:readaloud_buddy/app/tricky_words_print.dart';
import 'package:readaloud_buddy/app/weekly_summary.dart';
import 'package:readaloud_buddy/app/weekly_summary_text.dart';
import 'package:readaloud_buddy/data/repositories/learner_repository.dart';
import 'package:readaloud_buddy/data/repositories/progress_repository.dart';
import 'package:readaloud_buddy/data/repositories/session_repository.dart';
import 'package:readaloud_buddy/ui/screens/weekly_summary_screen.dart';

import 'test_app.dart';

/// Remembers what would have been printed.
class FakePrinter implements TrickyWordsPrinter {
  final printed = <(String, List<String>)>[];
  @override
  Future<void> print({required String title, required String hint, required List<String> words}) async =>
      printed.add((title, words));
}

void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  WordOutcome strong(WordResult r) => WordOutcome(
      position: 1, word: 'strong', patterns: const ['EN-BL3'], primaryPattern: 'EN-BL3', result: r);

  /// Mia: one story the week before (40 wpm, "strong" misread) and two this
  /// week (46 wpm, "strong" read well; the last one Independent).
  Future<TestApp> seeded(WidgetTester tester, FakePrinter printer) async {
    final app = TestApp(); // "now" is Oct 15, 2026
    await tester.runAsync(() async {
      final mia = await LearnerRepository(app.db)
          .create(nickname: 'Mia', grade: 2, languages: 'EN', currentLevel: 2);
      final sessions = SessionRepository(app.db);
      for (final (day, wcpm, level, word) in [
        (3, 40.0, PhilIriLevel.instructional, WordResult.misread),
        (13, 46.0, PhilIriLevel.instructional, WordResult.correct),
        (14, 46.0, PhilIriLevel.independent, WordResult.correct),
      ]) {
        await sessions.saveStory(
          learnerId: mia.id,
          storyId: 'S06',
          startedAt: DateTime(2026, 10, day, 9),
          scores: SessionScores(
            wordsTotal: 46, wordsCorrect: wcpm.round(), hesitations: 0, miscues: 0,
            skips: 0, unsureWords: 0, hintsGiven: 0, readingSeconds: 60,
            questionsCorrect: 3, questionsTotal: 3,
          ),
          level: level,
          decision: const LevelDecision(move: LevelMove.stay, levelBefore: 2, levelAfter: 2),
          words: [strong(word)],
        );
      }
      final progress = ProgressRepository(app.db);
      await progress.saveMastery(
          mia.id,
          SoundMastery(
            mastery: {'EN-SH': 0.2, 'EN-SV': 0.9},
            observations: {'EN-SH': 4, 'EN-SV': 6},
          ));
      await progress.saveTrickyWords(
          mia.id, TrickyWords(words: const [TrickyWord(word: 'through', patternCode: 'EN-OU')]));
      await app.container.read(currentLearnerProvider.notifier).select(mia.id);
    });
    return app;
  }

  testWidgets('screen 11: minutes, stories, words/min, level, celebrate, tip, print',
      (tester) async {
    final printer = FakePrinter();
    final app = await seeded(tester, printer);
    await app.pump(
      tester,
      ProviderScope(
        overrides: [trickyWordsPrinterProvider.overrideWithValue(printer)],
        child: const WeeklySummaryScreen(),
      ),
    );
    await settle(tester);

    expect(find.text('Weekly summary · Oct 9–15'), findsOneWidget);
    expect(find.text("Mia's reading week"), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2)); // 2 minutes (2 × 60 s) and 2 stories
    expect(find.text('+6'), findsOneWidget); // 46 vs 40 words/min
    expect(find.text('Level 2 → almost 3'), findsOneWidget);
    expect(find.text('Mia read "strong" on their own this week. Those were hard before!'),
        findsOneWidget);
    expect(find.textContaining('"shell" and "ship"'), findsOneWidget); // weakest: sh
    await app.screenshot(tester, 's11_summary');

    await tester.tap(find.text("Print Mia's tricky words"));
    await tester.pump();
    final (title, words) = printer.printed.single;
    expect(title, "Mia's tricky words");
    expect(words, ['through']);

    await tester.tap(find.text('FIL'));
    await settle(tester);
    expect(find.text('Linggo ng pagbasa ni Mia'), findsOneWidget);
    expect(find.text('🎉 Ipagdiwang'), findsOneWidget);
    expect(find.text('Antas 2 → malapit na sa 3'), findsOneWidget);
  });

  group('SummaryText', () {
    WeeklySummary summary({
      DateTime? from,
      double? change,
      double? wcpm,
      String? tip,
      int stories = 0,
      List<String> celebrate = const [],
    }) =>
        WeeklySummary(
          nickname: 'Jojo',
          from: from ?? DateTime(2026, 9, 28),
          to: DateTime(2026, 10, 4),
          minutes: 0,
          stories: stories,
          wcpm: wcpm,
          wcpmChange: change,
          level: 4,
          levelProgress: 1,
          almostNext: false,
          topLevel: true,
          celebrateWords: celebrate,
          tipPattern: tip,
          trickyWords: const [],
        );

    test('dates across two months, top level, no comparison', () {
      final t = SummaryText(summary(wcpm: 51.4));
      expect(t.dates, 'Sep 28 – Oct 4');
      expect(t.levelBadge, 'Level 4 · top level');
      expect(t.wcpmValue, '51'); // no week before: just the average
      expect(SummaryText(summary(change: -2.2)).wcpmValue, '−2');
      expect(SummaryText(summary()).wcpmValue, '–');
    });

    test('celebrate falls back to stories read, then to a gentle start', () {
      expect(SummaryText(summary(stories: 1)).celebrate, 'Jojo read 1 story this week. Every story helps!');
      expect(SummaryText(summary()).celebrate, startsWith('No reading yet'));
      expect(
          SummaryText(summary(celebrate: ['ship', 'cat', 'red'])).celebrate,
          'Jojo read "ship", "cat" and "red" on their own this week. Those were hard before!');
    });

    test('sight-word and Filipino tips', () {
      const patterns = {
        'EN-SW': SoundPattern('EN-SW', 'Sight', ['the', 'was', 'said']),
        'FIL-CV': SoundPattern('FIL-CV', 'KP', ['bola', 'pusa']),
      };
      expect(SummaryText(summary(tip: 'EN-SW'), patterns: patterns).tip,
          startsWith('Write "the", "was" and "said" on small cards.'));
      expect(SummaryText(summary(tip: 'FIL-CV'), filipino: true, patterns: patterns).tip,
          'Kapag may nakita kayong salitang tulad ng "bola" at "pusa" sa karatula o pakete, '
          'ipabasa ito kay Jojo.');
    });
  });

  testWidgets('the printed page is a real PDF', (tester) async {
    final bytes = (await tester.runAsync(() => PdfTrickyWordsPrinter.buildPdf(
        title: "Mia's tricky words", hint: 'Read each word together.', words: ['through', 'strong'])))!;
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
}
