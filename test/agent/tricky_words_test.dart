import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

import 'fixtures.dart';

void main() {
  group('§8 Tricky words', () {
    test('misread, skipped and correctAfterHint make a word tricky', () {
      final t = TrickyWords();
      final r = t.recordActivity([
        outcome('ship', WordResult.misread),
        outcome('three', WordResult.skipped),
        outcome('Through,', WordResult.correctAfterHint),
        outcome('cat', WordResult.correct),
        outcome('dog', WordResult.hesitated),
        outcome('sun', WordResult.unsure),
      ]);
      expect([for (final w in r.added) w.word], ['ship', 'three', 'through']);
      expect(t.contains('cat'), isFalse);
      expect(t.contains('sun'), isFalse);
    });

    test('leaves after clean reads in 2 later sessions', () {
      final t = TrickyWords()
        ..recordActivity([outcome('ship', WordResult.misread)]);
      t.recordActivity([outcome('ship', WordResult.correct)]);
      expect(t.contains('ship'), isTrue);
      final r = t.recordActivity([outcome('ship', WordResult.correct)]);
      expect(t.contains('ship'), isFalse);
      expect(r.removed.single.word, 'ship');
    });

    test('a hesitated read counts as a clean read', () {
      final t = TrickyWords()
        ..recordActivity([outcome('ship', WordResult.misread)])
        ..recordActivity([outcome('ship', WordResult.hesitated)])
        ..recordActivity([outcome('ship', WordResult.hesitated)]);
      expect(t.contains('ship'), isFalse);
    });

    test('reading it 2 times in ONE session counts as only 1 clean read', () {
      final t = TrickyWords()
        ..recordActivity([outcome('ship', WordResult.misread)])
        ..recordActivity([
          outcome('ship', WordResult.correct),
          outcome('ship', WordResult.correct),
        ]);
      expect(t.contains('ship'), isTrue);
      expect(t.words.single.cleanReads, 1);
    });

    test('the session that adds the word does not count as a clean read', () {
      final t = TrickyWords()
        ..recordActivity([
          outcome('ship', WordResult.misread),
          outcome('ship', WordResult.correct),
        ]);
      expect(t.words.single.cleanReads, 0);
    });
  });
}
