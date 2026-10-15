/// The one result each expected word ends with (AGENT_SPEC §1).
enum WordResult {
  correct,
  hesitated,
  correctAfterHint,
  misread,
  skipped,
  unsure;

  /// Counts toward wordsCorrect.
  bool get countsAsCorrect => this == correct || this == hesitated;

  /// `unsure` words are left out of every total.
  bool get isScored => this != unsure;

  /// Phil-IRI miscues (skips are counted separately).
  bool get isMiscue => this == misread || this == correctAfterHint;

  /// Makes a word "tricky" (§8).
  bool get makesTricky =>
      this == misread || this == skipped || this == correctAfterHint;
}

/// What happened to one expected word in a reading session.
/// Mirrors the `word_events` table in DATA_MODEL.md.
class WordOutcome {
  const WordOutcome({
    required this.position,
    required this.word,
    required this.patterns,
    required this.primaryPattern,
    required this.result,
    this.responseMs = 0,
    this.hintLevel = 0,
  });

  final int position; // 1-based, as in the story
  final String word;
  final List<String> patterns;
  final String primaryPattern;
  final WordResult result;
  final int responseMs; // time since the previous word was finished
  final int hintLevel; // 0–3, highest hint given for this word

  @override
  String toString() => 'WordOutcome($position "$word" ${result.name} '
      '${responseMs}ms hint$hintLevel)';
}
