import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/data/story.dart';

import 'fixtures.dart';

/// Always returns the same "random" number, so scores are predictable.
class FixedRandom implements Random {
  FixedRandom(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

Story story(String id, String lang, int level, List<String> patterns) => Story(
      id: id,
      title: id,
      language: lang,
      level: level,
      text: '',
      words: [
        for (var i = 0; i < 4; i++)
          StoryWord(
            position: i + 1,
            word: 'w$i',
            patterns: patterns,
            primaryPattern: patterns.first,
            syllables: 1,
            difficulty: 0.1,
          ),
      ],
      questions: const [],
    );

void main() {
  final all = loadStories();

  group('§9 Story selection', () {
    test('candidates: only stories at the learner level and language', () {
      final shelf = StorySelector(random: Random(1)).select(
        stories: all,
        level: 1,
        languages: ['EN'],
        mastery: SoundMastery(),
      );
      expect(shelf.picks, isNotEmpty);
      for (final p in shelf.picks) {
        expect((p.story.level, p.story.language), (1, 'EN'));
      }
    });

    test('"Both" (EN,FIL) sees stories in both languages', () {
      final shelf = StorySelector(random: Random(1)).select(
        stories: all,
        level: 1,
        languages: ['EN', 'FIL'],
        mastery: SoundMastery(),
      );
      expect({for (final p in shelf.picks) p.story.language}, {'EN', 'FIL'});
    });

    test('shows all candidates, up to 4, ordered by score', () {
      for (var level = 1; level <= 4; level++) {
        final candidates = all
            .where((s) => s.level == level && s.language == 'EN')
            .length;
        final shelf = StorySelector(random: Random(level)).select(
          stories: all,
          level: level,
          languages: ['EN'],
          mastery: SoundMastery(),
        );
        expect(shelf.picks.length, min(candidates, 4), reason: 'L$level');
        final scores = [for (final p in shelf.picks) p.score];
        expect(scores, [...scores]..sort((a, b) => b.compareTo(a)));
      }
    });

    test('score = weak-sound coverage: weaker sounds rank first', () {
      final mastery = SoundMastery(mastery: {'EN-SH': 0.1, 'EN-SV': 0.9});
      final shelf = StorySelector(random: FixedRandom(0)).select(
        stories: [
          story('easy', 'EN', 1, ['EN-SV']),
          story('sh', 'EN', 1, ['EN-SH']),
        ],
        level: 1,
        languages: ['EN'],
        mastery: mastery,
      );
      expect(shelf.picks.first.story.id, 'sh');
      expect(shelf.picks.first.score, closeTo(0.9, 1e-12)); // 1 - 0.1
      expect(shelf.picks.last.score, closeTo(0.1, 1e-12)); // 1 - 0.9
    });

    test('recently read (last 3 sessions) gets −1.0 but is never hidden', () {
      final stories = [
        story('a', 'EN', 1, ['EN-SH']),
        story('b', 'EN', 1, ['EN-SV']),
      ];
      final shelf = StorySelector(random: FixedRandom(0)).select(
        stories: stories,
        level: 1,
        languages: ['EN'],
        mastery: SoundMastery(),
        recentStoryIds: ['a', 'x', 'y', 'z'],
      );
      expect([for (final p in shelf.picks) p.story.id], ['b', 'a']);
      expect(shelf.picks.last.score, closeTo(0.65 - 1.0, 1e-12));
    });

    test('only the last 3 sessions count as recent', () {
      final shelf = StorySelector(random: FixedRandom(0)).select(
        stories: [story('a', 'EN', 1, ['EN-SH'])],
        level: 1,
        languages: ['EN'],
        mastery: SoundMastery(),
        recentStoryIds: ['x', 'y', 'z', 'a'], // 'a' was 4 sessions ago
      );
      expect(shelf.picks.single.score, closeTo(0.65, 1e-12));
    });

    test('random variety bonus is between 0 and 0.15', () {
      final shelf = StorySelector(random: FixedRandom(0.999999)).select(
        stories: [story('a', 'EN', 1, ['EN-SH'])],
        level: 1,
        languages: ['EN'],
        mastery: SoundMastery(),
      );
      expect(shelf.picks.single.score, closeTo(0.65 + 0.15, 1e-5));
    });

    test('includes one "read again" favorite if available', () {
      final stories = [
        for (final id in ['a', 'b', 'c', 'd', 'e']) story(id, 'EN', 2, ['EN-SV']),
        story('fav', 'EN', 1, ['EN-SV']),
      ];
      final shelf = StorySelector(random: FixedRandom(0)).select(
        stories: stories,
        level: 2,
        languages: ['EN'],
        mastery: SoundMastery(),
        favoriteStoryId: 'fav',
      );
      expect(shelf.picks, hasLength(4));
      expect(shelf.picks.where((p) => p.isFavorite).single.story.id, 'fav');
    });

    test('explains the pick in one kid-friendly line', () {
      final shelf = StorySelector(random: FixedRandom(0)).select(
        stories: [story('sh', 'EN', 1, ['EN-SH'])],
        level: 1,
        languages: ['EN'],
        mastery: SoundMastery(),
      );
      expect(shelf.focusPattern, 'EN-SH');
      expect(shelf.reason, "These stories have more 'sh' words");
    });

    test('hint word parts keep every letter of every story word', () {
      for (final s in all) {
        for (final w in s.words) {
          expect(HintLadder.wordParts(w.word, s.language).join(),
              WordMatcher.normalize(w.word),
              reason: '${s.id} ${w.word}');
        }
      }
    });
  });
}
