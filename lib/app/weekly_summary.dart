import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent.dart';
import '../data/database_providers.dart';
import '../data/db/app_database.dart';
import '../data/repositories/learner_repository.dart';
import 'current_learner.dart';
import 'home_data.dart';

/// Screen 11: one reader's last 7 days, for a parent.
class WeeklySummary {
  const WeeklySummary({
    required this.nickname,
    required this.from,
    required this.to,
    required this.minutes,
    required this.stories,
    required this.wcpm,
    required this.wcpmChange,
    required this.score,
    required this.profile,
    required this.profileProgress,
    required this.scoreChange,
    required this.celebrateWords,
    required this.tipPattern,
    required this.trickyWords,
  });

  final String nickname;

  /// The 7 days: [from] (6 days ago) to [to] (today).
  final DateTime from;
  final DateTime to;
  final int minutes;
  final int stories;

  /// Average words correct per minute this week (null: no stories).
  final double? wcpm;

  /// This week's average minus the 7 days before (null: nothing to compare).
  final double? wcpmChange;

  /// The reading score (0–100) and its CRLA profile (AGENT_SPEC §5).
  final double score;
  final ReadingProfile profile;

  /// 0–1: how far through the profile toward the next one (1 at the top).
  final double profileProgress;

  /// The score now minus at the start of the 7 days (null: no story yet).
  final double? scoreChange;

  /// Within [almostPoints] of the next profile.
  bool get almostNext {
    final next = profile.next;
    return next != null &&
        const ReadingScorer().minScoreOf(next) - score <= almostPoints;
  }

  static const almostPoints = 5;

  /// Words missed before this week and read on their own this week.
  final List<String> celebrateWords;

  /// The sound to practise at home (weakest pattern), or null.
  final String? tipPattern;
  final List<String> trickyWords;

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Builds the summary from the reader's data. [sessions] may be in any
  /// order; [events] are the word events of those sessions.
  static WeeklySummary compute({
    required Learner learner,
    required List<ReadingSession> sessions,
    required List<WordEvent> events,
    required SoundMastery mastery,
    required List<String> trickyWords,
    required DateTime now,
    AgentConfig config = const AgentConfig(),
  }) {
    final today = _day(now);
    final from = today.subtract(const Duration(days: 6));
    final prevFrom = from.subtract(const Duration(days: 7));
    bool inWeek(ReadingSession s) => !s.startedAt.isBefore(from);
    bool inPrev(ReadingSession s) => !s.startedAt.isBefore(prevFrom) && s.startedAt.isBefore(from);

    final week = sessions.where(inWeek).toList();
    final storiesWeek = week.where((s) => s.type == SessionType.story).toList();
    final storiesPrev = sessions.where((s) => inPrev(s) && s.type == SessionType.story).toList();
    double? avg(List<ReadingSession> l) =>
        l.isEmpty ? null : l.fold<double>(0, (a, s) => a + s.wcpm) / l.length;
    final wcpm = avg(storiesWeek);
    final prev = avg(storiesPrev);

    // §5: the score now, and at the start of the 7 days: after the last
    // story before them, else before the first story in them.
    final scorer = ReadingScorer(config);
    final stories = sessions.where((s) => s.type == SessionType.story).toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final before = stories.where((s) => s.startedAt.isBefore(from)).lastOrNull;
    final startScore = before?.scoreAfter ?? storiesWeek.firstOrNull?.scoreBefore;
    final score = learner.readingScore;

    // Celebrate: missed before this week, read on their own this week (and
    // not missed again this week).
    final weekIds = {for (final s in week) s.id};
    final missedBefore = <String>{}, cleanNow = <String>{}, missedNow = <String>{};
    for (final e in events) {
      final w = WordMatcher.normalize(e.word);
      final now = weekIds.contains(e.sessionId);
      if (e.result.makesTricky) {
        (now ? missedNow : missedBefore).add(w);
      } else if (now && e.result.countsAsCorrect) {
        cleanNow.add(w);
      }
    }
    final celebrate = [
      for (final w in cleanNow)
        if (missedBefore.contains(w) && !missedNow.contains(w)) w,
    ]..sort((a, b) => b.length.compareTo(a.length)); // longer words first

    // Tip: the weakest sound the reader has practised, in their language.
    final languages = learner.languageList;
    final practised = mastery.all.keys
        .where((p) => mastery.observationsOf(p) > 0)
        .where((p) => languages.contains(p.split('-').first))
        .toList()
      ..sort((a, b) => mastery.of(a).compareTo(mastery.of(b)));

    return WeeklySummary(
      nickname: learner.nickname,
      from: from,
      to: today,
      minutes: (week.fold<double>(0, (a, s) => a + s.readingSeconds) / 60).round(),
      stories: storiesWeek.length,
      wcpm: wcpm,
      wcpmChange: wcpm != null && prev != null ? wcpm - prev : null,
      score: score,
      profile: scorer.profileOf(score),
      profileProgress: scorer.progressInProfile(score),
      scoreChange: startScore == null ? null : score - startScore,
      celebrateWords: celebrate.take(3).toList(),
      tipPattern: practised.firstOrNull,
      trickyWords: trickyWords,
    );
  }
}

/// The current reader's weekly summary.
final weeklySummaryProvider = FutureProvider.autoDispose<WeeklySummary?>((ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  if (learner == null) return null;
  final sessionsRepo = ref.watch(sessionRepositoryProvider);
  final progress = ref.watch(progressRepositoryProvider);
  final sessions = await sessionsRepo.recent(learner.id);
  final events = <WordEvent>[];
  for (final s in sessions) {
    events.addAll((await sessionsRepo.byId(s.id))?.words ?? const []);
  }
  return WeeklySummary.compute(
    learner: learner,
    sessions: sessions,
    events: events,
    mastery: await progress.loadMastery(learner.id),
    trickyWords: [for (final t in await progress.trickyWordEntries(learner.id)) t.word],
    now: ref.watch(nowProvider)(),
  );
});
