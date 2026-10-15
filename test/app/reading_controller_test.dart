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
      clock.advance(const Duration(seconds: 5));
      c.tick();
      expect(c.hint!.level, 1);
      clock.advance(const Duration(seconds: 5));
      c.tick();
      expect(c.hint!.level, 2);
      await hear('Sam');
      expect(c.resultOf(0), WordResult.correctAfterHint);
      expect(c.hint, isNull);
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
  });
}
