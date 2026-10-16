import 'word_matcher.dart';

/// One piece of a spoken hint: a phonics sound, a rime ("ad") or a whole
/// word. [clip] names a recorded audio clip (`assets/sounds/CLIP.mp3`);
/// until that clip exists the app says [tts] with text-to-speech.
class SpokenPart {
  const SpokenPart(this.tts, {this.clip});

  /// Text for text-to-speech, spelled so it is said as a sound ("huh"),
  /// never as a letter name ("aitch").
  final String tts;

  /// File name (without .mp3) of a recorded clip, or null for whole words.
  final String? clip;

  @override
  bool operator ==(Object other) =>
      other is SpokenPart && other.tts == tts && other.clip == clip;

  @override
  int get hashCode => Object.hash(tts, clip);

  @override
  String toString() => clip == null ? '"$tts"' : '$clip:"$tts"';
}

/// English grapheme → phonics sound map, for hints that say sounds instead
/// of letter names (AGENT_SPEC §2): "had" → "huh… ad… had".
///
/// Every sound has a stable clip id ([sounds] keys). The TTS spellings are
/// a stand-in: recorded clips in assets/sounds/ should replace them,
/// because TTS can only approximate a pure sound.
abstract final class Phonics {
  /// Clip id → TTS spelling. Consonants use letters as ids (h.mp3, th.mp3),
  /// vowels say which sound (a_short.mp3, a_long.mp3).
  static const sounds = <String, String>{
    // Consonants
    'b': 'buh', 'c': 'kuh', 'd': 'duh', 'f': 'fuh', 'g': 'guh', 'h': 'huh',
    'j': 'juh', 'k': 'kuh', 'l': 'luh', 'm': 'mmm', 'n': 'nuh', 'p': 'puh',
    'r': 'ruh', 's': 'suh', 't': 'tuh', 'v': 'vuh', 'w': 'wuh', 'x': 'ks',
    'y': 'yuh', 'z': 'zuh', 'qu': 'kwuh',
    // Consonant digraphs
    'th': 'thuh', 'sh': 'shh', 'ch': 'chuh', 'wh': 'wuh', 'ph': 'fuh',
    'ck': 'kuh', 'kn': 'nuh', 'wr': 'ruh',
    // Short vowels
    'a_short': 'ah', 'e_short': 'eh', 'i_short': 'ih', 'o_short': 'aw',
    'u_short': 'uh', 'schwa': 'uh',
    // Long vowels and vowel teams
    'a_long': 'ay', 'e_long': 'ee', 'i_long': 'eye', 'o_long': 'oh',
    'u_long': 'you', 'oo': 'oo', 'ow': 'ow', 'oy': 'oy', 'aw': 'aw',
    // r-controlled vowels
    'ar': 'ar', 'or': 'or', 'er': 'er',
  };

  /// Letters at the start of a consonant cluster → clip ids, longest first.
  static const _consonants = <String, List<String>>{
    'sch': ['s', 'c'], 'squ': ['s', 'qu'], //
    'th': ['th'], 'sh': ['sh'], 'ch': ['ch'], 'wh': ['wh'], 'ph': ['ph'],
    'ck': ['ck'], 'kn': ['kn'], 'wr': ['wr'], 'qu': ['qu'],
  };

  /// Vowel spellings at the start of a word → clip id, longest first.
  static const _vowelTeams = <String, String>{
    'igh': 'i_long', 'ea': 'e_long', 'ee': 'e_long', 'ai': 'a_long',
    'ay': 'a_long', 'oa': 'o_long', 'oo': 'oo', 'ou': 'ow', 'ow': 'ow',
    'oi': 'oy', 'oy': 'oy', 'au': 'aw', 'aw': 'aw', 'ar': 'ar', 'or': 'or',
    'er': 'er', 'ir': 'er', 'ur': 'er',
  };

  /// Common words whose letters don't give their sounds: (first sounds as
  /// clip ids, rime as TTS text). Without a first sound they start with
  /// the rime ("are", "of").
  static const _irregular = <String, (List<String>, String)>{
    'the': (['th'], 'uh'), 'a': ([], 'uh'), 'i': ([], 'eye'),
    'was': (['w'], 'uz'), 'to': (['t'], 'oo'), 'two': (['t'], 'oo'),
    'do': (['d'], 'oo'), 'who': (['h'], 'oo'), 'said': (['s'], 'ed'),
    'they': (['th'], 'ay'), 'one': (['w'], 'un'), 'once': (['w'], 'unce'),
    'you': (['y'], 'oo'), 'your': (['y'], 'or'), 'are': ([], 'ar'),
    'of': ([], 'uv'), 'have': (['h'], 'av'), 'give': (['g'], 'iv'),
    'live': (['l'], 'iv'), 'love': (['l'], 'uv'), 'come': (['c'], 'um'),
    'some': (['s'], 'um'), 'could': (['c'], 'ood'), 'would': (['w'], 'ood'),
    'what': (['w'], 'ut'), 'were': (['w'], 'er'), 'where': (['wh'], 'air'),
    'there': (['th'], 'air'), 'does': (['d'], 'uz'), 'move': (['m'], 'oov'),
    'put': (['p'], 'ood'), 'whole': (['h'], 'ole'), 'any': ([], 'enny'),
    'many': (['m'], 'enny'), 'our': ([], 'ower'), 'eye': ([], 'eye'),
  };

  /// Rimes TTS would otherwise say as letter names or the wrong sound.
  static const _rimeSay = <String, String>{
    'e': 'ee', 'o': 'oh', 'y': 'eye', 'ey': 'ay', 'ew': 'oo', 'ue': 'oo',
    'ough': 'oo', 'ia': 'ee-uh', 'ea': 'ee', 'ee': 'ee', 'ou': 'oo',
  };

  static const _vowels = 'aeiou';

  /// The first sound(s) of [word] as spoken parts: the consonants before
  /// the first vowel ("str" → s, t, r), or the first vowel sound.
  static List<SpokenPart> firstSounds(String word) {
    final w = WordMatcher.normalize(word);
    if (w.isEmpty) return const [];
    final irregular = _irregular[w];
    if (irregular != null) {
      final (onset, rime) = irregular;
      return onset.isEmpty ? [_rimePart(rime, rime)] : [for (final id in onset) _sound(id)];
    }
    final onset = _onset(w);
    if (onset.isEmpty) return [_sound(_firstVowel(w))];
    return [for (final id in _consonantIds(onset, w)) _sound(id)];
  }

  /// Level 2 speech for a one-syllable English word: first sounds, the
  /// rime, then the blended word ("huh… ad… had").
  static List<SpokenPart> onsetRime(String word) {
    final w = WordMatcher.normalize(word);
    final irregular = _irregular[w];
    if (irregular != null) {
      final (onset, rime) = irregular;
      return [
        for (final id in onset) _sound(id),
        _rimePart(rime, rime),
        SpokenPart(w),
      ];
    }
    final onset = _onset(w);
    if (onset.isEmpty) return [_sound(_firstVowel(w)), SpokenPart(w)];
    final rime = w.substring(onset.length);
    return [
      for (final id in _consonantIds(onset, w)) _sound(id),
      _rimePart(_rimeSay[rime] ?? rime, rime),
      SpokenPart(w),
    ];
  }

  /// One syllable of a longer English word, spelled so TTS says it as a
  /// sound: a lone vowel ("a·gain" → uh) or consonant + y ("shi·ny" → nee)
  /// would otherwise come out as letter names.
  static SpokenPart syllable(String part) {
    const lone = {
      'a': 'schwa', 'e': 'e_short', 'i': 'i_short', 'o': 'o_long', 'u': 'u_short',
    };
    final id = lone[part];
    if (id != null) return _sound(id);
    if (RegExp(r'^[^aeiou]+y$').hasMatch(part)) {
      return SpokenPart('${part.substring(0, part.length - 1)}ee');
    }
    return SpokenPart(part);
  }

  /// The consonant letters before the first vowel ("y" counts as a vowel
  /// after the first letter: "try" → "tr").
  static String _onset(String w) {
    var i = 0;
    while (i < w.length && !_vowels.contains(w[i]) && !(i > 0 && w[i] == 'y')) {
      i++;
    }
    // "qu" belongs to the onset ("quick", "squid").
    if (i < w.length && w[i] == 'u' && i > 0 && w[i - 1] == 'q') i++;
    return i == w.length ? w : w.substring(0, i);
  }

  /// Splits an onset into clip ids: digraphs first, then single letters.
  /// "c" before e/i/y is a "s" sound (city).
  static List<String> _consonantIds(String onset, String word) {
    final ids = <String>[];
    var i = 0;
    while (i < onset.length) {
      final match = _consonants.keys.firstWhere(
          (k) => onset.startsWith(k, i),
          orElse: () => '');
      if (match.isNotEmpty) {
        ids.addAll(_consonants[match]!);
        i += match.length;
        continue;
      }
      final c = onset[i];
      final next = i + 1 < word.length ? word[i + 1] : '';
      ids.add(c == 'c' && 'eiy'.contains(next) && next.isNotEmpty ? 's' : c);
      i++;
    }
    return ids;
  }

  /// Clip id of the vowel sound a word starts with.
  static String _firstVowel(String w) {
    for (final team in _vowelTeams.keys) {
      if (w.startsWith(team)) return _vowelTeams[team]!;
    }
    final v = w[0];
    if (!_vowels.contains(v)) return v;
    // Magic e: vowel, one consonant, e at the end (ate, ice) = long.
    final magicE = RegExp('^[aeiou][^aeiou]es?\$').hasMatch(w);
    return '${v}_${magicE ? 'long' : 'short'}';
  }

  static SpokenPart _sound(String id) => SpokenPart(sounds[id] ?? id, clip: id);

  static SpokenPart _rimePart(String say, String rime) =>
      SpokenPart(say, clip: 'rime_$rime');
}
