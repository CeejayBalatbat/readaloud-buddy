import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

import 'fixtures.dart';

void main() {
  group('§7 Sound mastery (BKT)', () {
    test('a correct read from p0 = 0.35 gives 0.7469 (hand-calculated)', () {
      // post = .35*.92 / (.35*.92 + .65*.20) = .712389
      // new  = .712389 + (1 - .712389) * .12 = .746903
      expect(SoundMastery.bktUpdate(0.35, correct: true),
          closeTo(0.746903, 1e-6));
    });

    test('a wrong read from p0 = 0.35 gives 0.1650 (hand-calculated)', () {
      // post = .35*.08 / (.35*.08 + .65*.80) = .051095
      // new  = .051095 + (1 - .051095) * .12 = .164964
      expect(SoundMastery.bktUpdate(0.35, correct: false),
          closeTo(0.164964, 1e-6));
    });

    test('unseen patterns start at p0', () {
      expect(SoundMastery().of('EN-SH'), 0.35);
    });

    test('every pattern of a scored word is updated', () {
      final m = SoundMastery()
        ..recordWords([
          outcome('The', WordResult.correct, patterns: ['EN-SW', 'EN-TH']),
        ]);
      expect(m.of('EN-SW'), closeTo(0.746903, 1e-6));
      expect(m.of('EN-TH'), closeTo(0.746903, 1e-6));
      expect(m.observationsOf('EN-TH'), 1);
    });

    test('hesitated counts as correct; correctAfterHint/misread/skipped do not',
        () {
      for (final (r, up) in [
        (WordResult.hesitated, true),
        (WordResult.correctAfterHint, false),
        (WordResult.misread, false),
        (WordResult.skipped, false),
      ]) {
        final m = SoundMastery()..recordWords([outcome('x', r)]);
        expect(m.of('EN-SV') > 0.35, up, reason: r.name);
      }
    });

    test('unsure words are not used', () {
      final m = SoundMastery()..recordWords([outcome('x', WordResult.unsure)]);
      expect(m.of('EN-SV'), 0.35);
      expect(m.observationsOf('EN-SV'), 0);
    });

    test('status: Mastered ≥ 0.85, Learning 0.50–0.84, Needs help < 0.50', () {
      expect(SoundMastery.statusFor(0.85), MasteryStatus.mastered);
      expect(SoundMastery.statusFor(0.8499), MasteryStatus.learning);
      expect(SoundMastery.statusFor(0.50), MasteryStatus.learning);
      expect(SoundMastery.statusFor(0.4999), MasteryStatus.needsHelp);
    });

    test('repeated correct reads reach Mastered', () {
      final m = SoundMastery();
      for (var i = 0; i < 3; i++) {
        m.observe('EN-SH', correct: true);
      }
      expect(m.statusOf('EN-SH'), MasteryStatus.mastered);
    });
  });
}
