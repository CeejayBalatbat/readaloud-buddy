import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

import 'fixtures.dart';

void main() {
  /// [mic] = false acts like tap-to-read: silence never pauses the timer.
  ReadingTracker tracker(String text,
          {String lang = 'EN',
          AgentConfig? cfg,
          bool mic = true,
          bool autoHints = true,
          Set<int> pageStarts = const {0},
          double? hintWaitSec,
          int startHintLevel = 1}) =>
      ReadingTracker(
        words: words(text),
        language: lang,
        config: cfg ?? const AgentConfig(),
        listensForQuiet: mic,
        autoHints: autoHints,
        pageStarts: pageStarts,
        hintWaitSec: hintWaitSec,
        startHintLevel: startHintLevel,
      );

  List<WordResult> results(ReadingTracker t) =>
      [for (final o in t.outcomes) o.result];

  group('§1 Word results', () {
    test('correct: matched within 3 s of the previous word', () {
      final t = tracker('Sam has a cat');
      t.onWordHeard('Sam', s(1));
      t.onWordHeard('has', s(4)); // exactly 3 s later still counts
      expect(results(t), [WordResult.correct, WordResult.correct]);
    });

    test('hesitated: matched but took more than 3 s', () {
      final t = tracker('Sam has');
      t.onWordHeard('Sam', s(3.5));
      expect(t.outcomes.single.result, WordResult.hesitated);
      expect(t.outcomes.single.responseMs, 3500);
    });

    test('correctAfterHint: matched only after a hint was given', () {
      final t = tracker('Sam through the', mic: false);
      t.onWordHeard('Sam', s(0)); // the first word of a page is never timed
      final u = t.tick(s(5)); // level 1 hint
      expect(u.hint!.level, 1);
      t.onWordHeard('through', s(6));
      expect(t.outcomes.last.result, WordResult.correctAfterHint);
      expect(t.outcomes.last.hintLevel, 1);
      expect(WordResult.correctAfterHint.countsAsCorrect, isFalse);
    });

    test('misread: a different word was heard in its place', () {
      final t = tracker('Sam has a cat');
      t.onWordHeard('Sam', s(1));
      t.onWordHeard('his', s(2));
      expect(results(t), [WordResult.correct, WordResult.misread]);
      expect(t.currentIndex, 2); // moves on to "a"
    });

    test('skipped: a later word (look-ahead 2) matched first', () {
      final t = tracker('Sam has a big cat');
      t.onWordHeard('Sam', s(1));
      final u = t.onWordHeard('big', s(2)); // skips "has" and "a"
      expect([for (final o in u.finished) o.result],
          [WordResult.skipped, WordResult.skipped, WordResult.correct]);
    });

    test('look-ahead is only 2 words: a word 3 ahead is a misread', () {
      final t = tracker('Sam has a big cat');
      t.onWordHeard('big', s(1)); // "big" is 3 ahead of "Sam"
      expect(results(t), [WordResult.misread]);
    });

    test('unsure: confidence below 0.5 is excluded from totals', () {
      final t = tracker('Sam has');
      t.onWordHeard('Sam', s(1), confidence: 0.3);
      expect(t.outcomes.single.result, WordResult.unsure);
      expect(WordResult.unsure.isScored, isFalse);
    });

    test('missing confidence is NOT unsure by default', () {
      final t = tracker('Sam has');
      t.onWordHeard('Sam', s(1)); // confidence: null
      expect(t.outcomes.single.result, WordResult.correct);
    });

    test('missing confidence is unsure when the config flag is on', () {
      final t = tracker('Sam has',
          cfg: const AgentConfig(treatMissingConfidenceAsUnsure: true));
      t.onWordHeard('Sam', s(1));
      expect(t.outcomes.single.result, WordResult.unsure);
    });

    test('FIL alignment uses exact matching (bato is a misread of bata)', () {
      final t = tracker('Ang bata', lang: 'FIL');
      t.onWordHeard('ang', s(1));
      t.onWordHeard('bato', s(2));
      expect(results(t), [WordResult.correct, WordResult.misread]);
    });

    test('each expected word ends in exactly one result', () {
      final t = tracker('one two three four five six');
      t.onWordHeard('one', s(1));
      t.onWordHeard('three', s(2));
      t.onWordHeard('xyz', s(3));
      t.finish(s(4));
      expect([for (final o in t.outcomes) o.position], [1, 2, 3, 4, 5, 6]);
      expect(t.isFinished, isTrue);
    });
  });

  group('§2 Hint ladder timing', () {
    // Most timing tests read "Sam" first, because the first word of a
    // page is never timed, and use mic: false so silence doesn't pause.
    ReadingTracker afterSam(String text,
        {bool mic = false, double? hintWaitSec, int startHintLevel = 1}) {
      final t = tracker('Sam $text',
          mic: mic, hintWaitSec: hintWaitSec, startHintLevel: startHintLevel);
      t.onWordHeard('Sam', s(0));
      return t;
    }

    test('hints escalate 1 → 2 → 3 every 5 s while stuck', () {
      final t = afterSam('through');
      expect(t.tick(s(4.9)).hint, isNull);
      expect(t.tick(s(5)).hint!.level, 1);
      expect(t.tick(s(9.9)).hint, isNull);
      expect(t.tick(s(10)).hint!.level, 2);
      expect(t.tick(s(15)).hint!.level, 3);
    });

    test('dyslexia mode waits 8 s', () {
      const cfg = AgentConfig();
      final t = afterSam('through', hintWaitSec: cfg.hintWaitFor(dyslexiaMode: true));
      expect(t.tick(s(7.9)).hint, isNull);
      expect(t.tick(s(8)).hint!.level, 1);
    });

    test('a parent-set wait time overrides the default', () {
      expect(const AgentConfig().hintWaitFor(parentSetSec: 6), 6);
      expect(const AgentConfig().hintWaitFor(), 5);
      expect(const AgentConfig().hintWaitFor(dyslexiaMode: true), 8);
    });

    test('the first word of a page is never timed', () {
      final t = tracker('through the', mic: false);
      expect(t.tick(s(60)).hint, isNull);
      expect(t.currentHintLevel, 0);
    });

    test('the first word of a later page is not timed either', () {
      // Page 1 = "Sam ran.", page 2 = "The cat".
      final t = tracker('Sam ran. The cat', mic: false, pageStarts: {0, 2});
      t.onWordHeard('Sam', s(0));
      t.onWordHeard('ran', s(1));
      expect(t.tick(s(60)).hint, isNull); // waiting on "The"
      t.onWordHeard('The', s(61));
      expect(t.tick(s(66)).hint!.word, 'cat'); // "cat" is timed again
    });

    test('no speech heard: the timer pauses (not resets) and Buddy asks '
        'the child to read louder', () {
      final t = afterSam('through', mic: true);
      // A child who stops right after reading a word still gets hint 1.
      expect(t.tick(s(5)).hint!.level, 1);
      expect(t.isQuiet(s(7.9)), isFalse);
      expect(t.isQuiet(s(8)), isTrue); // 8 s with no speech
      expect(t.tick(s(60)).hint, isNull); // silence never brings hint 2
      expect(t.currentHintLevel, 1);
      expect(t.isQuiet(s(60)), isTrue);
      t.onSpeech(s(60)); // the child speaks again
      expect(t.isQuiet(s(60)), isFalse);
      // 3 s were counted before the quiet (5 → 8), so 2 s are left.
      expect(t.tick(s(61.9)).hint, isNull);
      expect(t.tick(s(62)).hint!.level, 2);
    });

    test('a silent mic on the first word: ask to read louder, no hint', () {
      final t = tracker('through the');
      expect(t.isQuiet(s(7.9)), isFalse);
      expect(t.isQuiet(s(8)), isTrue);
      expect(t.tick(s(60)).hint, isNull);
    });

    test('tap-to-read is never "quiet"', () {
      final t = tracker('through the', mic: false);
      expect(t.isQuiet(s(60)), isFalse);
    });

    test('the quiet wait is never shorter than the hint wait', () {
      final t = afterSam('through', mic: true, hintWaitSec: 10);
      expect(t.isQuiet(s(9.9)), isFalse);
      expect(t.tick(s(10)).hint!.level, 1);
    });

    test('speaking but not matching counts toward hints', () {
      final t = afterSam('through', mic: true);
      final levels = <int>[];
      for (var i = 1; i <= 15; i++) {
        t.onSpeech(s(i)); // "thr… thr…"
        final h = t.tick(s(i)).hint;
        if (h != null) levels.add(h.level);
        expect(t.isQuiet(s(i)), isFalse);
      }
      expect(levels, [1, 2, 3]);
    });

    test('never auto-skips: after level 3 Buddy waits for the child', () {
      final t = afterSam('through the');
      t.tick(s(15)); // jumps straight through 1, 2, 3
      expect(t.currentHintLevel, 3);
      final u = t.tick(s(600));
      expect(u.finished, isEmpty);
      expect(t.currentIndex, 1);
      expect(t.currentHintLevel, 3);
    });

    test('"Next word" marks the word skipped only when tapped', () {
      final t = afterSam('through the');
      t.tick(s(15));
      final u = t.skipWord(s(30));
      expect(u.finished.single.result, WordResult.skipped);
      expect(u.finished.single.hintLevel, 3);
      expect(t.currentIndex, 2);
      expect(t.currentHintLevel, 0);
    });

    test('after level 3, reading the word gives correctAfterHint', () {
      final t = afterSam('through');
      t.tick(s(15));
      t.onWordHeard('through', s(16));
      expect(t.outcomes.last.result, WordResult.correctAfterHint);
      expect(t.outcomes.last.hintLevel, 3);
    });

    test('a recognizer restart does not reset the hint timer', () {
      final t = afterSam('through');
      t.tick(s(3));
      t.onListeningRestarted(s(3));
      expect(t.tick(s(5)).hint!.level, 1); // still due at 5 s, not 8 s
    });

    test('progress on a word resets the timer for the next word', () {
      final t = afterSam('has a');
      t.onWordHeard('has', s(4));
      expect(t.tick(s(8.9)).hint, isNull);
      expect(t.tick(s(9)).hint!.word, 'a');
    });

    test('a learner who starts at level 2 skips the first-sound hint', () {
      final t = afterSam('through', startHintLevel: 2);
      expect(t.tick(s(5)).hint!.level, 2);
      expect(t.tick(s(10)).hint!.level, 3);
    });

    test('Help gives the next hint step now; the timer then counts from it',
        () {
      final t = afterSam('through');
      expect(t.requestHint(s(1))!.level, 1);
      expect(t.currentHint!.level, 1);
      expect(t.tick(s(5.9)).hint, isNull); // next step due at 6 s, not 5 s
      expect(t.tick(s(6)).hint!.level, 2);
      expect(t.requestHint(s(7))!.level, 3);
      expect(t.requestHint(s(8)), isNull); // nothing after the whole word
    });

    test('Help works on the first word of a page and while the mic is quiet',
        () {
      final t = tracker('through the');
      expect(t.isQuiet(s(20)), isTrue);
      expect(t.requestHint(s(20))!.level, 1);
      expect(t.requestHint(s(21))!.level, 2);
    });

    test('Hints = Only when I tap Help: no timed hints, Help still works', () {
      final t = tracker('Sam through', mic: false, autoHints: false);
      t.onWordHeard('Sam', s(0));
      expect(t.tick(s(60)).hint, isNull);
      expect(t.currentHintLevel, 0);
      expect(t.requestHint(s(61))!.level, 1);
      expect(t.tick(s(120)).hint, isNull); // still no automatic step
      expect(t.requestHint(s(121))!.level, 2);
    });

    test('hint success = word read within 5 s after the hint', () {
      final t = afterSam('through the cat');
      t.tick(s(5)); // level 1 at 5 s
      t.onWordHeard('through', s(7)); // 2 s later -> success
      t.tick(s(12)); // level 1 on "the"
      t.tick(s(17)); // level 2 on "the" -> level 1 failed
      t.onWordHeard('the', s(23)); // 6 s after level 2 -> failed
      expect(
        [for (final a in t.hintAttempts) (a.level, a.success)],
        [(1, true), (1, false), (2, false)],
      );
    });
  });
}
