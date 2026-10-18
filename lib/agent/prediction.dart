import 'dart:math';

import '../data/story.dart';
import 'agent_config.dart';
import 'mastery.dart';
import 'philiri.dart';

double _sigmoid(double x) => 1 / (1 + exp(-x));
double _logit(double p) => log(p / (1 - p));

/// One book's predicted word accuracy for a learner (AGENT_SPEC §9).
class BookPrediction {
  const BookPrediction({required this.story, required this.accuracy, required this.band});

  final Story story;

  /// Predicted share of words read correctly, 0–1.
  final double accuracy;

  /// Independent (easy), Instructional (just right) or Frustration (too
  /// hard), from the Phil-IRI word thresholds.
  final PhilIriLevel band;
}

/// Predicts how many words of a book a learner will read correctly, from
/// their BKT mastery of each word's patterns (AGENT_SPEC §9), and learns
/// from the difference between predicted and actual accuracy. Pure Dart.
class AccuracyPredictor {
  const AccuracyPredictor({
    required this.patternDifficulty,
    this.config = const AgentConfig(),
  });

  /// Each pattern's difficulty, 0–1 (assets/data/sound_patterns.json).
  final Map<String, double> patternDifficulty;
  final AgentConfig config;

  /// Mastery of a sound the learner hasn't read yet, guessed from the
  /// reading score: about half at score = 100 × the pattern's difficulty.
  double prior(String pattern, double score) {
    final d = patternDifficulty[pattern] ?? 0.5;
    return _sigmoid((score - 100 * d) / config.priorSpread)
        .clamp(config.priorMin, config.priorMax)
        .toDouble();
  }

  /// BKT mastery once the pattern was read at least once, else the prior.
  double masteryOf(String pattern, SoundMastery mastery, double score) =>
      mastery.observationsOf(pattern) > 0 ? mastery.of(pattern) : prior(pattern, score);

  /// Chance the learner reads [word] (in a book of [difficulty]) right.
  double wordProbability(
    StoryWord word,
    SoundMastery mastery, {
    required double score,
    required double bias,
    required double difficulty,
  }) {
    final m = word.patterns.isEmpty
        ? prior('', score)
        : word.patterns.map((p) => masteryOf(p, mastery, score)).reduce(min);
    final raw = m * (1 - config.bktSlip) + (1 - m) * config.bktGuess;
    final gap = ((score - difficulty) / 10).clamp(-config.textGapMaxSteps, config.textGapMaxSteps);
    return _sigmoid(_logit(raw) + bias + config.textGapWeight * gap);
  }

  /// Predicted word accuracy of [story], 0–1.
  double accuracy(Story story, SoundMastery mastery, {required double score, required double bias}) {
    if (story.words.isEmpty) return 1;
    var sum = 0.0;
    for (final w in story.words) {
      sum += wordProbability(w, mastery, score: score, bias: bias, difficulty: story.difficulty);
    }
    return sum / story.words.length;
  }

  PhilIriLevel bandOf(double accuracy) => PhilIriClassifier(config).wordLevel(accuracy);

  BookPrediction predict(Story story, SoundMastery mastery, {required double score, required double bias}) {
    final a = accuracy(story, mastery, score: score, bias: bias);
    return BookPrediction(story: story, accuracy: a, band: bandOf(a));
  }

  /// The prediction correction after a story read with [actual] accuracy
  /// when [predicted] was expected: guesses that were too high come down.
  double updatedBias(double bias, {required double predicted, required double actual}) {
    double c(double p) => p.clamp(config.accuracyClampMin, config.accuracyClampMax).toDouble();
    final next = bias + config.biasLearningRate * (_logit(c(actual)) - _logit(c(predicted)));
    return next.clamp(config.biasMin, config.biasMax).toDouble();
  }
}
