import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

import 'fixtures.dart';

void main() {
  const c = PhilIriClassifier();
  const ind = PhilIriLevel.independent;
  const ins = PhilIriLevel.instructional;
  const fru = PhilIriLevel.frustration;

  group('§4 Phil-IRI classification', () {
    test('word accuracy thresholds have no gaps (97% / 90%)', () {
      expect(c.wordLevel(1.0), ind);
      expect(c.wordLevel(0.97), ind);
      expect(c.wordLevel(0.9699), ins);
      expect(c.wordLevel(0.90), ins);
      expect(c.wordLevel(27 / 30), ins); // exactly 90% from real counts
      expect(c.wordLevel(0.8999), fru);
    });

    test('comprehension thresholds have no gaps (80% / 59%)', () {
      expect(c.comprehensionLevel(1.0), ind);
      expect(c.comprehensionLevel(0.80), ind);
      expect(c.comprehensionLevel(0.7999), ins);
      expect(c.comprehensionLevel(2 / 3), ins);
      expect(c.comprehensionLevel(0.59), ins);
      expect(c.comprehensionLevel(0.5899), fru);
      expect(c.comprehensionLevel(1 / 3), fru);
    });

    test('overall: Frustration if either is, Independent only if both', () {
      PhilIriLevel o(double a, double q) =>
          c.classify(accuracy: a, comprehension: q).overall;
      expect(o(1.0, 1.0), ind);
      expect(o(1.0, 2 / 3), ins);
      expect(o(0.92, 1.0), ins);
      expect(o(0.92, 2 / 3), ins);
      expect(o(1.0, 1 / 3), fru);
      expect(o(0.85, 1.0), fru);
    });

    test('matches every row of Sessions.csv exactly', () {
      final rows = readCsv('Sessions.csv');
      expect(rows, hasLength(550));
      for (final r in rows) {
        final res = c.classify(
          accuracy:
              int.parse(r['words_correct']!) / int.parse(r['words_total']!),
          comprehension: int.parse(r['questions_correct']!) /
              int.parse(r['questions_total']!),
        );
        final id = r['session_id'];
        expect(res.word.label, r['word_level'], reason: '$id word');
        expect(res.comprehension.label, r['comprehension_level'],
            reason: '$id comprehension');
        expect(res.overall.label, r['philiri_level'], reason: '$id overall');
      }
    });
  });
}
