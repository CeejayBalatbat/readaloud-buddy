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

void main() {
  final all = loadStories();
  final predictor = AccuracyPredictor(patternDifficulty: loadPatternDifficulty());

  StoryShelf shelf({
    double score = 50,
    double bias = 1.6,
    List<String> languages = const ['EN'],
    SoundMastery? mastery,
    List<String> recent = const [],
    Map<String, double> best = const {},
    List<Story>? stories,
    Random? random,
  }) =>
      StorySelector(random: random ?? FixedRandom(0)).select(
        stories: stories ?? all,
        languages: languages,
        mastery: mastery ?? SoundMastery(),
        score: score,
        bias: bias,
        predictor: predictor,
        recentStoryIds: recent,
        bestPastAccuracy: best,
      );

  group('§9 Recommendation by prediction', () {
    test('candidates: every story in the reader\'s language(s), predicted', () {
      final en = shelf();
      expect(en.predictions.map((p) => p.story.language).toSet(), {'EN'});
      expect(en.predictions, hasLength(all.where((s) => s.language == 'EN').length));
      final both = shelf(languages: ['EN', 'FIL']);
      expect(both.predictions, hasLength(all.length));
      // Most likely to be read well first.
      final acc = [for (final p in both.predictions) p.accuracy];
      expect(acc, [...acc]..sort((a, b) => b.compareTo(a)));
    });

    test('up to 3 "just right" (Instructional) books, never a Frustration one', () {
      final s = shelf(score: 50);
      final justRight = s.picks.where((p) => p.kind == PickKind.justRight).toList();
      expect(justRight, isNotEmpty);
      expect(justRight.length, lessThanOrEqualTo(3));
      for (final p in justRight) {
        expect(p.prediction.band, PhilIriLevel.instructional);
      }
      expect(s.picks.any((p) => p.prediction.band == PhilIriLevel.frustration), isFalse);
      expect(s.nothingFits, isFalse);
      expect(s.picks, hasLength(4));
    });

    test('one easy re-read: read before, now easy, the one read best', () {
      final s = shelf(score: 50, best: {'S01': 0.92, 'S02': 0.99, 'S18': 1.0});
      final again = s.picks.where((p) => p.isFavorite).toList();
      expect(again.single.story.id, 'S02'); // S18 is too hard now
      expect(again.single.prediction.band, PhilIriLevel.independent);
      expect(s.picks.last.isFavorite, isTrue); // shown last
    });

    test('no re-read yet: the free slot is the easy book closest to just right', () {
      final s = shelf(score: 50);
      final easy = s.predictions.where((p) => p.band == PhilIriLevel.independent).toList();
      final fill = s.picks.where((p) => p.kind == PickKind.easy).toList();
      expect(fill, isNotEmpty);
      final lowest = easy.map((p) => p.accuracy).reduce(min);
      expect(fill.first.prediction.accuracy, lowest);
    });

    test('a beginning reader (nothing fits yet): the easiest books, Buddy helps', () {
      final s = shelf(score: 0);
      expect(s.nothingFits, isTrue);
      expect(s.picks, hasLength(3));
      expect(s.picks.every((p) => p.kind == PickKind.challenge), isTrue);
      expect(s.picks.map((p) => p.story.id), s.predictions.take(3).map((p) => p.story.id));
      expect(s.reason, StorySelector.nothingFitsReason);
    });

    test('a strong reader: every book is easy, so the hardest easy ones', () {
      final s = shelf(score: 100, bias: 3);
      expect(s.picks, hasLength(4));
      expect(s.picks.every((p) => p.prediction.band == PhilIriLevel.independent), isTrue);
      expect(s.picks.map((p) => p.story.id), containsAll(['S18', 'S16']));
    });

    test('a higher reading score moves the shelf to harder books', () {
      double avg(StoryShelf s) =>
          s.picks.map((p) => p.story.difficulty).reduce((a, b) => a + b) / s.picks.length;
      expect(avg(shelf(score: 60)), greaterThan(avg(shelf(score: 30))));
    });

    test('recently read (last 3 sessions) goes to the back of the just-right line', () {
      // Three books that are all just right, so all three are shown.
      final three = [
        for (final p in shelf(score: 50).predictions)
          if (p.band == PhilIriLevel.instructional) p.story,
      ].take(3).toList();
      List<String> ids(StoryShelf s) => [
            for (final p in s.picks)
              if (p.kind == PickKind.justRight) p.story.id,
          ];
      final first = ids(shelf(score: 50, stories: three)).first;
      final after = ids(shelf(score: 50, stories: three, recent: [first]));
      expect(after, contains(first)); // still on the shelf
      expect(after.last, first);
      // Only the last 3 sessions count.
      expect(ids(shelf(score: 50, stories: three, recent: ['A', 'B', 'C', first])).first, first);
    });

    test('random variety bonus is between 0 and 0.15', () {
      final a = shelf(random: FixedRandom(0)).picks.first;
      final b = shelf(random: FixedRandom(0.999)).picks.first;
      expect(b.score - a.score, closeTo(0.15 * 0.999, 1e-9));
    });

    test('explains the pick in one kid-friendly line, naming a specific sound', () {
      final s = shelf(score: 50);
      expect(s.focusPattern, isNotNull);
      expect(const {'EN-SW', 'EN-SV'}.contains(s.focusPattern), isFalse);
      expect(s.reason, "These stories have more '${kidPatternLabels[s.focusPattern]}' words");
    });

    test('weak-sound coverage: average of (1 − mastery) per word', () {
      final story = Story(
        id: 'X',
        title: 'X',
        language: 'EN',
        difficulty: 10,
        text: 'a b',
        words: words('a b', patterns: ['EN-SH']),
        questions: const [],
      );
      expect(StorySelector.weakSoundCoverage(story, SoundMastery(mastery: {'EN-SH': 0.2})),
          closeTo(0.8, 1e-9));
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
