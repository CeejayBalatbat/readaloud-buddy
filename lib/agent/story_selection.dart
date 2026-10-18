import 'dart:math';

import '../data/story.dart';
import 'agent_config.dart';
import 'mastery.dart';
import 'philiri.dart';
import 'prediction.dart';

/// Short, kid-friendly names for sound patterns, used in the shelf reason.
const kidPatternLabels = <String, String>{
  'EN-SV': 'short vowel',
  'EN-SW': 'sight',
  'EN-BL': 'blend',
  'EN-BL3': 'blend',
  'EN-TH': 'th',
  'EN-SH': 'sh',
  'EN-CH': 'ch',
  'EN-NG': 'ng',
  'EN-ING': '-ing',
  'EN-ED': '-ed',
  'EN-VT': 'vowel team',
  'EN-OU': 'ou',
  'EN-RC': 'ar, or, ir',
  'EN-ME': 'magic e',
  'EN-ML': 'long',
  'FIL-CV': 'ba-be-bi-bo-bu',
  'FIL-SW': 'sight',
  'FIL-NG': 'ng',
  'FIL-MGA': 'mga',
  'FIL-DIP': 'ay, aw, oy',
  'FIL-KK': 'kambal-katinig',
  'FIL-AFX': 'panlapi',
  'FIL-ML': 'long',
};

/// Why a book is on the shelf.
enum PickKind {
  /// Predicted Instructional: just right.
  justRight,

  /// Read before and now predicted Independent: an easy re-read.
  readAgain,

  /// Predicted Independent, filling a free slot.
  easy,

  /// Nothing fits yet (a beginning reader): the easiest books.
  challenge,
}

class ShelfPick {
  const ShelfPick({required this.prediction, required this.kind, this.score = 0});

  final BookPrediction prediction;
  final PickKind kind;

  /// Order among the just-right books (weak-sound coverage − recently
  /// read + a little randomness).
  final double score;

  Story get story => prediction.story;
  bool get isFavorite => kind == PickKind.readAgain;
}

class StoryShelf {
  const StoryShelf({
    required this.picks,
    required this.predictions,
    this.focusPattern,
    this.reason,
    this.nothingFits = false,
  });

  final List<ShelfPick> picks;

  /// Every candidate book's prediction, most likely to be read well first
  /// (for Buddy's brain).
  final List<BookPrediction> predictions;

  /// The weak sound these stories practise most, e.g. "EN-SH".
  final String? focusPattern;

  /// One kid-friendly line, e.g. "These stories have more 'sh' words".
  final String? reason;

  /// No book is predicted Instructional or Independent yet.
  final bool nothingFits;
}

/// Story recommendation by prediction (AGENT_SPEC §9).
class StorySelector {
  StorySelector({this.config = const AgentConfig(), Random? random})
      : _random = random ?? Random();

  final AgentConfig config;
  final Random _random;

  static const nothingFitsReason = "Let's read these together. I'll help you!";

  /// Average over the story's words of (1 − mastery) of each word's
  /// patterns. Higher = more practice on weak sounds.
  static double weakSoundCoverage(Story story, SoundMastery mastery) {
    if (story.words.isEmpty) return 0;
    var sum = 0.0;
    for (final w in story.words) {
      if (w.patterns.isEmpty) continue;
      sum += w.patterns.map((p) => 1 - mastery.of(p)).reduce((a, b) => a + b) /
          w.patterns.length;
    }
    return sum / story.words.length;
  }

  /// The shelf for a learner with reading [score] and prediction
  /// correction [bias]. [languages] e.g. ["EN"], ["FIL"] or both.
  /// [recentStoryIds] are the stories of the latest sessions, newest first.
  /// [bestPastAccuracy] is the best accuracy of each story read before.
  StoryShelf select({
    required List<Story> stories,
    required List<String> languages,
    required SoundMastery mastery,
    required double score,
    required double bias,
    required AccuracyPredictor predictor,
    List<String> recentStoryIds = const [],
    Map<String, double> bestPastAccuracy = const {},
    Map<String, String> patternLabels = kidPatternLabels,
  }) {
    final recent = recentStoryIds.take(config.recentSessionsWindow).toSet();
    final predictions = [
      for (final s in stories)
        if (languages.contains(s.language))
          predictor.predict(s, mastery, score: score, bias: bias),
    ]..sort((a, b) => b.accuracy.compareTo(a.accuracy));

    final justRight = [
      for (final p in predictions)
        if (p.band == PhilIriLevel.instructional)
          ShelfPick(
            prediction: p,
            kind: PickKind.justRight,
            score: weakSoundCoverage(p.story, mastery) -
                (recent.contains(p.story.id) ? config.recentlyReadPenalty : 0) +
                _random.nextDouble() * config.maxRandomBonus,
          ),
    ]..sort((a, b) => b.score.compareTo(a.score));
    // Easy books, the ones closest to "just right" first.
    final easy = predictions.where((p) => p.band == PhilIriLevel.independent).toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    final picks = justRight.take(config.instructionalPicks).toList();
    bool picked(Story s) => picks.any((p) => p.story.id == s.id);

    // One easy re-read: read before, now easy, read best before.
    final reRead = easy.where((p) => bestPastAccuracy.containsKey(p.story.id)).toList()
      ..sort((a, b) => bestPastAccuracy[b.story.id]!.compareTo(bestPastAccuracy[a.story.id]!));
    final favorite = reRead.firstOrNull;

    // Free slots: easy books closest to just right, then more just-right ones.
    final slots = config.shelfSize - (favorite == null ? 0 : 1);
    final fill = [
      for (final p in easy)
        if (p.story.id != favorite?.story.id) ShelfPick(prediction: p, kind: PickKind.easy),
      ...justRight.skip(config.instructionalPicks),
    ];
    for (final f in fill) {
      if (picks.length >= slots) break;
      if (!picked(f.story)) picks.add(f);
    }
    if (favorite != null) picks.add(ShelfPick(prediction: favorite, kind: PickKind.readAgain));

    var nothingFits = false;
    if (picks.isEmpty) {
      // A beginning reader: every book is predicted too hard. Offer the
      // easiest few, and Buddy helps.
      nothingFits = true;
      picks.addAll([
        for (final p in predictions.take(config.instructionalPicks))
          ShelfPick(prediction: p, kind: PickKind.challenge),
      ]);
    }

    final focus = _focusPattern(picks, mastery);
    return StoryShelf(
      picks: picks,
      predictions: predictions,
      focusPattern: focus,
      nothingFits: nothingFits,
      reason: nothingFits
          ? nothingFitsReason
          : focus == null
              ? null
              : "These stories have more '${patternLabels[focus] ?? focus}' words",
    );
  }

  /// The pattern with the most weak-sound practice across the picks,
  /// preferring a specific sound over the [AgentConfig.commonPatterns].
  String? _focusPattern(List<ShelfPick> picks, SoundMastery mastery) =>
      topWeakPattern([for (final p in picks) p.story], mastery, config);

  /// The sound pattern that [stories] practise most, weighted by how weak
  /// the learner is at it (1 − mastery per word).
  static String? topWeakPattern(
    List<Story> stories,
    SoundMastery mastery, [
    AgentConfig config = const AgentConfig(),
  ]) {
    final weight = <String, double>{};
    for (final s in stories) {
      for (final w in s.words) {
        for (final code in w.patterns) {
          weight[code] = (weight[code] ?? 0) + 1 - mastery.of(code);
        }
      }
    }
    final specific = weight.entries
        .where((e) => !config.commonPatterns.contains(e.key))
        .toList();
    final pool = specific.isNotEmpty ? specific : weight.entries.toList();
    if (pool.isEmpty) return null;
    return pool.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}
