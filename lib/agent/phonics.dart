import 'dart:convert';

import 'word_matcher.dart';

/// One piece of a spoken hint. Buddy says [tts] with text-to-speech.
/// When [clips] is not empty and a recorded clip exists for every one of
/// them (`assets/sounds/<PHONEME>.mp3`, e.g. HH.mp3), the clips are played
/// instead.
class SpokenPart {
  const SpokenPart(this.tts, {this.clips = const []});

  final String tts;

  /// CMU phonemes of a sound, e.g. ["HH"] or ["S", "T", "R"].
  final List<String> clips;

  @override
  bool operator ==(Object other) =>
      other is SpokenPart && other.tts == tts && other.clips.join() == clips.join();

  @override
  int get hashCode => Object.hash(tts, clips.join());

  @override
  String toString() => clips.isEmpty ? '"$tts"' : '"$tts" ${clips.join(' ')}';
}

/// How a word is taught (AGENT_SPEC §2).
enum WordType {
  /// A heart word, learned by sight (the, was, said): not sounded out.
  sight,

  /// Follows the phonics rules.
  decodable,

  /// Only part of it follows the rules (through, island).
  tricky,
}

/// One English word from assets/data/phonics.json (made by
/// tools/gen_phonics.py from the CMU Pronouncing Dictionary).
class PhonicsEntry {
  const PhonicsEntry({
    required this.word,
    required this.type,
    required this.graphemes,
    required this.phonemes,
    required this.onset,
    required this.rime,
    required this.rimeSay,
    required this.onsetPhonemes,
    this.keyword,
    this.emoji,
    this.needsReview = false,
  });

  factory PhonicsEntry.fromJson(String word, Map<String, dynamic> j) => PhonicsEntry(
        word: word,
        type: WordType.values.byName(j['type'] as String),
        graphemes: List<String>.from(j['graphemes'] as List),
        phonemes: List<String>.from(j['phonemes'] as List),
        onset: j['onset'] as String,
        rime: j['rime'] as String,
        rimeSay: j['rime_say'] as String,
        onsetPhonemes: List<String>.from(j['onset_phonemes'] as List),
        keyword: j['keyword'] as String?,
        emoji: j['emoji'] as String?,
        needsReview: j['needs_review'] as bool? ?? false,
      );

  final String word;
  final WordType type;

  /// Letters grouped by sound: kite → k, i, t, e(silent).
  final List<String> graphemes;

  /// CMU sounds of the graphemes that are not silent: HH AE D.
  final List<String> phonemes;

  /// The visual split: h · ad, sh · ip, str · ong ("" before a vowel).
  final String onset;
  final String rime;

  /// The rime spelled so text-to-speech says it as a chunk ("ead" in
  /// thread → "ed"); usually the same as [rime].
  final String rimeSay;
  final List<String> onsetPhonemes;

  /// A picture word with the same first sound: hat 🎩, shoe 👟.
  final String? keyword;
  final String? emoji;
  final bool needsReview;
}

/// All English words with their phonics data.
class PhonicsDictionary {
  const PhonicsDictionary(this._words);

  static const empty = PhonicsDictionary({});

  factory PhonicsDictionary.parse(String json) {
    final words = (jsonDecode(json) as Map<String, dynamic>)['words'] as Map<String, dynamic>;
    return PhonicsDictionary({
      for (final e in words.entries)
        e.key: PhonicsEntry.fromJson(e.key, e.value as Map<String, dynamic>),
    });
  }

  final Map<String, PhonicsEntry> _words;

  /// The entry for [word] as printed ("Had," → had), or null.
  PhonicsEntry? operator [](String word) => _words[WordMatcher.normalize(word)];

  Iterable<PhonicsEntry> get entries => _words.values;
  int get length => _words.length;
}
