import 'agent_config.dart';
import 'philiri.dart';

enum LevelMove { up, stay, down }

/// What Buddy decided after a story (AGENT_SPEC §5).
class LevelDecision {
  const LevelDecision({
    required this.move,
    required this.levelBefore,
    required this.levelAfter,
  });

  final LevelMove move;
  final int levelBefore;
  final int levelAfter;

  /// "Buddy's plan" for the Results screen, in kid-friendly words.
  String get buddyPlan => switch (move) {
        LevelMove.up =>
          "Wow! You're ready for Level $levelAfter stories. Let's go up!",
        LevelMove.down =>
          "Let's practise with Level $levelAfter stories for a bit. "
              "You'll be back up soon!",
        LevelMove.stay =>
          "Let's read more Level $levelAfter stories to get even stronger!",
      };
}

/// "Buddy's plan" for the Results screen (AGENT_SPEC §5): how the story
/// felt, what Buddy decided, and what would happen next, in kid words.
/// [next] is the state after [decision] was applied.
String buddyPlanFor({
  required PhilIriLevel result,
  required LevelDecision decision,
  required LevelState next,
  AgentConfig config = const AgentConfig(),
}) {
  final level = decision.levelAfter;
  switch (decision.move) {
    case LevelMove.up:
      return "That was easy for you! You're moving up to Level $level. Hooray!";
    case LevelMove.down:
      return "That one was a bit hard. Let's read Level $level stories for a "
          "while. You'll be back up soon!";
    case LevelMove.stay:
      final feel = switch (result) {
        PhilIriLevel.independent => 'This story was easy for you.',
        PhilIriLevel.instructional => 'This story was just right.',
        PhilIriLevel.frustration => 'This story was a bit tricky.',
      };
      final easyInARow = next.resultsAtLevel.reversed
          .takeWhile((r) => r == PhilIriLevel.independent)
          .length;
      final toGo = config.framesToMoveUp - easyInARow;
      if (level < config.maxLevel && easyInARow > 0 && toGo > 0) {
        return toGo == 1
            ? '$feel Read one more story this well and you\'ll move up to '
                'Level ${level + 1}!'
            : '$feel Read $toGo more stories this well and you\'ll move up '
                'to Level ${level + 1}!';
      }
      return switch (result) {
        PhilIriLevel.frustration =>
          "$feel Let's keep practising Level $level stories together.",
        _ => "$feel Keep reading Level $level stories to get even stronger!",
      };
  }
}

/// A learner's level plus the results that count toward the next move:
/// only results since the last level change (streaks reset on a change).
class LevelState {
  const LevelState({required this.level, this.resultsAtLevel = const []});

  final int level;
  final List<PhilIriLevel> resultsAtLevel;

  /// Applies one story result and returns the decision plus the new state.
  (LevelDecision, LevelState) apply(
    PhilIriLevel result, [
    AgentConfig config = const AgentConfig(),
  ]) {
    final results = [...resultsAtLevel, result];

    var move = LevelMove.stay;
    if (_endsWith(results, PhilIriLevel.independent, config.framesToMoveUp) &&
        level < config.maxLevel) {
      move = LevelMove.up;
    } else if (_endsWith(
            results, PhilIriLevel.frustration, config.framesToMoveDown) &&
        level > config.minLevel) {
      move = LevelMove.down;
    }

    final newLevel = switch (move) {
      LevelMove.up => level + 1,
      LevelMove.down => level - 1,
      LevelMove.stay => level,
    };
    final decision =
        LevelDecision(move: move, levelBefore: level, levelAfter: newLevel);
    final next = move == LevelMove.stay
        ? LevelState(level: level, resultsAtLevel: results)
        : LevelState(level: newLevel); // streaks reset on a level change
    return (decision, next);
  }

  static bool _endsWith(List<PhilIriLevel> results, PhilIriLevel r, int n) =>
      results.length >= n &&
      results.sublist(results.length - n).every((x) => x == r);
}
