import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
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
    required this.level,
    required this.levelProgress,
    required this.almostNext,
    required this.topLevel,
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
  final int level;

  /// 0–1: Independent results in a row toward moving up (AGENT_SPEC §5).
  final double levelProgress;

  /// One more Independent story moves the reader up.
  final bool almostNext;
  final bool topLevel;

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
    required LevelState levelState,
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

    // §5: Independent results in a row at this level.
    var streak = 0;
    for (final r in levelState.resultsAtLevel.reversed) {
      if (r != PhilIriLevel.independent) break;
      streak++;
    }
    final top = levelState.level >= config.maxLevel;

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
      level: levelState.level,
      levelProgress: top ? 1 : (streak / config.framesToMoveUp).clamp(0, 1).toDouble(),
      almostNext: !top && streak == config.framesToMoveUp - 1,
      topLevel: top,
      celebrateWords: celebrate.take(3).toList(),
      tipPattern: practised.firstOrNull,
      trickyWords: trickyWords,
    );
  }
}

/// A sound pattern from assets/data/sound_patterns.json.
class SoundPattern {
  const SoundPattern(this.code, this.name, this.examples);
  final String code;
  final String name;
  final List<String> examples;
}

final soundPatternsProvider = FutureProvider<Map<String, SoundPattern>>((ref) async {
  final list = jsonDecode(await rootBundle.loadString('assets/data/sound_patterns.json')) as List;
  return {
    for (final p in list.cast<Map<String, dynamic>>())
      p['code'] as String: SoundPattern(
        p['code'] as String,
        p['name'] as String,
        [for (final e in (p['examples'] as String).split(',')) e.trim()],
      ),
  };
});

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
    levelState: await sessionsRepo.levelState(learner.id),
    trickyWords: [for (final t in await progress.trickyWordEntries(learner.id)) t.word],
    now: ref.watch(nowProvider)(),
  );
});
