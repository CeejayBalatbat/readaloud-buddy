import 'dart:convert';

/// A sound pattern from assets/data/sound_patterns.json. Pure Dart (no
/// Flutter imports) so the agent's tests can load it too.
class SoundPattern {
  const SoundPattern(this.code, this.name, this.examples, {this.difficulty = 0.5});
  final String code;
  final String name;
  final List<String> examples;

  /// 0–1: how hard the sound is (used for the score-based prior, §9).
  final double difficulty;
}

/// Parses the whole sound_patterns.json file, by code.
Map<String, SoundPattern> parseSoundPatterns(String jsonText) => {
      for (final p in (jsonDecode(jsonText) as List).cast<Map<String, dynamic>>())
        p['code'] as String: SoundPattern(
          p['code'] as String,
          p['name'] as String,
          [for (final e in (p['examples'] as String).split(',')) e.trim()],
          difficulty: (p['difficulty'] as num).toDouble(),
        ),
    };

/// Each pattern's difficulty, for the accuracy predictor.
Map<String, double> patternDifficulties(Map<String, SoundPattern> patterns) =>
    {for (final p in patterns.values) p.code: p.difficulty};
