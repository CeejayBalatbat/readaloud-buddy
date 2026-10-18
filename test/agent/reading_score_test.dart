import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/data/story.dart';

import 'fixtures.dart';

void main() {
  const scorer = ReadingScorer();

  group('§5 Reading profiles (CRLA) and ranks', () {
    test('cut-offs are lower bounds: 20, 40, 60, 80', () {
      final cases = {
        0.0: ReadingProfile.lowEmerging,
        19.9: ReadingProfile.lowEmerging,
        20.0: ReadingProfile.highEmerging,
        39.9: ReadingProfile.highEmerging,
        40.0: ReadingProfile.developing,
        59.9: ReadingProfile.developing,
        60.0: ReadingProfile.transitioning,
        79.9: ReadingProfile.transitioning,
        80.0: ReadingProfile.gradeLevel,
        100.0: ReadingProfile.gradeLevel,
      };
      cases.forEach((score, profile) => expect(scorer.profileOf(score), profile, reason: '$score'));
    });

    test('grown-ups see the CRLA label, children a rank', () {
      expect([for (final p in ReadingProfile.values) p.label], [
        'Low Emerging',
        'High Emerging',
        'Developing',
        'Transitioning',
        'Reading at Grade Level',
      ]);
      expect([for (final p in ReadingProfile.values) p.rank],
          ['🌱 Seed', '🌿 Sprout', '🍃 Leaf', '🌳 Tree', '⭐ Super Reader']);
    });

    test('cut-offs come from the config', () {
      const s = ReadingScorer(AgentConfig(developingMin: 45));
      expect(s.profileOf(44), ReadingProfile.highEmerging);
      expect(s.profileOf(45), ReadingProfile.developing);
    });

    test('progress through a profile toward the next', () {
      expect(scorer.progressInProfile(40), 0);
      expect(scorer.progressInProfile(50), closeTo(0.5, 1e-9));
      expect(scorer.progressInProfile(95), 1); // top profile
    });
  });

  group('§5 Evidence from one reading', () {
    ScoreEvidence ev({
      double d = 40,
      double acc = 0.935,
      double? wcpm,
      double? comp = 0.66,
      double? mastery = 0.6,
    }) =>
        scorer.evidence(
          difficulty: d,
          accuracy: acc,
          wcpm: wcpm ?? scorer.expectedWcpm(d),
          comprehension: comp,
          bookMastery: mastery,
        );

    test('a reading right on target says "the book\'s difficulty"', () {
      expect(ev().value, closeTo(40, 1e-9));
    });

    test('accuracy: 250 × (accuracy − 93.5%)', () {
      expect(ev(acc: 0.97).accuracyPart, closeTo(8.75, 1e-9));
      expect(ev(acc: 0.90).accuracyPart, closeTo(-8.75, 1e-9));
    });

    test('comprehension: 15 × (comprehension − 0.66)', () {
      expect(ev(comp: 1).comprehensionPart, closeTo(5.1, 1e-9));
      expect(ev(comp: 1 / 3).comprehensionPart, closeTo(-4.9, 1e-9));
    });

    test('fluency: words per minute vs expected (20 + 0.9 × D), −4 … +4', () {
      expect(scorer.expectedWcpm(0), 20);
      expect(scorer.expectedWcpm(100), 110);
      expect(ev(wcpm: 2 * scorer.expectedWcpm(40)).fluencyPart, closeTo(4, 1e-9));
      expect(ev(wcpm: 0).fluencyPart, closeTo(-4, 1e-9));
    });

    test('mastery: 10 × (book mastery − 0.6)', () {
      expect(ev(mastery: 1).masteryPart, closeTo(4, 1e-9));
      expect(ev(mastery: 0.35).masteryPart, closeTo(-2.5, 1e-9));
    });

    test('kept within the book difficulty ± 30 and within 0–100', () {
      expect(ev(acc: 0.5).value, 10); // 40 − 30
      expect(ev(d: 10, acc: 0.5).value, 0);
      expect(ev(d: 90, acc: 1, comp: 1, mastery: 1, wcpm: 500).value, 100);
    });

    test('book mastery: the weakest pattern of each word, averaged', () {
      final story = Story(
        id: 'X',
        title: 'X',
        language: 'EN',
        difficulty: 10,
        text: 'the cat',
        words: [
          ...words('the', patterns: ['EN-SW', 'EN-TH']),
          ...words('cat', patterns: ['EN-SV']),
        ],
        questions: const [],
      );
      final m = SoundMastery(mastery: {'EN-SW': 0.9, 'EN-TH': 0.3, 'EN-SV': 0.8});
      expect(ReadingScorer.bookMastery(story, m), closeTo((0.3 + 0.8) / 2, 1e-9));
    });
  });

  group('§5 Score update', () {
    ScoreEvidence at(double value) => ScoreEvidence(
        difficulty: value, accuracyPart: 0, fluencyPart: 0, value: value);

    test('moves 35% of the way to the evidence', () {
      final u = scorer.update(30, at(40));
      expect(u.after, closeTo(33.5, 1e-9));
      expect(u.change, closeTo(3.5, 1e-9));
    });

    test('never more than 12 points at once', () {
      expect(scorer.update(30, at(100)).after, 42);
      expect(scorer.update(60, at(0)).after, 48);
    });

    test('a strong reading moves a child up a profile; a weak one down', () {
      final up = scorer.update(38, scorer.evidence(
          difficulty: 40, accuracy: 0.99, wcpm: 80, comprehension: 1, bookMastery: 0.9));
      expect(scorer.profileOf(up.after), ReadingProfile.developing);
      final down = scorer.update(42, scorer.evidence(
          difficulty: 40, accuracy: 0.80, wcpm: 30, comprehension: 1 / 3, bookMastery: 0.4));
      expect(scorer.profileOf(down.after), ReadingProfile.highEmerging);
    });
  });

  group("§5 Buddy's plan (kid words)", () {
    ScoreUpdate u(double before, double after) => ScoreUpdate(
        before: before,
        after: after,
        evidence: const ScoreEvidence(difficulty: 0, accuracyPart: 0, fluencyPart: 0, value: 0));

    test('a new higher rank is celebrated', () {
      expect(scorer.buddyPlan(u(38, 41), PhilIriLevel.independent),
          'Wow! You grew into a 🍃 Leaf reader! Hooray!');
      expect(scorer.buddyPlan(u(78, 81), PhilIriLevel.independent),
          "Wow! You're a ⭐ Super Reader now! Hooray!");
    });

    test('a lower rank is never announced', () {
      final plan = scorer.buddyPlan(u(41, 37), PhilIriLevel.frustration);
      expect(plan, contains('easier stories'));
      for (final p in ReadingProfile.values) {
        expect(plan, isNot(contains(p.rankName)));
      }
    });

    test('same rank: how it felt, and growing toward the next rank', () {
      expect(scorer.buddyPlan(u(30, 33), PhilIriLevel.instructional),
          "This story was just right. You're growing toward 🍃 Leaf!");
      expect(scorer.buddyPlan(u(30, 29), PhilIriLevel.frustration),
          "This story was a bit tricky. Let's keep practising together.");
      expect(scorer.buddyPlan(u(85, 88), PhilIriLevel.independent),
          "This story was easy for you. You're a ⭐ Super Reader! Keep reading to stay super!");
    });

    test('never shows the child a number or a CRLA label', () {
      for (final (a, b) in [(10.0, 25.0), (30.0, 31.0), (50.0, 45.0), (85.0, 90.0)]) {
        for (final r in PhilIriLevel.values) {
          final plan = scorer.buddyPlan(u(a, b), r);
          expect(plan, isNot(matches(RegExp(r'\d'))), reason: plan);
          for (final p in ReadingProfile.values) {
            expect(plan, isNot(contains(p.label)), reason: plan);
          }
        }
      }
    });
  });
}
