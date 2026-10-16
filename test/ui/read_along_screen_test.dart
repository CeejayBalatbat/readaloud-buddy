import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/speech/speech_providers.dart';
import 'package:readaloud_buddy/speech/speech_service.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/app/buddy_brain.dart';
import 'package:readaloud_buddy/app/feedback_mode.dart';
import 'package:readaloud_buddy/app/hint_mode.dart';
import 'package:readaloud_buddy/speech/fake_speech_service.dart';
import 'package:readaloud_buddy/app/reading_controller.dart';
import 'package:readaloud_buddy/ui/screens/read_along_screen.dart';

import 'test_app.dart';

void main() {
  final kite = TestApp.story('S06'); // The Big Red Kite
  const quiet = "I can't hear you. Try reading a bit louder!";

  Future<void> setMode(WidgetTester tester, TestApp app, FeedbackMode mode) =>
      tester.runAsync(() => app.container.read(feedbackModeProvider.notifier).set(mode));

  /// Most tests here are about live feedback (colors and timed hints); the
  /// read-first review mode has its own group below.
  Future<(TestApp, List<ReadingController>)> open(WidgetTester tester,
      {FeedbackMode mode = FeedbackMode.live, TestApp? app}) async {
    app ??= TestApp();
    await setMode(tester, app, mode);
    final finished = <ReadingController>[];
    await app.pump(tester, ReadAlongScreen(story: kite, onFinished: finished.add));
    return (app, finished);
  }

  Future<void> tapWord(WidgetTester tester, String text) async {
    await tester.tap(find.bySemanticsLabel(text).first);
    await tester.pump();
  }

  testWidgets('shows the title, page count, story text and controls',
      (tester) async {
    final (app, _) = await open(tester);
    expect(find.text('The Big Red Kite'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Mia'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Listening'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    await app.screenshot(tester, 's05_start');
  });

  testWidgets('tap = read, long-press = misread, tap ahead = skip',
      (tester) async {
    final (app, _) = await open(tester);
    await app.wait(tester, 1);
    await tapWord(tester, 'Mia');
    await app.wait(tester, 4); // more than 3 s: took a while
    await tapWord(tester, 'ran');
    await tester.longPress(find.bySemanticsLabel('up'));
    await tester.pump();
    await tapWord(tester, 'hill'); // skips "the"
    final results = app.container
        .read(buddyBrainProvider)
        .reading!
        .outcomes
        .map((o) => o.result);
    expect(results, [
      WordResult.correct,
      WordResult.hesitated,
      WordResult.misread,
      WordResult.skipped,
      WordResult.correct,
    ]);
    await app.screenshot(tester, 's05_reading');
  });

  testWidgets('waiting shows the hint screen, step by step', (tester) async {
    final (app, _) = await open(tester);
    await tapWord(tester, 'Mia'); // the first word of a page is never timed
    await app.wait(tester, 5);
    expect(find.text('IT STARTS LIKE'), findsOneWidget);
    expect(find.text('Hint appeared after 5 seconds on this word'), findsOneWidget);
    // Said aloud too, with a keyword ("ran" starts like rabbit), never "ar".
    expect(app.tts.spoken, ['It starts like', 'rabbit']);
    expect(find.text('rabbit'), findsOneWidget);
    expect(find.text('🐰'), findsOneWidget);

    await app.wait(tester, 5);
    expect(find.text("LET'S BREAK IT UP"), findsOneWidget);
    expect(find.text('✓ 1 · Sound'), findsOneWidget);
    await app.screenshot(tester, 's06_hint');

    await app.wait(tester, 5);
    expect(find.text('THE WORD IS'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('ran').first);
    await tester.pump();
    expect(find.text('THE WORD IS'), findsNothing); // back to reading
    expect(find.text('Help'), findsOneWidget);
  });

  testWidgets('Help asks Buddy for a hint right away', (tester) async {
    final (app, _) = await open(tester);
    await tester.tap(find.text('Help'));
    await tester.pump();
    expect(find.text('IT STARTS LIKE'), findsOneWidget);
    expect(find.text('You asked Buddy for help'), findsOneWidget);
    await app.screenshot(tester, 's06_help');
  });

  testWidgets('Filipino without phone support: tap to read, with a note',
      (tester) async {
    final fil = TestApp.stories.firstWhere((s) => s.language == 'FIL');
    final app = TestApp(); // the test speech service is tap-to-read
    await app.pump(tester, ReadAlongScreen(story: fil, onFinished: (_) {}));
    expect(find.textContaining("can't listen in Filipino"), findsOneWidget);
    // English stories don't show it.
    final (_, _) = await open(tester);
    expect(find.textContaining("can't listen in Filipino"), findsNothing);
  });

  testWidgets('a sight word gets one hint: "This one we just know"',
      (tester) async {
    final (app, _) = await open(tester);
    for (final w in ['Mia', 'ran', 'up']) {
      await tapWord(tester, w);
    }
    await app.wait(tester, 5); // stuck on "the"
    expect(find.text('WE JUST KNOW THIS ONE'), findsOneWidget);
    expect(find.text('This one we just know: the ❤️'), findsOneWidget);
    expect(app.tts.spoken, ['This one we just know.', 'the']);
    expect(find.text("Buddy's hint steps"), findsNothing);
    expect(find.text('Next word →'), findsOneWidget);
    await app.screenshot(tester, 's06_sight_word');
  });

  testWidgets('no hint on the first word, however long Buddy waits',
      (tester) async {
    final (app, _) = await open(tester);
    await app.wait(tester, 60);
    expect(find.text('IT STARTS LIKE'), findsNothing);
  });

  testWidgets('after the whole word Buddy waits for "Next word"',
      (tester) async {
    final (app, _) = await open(tester);
    await tapWord(tester, 'Mia');
    for (var i = 0; i < 3; i++) {
      await app.wait(tester, 5);
    }
    expect(find.text('THE WORD IS'), findsOneWidget);
    expect(find.text('Next word →'), findsOneWidget);
    await app.wait(tester, 120); // no auto-skip
    expect(find.text('THE WORD IS'), findsOneWidget);
    await app.screenshot(tester, 's06_next_word');

    await tester.tap(find.text('Next word →'));
    await tester.pump();
    expect(find.text('THE WORD IS'), findsNothing);
    final results = app.container.read(buddyBrainProvider).reading!.outcomes;
    expect(results.map((o) => o.result), [WordResult.correct, WordResult.skipped]);
  });

  testWidgets('Help on the hint screen gives the next step, then says the '
      'word again', (tester) async {
    final (app, _) = await open(tester);
    await tester.tap(find.text('Help'));
    await tester.pump();
    expect(find.text('IT STARTS LIKE'), findsOneWidget);
    await tester.tap(find.text('💡 Help'));
    await tester.pump();
    expect(find.text("LET'S BREAK IT UP"), findsOneWidget);
    await tester.tap(find.text('💡 Help'));
    await tester.pump();
    expect(find.text('THE WORD IS'), findsOneWidget);
    expect(find.text('Next word →'), findsOneWidget);
    app.tts.spoken.clear();
    await tester.tap(find.text('💡 Help')); // Help still works: says it again
    await tester.pump();
    expect(find.text('THE WORD IS'), findsOneWidget);
    expect(app.tts.spoken, ['mia']);
  });

  testWidgets('a silent mic: Buddy asks the child to read louder',
      (tester) async {
    final mic = FakeSpeechService(hearsSilence: true);
    final (app, _) = await open(tester, app: TestApp(speechService: mic));
    await app.wait(tester, 7);
    expect(find.text(quiet), findsNothing);
    await app.wait(tester, 1);
    expect(find.text(quiet), findsOneWidget);
    expect(app.tts.spoken, [quiet]); // said aloud once
    expect(find.text('IT STARTS LIKE'), findsNothing);
    await app.screenshot(tester, 's05_quiet');

    mic.speak(); // the child reads again
    await tester.pump(); // deliver the voice event
    await tester.pump(); // redraw
    expect(find.text(quiet), findsNothing);
    // Help still works while the mic is quiet.
    await app.wait(tester, 30);
    await tester.tap(find.text('Help'));
    await tester.pump();
    expect(find.text('IT STARTS LIKE'), findsOneWidget);
  });

  testWidgets('Hints = Only when I tap Help: no timed hints', (tester) async {
    final app = TestApp();
    await tester.runAsync(
        () => app.container.read(hintModeProvider.notifier).set(HintMode.helpOnly));
    await open(tester, app: app);
    await tapWord(tester, 'Mia');
    await app.wait(tester, 30);
    expect(find.text('IT STARTS LIKE'), findsNothing);
    await tester.tap(find.text('Help'));
    await tester.pump();
    expect(find.text('IT STARTS LIKE'), findsOneWidget);
  });

  testWidgets('pause and go on', (tester) async {
    final (app, _) = await open(tester);
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Go on'), findsOneWidget);
    await app.wait(tester, 20);
    expect(find.text('IT STARTS LIKE'), findsNothing);
    await tester.tap(find.text('Go on'));
    await tester.pump();
    expect(find.text('Listening'), findsOneWidget);
  });

  testWidgets('reading every word turns the pages and finishes',
      (tester) async {
    final (app, finished) = await open(tester);
    for (final w in kite.words) {
      app.speech.hear(w.word);
      await tester.pump();
    }
    expect(find.text('4 / 4'), findsOneWidget);
    expect(finished, hasLength(1));
    expect(finished.single.outcomes, hasLength(kite.words.length));
  });

  testWidgets('a blocked microphone shows what a grown-up can do',
      (tester) async {
    final app = TestApp(speechService: _NoMicSpeech());
    await app.pump(tester, ReadAlongScreen(story: kite, onFinished: (_) {}));
    await tester.pump();
    expect(find.text('Mic is off'), findsOneWidget);
    expect(find.textContaining("Buddy can't hear you yet"), findsOneWidget);
    // Tapping the mic asks again.
    await tester.tap(find.text('Mic is off'));
    await tester.pump();
    expect((app.container.read(speechServiceProvider('EN')) as _NoMicSpeech).starts, 2);
  });

  testWidgets("long-pressing the title opens Buddy's brain", (tester) async {
    final (app, _) = await open(tester);
    await tapWord(tester, 'Mia');
    await tester.longPress(find.text('The Big Red Kite'));
    await tester.pumpAndSettle();
    expect(find.text("Buddy's brain"), findsOneWidget);
    expect(find.text('PERCEPTS · WORD RESULTS (§1)'), findsOneWidget);
    expect(find.textContaining('Mia · correct'), findsOneWidget);
    await app.screenshot(tester, 'brain_reading');
  });

  group('read first, review after (default)', () {
    // Page 1 of the kite story: "Mia ran up the hill with her kite. The
    // wind was strong."
    const page1Rest = ['with', 'her', 'kite.', 'The', 'wind', 'was', 'strong.'];

    Future<void> readPage1WithMisses(WidgetTester tester, TestApp app) async {
      await tapWord(tester, 'Mia');
      await tapWord(tester, 'ran');
      await tester.longPress(find.bySemanticsLabel('up')); // misread
      await tester.pump();
      await tapWord(tester, 'hill'); // skips "the"
      for (final w in page1Rest) {
        app.speech.hear(w.replaceAll('.', ''));
        await tester.pump();
      }
    }

    double readingSeconds(TestApp app) =>
        app.container.read(buddyBrainProvider).reading!.readingSeconds;

    testWidgets('it is the default: soft marker, no legend, no timed hints',
        (tester) async {
      final app = TestApp();
      await app.pump(tester, ReadAlongScreen(story: kite, onFinished: (_) {}));
      expect(find.text('Took a while'), findsNothing); // no color legend
      expect(find.text('Help'), findsOneWidget);
      await tapWord(tester, 'Mia');
      await app.wait(tester, 30);
      expect(find.text('IT STARTS LIKE'), findsNothing);
      await app.screenshot(tester, 's05_read_first');
      // Help still works.
      await tester.tap(find.text('Help'));
      await tester.pump();
      expect(find.text('IT STARTS LIKE'), findsOneWidget);
    });

    testWidgets('after the page: review the missed words, then go on',
        (tester) async {
      final (app, _) = await open(tester, mode: FeedbackMode.review);
      await readPage1WithMisses(tester, app);
      expect(find.text('Next page →'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
      expect(find.bySemanticsLabel('up'), findsOneWidget);
      expect(find.bySemanticsLabel('the'), findsOneWidget);
      expect(find.bySemanticsLabel('Mia'), findsNothing); // read fine
      expect(app.tts.spoken.last, contains("Let's practise these words"));
      await app.screenshot(tester, 's05b_review');

      // Time stops during review (WCPM only counts reading).
      final before = readingSeconds(app);
      await app.wait(tester, 30);
      expect(readingSeconds(app), before);

      // Hear a word, then say it again.
      await tester.tap(find.text('🔊 Hear it').last);
      await tester.pump();
      expect(app.tts.spoken.last, 'the');
      await tester.tap(find.bySemanticsLabel('the')); // tap-to-read: "say" it
      await tester.pump();
      expect(find.text('✓ You said it!'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('up'));
      await tester.pump();
      expect(find.text('✓ You said it!'), findsNWidgets(2));
      expect(find.text('Great job! On to the next page.'), findsOneWidget);

      // Practice does not change the scores (Phil-IRI).
      final results = app.container.read(buddyBrainProvider).reading!.outcomes;
      expect(results[2].result, WordResult.misread);
      expect(results[3].result, WordResult.skipped);

      await tester.tap(find.text('Next page →'));
      await tester.pump();
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
    });

    testWidgets('a page with no missed words goes straight on',
        (tester) async {
      final (app, _) = await open(tester, mode: FeedbackMode.review);
      for (final w in kite.words.take(12)) {
        app.speech.hear(w.word);
        await tester.pump();
      }
      expect(find.text('Next page →'), findsNothing);
      expect(find.text('2 / 4'), findsOneWidget);
    });

    testWidgets('the story finishes only after the last review',
        (tester) async {
      final (app, finished) = await open(tester, mode: FeedbackMode.review);
      final words = kite.words;
      for (final w in words.take(words.length - 1)) {
        app.speech.hear(w.word);
        await tester.pump();
      }
      app.speech.hear('banana'); // misreads the last word
      await tester.pump();
      expect(find.text('All done ✓'), findsOneWidget);
      expect(finished, isEmpty);
      await tester.tap(find.text('All done ✓'));
      await tester.pump();
      expect(finished, hasLength(1));
      expect(finished.single.outcomes.last.result, WordResult.misread);
    });
  });
}

/// A recognizer whose microphone permission was refused.
class _NoMicSpeech implements SpeechService {
  final _state = ValueNotifier(const SpeechState());
  int starts = 0;

  @override
  Stream<HeardWord> get words => const Stream.empty();
  @override
  Stream<void> get voice => const Stream.empty();
  @override
  bool get hearsSilence => true;
  @override
  ValueListenable<SpeechState> get state => _state;
  @override
  bool get isListening => false;
  @override
  Future<void> start({required String language}) async {
    starts++;
    _state.value = const SpeechState(status: MicStatus.noPermission);
  }

  @override
  Future<void> stop() async {}
  @override
  set expectedWord(String? word) {}
  @override
  void mute(bool muted) {}
  @override
  void dispose() {}
}
