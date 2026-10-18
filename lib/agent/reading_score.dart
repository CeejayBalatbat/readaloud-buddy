import 'dart:math';

import '../data/story.dart';
import 'agent_config.dart';
import 'mastery.dart';
import 'philiri.dart';

/// DepEd CRLA-style reading profiles on the 0–100 reading score
/// (AGENT_SPEC §5). Grown-ups see [label]; children only see [rank].
enum ReadingProfile {
  lowEmerging('Low Emerging', 'Seed', '🌱'),
  highEmerging('High Emerging', 'Sprout', '🌿'),
  developing('Developing', 'Leaf', '🍃'),
  transitioning('Transitioning', 'Tree', '🌳'),
  gradeLevel('Reading at Grade Level', 'Super Reader', '⭐');

  const ReadingProfile(this.label, this.rankName, this.emoji);

  /// The CRLA profile, for teachers and parents.
  final String label;

  /// The child's friendly rank, e.g. "Sprout".
  final String rankName;
  final String emoji;

  /// "🌿 Sprout", for the child.
  String get rank => '$emoji $rankName';

  ReadingProfile? get next => index + 1 < values.length ? values[index + 1] : null;
}

/// What one reading says about the child: the book's difficulty nudged by
/// each part (AGENT_SPEC §5). Parts are null when they don't apply (the
/// reading check has no questions and no mastery part).
class ScoreEvidence {
  const ScoreEvidence({
    required this.difficulty,
    required this.accuracyPart,
    required this.fluencyPart,
    this.comprehensionPart,
    this.masteryPart,
    required this.value,
  });

  final double difficulty;
  final double accuracyPart;
  final double fluencyPart;
  final double? comprehensionPart;
  final double? masteryPart;

  /// The evidence itself, 0–100.
  final double value;
}

/// The reading score before and after one story.
class ScoreUpdate {
  const ScoreUpdate({required this.before, required this.after, required this.evidence});

  final double before;
  final double after;
  final ScoreEvidence evidence;

  double get change => after - before;
}

/// The reading score rules (AGENT_SPEC §5). Pure Dart.
class ReadingScorer {
  const ReadingScorer([this.config = const AgentConfig()]);

  final AgentConfig config;

  ReadingProfile profileOf(double score) {
    if (score >= config.gradeLevelMin) return ReadingProfile.gradeLevel;
    if (score >= config.transitioningMin) return ReadingProfile.transitioning;
    if (score >= config.developingMin) return ReadingProfile.developing;
    if (score >= config.highEmergingMin) return ReadingProfile.highEmerging;
    return ReadingProfile.lowEmerging;
  }

  /// The lowest score of [profile].
  double minScoreOf(ReadingProfile profile) => switch (profile) {
        ReadingProfile.lowEmerging => 0,
        ReadingProfile.highEmerging => config.highEmergingMin,
        ReadingProfile.developing => config.developingMin,
        ReadingProfile.transitioning => config.transitioningMin,
        ReadingProfile.gradeLevel => config.gradeLevelMin,
      };

  /// 0–1: how far [score] is through its profile toward the next one (1 at
  /// the top profile).
  double progressInProfile(double score) {
    final p = profileOf(score);
    final next = p.next;
    if (next == null) return 1;
    final lo = minScoreOf(p), hi = minScoreOf(next);
    return ((score - lo) / (hi - lo)).clamp(0.0, 1.0);
  }

  /// Words correct per minute expected of a reader at difficulty [d].
  double expectedWcpm(double d) => config.wcpmAtZero + config.wcpmPerPoint * d;

  /// Average over the book's words of the word's weakest pattern mastery.
  static double bookMastery(Story story, SoundMastery mastery) {
    final ws = story.words.where((w) => w.patterns.isNotEmpty).toList();
    if (ws.isEmpty) return mastery.config.bktP0;
    return ws.map((w) => w.patterns.map(mastery.of).reduce(min)).reduce((a, b) => a + b) /
        ws.length;
  }

  /// What a reading of a book with difficulty [difficulty] says about the
  /// child. Leave [comprehension] and [bookMastery] null for a reading-check
  /// passage (§6).
  ScoreEvidence evidence({
    required double difficulty,
    required double accuracy,
    required double wcpm,
    double? comprehension,
    double? bookMastery,
  }) {
    final c = config;
    final accuracyPart = c.accuracyWeight * (accuracy - c.targetAccuracy);
    final ratio = (wcpm / expectedWcpm(difficulty)).clamp(c.fluencyRatioMin, c.fluencyRatioMax);
    final fluencyPart = c.fluencyWeight * (ratio - 1);
    final comprehensionPart = comprehension == null
        ? null
        : c.comprehensionWeight * (comprehension - c.targetComprehension);
    final masteryPart =
        bookMastery == null ? null : c.masteryWeight * (bookMastery - c.targetMastery);
    final raw = difficulty + accuracyPart + fluencyPart + (comprehensionPart ?? 0) + (masteryPart ?? 0);
    final value = raw
        .clamp(difficulty - c.evidenceMaxGap, difficulty + c.evidenceMaxGap)
        .clamp(0.0, 100.0)
        .toDouble();
    return ScoreEvidence(
      difficulty: difficulty,
      accuracyPart: accuracyPart,
      fluencyPart: fluencyPart,
      comprehensionPart: comprehensionPart,
      masteryPart: masteryPart,
      value: value,
    );
  }

  /// The new score after a story: [scoreLearningRate] of the way to the
  /// evidence, at most [maxScoreStep] points.
  ScoreUpdate update(double score, ScoreEvidence e) {
    final step = (config.scoreLearningRate * (e.value - score))
        .clamp(-config.maxScoreStep, config.maxScoreStep);
    return ScoreUpdate(
      before: score,
      after: (score + step).clamp(0.0, 100.0).toDouble(),
      evidence: e,
    );
  }

  /// "Buddy's plan" for the Results screen, in kid words (§5). Names the
  /// child's rank, never the score or the CRLA label.
  String buddyPlan(ScoreUpdate u, PhilIriLevel result) {
    final before = profileOf(u.before), after = profileOf(u.after);
    if (after.index > before.index) {
      return after.next == null
          ? "Wow! You're a ${after.rank} now! Hooray!"
          : 'Wow! You grew into a ${after.rank} reader! Hooray!';
    }
    if (after.index < before.index) {
      return "That one was a bit tricky. Buddy will pick some easier stories "
          "for a while. You'll grow again soon!";
    }
    final feel = switch (result) {
      PhilIriLevel.independent => 'This story was easy for you.',
      PhilIriLevel.instructional => 'This story was just right.',
      PhilIriLevel.frustration => 'This story was a bit tricky.',
    };
    final next = after.next;
    if (u.change > 0.5) {
      return next == null
          ? "$feel You're a ${after.rank}! Keep reading to stay super!"
          : "$feel You're growing toward ${next.rank}!";
    }
    return result == PhilIriLevel.frustration
        ? "$feel Let's keep practising together."
        : '$feel Keep reading to grow even stronger!';
  }
}
