import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

void main() {
  const ind = PhilIriLevel.independent;
  const ins = PhilIriLevel.instructional;
  const fru = PhilIriLevel.frustration;
  const flagger = TeacherFlagger();

  List<SessionSummary> levels(List<PhilIriLevel> ls) =>
      [for (final l in ls) SessionSummary(level: l)];

  group('§10 Teacher flag', () {
    test('flags when 2 of the last 3 sessions are Frustration', () {
      expect(
          flagger.shouldFlag(
              sessions: levels([ind, fru, ins, fru]), mastery: SoundMastery()),
          isTrue);
    });

    test('does not flag for only 1 Frustration in the last 3', () {
      expect(
          flagger.shouldFlag(
              sessions: levels([fru, fru, ins, ind, fru]),
              mastery: SoundMastery()),
          isFalse); // the old Frustrations are outside the window
    });

    test('flags a pattern still "Needs help" after 3 sessions practising it',
        () {
      final sessions = [
        for (var i = 0; i < 3; i++)
          const SessionSummary(level: ins, patternsPracticed: {'EN-SH'}),
      ];
      final weak = SoundMastery(mastery: {'EN-SH': 0.2});
      final reasons = flagger.reasons(sessions: sessions, mastery: weak);
      expect(reasons.single, contains('EN-SH'));
    });

    test('no pattern flag after only 2 sessions, or once it is Learning', () {
      const sh = SessionSummary(level: ins, patternsPracticed: {'EN-SH'});
      expect(
          flagger.shouldFlag(
              sessions: [sh, sh], mastery: SoundMastery(mastery: {'EN-SH': 0.2})),
          isFalse);
      expect(
          flagger.shouldFlag(
              sessions: [sh, sh, sh],
              mastery: SoundMastery(mastery: {'EN-SH': 0.6})),
          isFalse);
    });
  });
}
