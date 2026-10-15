import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent.dart';
import '../data/database_providers.dart';
import '../data/db/app_database.dart';
import '../data/repositories/learner_repository.dart';
import '../data/story.dart';
import '../data/story_providers.dart';
import 'current_learner.dart';

/// Minutes of reading a day that fill the "Today's reading" ring.
const dailyGoalMinutes = 10;

/// Stories per new leaf on Buddy (pet growth; Phase 5 adds more).
const storiesPerLeaf = 5;

/// Numbers for the Home screen.
class HomeStats {
  const HomeStats({
    required this.learner,
    required this.streakDays,
    required this.minutesToday,
    required this.storiesRead,
  });

  final Learner learner;
  final int streakDays;
  final int minutesToday;
  final int storiesRead;

  int get storiesToNextLeaf => storiesPerLeaf - storiesRead % storiesPerLeaf;
  double get leafProgress => (storiesRead % storiesPerLeaf) / storiesPerLeaf;
}

/// Days in a row with at least one session, counting back from today (or
/// from yesterday, so the streak isn't lost before today's reading).
int streakDays(Iterable<DateTime> sessionTimes, DateTime now) {
  DateTime day(DateTime t) => DateTime(t.year, t.month, t.day);
  final days = {for (final t in sessionTimes) day(t)};
  var d = day(now);
  if (!days.contains(d)) d = d.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(d)) {
    streak++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return streak;
}

/// "Magandang umaga/tanghali/hapon/gabi" (good morning/noon/afternoon/evening).
String filipinoGreeting(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Magandang umaga,';
  if (h < 13) return 'Magandang tanghali,';
  if (h < 18) return 'Magandang hapon,';
  return 'Magandang gabi,';
}

/// Lets tests fix "now".
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final homeStatsProvider = FutureProvider.autoDispose<HomeStats?>((ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  if (learner == null) return null;
  final now = ref.watch(nowProvider)();
  final sessions = await ref.watch(sessionRepositoryProvider).recent(learner.id);
  final today = DateTime(now.year, now.month, now.day);
  final secondsToday = sessions
      .where((s) => !s.startedAt.isBefore(today))
      .fold<double>(0, (sum, s) => sum + s.readingSeconds);
  return HomeStats(
    learner: learner,
    streakDays: streakDays(sessions.map((s) => s.startedAt), now),
    minutesToday: (secondsToday / 60).floor(),
    storiesRead: sessions.where((s) => s.type == SessionType.story).length,
  );
});

/// One story on the shelf, with the little labels under its cover.
class ShelfItem {
  const ShelfItem({
    required this.story,
    required this.isNew,
    required this.isFavorite,
    this.soundLabel,
  });

  final Story story;
  final bool isNew;
  final bool isFavorite;
  final String? soundLabel; // e.g. "sh": the weak sound it practises most
}

class ShelfData {
  const ShelfData({required this.level, required this.items, required this.reason});
  final int level;
  final List<ShelfItem> items;
  final String reason;
}

/// Buddy's story picks (AGENT_SPEC §9) for the current reader.
final shelfProvider = FutureProvider.autoDispose<ShelfData?>((ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  if (learner == null) return null;
  final stories = await ref.watch(storiesProvider.future);
  final sessionsRepo = ref.watch(sessionRepositoryProvider);
  final mastery =
      await ref.watch(progressRepositoryProvider).loadMastery(learner.id);
  final sessions = await sessionsRepo.recent(learner.id);
  final storySessions = sessions.where((s) => s.type == SessionType.story);
  final readIds = {for (final s in storySessions) s.storyId};

  // Favorite = the story at this level the reader read best before.
  final atLevel = {
    for (final s in stories)
      if (s.level == learner.currentLevel) s.id,
  };
  final best = storySessions.where((s) => atLevel.contains(s.storyId)).toList()
    ..sort((a, b) => b.accuracy.compareTo(a.accuracy));

  final shelf = StorySelector().select(
    stories: stories,
    level: learner.currentLevel,
    languages: learner.languageList,
    mastery: mastery,
    recentStoryIds: [for (final s in sessions) s.storyId],
    favoriteStoryId: best.isEmpty ? null : best.first.storyId,
  );

  final items = [
    for (final p in shelf.picks)
      ShelfItem(
        story: p.story,
        isNew: !readIds.contains(p.story.id),
        isFavorite: p.isFavorite,
        soundLabel: _topSound(p.story, mastery),
      ),
  ];
  final newCount = items.where((i) => i.isNew).length;
  final extras = [
    if (newCount == 1) 'One is new',
    if (newCount > 1 && newCount < items.length) '$newCount are new',
    if (items.any((i) => i.isFavorite)) 'one you loved',
  ];
  final reason = shelf.reason == null
      ? 'These stories are just right for you.'
      : '${shelf.reason}.${extras.isEmpty ? '' : ' ${extras.join(', ')}.'}';
  return ShelfData(level: learner.currentLevel, items: items, reason: reason);
});

/// The kid label of the weak sound a story practises most.
String? _topSound(Story story, SoundMastery mastery) {
  final code = StorySelector.topWeakPattern([story], mastery);
  return code == null ? null : kidPatternLabels[code] ?? code;
}

/// Call after a reading is saved so Home and the shelf show fresh data.
void refreshAfterReading(ProviderContainer c) {
  c.invalidate(homeStatsProvider);
  c.invalidate(shelfProvider);
}
