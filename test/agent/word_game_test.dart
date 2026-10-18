import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/data/story.dart';

void main() {
  final stories =
      parseStories(File('assets/data/stories.json').readAsStringSync());
  const game = WordGame();
  // The books Buddy would recommend to a beginning reader.
  const easyBooks = {'S01', 'S02', 'S03', 'S04', 'S05'};

  List<GameWord> pick(List<TrickyWord> tricky, {SoundMastery? mastery}) =>
      game.pickWords(
        tricky: tricky,
        mastery: mastery ?? SoundMastery(),
        stories: stories,
        practiceStoryIds: easyBooks,
        languages: ['EN'],
        random: Random(1),
      );

  group('Screen 9: Build the word', () {
    test('tricky words first, weakest sound first', () {
      final words = pick(
        const [
          TrickyWord(word: 'cat', patternCode: 'EN-SV'),
          TrickyWord(word: 'ship', patternCode: 'EN-SH'),
        ],
        mastery: SoundMastery(mastery: {'EN-SV': 0.9, 'EN-SH': 0.2}),
      );
      expect(words.take(2).map((w) => w.word), ['ship', 'cat']);
      expect(words.take(2).every((w) => w.fromTrickyList), isTrue);
    });

    test('topped up to 5 with words from the recommended books', () {
      final words = pick(const [TrickyWord(word: 'ship', patternCode: 'EN-SH')]);
      expect(words, hasLength(5));
      final easyWords = {
        for (final s in stories)
          if (easyBooks.contains(s.id))
            for (final w in s.words) WordMatcher.normalize(w.word),
      };
      expect(words.skip(1).every((w) => easyWords.contains(w.word)), isTrue);
      expect(words.skip(1).any((w) => w.fromTrickyList), isFalse);
      expect(words.map((w) => w.word).toSet(), hasLength(5)); // no repeats
      for (final w in words.skip(1)) {
        expect(w.patternCode, isNot('EN-SW'), reason: 'no sight words to build');
      }
    });

    test('hyphenated and very long words are left out', () {
      final words = game.pickWords(
        tricky: const [
          TrickyWord(word: 'arawaraw', patternCode: 'FIL-CV'),
          TrickyWord(word: 'masayangmasaya', patternCode: 'FIL-CV'),
          TrickyWord(word: 'bata', patternCode: 'FIL-CV'),
        ],
        mastery: SoundMastery(),
        stories: stories,
        practiceStoryIds: easyBooks,
        languages: ['FIL'],
      );
      expect(words.first.word, 'bata');
      expect(words.map((w) => w.word), isNot(contains('arawaraw')));
      expect(words.map((w) => w.word), isNot(contains('masayangmasaya')));
      expect(words.first.language, 'FIL');
    });

    test('"Why this game?" names the sounds', () {
      final why = WordGame.whyLine('Mia', const [
        GameWord(word: 'strong', patternCode: 'EN-BL3', fromTrickyList: true),
        GameWord(word: 'ring', patternCode: 'EN-NG', fromTrickyList: true),
      ]);
      expect(why, 'Buddy picks words Mia found tricky, like "blend" and "ng".');
      expect(
          WordGame.whyLine('Mia', const [
            GameWord(word: 'ship', patternCode: 'EN-SH', fromTrickyList: true),
            GameWord(word: 'then', patternCode: 'EN-TH'),
          ]),
          'Buddy picks words Mia found tricky and sounds Mia is still learning, '
          'like "sh" and "th".');
    });

    test('tiles = the word\'s letters + 2 look-alikes, shuffled', () {
      final tiles = WordGame.tiles('ship', random: Random(3));
      expect(tiles, hasLength(6));
      for (final c in 'ship'.split('')) {
        expect(tiles, contains(c));
      }
      final extra = [...tiles]..removeWhere('ship'.contains);
      expect(extra, hasLength(2));
      expect(tiles.take(4).join(), isNot('ship'));
    });

    test('a round: right letters stay, a wrong one counts as a mistake', () {
      const word = GameWord(word: 'cat', patternCode: 'EN-SV');
      final r = BuildRound(word, ['t', 'a', 'x', 'c']);
      expect(r.place(0), isFalse); // "t" is not first
      expect(r.mistakes, 1);
      expect(r.place(3), isTrue); // c
      expect(r.place(1), isTrue); // a
      expect(r.place(3), isFalse); // already used
      expect(r.place(0), isTrue); // t
      expect(r.isDone, isTrue);
      expect(r.isClean, isFalse);
      expect(r.placed.join(), 'cat');
    });

    test('§8: two clean builds take a word off the tricky list', () {
      const ship = GameWord(word: 'ship', patternCode: 'EN-SH', fromTrickyList: true);
      final tricky = TrickyWords(words: const [TrickyWord(word: 'ship', patternCode: 'EN-SH')]);
      // A build with a mistake doesn't count (and doesn't reset).
      tricky.recordActivity(WordGame.outcomesFor([(ship, false)]));
      expect(tricky.words.single.cleanReads, 0);
      tricky.recordActivity(WordGame.outcomesFor([(ship, true)]));
      expect(tricky.words.single.cleanReads, 1);
      final done = tricky.recordActivity(WordGame.outcomesFor([(ship, true)]));
      expect(done.removed.single.word, 'ship');
      expect(tricky.words, isEmpty);
    });
  });
}
