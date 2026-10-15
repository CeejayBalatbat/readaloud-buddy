import 'agent_config.dart';
import 'level_decision.dart';
import 'philiri.dart';

/// Placement check (AGENT_SPEC §6): up to 3 passages, levels 1 → 3,
/// stopping at the first Frustration.
class PlacementCheck {
  PlacementCheck([this.config = const AgentConfig()]);

  final AgentConfig config;

  /// Result for level 1, 2, 3 in order.
  final List<PhilIriLevel> results = [];

  bool get isDone =>
      (results.isNotEmpty && results.last == PhilIriLevel.frustration) ||
      results.length >= config.placementMaxLevel;

  /// Level of the next passage to read, or null when done.
  int? get nextPassageLevel => isDone ? null : results.length + 1;

  void record(PhilIriLevel result) {
    if (isDone) throw StateError('Placement check is already finished');
    results.add(result);
  }

  /// Highest level that was not Frustration (min 1, max 3).
  int get startLevel {
    var level = config.minLevel;
    for (var i = 0; i < results.length; i++) {
      if (results[i] != PhilIriLevel.frustration) level = i + 1;
    }
    return level;
  }

  /// The learner's starting [LevelState]. The placement result at the start
  /// level counts as the first result there, so one more Independent story
  /// after an Independent placement moves the child up. Placement never
  /// moves a child down: this only seeds the state, it makes no decision.
  LevelState toLevelState() {
    if (!isDone) throw StateError('Placement check is not finished');
    final level = startLevel;
    return LevelState(level: level, resultsAtLevel: [results[level - 1]]);
  }
}
