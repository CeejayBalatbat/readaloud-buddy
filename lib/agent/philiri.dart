import 'agent_config.dart';

/// Phil-IRI reading levels (AGENT_SPEC §4).
enum PhilIriLevel {
  independent('Independent'),
  instructional('Instructional'),
  frustration('Frustration');

  const PhilIriLevel(this.label);

  /// As written in docs/dataset/Sessions.csv.
  final String label;

  static PhilIriLevel fromLabel(String label) =>
      values.firstWhere((l) => l.label == label);
}

/// The word, comprehension and overall level for one reading.
class PhilIriResult {
  const PhilIriResult(this.word, this.comprehension, this.overall);
  final PhilIriLevel word;
  final PhilIriLevel comprehension;
  final PhilIriLevel overall;
}

class PhilIriClassifier {
  const PhilIriClassifier([this.config = const AgentConfig()]);

  final AgentConfig config;

  PhilIriLevel wordLevel(double accuracy) {
    if (accuracy >= config.independentAccuracy) return PhilIriLevel.independent;
    if (accuracy >= config.instructionalAccuracy) {
      return PhilIriLevel.instructional;
    }
    return PhilIriLevel.frustration;
  }

  PhilIriLevel comprehensionLevel(double comprehension) {
    if (comprehension >= config.independentComprehension) {
      return PhilIriLevel.independent;
    }
    if (comprehension >= config.instructionalComprehension) {
      return PhilIriLevel.instructional;
    }
    return PhilIriLevel.frustration;
  }

  /// Frustration if either part is Frustration; Independent only if both
  /// are Independent; otherwise Instructional.
  PhilIriResult classify({
    required double accuracy,
    required double comprehension,
  }) {
    final w = wordLevel(accuracy);
    final c = comprehensionLevel(comprehension);
    final PhilIriLevel overall;
    if (w == PhilIriLevel.frustration || c == PhilIriLevel.frustration) {
      overall = PhilIriLevel.frustration;
    } else if (w == PhilIriLevel.independent &&
        c == PhilIriLevel.independent) {
      overall = PhilIriLevel.independent;
    } else {
      overall = PhilIriLevel.instructional;
    }
    return PhilIriResult(w, c, overall);
  }
}
