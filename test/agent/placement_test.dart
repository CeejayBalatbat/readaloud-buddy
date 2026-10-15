import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

void main() {
  const ind = PhilIriLevel.independent;
  const ins = PhilIriLevel.instructional;
  const fru = PhilIriLevel.frustration;

  PlacementCheck place(List<PhilIriLevel> results) {
    final p = PlacementCheck();
    for (final r in results) {
      p.record(r);
    }
    return p;
  }

  group('§6 Placement check', () {
    test('passages go level 1 → 2 → 3', () {
      final p = PlacementCheck();
      expect(p.nextPassageLevel, 1);
      p.record(ind);
      expect(p.nextPassageLevel, 2);
      p.record(ins);
      expect(p.nextPassageLevel, 3);
      p.record(ins);
      expect(p.nextPassageLevel, isNull);
    });

    test('stops at the first Frustration', () {
      final p = place([ind, fru]);
      expect(p.isDone, isTrue);
      expect(() => p.record(ind), throwsStateError);
    });

    test('start level = highest level that was not Frustration', () {
      expect(place([ind, fru]).startLevel, 1);
      expect(place([ind, ins, fru]).startLevel, 2);
      expect(place([ins, ins, ins]).startLevel, 3);
    });

    test('Frustration on the first passage starts at level 1 (min 1)', () {
      expect(place([fru]).startLevel, 1);
    });

    test('tops out at level 3 even if level 3 is Independent', () {
      final p = place([ind, ind, ind]);
      expect(p.isDone, isTrue);
      expect(p.startLevel, 3);
    });
  });

  group('§5 Placement and level decisions', () {
    test('placement counts as the first result at the starting level', () {
      // Ends Independent at level 2 -> one more Independent moves up.
      final state = place([ind, ind, fru]).toLevelState();
      expect(state.level, 2);
      final (d, _) = state.apply(ind);
      expect(d.move, LevelMove.up);
      expect(d.levelAfter, 3);
    });

    test('an Instructional placement does not start a streak', () {
      final (d, _) = place([ind, ins, fru]).toLevelState().apply(ind);
      expect(d.move, LevelMove.stay);
    });

    test('the placement check itself never moves a child down', () {
      // The Frustration on passage 3 is not a result at level 2.
      final state = place([ind, ind, fru]).toLevelState();
      expect(state.level, 2);
      expect(state.resultsAtLevel, [ind]);
    });
  });
}
