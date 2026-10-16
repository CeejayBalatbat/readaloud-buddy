import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

void main() {
  group('§2 Hint content', () {
    test('level 1 = first sound: first letter or digraph/blend', () {
      expect(HintLadder.firstSound('through', 'EN'), 'thr');
      expect(HintLadder.firstSound('The', 'EN'), 'th');
      expect(HintLadder.firstSound('shell', 'EN'), 'sh');
      expect(HintLadder.firstSound('children', 'EN'), 'ch');
      expect(HintLadder.firstSound('strong', 'EN'), 'str');
      expect(HintLadder.firstSound('cat', 'EN'), 'c');
      // Filipino: the opening syllable (Abakada style).
      expect(HintLadder.firstSound('ngunit', 'FIL'), 'ngu');
      expect(HintLadder.firstSound('bangka', 'FIL'), 'ba');
      expect(HintLadder.firstSound('may', 'FIL'), 'ma');
      expect(HintLadder.firstSound('aso', 'FIL'), 'a');
      expect(HintLadder.firstSound('bata', 'FIL'), 'ba');
    });

    test('level 2 = word parts, e.g. "thr · ough"', () {
      expect(HintLadder.hintFor('through', 2, 'EN').display, 'thr · ough');
      expect(HintLadder.wordParts('bata', 'FIL'), ['ba', 'ta']);
      expect(HintLadder.wordParts('bangka', 'FIL'), ['bang', 'ka']);
      expect(HintLadder.wordParts('kumain', 'FIL'), ['ku', 'ma', 'in']);
      expect(HintLadder.wordParts('basket', 'EN'), ['bas', 'ket']);
      expect(HintLadder.wordParts('children', 'EN'), ['chil', 'dren']);
      expect(HintLadder.wordParts('kite', 'EN'), ['k', 'ite']);
      // Magic e also before "le" after a vowel; consonant + le is a part.
      expect(HintLadder.wordParts('smile', 'EN'), ['sm', 'ile']);
      expect(HintLadder.wordParts('hole', 'EN'), ['h', 'ole']);
      expect(HintLadder.wordParts('little', 'EN'), ['litt', 'le']);
      expect(HintLadder.wordParts('masayang-masaya', 'FIL'),
          ['ma', 'sa', 'yang', 'ma', 'sa', 'ya']);
    });

    test('word parts never lose or add letters (every story word)', () {
      // Checked against every word in stories.json in story_selection_test.
      for (final w in ['carefully', 'another', 'ipinagdiriwang', 'little']) {
        final lang = w == 'ipinagdiriwang' ? 'FIL' : 'EN';
        expect(HintLadder.wordParts(w, lang).join(), w);
      }
    });

    test('level 3 = the whole word', () {
      final h = HintLadder.hintFor('Through,', 3, 'EN');
      expect(h.level, 3);
      expect(h.display, 'through');
    });
  });

  group('§2 Hint learning', () {
    HintStats stats({
      required int l1Uses,
      required int l1Ok,
      required int l2Uses,
      required int l2Ok,
    }) =>
        HintStats({1: (l1Uses, l1Ok), 2: (l2Uses, l2Ok)});

    test('starts at level 2 when L2 ≥ 70% and L1 < 40% over ≥ 10 uses', () {
      expect(stats(l1Uses: 10, l1Ok: 3, l2Uses: 10, l2Ok: 7).startLevel(), 2);
    });

    test('stays at level 1 with fewer than 10 uses', () {
      expect(stats(l1Uses: 9, l1Ok: 0, l2Uses: 10, l2Ok: 10).startLevel(), 1);
      expect(stats(l1Uses: 10, l1Ok: 0, l2Uses: 9, l2Ok: 9).startLevel(), 1);
    });

    test('stays at level 1 when L1 works well enough (40% or more)', () {
      expect(stats(l1Uses: 10, l1Ok: 4, l2Uses: 10, l2Ok: 9).startLevel(), 1);
    });

    test('stays at level 1 when L2 is below 70%', () {
      expect(stats(l1Uses: 10, l1Ok: 0, l2Uses: 10, l2Ok: 6).startLevel(), 1);
    });

    test('recordAll counts uses and successes per level', () {
      final h = HintStats()
        ..recordAll(const [
          HintAttempt(level: 1, success: true),
          HintAttempt(level: 1, success: false),
          HintAttempt(level: 2, success: true),
        ]);
      expect((h.uses(1), h.successes(1)), (2, 1));
      expect(h.successRate(2), 1.0);
    });
  });
}
