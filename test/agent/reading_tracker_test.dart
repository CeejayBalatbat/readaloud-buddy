import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

import 'fixtures.dart';

void main() {
  ReadingTracker tracker(String text, {String lang = 'EN', AgentConfig? cfg}) =>
      ReadingTracker(
        words: words(text),
        language: lang,
        config: cfg ?? const AgentConfig(),
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
      final t = tracker('through the');
      final u = t.tick(s(5)); // level 1 hint
      expect(u.hint!.level, 1);
      t.onWordHeard('through', s(6));
      expect(t.outcomes.single.result, WordResult.correctAfterHint);
      expect(t.outcomes.single.hintLevel, 1);
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
    test('hints escalate 1 → 2 → 3 every 5 s with no progress', () {
      final t = tracker('through');
      expect(t.tick(s(4.9)).hint, isNull);
      expect(t.tick(s(5)).hint!.level, 1);
      expect(t.tick(s(9.9)).hint, isNull);
      expect(t.tick(s(10)).hint!.level, 2);
      expect(t.tick(s(15)).hint!.level, 3);
    });

    test('dyslexia mode waits 8 s', () {
      const cfg = AgentConfig();
      final t = ReadingTracker(
        words: words('through'),
        language: 'EN',
        hintWaitSec: cfg.hintWaitFor(dyslexiaMode: true),
      );
      expect(t.tick(s(7.9)).hint, isNull);
      expect(t.tick(s(8)).hint!.level, 1);
    });

    test('a parent-set wait time overrides the default', () {
      expect(const AgentConfig().hintWaitFor(parentSetSec: 6), 6);
      expect(const AgentConfig().hintWaitFor(), 5);
      expect(const AgentConfig().hintWaitFor(dyslexiaMode: true), 8);
    });

    test('after level 3, reading the word gives correctAfterHint', () {
      final t = tracker('through');
      t.tick(s(15)); // jumps straight through 1, 2, 3
      expect(t.currentHintLevel, 3);
      t.onWordHeard('through', s(16));
      expect(t.outcomes.single.result, WordResult.correctAfterHint);
      expect(t.outcomes.single.hintLevel, 3);
    });

    test('after level 3, if the child does not read it Buddy moves on: skipped',
        () {
      final t = tracker('through the');
      t.tick(s(15));
      final u = t.tick(s(20));
      expect(u.finished.single.result, WordResult.skipped);
      expect(u.finished.single.hintLevel, 3);
      expect(t.currentIndex, 1);
    });

    test('a recognizer restart does not reset the hint timer', () {
      final t = tracker('through');
      t.tick(s(3));
      t.onListeningRestarted(s(3));
      expect(t.tick(s(5)).hint!.level, 1); // still due at 5 s, not 8 s
    });

    test('progress on a word resets the timer for the next word', () {
      final t = tracker('Sam has');
      t.onWordHeard('Sam', s(4));
      expect(t.tick(s(8.9)).hint, isNull);
      expect(t.tick(s(9)).hint!.word, 'has');
    });

    test('a learner who starts at level 2 skips the first-sound hint', () {
      final t = ReadingTracker(
          words: words('through'), language: 'EN', startHintLevel: 2);
      expect(t.tick(s(5)).hint!.level, 2);
      expect(t.tick(s(10)).hint!.level, 3);
    });

    test('hint success = word read within 5 s after the hint', () {
      final t = tracker('through the cat');
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
