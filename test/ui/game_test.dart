import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/app/current_learner.dart';
import 'package:readaloud_buddy/data/repositories/learner_repository.dart';
import 'package:readaloud_buddy/data/repositories/progress_repository.dart';
import 'package:readaloud_buddy/ui/screens/home_shell.dart';

import 'test_app.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('Games tab → Build the word with a tricky word, then a star',
      (tester) async {
    final app = TestApp();
    late String id;
    await tester.runAsync(() async {
      final mia = await LearnerRepository(app.db)
          .create(nickname: 'Mia', grade: 2, languages: 'EN');
      id = mia.id;
      await ProgressRepository(app.db).saveTrickyWords(
          mia.id,
          TrickyWords(words: const [
            TrickyWord(word: 'ship', patternCode: 'EN-SH', cleanReads: 1),
          ]));
      await app.container.read(currentLearnerProvider.notifier).select(mia.id);
    });
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Games'));
    await settle(tester);
    expect(find.text('Build the word'), findsOneWidget);
    expect(find.textContaining('from your tricky list'), findsOneWidget);
    expect(find.textContaining('Mia found tricky'), findsOneWidget);

    await tester.tap(find.text('▶ Play'));
    await settle(tester);
    expect(find.text('1 / 5'), findsOneWidget);
    expect(app.tts.spoken, contains('ship')); // Buddy says the word
    expect(find.text('Why this game?'.toUpperCase()), findsOneWidget);
    await app.screenshot(tester, 's09_game');

    // A wrong letter first is refused gently...
    final wrong = ['a', 'e', 'o', 'u', 'b', 'd', 'n', 'm', 't', 'r', 'z', 'c', 'q', 'v']
        .firstWhere((c) => find.bySemanticsLabel('Letter $c').evaluate().isNotEmpty);
    await tester.tap(find.bySemanticsLabel('Letter $wrong'));
    await tester.pump();
    expect(find.text('Not that one. Listen again!'), findsOneWidget);
    // ...then build "ship".
    for (final c in ['s', 'h', 'i', 'p']) {
      await tester.tap(find.bySemanticsLabel('Letter $c').first);
      await tester.pump();
    }
    expect(find.text('You built "ship"!'), findsOneWidget); // not clean: no 🎉
    // Build the other four cleanly by reading the target from the screen.
    for (var n = 2; n <= 5; n++) {
      await tester.tap(find.text('Next word →'));
      await settle(tester);
      expect(find.text('$n / 5'), findsOneWidget);
      final word = app.tts.spoken.last;
      for (final c in word.split('')) {
        await tester.tap(find.bySemanticsLabel('Letter $c').first);
        await tester.pump();
      }
      expect(find.text('You built "$word"! 🎉'), findsOneWidget);
    }
    await tester.tap(find.text('Finish ✓'));
    await settle(tester);
    expect(find.text('You built 5 words!'), findsOneWidget);
    expect(find.text('+1 ⭐ for practising'), findsOneWidget);

    final learner = await tester.runAsync(() => LearnerRepository(app.db).byId(id));
    expect(learner!.stars, 1);
    // "ship" had a mistake, so it is still tricky with 1 clean read.
    final tricky = await tester.runAsync(() => ProgressRepository(app.db).loadTrickyWords(id));
    expect(tricky!.words.single.cleanReads, 1);
  });
}
