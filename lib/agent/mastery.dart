import 'agent_config.dart';
import 'word_result.dart';

enum MasteryStatus { mastered, learning, needsHelp }

/// Sound mastery per sound-pattern code, using Bayesian Knowledge Tracing
/// (AGENT_SPEC §7). One instance per learner (the `mastery` table).
class SoundMastery {
  SoundMastery({
    this.config = const AgentConfig(),
    Map<String, double>? mastery,
    Map<String, int>? observations,
  })  : _mastery = {...?mastery},
        _observations = {...?observations};

  final AgentConfig config;
  final Map<String, double> _mastery;
  final Map<String, int> _observations;

  /// Mastery estimate 0–1; patterns never seen start at p0.
  double of(String pattern) => _mastery[pattern] ?? config.bktP0;

  int observationsOf(String pattern) => _observations[pattern] ?? 0;

  Map<String, double> get all => Map.unmodifiable(_mastery);
  Map<String, int> get allObservations => Map.unmodifiable(_observations);

  MasteryStatus statusOf(String pattern) => statusFor(of(pattern), config);

  static MasteryStatus statusFor(
    double m, [
    AgentConfig config = const AgentConfig(),
  ]) {
    if (m >= config.masteredMin) return MasteryStatus.mastered;
    if (m >= config.learningMin) return MasteryStatus.learning;
    return MasteryStatus.needsHelp;
  }

  /// One BKT step: Bayes update on the observation, then the learn step.
  static double bktUpdate(
    double m, {
    required bool correct,
    AgentConfig config = const AgentConfig(),
  }) {
    final slip = config.bktSlip, guess = config.bktGuess;
    final post = correct
        ? m * (1 - slip) / (m * (1 - slip) + (1 - m) * guess)
        : m * slip / (m * slip + (1 - m) * (1 - guess));
    return post + (1 - post) * config.bktLearn;
  }

  void observe(String pattern, {required bool correct}) {
    _mastery[pattern] = bktUpdate(of(pattern), correct: correct, config: config);
    _observations[pattern] = observationsOf(pattern) + 1;
  }

  /// Updates every pattern of every scored (not `unsure`) word.
  void recordWords(Iterable<WordOutcome> outcomes) {
    for (final o in outcomes) {
      if (!o.result.isScored) continue;
      for (final p in o.patterns) {
        observe(p, correct: o.result.countsAsCorrect);
      }
    }
  }
}
