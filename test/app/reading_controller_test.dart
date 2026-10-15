import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/app/reading_controller.dart';
import 'package:readaloud_buddy/data/story.dart';
import 'package:readaloud_buddy/speech/fake_speech_service.dart';

void main() {
  final stories =
      parseStories(File('assets/data/stories.json').readAsStringSync());
  final s01 = stories.firstWhere((s) => s.id == 'S01');

  group('paginate', () {
    test('pages hold whole sentences, about 12 words each', () {
      final tokens = s01.text.split(' ');
      final pages = paginate(tokens);
      expect([for (final p in pages) ...p], List.generate(tokens.length, (i) => i));
      for (final p in pages) {
        expect(tokens[p.last], matches(RegExp(r'[.!?]$')));
        expect(p.length, lessThanOrEqualTo(12));
      }
    });

    test('every story splits into pages without losing a word', () {
      for (final s in stories) {
        final pages = paginate(s.text.split(' '));
        expect(pages.expand((p) => p).length, s.words.length, reason: s.id);
      }
    });
  });

  group('ReadingController', () {
    late FakeSpeechService speech;
    late ManualClock clock;
    late ReadingController c;

    setUp(() async {
      speech = FakeSpeechService();
      clock = ManualClock();
      c = ReadingController(
        story: s01,
        speech: speech,
        clock: clock,
        tickEvery: const Duration(days: 1), // we call tick() ourselves
      );
      await c.start();
    });
    tearDown(() {
      c.dispose();
      speech.dispose();
    });

    Future<void> hear(String w) async {
      speech.hear(w);
      await Future<void>.delayed(Duration.zero); // let the stream deliver
    }

    test('heard words become word results with real timing', () async {
      clock.advance(const Duration(seconds: 1));
      await hear('Sam');
      clock.advance(const Duration(seconds: 4));
      await hear('has');
      expect(c.resultOf(0), WordResult.correct);
      expect(c.resultOf(1), WordResult.hesitated);
      expect(c.currentIndex, 2);
    });

    test('waiting on a word brings the hint ladder', () async {
      await hear('Sam'); // the first word of a page is never timed
      clock.advance(const Duration(seconds: 5));
      c.tick();
      expect(c.hint!.level, 1);
      clock.advance(const Duration(seconds: 5));
      c.tick();
      expect(c.hint!.level, 2);
      await hear('has');
      expect(c.resultOf(1), WordResult.correctAfterHint);
      expect(c.hint, isNull);
    });

    test('no hint on the first word of a page, however long', () {
      clock.advance(const Duration(seconds: 60));
      c.tick();
      expect(c.hint, isNull);
    });

    test('after the whole word Buddy waits; "Next word" skips it', () async {
      await hear('Sam');
      clock.advance(const Duration(seconds: 15));
      c.tick();
      expect(c.hint!.level, 3);
      expect(c.canSkipWord, isTrue);
      clock.advance(const Duration(minutes: 5));
      c.tick();
      expect(c.currentIndex, 1); // still waiting on "has"
      c.nextWord();
      expect(c.resultOf(1), WordResult.skipped);
      expect(c.currentIndex, 2);
      expect(c.canSkipWord, isFalse);
    });

    test('Help gives a hint now and is marked as asked-for', () {
      c.help();
      expect(c.hint!.level, 1);
      expect(c.hintFromHelp, isTrue);
    });

    test('pause stops time and ignores words; resume carries on', () async {
      c.pause();
      clock.advance(const Duration(seconds: 30)); // clock is stopped
      await hear('Sam');
      expect(c.outcomes, isEmpty);
      c.tick();
      expect(c.hint, isNull);
      c.resume();
      await hear('Sam');
      expect(c.resultOf(0), WordResult.correct);
    });

    test('the page follows the current word, and the end is detected',
        () async {
      expect(c.pageIndex, 0);
      for (final w in s01.words) {
        await hear(w.word);
      }
      expect(c.isFinished, isTrue);
      expect(c.pageIndex, c.pages.length - 1);
      expect(c.outcomes.every((o) => o.result == WordResult.correct), isTrue);
    });

    test('a misread word from long-press moves on', () async {
      await hear(FakeSpeechService.misreadWord);
      expect(c.resultOf(0), WordResult.misread);
    });

    test('tap-to-read never says "I can\'t hear you"', () {
      clock.advance(const Duration(seconds: 60));
      c.tick();
      expect(c.isQuiet, isFalse);
    });
  });

  group('ReadingController with a real mic', () {
    late FakeSpeechService speech;
    late ManualClock clock;

    Future<ReadingController> open({bool autoHints = true}) async {
      speech = FakeSpeechService(hearsSilence: true);
      clock = ManualClock();
      final c = ReadingController(
        story: s01,
        speech: speech,
        clock: clock,
        autoHints: autoHints,
        tickEvery: const Duration(days: 1),
      );
      addTearDown(() {
        c.dispose();
        speech.dispose();
      });
      await c.start();
      return c;
    }

    /// Lets heard words/voice arrive first, then moves time on.
    Future<void> wait(ReadingController c, double sec) async {
      await Future<void>.delayed(Duration.zero);
      clock.advance(Duration(milliseconds: (sec * 1000).round()));
      c.tick();
    }

    test('silence pauses the hint timer and shows "can\'t hear you"',
        () async {
      final c = await open();
      speech.hear('Sam');
      await wait(c, 5);
      expect(c.hint!.level, 1); // stopped after a word: first hint
      await wait(c, 3);
      expect(c.isQuiet, isTrue);
      await wait(c, 60);
      expect(c.hint!.level, 1); // no more hints in silence
      speech.speak(); // "h… h…"
      await Future<void>.delayed(Duration.zero);
      expect(c.isQuiet, isFalse);
      await wait(c, 1.9); // 3 s counted before the quiet + 2 s now
      expect(c.hint!.level, 1);
      await wait(c, 0.1);
      expect(c.hint!.level, 2);
    });

    test('mumbling (speech, no match) brings hints', () async {
      final c = await open();
      speech.hear('Sam');
      for (var i = 0; i < 10; i++) {
        speech.speak();
        await wait(c, 1);
      }
      expect(c.hint!.level, 2);
      expect(c.isQuiet, isFalse);
    });

    test('a hint due while the child speaks is shown on the next tick',
        () async {
      final c = await open();
      speech.hear('Sam');
      await Future<void>.delayed(Duration.zero);
      var notified = 0;
      c.addListener(() => notified++);
      clock.advance(const Duration(seconds: 5));
      speech.speak(); // counts the 5 s, but only tick gives the hint
      await Future<void>.delayed(Duration.zero);
      expect(c.hint, isNull);
      c.tick();
      expect(c.hint!.level, 1);
      expect(notified, greaterThan(0));
    });

    test('Hints = Only when I tap Help: no timed hints; Help still works',
        () async {
      final c = await open(autoHints: false);
      speech.hear('Sam');
      for (var i = 0; i < 30; i++) {
        speech.speak();
        await wait(c, 1);
      }
      expect(c.hint, isNull);
      expect(c.help(), isTrue);
      expect(c.hint!.level, 1);
    });

    test('Help works on the first word and while the mic is quiet', () async {
      final c = await open();
      await wait(c, 20);
      expect(c.isQuiet, isTrue);
      expect(c.help(), isTrue);
      expect(c.hint!.level, 1);
    });
  });
}
