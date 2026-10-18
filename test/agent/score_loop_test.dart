import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

import 'fixtures.dart';

/// The whole loop (AGENT_SPEC §5, §7, §9) with a pretend child: Buddy
/// recommends a book, the child reads it as well as their true ability
/// allows, and Buddy updates mastery, the reading score and its prediction
/// correction. The score should settle near the child's true ability and
/// the predictions should get close to what really happens.
void main() {
  final stories = loadStories().where((s) => s.language == 'EN').toList();
  final predictor = AccuracyPredictor(patternDifficulty: loadPatternDifficulty());
  const scorer = ReadingScorer();

  /// The pretend child reads a book of difficulty [d] with this accuracy.
  double trueAccuracy(double ability, double d) => (0.935 + 0.004 * (ability - d)).clamp(0.5, 1.0);

  ({double score, List<double> errors}) run({
    required double ability,
    required double startScore,
    int stories_ = 30,
    int seed = 7,
  }) {
    final rnd = Random(seed);
    final mastery = SoundMastery();
    var score = startScore, bias = const AgentConfig().predictionBiasStart;
    final best = <String, double>{};
    final errors = <double>[];
    for (var i = 0; i < stories_; i++) {
      final shelf = StorySelector(random: rnd).select(
        stories: stories,
        languages: ['EN'],
        mastery: mastery,
        score: score,
        bias: bias,
        predictor: predictor,
        bestPastAccuracy: best,
      );
      final book = shelf.picks.first.story;
      final predicted = predictor.accuracy(book, mastery, score: score, bias: bias);
      final p = trueAccuracy(ability, book.difficulty);
      final outcomes = [
        for (final w in book.words)
          WordOutcome(
            position: w.position,
            word: w.word,
            patterns: w.patterns,
            primaryPattern: w.primaryPattern,
            result: rnd.nextDouble() < p ? WordResult.correct : WordResult.misread,
          ),
      ];
      final actual = outcomes.where((o) => o.result.countsAsCorrect).length / outcomes.length;
      errors.add((predicted - actual).abs());
      mastery.recordWords(outcomes);
      final e = scorer.evidence(
        difficulty: book.difficulty,
        accuracy: actual,
        wcpm: scorer.expectedWcpm(book.difficulty),
        comprehension: actual >= 0.9 ? 2 / 3 : 1 / 3,
        bookMastery: ReadingScorer.bookMastery(book, mastery),
      );
      score = scorer.update(score, e).after;
      bias = predictor.updatedBias(bias, predicted: predicted, actual: actual);
      best[book.id] = max(best[book.id] ?? 0, actual);
    }
    return (score: score, errors: errors);
  }

  double mean(Iterable<double> v) => v.reduce((a, b) => a + b) / v.length;

  // Children of different true ability, starting from a reading-check score
  // that was too low, too high or right; 8 different random runs each.
  const children = [(55.0, 10.0), (30.0, 70.0), (70.0, 40.0), (45.0, 45.0), (85.0, 60.0), (15.0, 30.0)];
  for (final (ability, start) in children) {
    test('true ability $ability, starting at $start: the score settles near it', () {
      final early = <double>[], late = <double>[];
      for (var seed = 1; seed <= 8; seed++) {
        final r = run(ability: ability, startScore: start, seed: seed);
        expect((r.score - ability).abs(), lessThan(15), reason: 'seed $seed: score ${r.score}');
        early.add(mean(r.errors.take(5)));
        late.add(mean(r.errors.skip(20)));
        // Within about 9 points once Buddy has learned (short easy books
        // make single readings noisy).
        expect(late.last, lessThan(0.09), reason: 'seed $seed: errors ${r.errors}');
      }
      // On average, later predictions are closer than the first ones.
      expect(mean(late), lessThan(mean(early)));
    });
  }
}
