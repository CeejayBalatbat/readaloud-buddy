import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/data/story.dart';

import 'fixtures.dart';

void main() {
  final stories = loadStories();
  Story byId(String id) => stories.firstWhere((s) => s.id == id);
  final predictor = AccuracyPredictor(patternDifficulty: loadPatternDifficulty());
  const bias = 1.6;

  StoryWord word(List<String> patterns) => words('w', patterns: patterns).single;

  group('§9 Prior mastery from the reading score', () {
    test('a sound not read yet is a coin flip at score = 100 × its difficulty', () {
      expect(predictor.prior('EN-TH', 40), closeTo(0.5, 1e-9)); // EN-TH is 0.40
      expect(predictor.prior('EN-TH', 60), greaterThan(0.8));
      expect(predictor.prior('EN-TH', 20), lessThan(0.2));
    });

    test('kept within 0.02–0.98', () {
      expect(predictor.prior('EN-SV', 100), 0.98);
      expect(predictor.prior('EN-OU', 0), 0.02);
    });

    test('once the child has read a sound, BKT mastery is used instead', () {
      final m = SoundMastery(mastery: {'EN-TH': 0.3}, observations: {'EN-TH': 4});
      expect(predictor.masteryOf('EN-TH', m, 90), 0.3);
      expect(predictor.masteryOf('EN-SH', m, 90), predictor.prior('EN-SH', 90));
    });
  });

  group('§9 Word and book predictions', () {
    final m = SoundMastery(
        mastery: {'EN-SV': 0.95, 'EN-TH': 0.2}, observations: {'EN-SV': 9, 'EN-TH': 9});
    double p(List<String> pats, {double score = 40, double b = bias, double d = 40}) =>
        predictor.wordProbability(word(pats), m, score: score, bias: b, difficulty: d);

    test('the weakest sound of a word decides', () {
      expect(p(['EN-SV', 'EN-TH']), p(['EN-TH']));
      expect(p(['EN-SV']), greaterThan(p(['EN-TH'])));
    });

    test('a known sound reads well; BKT chance is corrected by the bias', () {
      // m = 0.95: BKT says 0.95 × 0.92 + 0.05 × 0.2 = 0.884; σ(logit + 1.6) ≈ 0.974
      expect(p(['EN-SV']), closeTo(0.974, 0.001));
      expect(p(['EN-SV'], b: 0), closeTo(0.884, 0.001));
    });

    test('books harder than the reader come down, at most 4 steps of 0.5', () {
      expect(p(['EN-SV'], d: 70), lessThan(p(['EN-SV'], d: 40)));
      expect(p(['EN-SV'], d: 80, score: 40), p(['EN-SV'], d: 100, score: 40)); // capped at 40 points
      expect(p(['EN-SV'], d: 20), greaterThan(p(['EN-SV'], d: 40)));
    });

    test('the same reader: an easy book is predicted higher than a hard one', () {
      final fresh = SoundMastery();
      final easy = predictor.accuracy(byId('S03'), fresh, score: 40, bias: bias);
      final hard = predictor.accuracy(byId('S18'), fresh, score: 40, bias: bias);
      expect(easy, greaterThan(hard));
    });

    test('bands use the Phil-IRI word thresholds', () {
      expect(predictor.bandOf(0.97), PhilIriLevel.independent);
      expect(predictor.bandOf(0.93), PhilIriLevel.instructional);
      expect(predictor.bandOf(0.90), PhilIriLevel.instructional);
      expect(predictor.bandOf(0.899), PhilIriLevel.frustration);
    });

    test('books around the reader\'s score come out "just right"', () {
      final fresh = SoundMastery();
      final justRight = [
        for (final s in stories)
          if (s.language == 'EN' &&
              predictor.predict(s, fresh, score: 50, bias: bias).band == PhilIriLevel.instructional)
            s.difficulty,
      ];
      expect(justRight, isNotEmpty);
      for (final d in justRight) {
        expect((d - 50).abs(), lessThanOrEqualTo(25), reason: 'difficulty $d');
      }
    });
  });

  group('§9 Learning from the error', () {
    test('a guess that was too high brings the bias down, and vice versa', () {
      expect(predictor.updatedBias(1.6, predicted: 0.95, actual: 0.90), lessThan(1.6));
      expect(predictor.updatedBias(1.6, predicted: 0.90, actual: 0.95), greaterThan(1.6));
      expect(predictor.updatedBias(1.6, predicted: 0.93, actual: 0.93), closeTo(1.6, 1e-9));
    });

    test('bias += 0.3 × (logit(actual) − logit(predicted)), kept within −2…5', () {
      double logit(double p) => log(p / (1 - p));
      expect(predictor.updatedBias(1.6, predicted: 0.95, actual: 0.90),
          closeTo(1.6 + 0.3 * (logit(0.90) - logit(0.95)), 1e-9));
      expect(predictor.updatedBias(4.9, predicted: 0.5, actual: 1.0), 5);
      expect(predictor.updatedBias(-1.9, predicted: 0.99, actual: 0.0), -2);
    });

    test('a reader Buddy overestimates: the error shrinks story after story', () {
      final s = byId('S08');
      final m = SoundMastery();
      var b = bias;
      final errors = <double>[];
      for (var i = 0; i < 10; i++) {
        final predicted = predictor.accuracy(s, m, score: 45, bias: b);
        const actual = 0.85; // this child always reads it at 85%
        errors.add((predicted - actual).abs());
        b = predictor.updatedBias(b, predicted: predicted, actual: actual);
      }
      expect(errors.first, greaterThan(0.05));
      expect(errors.last, lessThan(0.01));
      for (var i = 1; i < errors.length; i++) {
        expect(errors[i], lessThan(errors[i - 1]));
      }
    });
  });
}
