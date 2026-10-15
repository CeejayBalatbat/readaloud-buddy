import 'dart:math';

import '../data/story.dart';
import 'agent_config.dart';
import 'mastery.dart';

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

class ShelfPick {
  const ShelfPick({
    required this.story,
    required this.score,
    this.isFavorite = false,
  });

  final Story story;
  final double score;
  final bool isFavorite; // the "read again" favorite
}

class StoryShelf {
  const StoryShelf({required this.picks, this.focusPattern, this.reason});

  final List<ShelfPick> picks;

  /// The weak sound these stories practise most, e.g. "EN-SH".
  final String? focusPattern;

  /// One kid-friendly line, e.g. "These stories have more 'sh' words".
  final String? reason;
}

/// Story selection for the story shelf (AGENT_SPEC §9).
class StorySelector {
  StorySelector({this.config = const AgentConfig(), Random? random})
      : _random = random ?? Random();

  final AgentConfig config;
  final Random _random;

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

  /// [languages] e.g. ["EN"], ["FIL"] or ["EN", "FIL"] for "Both".
  /// [recentStoryIds] are the stories of the learner's latest sessions,
  /// newest first. [favoriteStoryId] is a story worth reading again.
  StoryShelf select({
    required List<Story> stories,
    required int level,
    required List<String> languages,
    required SoundMastery mastery,
    List<String> recentStoryIds = const [],
    String? favoriteStoryId,
    Map<String, String> patternLabels = kidPatternLabels,
  }) {
    final recent = recentStoryIds.take(config.recentSessionsWindow).toSet();
    final scored = [
      for (final s in stories)
        if (s.level == level && languages.contains(s.language))
          ShelfPick(
            story: s,
            score: weakSoundCoverage(s, mastery) -
                (recent.contains(s.id) ? config.recentlyReadPenalty : 0) +
                _random.nextDouble() * config.maxRandomBonus,
          ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    var picks = scored.take(config.shelfSize).toList();

    final favorite = favoriteStoryId == null
        ? null
        : stories.where((s) => s.id == favoriteStoryId).firstOrNull;
    if (favorite != null && languages.contains(favorite.language)) {
      final at = picks.indexWhere((p) => p.story.id == favorite.id);
      final fav = ShelfPick(
        story: favorite,
        score: at >= 0 ? picks[at].score : double.negativeInfinity,
        isFavorite: true,
      );
      if (at >= 0) {
        picks[at] = fav;
      } else if (picks.length < config.shelfSize) {
        picks.add(fav);
      } else {
        picks[picks.length - 1] = fav;
      }
    }

    final focus = _focusPattern(picks, mastery);
    return StoryShelf(
      picks: picks,
      focusPattern: focus,
      reason: focus == null
          ? null
          : "These stories have more '${patternLabels[focus] ?? focus}' words",
    );
  }

  /// The pattern with the most weak-sound practice across the picks.
  String? _focusPattern(List<ShelfPick> picks, SoundMastery mastery) {
    final weight = <String, double>{};
    for (final p in picks) {
      for (final w in p.story.words) {
        for (final code in w.patterns) {
          weight[code] = (weight[code] ?? 0) + 1 - mastery.of(code);
        }
      }
    }
    if (weight.isEmpty) return null;
    return weight.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}
