import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

void main() {
  const ind = PhilIriLevel.independent;
  const ins = PhilIriLevel.instructional;
  const fru = PhilIriLevel.frustration;

  /// Runs results through the rules and returns each decision's move.
  List<LevelMove> run(LevelState start, List<PhilIriLevel> results,
      [AgentConfig cfg = const AgentConfig()]) {
    var state = start;
    final moves = <LevelMove>[];
    for (final r in results) {
      final (d, next) = state.apply(r, cfg);
      moves.add(d.move);
      state = next;
    }
    return moves;
  }

  group('§5 Level decisions', () {
    test('2 Independent results in a row move up one level', () {
      const st = LevelState(level: 2);
      final (d1, s1) = st.apply(ind);
      expect(d1.move, LevelMove.stay);
      final (d2, s2) = s1.apply(ind);
      expect(d2.move, LevelMove.up);
      expect(s2.level, 3);
    });

    test('Independent results must be in a row', () {
      expect(run(const LevelState(level: 2), [ind, ins, ind]),
          [LevelMove.stay, LevelMove.stay, LevelMove.stay]);
    });

    test('never above level 4', () {
      final (d, s) = const LevelState(level: 4, resultsAtLevel: [ind]).apply(ind);
      expect(d.move, LevelMove.stay);
      expect(s.level, 4);
    });

    test('1 Frustration moves down one level (default framesToMoveDown = 1)',
        () {
      final (d, s) = const LevelState(level: 3).apply(fru);
      expect(d.move, LevelMove.down);
      expect((d.levelBefore, d.levelAfter, s.level), (3, 2, 2));
    });

    test('never below level 1', () {
      final (d, s) = const LevelState(level: 1).apply(fru);
      expect(d.move, LevelMove.stay);
      expect(s.level, 1);
    });

    test('framesToMoveDown = 2 needs 2 Frustrations in a row', () {
      const cfg = AgentConfig(framesToMoveDown: 2);
      expect(run(const LevelState(level: 3), [fru, ins, fru, fru], cfg),
          [LevelMove.stay, LevelMove.stay, LevelMove.stay, LevelMove.down]);
    });

    test('otherwise stay', () {
      expect(run(const LevelState(level: 2), [ins, ins, ind, ins]),
          everyElement(LevelMove.stay));
    });

    test('streaks reset when the level changes (up)', () {
      // ind, ind -> up to 3. One more ind at level 3 must NOT move up again.
      expect(run(const LevelState(level: 2), [ind, ind, ind, ind]),
          [LevelMove.stay, LevelMove.up, LevelMove.stay, LevelMove.up]);
    });

    test('streaks reset when the level changes (down)', () {
      const cfg = AgentConfig(framesToMoveDown: 2);
      // fru, fru -> down to 2; one more fru at level 2 must not move down.
      expect(run(const LevelState(level: 3), [fru, fru, fru], cfg),
          [LevelMove.stay, LevelMove.down, LevelMove.stay]);
    });

    test("Buddy's plan says how it felt, the decision, and what's next", () {
      String plan(LevelState start, PhilIriLevel r,
          [AgentConfig cfg = const AgentConfig()]) {
        final (d, next) = start.apply(r, cfg);
        return buddyPlanFor(result: r, decision: d, next: next, config: cfg);
      }

      expect(plan(const LevelState(level: 2), ind),
          "This story was easy for you. Read one more story this well and "
          "you'll move up to Level 3!");
      expect(plan(const LevelState(level: 2, resultsAtLevel: [ind]), ind),
          contains('moving up to Level 3'));
      expect(plan(const LevelState(level: 2), ins),
          'This story was just right. Keep reading Level 2 stories to get '
          'even stronger!');
      expect(plan(const LevelState(level: 2), fru), contains('Level 1'));
      expect(plan(const LevelState(level: 1), fru),
          contains("Let's keep practising Level 1"));
      // At the top level there is nothing to move up to.
      expect(plan(const LevelState(level: 4), ind),
          isNot(contains('move up')));
      // With framesToMoveDown = 2, one Frustration only stays.
      expect(plan(const LevelState(level: 3), fru,
              const AgentConfig(framesToMoveDown: 2)),
          contains('a bit tricky'));
    });

    test("Buddy's plan has kid-friendly words for each decision", () {
      final (up, _) = const LevelState(level: 1, resultsAtLevel: [ind]).apply(ind);
      expect(up.buddyPlan, contains('Level 2'));
      final (down, _) = const LevelState(level: 2).apply(fru);
      expect(down.buddyPlan, contains('Level 1'));
      final (stay, _) = const LevelState(level: 2).apply(ins);
      expect(stay.buddyPlan, contains('Level 2'));
    });
  });
}
