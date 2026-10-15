import 'word_result.dart';

/// Session scores (AGENT_SPEC §3).
class SessionScores {
  const SessionScores({
    required this.wordsTotal,
    required this.wordsCorrect,
    required this.hesitations,
    required this.miscues,
    required this.skips,
    required this.unsureWords,
    required this.hintsGiven,
    required this.readingSeconds,
    required this.questionsCorrect,
    required this.questionsTotal,
  });

  factory SessionScores.fromResults(
    Iterable<WordOutcome> outcomes, {
    required double readingSeconds,
    required int questionsCorrect,
    int questionsTotal = 3,
  }) {
    var total = 0, correct = 0, hes = 0, mis = 0, skip = 0, unsure = 0;
    var hints = 0;
    for (final o in outcomes) {
      final r = o.result;
      if (o.hintLevel > 0) hints++;
      if (!r.isScored) {
        unsure++;
        continue;
      }
      total++;
      if (r.countsAsCorrect) correct++;
      if (r == WordResult.hesitated) hes++;
      if (r.isMiscue) mis++;
      if (r == WordResult.skipped) skip++;
    }
    return SessionScores(
      wordsTotal: total,
      wordsCorrect: correct,
      hesitations: hes,
      miscues: mis,
      skips: skip,
      unsureWords: unsure,
      hintsGiven: hints,
      readingSeconds: readingSeconds,
      questionsCorrect: questionsCorrect,
      questionsTotal: questionsTotal,
    );
  }

  /// Words excluding `unsure`.
  final int wordsTotal;

  /// `correct` + `hesitated`.
  final int wordsCorrect;
  final int hesitations;

  /// `misread` + `correctAfterHint`.
  final int miscues;
  final int skips;
  final int unsureWords;

  /// Number of words that needed at least one hint.
  final int hintsGiven;
  final double readingSeconds;
  final int questionsCorrect;
  final int questionsTotal;

  double get accuracy => wordsTotal == 0 ? 0 : wordsCorrect / wordsTotal;

  double get wcpm =>
      readingSeconds <= 0 ? 0 : wordsCorrect / (readingSeconds / 60);

  double get comprehension =>
      questionsTotal == 0 ? 0 : questionsCorrect / questionsTotal;
}
