import 'dart:math' as math;

import 'agent_config.dart';

/// Word matching rules (AGENT_SPEC §1): lowercase, strip punctuation, then
/// compare with a per-language Levenshtein tolerance.
class WordMatcher {
  const WordMatcher([this.config = const AgentConfig()]);

  final AgentConfig config;

  static final _punctuation = RegExp(r"[^\p{L}\p{N}]", unicode: true);

  /// "Pip!" -> "pip", "Marco's" -> "marcos", "masayang-masaya" -> "masayangmasaya".
  static String normalize(String word) =>
      word.toLowerCase().replaceAll(_punctuation, '');

  /// True when [heard] counts as reading [expected] in [language] ("EN"/"FIL").
  bool matches(String expected, String heard, String language) {
    final e = normalize(expected);
    final h = normalize(heard);
    if (e.isEmpty || h.isEmpty) return false;
    if (e == h) return true;
    return levenshtein(e, h) <= maxDistanceFor(e, language);
  }

  /// Allowed edit distance for an expected (normalized) word.
  int maxDistanceFor(String normalizedExpected, String language) {
    if (language == 'FIL') return config.filMaxEditDistance;
    return normalizedExpected.length >= config.enMinLettersForTypoTolerance
        ? config.enMaxEditDistance
        : 0;
  }

  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = math.min(
          math.min(cur[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + cost,
        );
      }
      prev = cur;
    }
    return prev[b.length];
  }
}
