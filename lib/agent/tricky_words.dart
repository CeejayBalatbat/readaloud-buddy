import 'agent_config.dart';
import 'word_matcher.dart';
import 'word_result.dart';

/// One entry in the learner's tricky-word list (the `tricky_words` table).
class TrickyWord {
  const TrickyWord({
    required this.word,
    required this.patternCode,
    this.cleanReads = 0,
  });

  final String word; // normalized (lowercase, no punctuation)
  final String patternCode; // primary pattern
  final int cleanReads; // 0–2

  TrickyWord withCleanReads(int n) =>
      TrickyWord(word: word, patternCode: patternCode, cleanReads: n);
}

/// Tricky words (AGENT_SPEC §8). A word is added when it is misread,
/// skipped or read only after a hint, and leaves after it is read cleanly
/// (`correct` or `hesitated`) in 2 later sessions or games.
class TrickyWords {
  TrickyWords({
    this.config = const AgentConfig(),
    Iterable<TrickyWord> words = const [],
  }) : _words = {for (final w in words) w.word: w};

  final AgentConfig config;
  final Map<String, TrickyWord> _words;

  List<TrickyWord> get words => List.unmodifiable(_words.values);
  bool contains(String word) =>
      _words.containsKey(WordMatcher.normalize(word));

  /// Call once per finished session or game with all its word results.
  /// A word read several times in one activity counts once; if any of those
  /// reads was a miscue it is (re-)added with its clean-read count at 0.
  ({List<TrickyWord> added, List<TrickyWord> removed}) recordActivity(
    Iterable<WordOutcome> outcomes,
  ) {
    final missed = <String, WordOutcome>{};
    final clean = <String>{};
    for (final o in outcomes) {
      final key = WordMatcher.normalize(o.word);
      if (o.result.makesTricky) {
        missed.putIfAbsent(key, () => o);
      } else if (o.result.countsAsCorrect) {
        clean.add(key);
      }
    }

    final added = <TrickyWord>[];
    for (final MapEntry(key: key, value: o) in missed.entries) {
      final t = TrickyWord(word: key, patternCode: o.primaryPattern);
      if (!_words.containsKey(key)) added.add(t);
      _words[key] = t;
    }

    final removed = <TrickyWord>[];
    for (final key in clean.difference(missed.keys.toSet())) {
      final t = _words[key];
      if (t == null) continue;
      final n = t.cleanReads + 1;
      if (n >= config.trickyCleanReadsToRemove) {
        removed.add(_words.remove(key)!);
      } else {
        _words[key] = t.withCleanReads(n);
      }
    }
    return (added: added, removed: removed);
  }
}
