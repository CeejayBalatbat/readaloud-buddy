import 'agent_config.dart';
import 'phonics.dart';
import 'word_matcher.dart';

/// One hint shown/spoken to the child (AGENT_SPEC §2).
class Hint {
  const Hint({
    required this.level,
    required this.word,
    required this.parts,
    this.speech = const [],
    this.keyword,
    this.emoji,
    this.sight = false,
  });

  /// 1 = first sound, 2 = word parts, 3 = whole word.
  final int level;
  final String word;

  /// What to show: level 1 -> the onset ["sh"], level 2 -> ["sh", "ip"],
  /// level 3 -> ["ship"]. Filipino: syllables ("ba", "ba · ta").
  final List<String> parts;

  /// What Buddy says, piece by piece. Never a letter name or a lone
  /// sound: "had" level 1 → "It starts like", "hat"; level 2 → hat, ad,
  /// had; level 3 → had.
  final List<SpokenPart> speech;

  /// English: a picture word with the same first sound (hat 🎩).
  final String? keyword;
  final String? emoji;

  /// A heart word (the, was): one hint only, the whole word.
  final bool sight;

  /// e.g. "sh · ip", ready for the hint card.
  String get display => parts.join(' · ');
}

/// Builds hint content: first sound, word parts, whole word.
class HintLadder {
  const HintLadder._();

  // Longest first, so "str" wins over "st".
  static const _enOnsets = [
    'str', 'spr', 'scr', 'spl', 'shr', 'thr', 'squ', 'sch', //
    'th', 'sh', 'ch', 'wh', 'ph', 'bl', 'br', 'cl', 'cr', 'dr', 'fl', 'fr',
    'gl', 'gr', 'pl', 'pr', 'sc', 'sk', 'sl', 'sm', 'sn', 'sp', 'st', 'sw',
    'tr', 'tw',
  ];
  static const _filOnsets = [
    'ng', 'ts', 'bl', 'br', 'dr', 'gl', 'gr', 'kl', 'kr', 'pl', 'pr', 'tr',
  ];
  static const _enBlends = {
    'bl', 'br', 'cl', 'cr', 'dr', 'fl', 'fr', 'gl', 'gr', 'pl', 'pr', 'tr', //
    'sc', 'sk', 'sl', 'sm', 'sn', 'sp', 'st', 'sw', 'tw',
  };
  static const _enDigraphs = {'th', 'sh', 'ch', 'ph', 'wh', 'ck'};

  /// True for English heart words: they get one hint, the whole word.
  static bool isSight(String word, String language, PhonicsDictionary phonics) =>
      language != 'FIL' && phonics[word]?.type == WordType.sight;

  /// The hint for [word] at [level]. English hints use [phonics] (keyword
  /// + onset/rime); Filipino hints use syllables.
  static Hint hintFor(
    String word,
    int level,
    String language, {
    PhonicsDictionary phonics = PhonicsDictionary.empty,
  }) {
    if (level < 1 || level > 3) {
      throw ArgumentError.value(level, 'level', 'must be 1, 2 or 3');
    }
    final whole = WordMatcher.normalize(word);
    if (language == 'FIL') return _filipino(word, whole, level);
    final entry = phonics[word];
    if (entry == null) return _englishFallback(word, whole, level);

    if (entry.type == WordType.sight) {
      return Hint(
        level: 3,
        word: word,
        parts: [whole],
        sight: true,
        speech: [const SpokenPart('This one we just know.'), SpokenPart(whole)],
      );
    }
    // Vowel first ("and"): the onset is the first letter group.
    final onset = entry.onset.isNotEmpty ? entry.onset : _firstGrapheme(entry);
    final keyword = entry.keyword;
    switch (level) {
      case 1:
        return Hint(
          level: 1,
          word: word,
          parts: [onset],
          keyword: keyword,
          emoji: entry.emoji,
          speech: keyword == null
              ? const [SpokenPart('Look at how it starts.')]
              : [
                  const SpokenPart('It starts like'),
                  // A recorded clip of the sound may replace the keyword.
                  SpokenPart(keyword, clips: entry.onsetPhonemes),
                ],
        );
      case 2:
        final hasOnset = entry.onset.isNotEmpty;
        return Hint(
          level: 2,
          word: word,
          parts: hasOnset ? [entry.onset, entry.rime] : [whole],
          keyword: keyword,
          emoji: entry.emoji,
          // hat… ad… had: the keyword, the rime chunk, the word.
          speech: [
            if (keyword != null) SpokenPart(keyword),
            if (hasOnset) SpokenPart(entry.rimeSay),
            SpokenPart(whole),
          ],
        );
      default:
        return Hint(level: 3, word: word, parts: [whole], speech: [SpokenPart(whole)]);
    }
  }

  static String _firstGrapheme(PhonicsEntry e) =>
      e.graphemes.isEmpty ? e.word.substring(0, 1) : e.graphemes.first.replaceAll('(silent)', '');

  /// Filipino: syllables. Level 1 = opening syllable ("ba"), level 2 =
  /// syllables + word ("ba… ta… bata"), level 3 = word.
  static Hint _filipino(String word, String whole, int level) {
    final parts = wordParts(word, 'FIL');
    final first = firstSound(word, 'FIL');
    return switch (level) {
      1 => Hint(level: 1, word: word, parts: [first], speech: [SpokenPart(first)]),
      2 => Hint(
          level: 2,
          word: word,
          parts: parts,
          // One-syllable word: opening syllable + word ("ma… may"), never
          // a lone consonant.
          speech: !parts.first.contains(RegExp('[aeiou]'))
              ? [SpokenPart(first), SpokenPart(whole)]
              : [for (final p in parts) SpokenPart(p), SpokenPart(whole)],
        ),
      _ => Hint(level: 3, word: word, parts: [whole], speech: [SpokenPart(whole)]),
    };
  }

  /// An English word missing from phonics.json (re-run
  /// tools/gen_phonics.py): show the parts, but only ever say whole
  /// chunks and words, never letters.
  static Hint _englishFallback(String word, String whole, int level) {
    final parts = wordParts(word, 'EN');
    bool sayable(String p) => p.length > 1 && p.contains(RegExp('[aeiouy]'));
    return switch (level) {
      1 => Hint(
          level: 1,
          word: word,
          parts: [firstSound(word, 'EN')],
          speech: const [SpokenPart('Look at how it starts.')],
        ),
      2 => Hint(
          level: 2,
          word: word,
          parts: parts,
          speech: [for (final p in parts) if (sayable(p)) SpokenPart(p), SpokenPart(whole)],
        ),
      _ => Hint(level: 3, word: word, parts: [whole], speech: [SpokenPart(whole)]),
    };
  }

  /// Level 1: first letter, or the first digraph/blend (th, sh, ch, str…).
  /// Filipino uses the opening consonant-vowel syllable, as in the
  /// Abakada ("ba" in "bata", "ma" in "may", "nga" in "ngayon"), because
  /// Filipino reading is taught by syllables.
  static String firstSound(String word, String language) {
    final w = WordMatcher.normalize(word);
    if (w.isEmpty) return w;
    if (language == 'FIL') {
      final vowel = w.indexOf(RegExp('[aeiou]'));
      return vowel < 0 ? w : w.substring(0, vowel + 1);
    }
    final onsets = language == 'FIL' ? _filOnsets : _enOnsets;
    for (final o in onsets) {
      if (w.startsWith(o) && w.length > o.length) return o;
    }
    return w[0];
  }

  /// Level 2: the word split into parts. One-syllable words split into
  /// first sound + rest ("thr · ough"); longer words split into syllables
  /// ("ba · ta", "bas · ket"). This is a simple rule-based splitter, so a
  /// few English words come out slightly off; it never loses letters.
  static List<String> wordParts(String word, String language) {
    final pieces = word
        .toLowerCase()
        .split('-')
        .map(WordMatcher.normalize)
        .where((p) => p.isNotEmpty);
    return [for (final p in pieces) ..._splitPiece(p, language == 'FIL')];
  }

  static List<String> _splitPiece(String w, bool fil) {
    final nuclei = _nuclei(w, fil);
    if (nuclei.isEmpty) return [w];
    if (nuclei.length == 1) {
      final start = nuclei.first.$1;
      return start == 0 ? [w] : [w.substring(0, start), w.substring(start)];
    }
    final cuts = <int>[];
    for (var n = 0; n < nuclei.length - 1; n++) {
      final from = nuclei[n].$2; // first consonant after this vowel group
      final to = nuclei[n + 1].$1; // next vowel group
      cuts.add(_cutBetween(w, from, to, fil));
    }
    final parts = <String>[];
    var prev = 0;
    for (final c in cuts) {
      parts.add(w.substring(prev, c));
      prev = c;
    }
    parts.add(w.substring(prev));
    return parts;
  }

  /// Where to cut the consonants w[from..to) between two vowel groups.
  static int _cutBetween(String w, int from, int to, bool fil) {
    // Consonant "units": digraphs count as one sound.
    final units = <(int, int)>[];
    var i = from;
    while (i < to) {
      final two = i + 2 <= to ? w.substring(i, i + 2) : '';
      final isDigraph = fil ? two == 'ng' : _enDigraphs.contains(two);
      final len = isDigraph ? 2 : 1;
      units.add((i, i + len));
      i += len;
    }
    if (units.isEmpty) return from; // vowel next to vowel: ku · ma · in
    if (units.length == 1) {
      final u = w.substring(units[0].$1, units[0].$2);
      return (u == 'ck' || u == 'x') ? units[0].$2 : units[0].$1;
    }
    final lastTwo = w.substring(units[units.length - 2].$1, units.last.$2);
    if (units.length >= 3 && !fil && _enBlends.contains(lastTwo)) {
      return units[units.length - 2].$1; // chil · dren
    }
    return units.last.$1; // bas · ket, bang · ka
  }

  /// Vowel groups as (start, end) index pairs.
  static List<(int, int)> _nuclei(String w, bool fil) {
    bool isVowel(int i) {
      final c = w[i];
      if ('aeiou'.contains(c)) return true;
      // English "y" is a vowel except at the start (busy, day, yes).
      return !fil && c == 'y' && i > 0;
    }

    var end = w.length;
    // English silent final e (kite, home, smile) – but consonant + "le"
    // keeps its own part (lit · tle, ta · ble).
    if (!fil &&
        w.length > 3 &&
        w.endsWith('e') &&
        !isVowel(w.length - 2) &&
        !(w.endsWith('le') && !isVowel(w.length - 3))) {
      end = w.length - 1;
    }

    final groups = <(int, int)>[];
    var i = 0;
    while (i < end) {
      if (!isVowel(i)) {
        i++;
        continue;
      }
      final start = i;
      i++;
      // English keeps vowel teams together (rain, through); Filipino vowels
      // are each their own syllable (ku-ma-in, do-on).
      if (!fil) {
        while (i < end && isVowel(i)) {
          i++;
        }
      }
      groups.add((start, i));
    }
    return groups;
  }
}

/// Per-learner success counts for each hint level (the `hint_stats` table).
/// A hint "succeeds" when the word is read correctly within
/// `hintSuccessWindowSec` after it.
class HintStats {
  HintStats([Map<int, (int uses, int successes)>? counts])
      : _counts = {...?counts};

  final Map<int, (int, int)> _counts;

  /// (uses, successes) per hint level, for saving.
  Map<int, (int uses, int successes)> get counts => Map.unmodifiable(_counts);

  int uses(int level) => _counts[level]?.$1 ?? 0;
  int successes(int level) => _counts[level]?.$2 ?? 0;

  double successRate(int level) =>
      uses(level) == 0 ? 0 : successes(level) / uses(level);

  void record(int level, {required bool success}) {
    _counts[level] = (uses(level) + 1, successes(level) + (success ? 1 : 0));
  }

  void recordAll(Iterable<HintAttempt> attempts) {
    for (final a in attempts) {
      record(a.level, success: a.success);
    }
  }

  /// §2 Learning: start at level 2 when level 2 works (≥ 70%) and level 1
  /// doesn't (< 40%), once both have at least 10 uses. Otherwise level 1.
  int startLevel([AgentConfig config = const AgentConfig()]) {
    final enoughData = uses(1) >= config.hintLearningMinUses &&
        uses(2) >= config.hintLearningMinUses;
    if (enoughData &&
        successRate(2) >= config.hintLevel2SuccessMin &&
        successRate(1) < config.hintLevel1SuccessMax) {
      return 2;
    }
    return 1;
  }
}

/// One hint given during reading and whether it worked.
class HintAttempt {
  const HintAttempt({required this.level, required this.success});
  final int level;
  final bool success;

  @override
  String toString() => 'HintAttempt(level $level, success: $success)';
}
