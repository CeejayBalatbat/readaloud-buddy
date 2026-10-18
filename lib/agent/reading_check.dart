import '../data/story.dart';
import 'agent_config.dart';
import 'philiri.dart';
import 'reading_score.dart';

/// One finished reading-check passage.
class CheckPassage {
  const CheckPassage({required this.story, required this.wordLevel, required this.evidence});

  final Story story;
  final PhilIriLevel wordLevel;

  /// What the passage says about the child (§5 without questions or mastery).
  final ScoreEvidence evidence;
}

/// The reading check (AGENT_SPEC §6): up to 3 passages from books closest
/// to the target difficulties, stopping at the first Frustration. It sets
/// the starting reading score.
class ReadingCheck {
  ReadingCheck({required List<Story> stories, required this.language, this.config = const AgentConfig()})
      : _stories = [for (final s in stories) if (s.language == language) s];

  final String language;
  final AgentConfig config;
  final List<Story> _stories;
  final List<CheckPassage> passages = [];

  bool get isDone =>
      (passages.isNotEmpty && passages.last.wordLevel == PhilIriLevel.frustration) ||
      passages.length >= config.readingCheckTargets.length ||
      nextStory == null;

  /// Number of passages in a full check (for "1 of 3").
  int get total => config.readingCheckTargets.length;

  /// The book whose opening is read next: difficulty closest to the next
  /// target, not used yet (ties: the easier book). Null when done.
  Story? get nextStory {
    if (passages.length >= config.readingCheckTargets.length) return null;
    if (passages.isNotEmpty && passages.last.wordLevel == PhilIriLevel.frustration) return null;
    final target = config.readingCheckTargets[passages.length];
    final used = {for (final p in passages) p.story.id};
    Story? best;
    for (final s in _stories) {
      if (used.contains(s.id)) continue;
      if (best == null) {
        best = s;
        continue;
      }
      final d = (s.difficulty - target).abs(), b = (best.difficulty - target).abs();
      if (d < b || (d == b && s.difficulty < best.difficulty)) best = s;
    }
    return best;
  }

  /// Records a finished passage of [story] (accuracy from §3, no questions).
  CheckPassage record(Story story, {required double accuracy, required double wcpm}) {
    if (isDone) throw StateError('The reading check is already finished');
    final passage = CheckPassage(
      story: story,
      wordLevel: PhilIriClassifier(config).wordLevel(accuracy),
      evidence: ReadingScorer(config).evidence(
        difficulty: story.difficulty,
        accuracy: accuracy,
        wcpm: wcpm,
      ),
    );
    passages.add(passage);
    return passage;
  }

  /// The starting score: the last passage that was not Frustration and the
  /// Frustration passage averaged; just one of them if only one exists; the
  /// default if no passage was finished.
  double get startScore {
    final ok = passages.where((p) => p.wordLevel != PhilIriLevel.frustration).lastOrNull;
    final hard = passages.where((p) => p.wordLevel == PhilIriLevel.frustration).firstOrNull;
    if (ok != null && hard != null) return (ok.evidence.value + hard.evidence.value) / 2;
    return (ok ?? hard)?.evidence.value ?? config.startScoreDefault;
  }
}
