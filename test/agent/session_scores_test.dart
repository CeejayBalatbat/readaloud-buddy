import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

import 'fixtures.dart';

void main() {
  group('§3 Session scores', () {
    test('formulas: accuracy, WCPM and comprehension', () {
      final outcomes = [
        outcome('a', WordResult.correct),
        outcome('b', WordResult.correct),
        outcome('c', WordResult.hesitated),
        outcome('d', WordResult.misread),
        outcome('e', WordResult.correctAfterHint, hintLevel: 2),
        outcome('f', WordResult.skipped),
        outcome('g', WordResult.unsure),
      ];
      final sc = SessionScores.fromResults(outcomes,
          readingSeconds: 30, questionsCorrect: 2);
      expect(sc.wordsTotal, 6); // unsure excluded
      expect(sc.wordsCorrect, 3); // correct + hesitated
      expect(sc.accuracy, closeTo(0.5, 1e-12));
      expect(sc.wcpm, closeTo(6.0, 1e-12)); // 3 words / 0.5 min
      expect(sc.comprehension, closeTo(2 / 3, 1e-12));
      expect((sc.hesitations, sc.miscues, sc.skips, sc.unsureWords),
          (1, 2, 1, 1));
      expect(sc.hintsGiven, 1);
    });

    test('no words or no time gives 0, not a crash', () {
      final sc = SessionScores.fromResults(const [],
          readingSeconds: 0, questionsCorrect: 0);
      expect((sc.accuracy, sc.wcpm), (0, 0));
    });

    test('matches every session in Sessions.csv when built from Word_Events.csv',
        () {
      final events = <String, List<WordOutcome>>{};
      for (final e in readCsv('Word_Events.csv')) {
        events.putIfAbsent(e['session_id']!, () => []).add(outcome(
              e['word']!,
              resultFromCsv(e['result']!),
              hintLevel: int.parse(e['hint_level']!),
            ));
      }
      final sessions = readCsv('Sessions.csv');
      expect(sessions, hasLength(550));
      for (final r in sessions) {
        final id = r['session_id']!;
        final sc = SessionScores.fromResults(events[id]!,
            readingSeconds: double.parse(r['reading_seconds']!),
            questionsCorrect: int.parse(r['questions_correct']!),
            questionsTotal: int.parse(r['questions_total']!));
        expect(sc.wordsTotal, int.parse(r['words_total']!), reason: id);
        expect(sc.wordsCorrect, int.parse(r['words_correct']!), reason: id);
        expect(sc.hesitations, int.parse(r['hesitations']!), reason: id);
        expect(sc.miscues, int.parse(r['miscues']!), reason: id);
        expect(sc.skips, int.parse(r['skips']!), reason: id);
        expect(sc.unsureWords, int.parse(r['asr_unsure_words']!), reason: id);
        expect(sc.accuracy, closeTo(double.parse(r['word_accuracy']!), 1e-9),
            reason: id);
        expect(sc.comprehension,
            closeTo(double.parse(r['comprehension']!), 1e-9),
            reason: id);
        // The CSV rounds WCPM to 1 decimal.
        expect(sc.wcpm, closeTo(double.parse(r['wcpm']!), 0.051), reason: id);
      }
    });
  });
}
