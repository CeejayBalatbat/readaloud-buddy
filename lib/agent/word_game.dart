import 'dart:math';

import '../data/story.dart';
import 'mastery.dart';
import 'story_selection.dart';
import 'tricky_words.dart';
import 'word_matcher.dart';
import 'word_result.dart';

/// One word in the "Build the word" game (screen 9).
class GameWord {
  const GameWord({
    required this.word,
    required this.patternCode,
    this.fromTrickyList = false,
  });

  /// Lowercase letters only, e.g. "strong".
  final String word;
  final String patternCode;

  /// From the child's tricky-word list (AGENT_SPEC §8), not a filler.
  final bool fromTrickyList;

  String get language => patternCode.startsWith('FIL') ? 'FIL' : 'EN';

  @override
  String toString() => 'GameWord($word $patternCode${fromTrickyList ? ' tricky' : ''})';
}

/// Picks the game's words and builds its letter tiles. Pure Dart.
class WordGame {
  const WordGame({this.roundSize = 5});

  /// Words per game.
  final int roundSize;

  static final _letters = RegExp(r'^\p{L}{2,8}$', unicode: true);

  /// Sight-word patterns: learned by heart, not built from letters.
  static const _sightPatterns = {'EN-SW', 'FIL-SW'};

  /// The child's tricky words first, weakest sound first; topped up with
  /// words that practise their weakest sounds from [practiceStoryIds]: the
  /// stories Buddy would recommend (AGENT_SPEC §8, §9).
  List<GameWord> pickWords({
    required List<TrickyWord> tricky,
    required SoundMastery mastery,
    required List<Story> stories,
    required Set<String> practiceStoryIds,
    required List<String> languages,
    Random? random,
  }) {
    final rnd = random ?? Random();
    // Words written with a hyphen (araw-araw) can't be built letter by letter.
    final hyphenated = {
      for (final s in stories)
        for (final w in s.words)
          if (w.word.contains('-')) WordMatcher.normalize(w.word),
    };
    bool usable(String w) => _letters.hasMatch(w) && !hyphenated.contains(w);

    final picked = <GameWord>[];
    final seen = <String>{};
    final fromList = tricky.where((t) => usable(t.word)).toList()
      ..sort((a, b) {
        final m = mastery.of(a.patternCode).compareTo(mastery.of(b.patternCode));
        return m != 0 ? m : a.cleanReads.compareTo(b.cleanReads);
      });
    for (final t in fromList) {
      if (picked.length >= roundSize) break;
      if (seen.add(t.word)) {
        picked.add(GameWord(word: t.word, patternCode: t.patternCode, fromTrickyList: true));
      }
    }

    if (picked.length < roundSize) {
      final pool = <String, (GameWord, double)>{};
      for (final s in stories) {
        if (!practiceStoryIds.contains(s.id) || !languages.contains(s.language)) continue;
        for (final w in s.words) {
          final word = WordMatcher.normalize(w.word);
          if (!usable(word) || word.length < 3 || seen.contains(word)) continue;
          if (_sightPatterns.contains(w.primaryPattern)) continue;
          final score = 1 - mastery.of(w.primaryPattern) + rnd.nextDouble() * 0.15;
          final old = pool[word];
          if (old == null || old.$2 < score) {
            pool[word] = (GameWord(word: word, patternCode: w.primaryPattern), score);
          }
        }
      }
      final ranked = pool.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
      for (final (g, _) in ranked) {
        if (picked.length >= roundSize) break;
        picked.add(g);
      }
    }
    return picked;
  }

  /// The "Why this game?" line: the sounds the child is still learning.
  static String whyLine(String nickname, List<GameWord> words) {
    final labels = <String>[];
    for (final w in words) {
      final label = kidPatternLabels[w.patternCode];
      if (label != null && label != 'sight' && !labels.contains(label)) labels.add(label);
    }
    final tricky = words.where((w) => w.fromTrickyList).length;
    final source = tricky == 0
        ? 'words with sounds $nickname is still learning'
        : tricky == words.length
            ? 'words $nickname found tricky'
            : 'words $nickname found tricky and sounds $nickname is still learning';
    if (labels.isEmpty) return 'Buddy picks $source.';
    final like = labels.take(2).map((l) => '"$l"').join(' and ');
    return 'Buddy picks $source, like $like.';
  }

  /// Letters that are easy to mix up with each letter.
  static const _lookAlikes = {
    'b': 'dp', 'd': 'bq', 'p': 'bq', 'q': 'pd', 'm': 'nw', 'n': 'mu', 'u': 'nv',
    'w': 'mv', 's': 'zc', 'z': 's', 'c': 'ks', 'k': 'c', 'f': 'v', 'v': 'f',
    'a': 'eo', 'e': 'ai', 'i': 'el', 'o': 'au', 'l': 'it', 't': 'f', 'g': 'q',
    'h': 'n', 'r': 'n', 'y': 'v', 'j': 'i', 'x': 'k',
  };

  /// The word's letters plus [extra] look-alike letters that are not in
  /// the word, shuffled (never already in the right order).
  static List<String> tiles(String word, {int extra = 2, Random? random}) {
    final rnd = random ?? Random();
    final letters = word.split('');
    final pool = <String>[
      for (final c in letters) ...(_lookAlikes[c] ?? '').split(''),
      ...'aeioumnstrpbd'.split(''),
    ].where((c) => c.isNotEmpty && !letters.contains(c)).toSet().toList();
    pool.shuffle(rnd);
    final tiles = [...letters, ...pool.take(extra)];
    for (var tries = 0; tries < 10; tries++) {
      tiles.shuffle(rnd);
      if (tiles.take(letters.length).join() != word) break;
    }
    return tiles;
  }

  /// Clean builds count as clean reads for the tricky-word list (§8:
  /// "read cleanly in 2 later sessions or games"). Builds with a wrong
  /// tile don't count, but they don't reset anything either.
  static List<WordOutcome> outcomesFor(List<(GameWord, bool clean)> results) => [
        for (final (i, (g, clean)) in results.indexed)
          if (clean)
            WordOutcome(
              position: i + 1,
              word: g.word,
              patterns: [g.patternCode],
              primaryPattern: g.patternCode,
              result: WordResult.correct,
            ),
      ];
}

/// One word being built: tap (or drag) letters into the next empty slot.
class BuildRound {
  BuildRound(this.target, this.tiles);

  final GameWord target;
  final List<String> tiles;

  final List<String> _placed = [];
  final Set<int> _usedTiles = {};
  int _mistakes = 0;

  List<String> get placed => List.unmodifiable(_placed);
  bool isUsed(int tile) => _usedTiles.contains(tile);
  int get mistakes => _mistakes;
  bool get isDone => _placed.length == target.word.length;

  /// Built without a wrong tile.
  bool get isClean => isDone && _mistakes == 0;

  /// Tries tile [index] in the next slot. Returns true if it was the right
  /// letter (it stays), false if not (it goes back; counted as a mistake).
  bool place(int index) {
    if (isDone || isUsed(index)) return false;
    if (tiles[index] == target.word[_placed.length]) {
      _placed.add(tiles[index]);
      _usedTiles.add(index);
      return true;
    }
    _mistakes++;
    return false;
  }
}
