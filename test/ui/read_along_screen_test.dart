import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/speech/speech_providers.dart';
import 'package:readaloud_buddy/speech/speech_service.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/app/buddy_brain.dart';
import 'package:readaloud_buddy/app/reading_controller.dart';
import 'package:readaloud_buddy/ui/screens/read_along_screen.dart';

import 'test_app.dart';

void main() {
  final kite = TestApp.story('S06'); // The Big Red Kite

  Future<(TestApp, List<ReadingController>)> open(WidgetTester tester) async {
    final app = TestApp();
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
    await app.wait(tester, 5);
    expect(find.text('LISTEN TO THE FIRST SOUND'), findsOneWidget);
    expect(find.text('Hint appeared after 5 seconds on this word'), findsOneWidget);
    expect(app.tts.spoken, ['m']); // hint is said aloud too

    await app.wait(tester, 5);
    expect(find.text("LET'S BREAK IT UP"), findsOneWidget);
    expect(find.text('✓ 1 · Sound'), findsOneWidget);
    await app.screenshot(tester, 's06_hint');

    await app.wait(tester, 5);
    expect(find.text('THE WORD IS'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Mia').first);
    await tester.pump();
    expect(find.text('THE WORD IS'), findsNothing); // back to reading
    expect(find.text('Help'), findsOneWidget);
  });

  testWidgets('Help asks Buddy for a hint right away', (tester) async {
    final (app, _) = await open(tester);
    await tester.tap(find.text('Help'));
    await tester.pump();
    expect(find.text('LISTEN TO THE FIRST SOUND'), findsOneWidget);
    expect(find.text('You asked Buddy for help'), findsOneWidget);
    await app.screenshot(tester, 's06_help');
  });

  testWidgets('pause and go on', (tester) async {
    final (app, _) = await open(tester);
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Go on'), findsOneWidget);
    await app.wait(tester, 20);
    expect(find.text('LISTEN TO THE FIRST SOUND'), findsNothing);
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
}

/// A recognizer whose microphone permission was refused.
class _NoMicSpeech implements SpeechService {
  final _state = ValueNotifier(const SpeechState());
  int starts = 0;

  @override
  Stream<HeardWord> get words => const Stream.empty();
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
