import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/current_learner.dart';
import '../../app/home_data.dart';
import '../../data/database_providers.dart';
import '../../data/db/app_database.dart';
import '../story_flow.dart';
import '../theme/app_colors.dart';
import '../widgets/buddy.dart';
import '../widgets/buddy_brain_sheet.dart';
import '../widgets/common.dart';
import '../widgets/story_cover.dart';
import '../widgets/svg_art.dart';
import 'setup_screen.dart';

/// The child's main screen with the bottom tabs: Home (s03), Stories
/// (s04), Games and Settings (Phase 5).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final body = switch (_tab) {
      0 => HomeTab(onRead: () => setState(() => _tab = 1)),
      1 => const ShelfTab(),
      2 => const _ComingSoon(
          title: 'Word games',
          text: 'Games with your tricky words are coming soon!'),
      _ => const SettingsTab(),
    };
    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: _TabBar(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onTap});

  final int current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Home', SvgArt.home),
      ('Stories', SvgArt.book),
      ('Games', SvgArt.puzzle),
      ('Settings', SvgArt.gear),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (final (i, (label, icon)) in tabs.indexed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == current,
                    label: label,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgIcon(icon(i == current ? '#1F9E8F' : '#5B6680'), size: 26),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: i == current ? AppColors.teal : AppColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen 3: greeting, stars and streak, Buddy growing, today's minutes,
/// and the big Read! button.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, required this.onRead});

  final VoidCallback onRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(homeStatsProvider).value;
    if (stats == null) return const Center(child: CircularProgressIndicator());
    final now = ref.watch(nowProvider)();
    final mins = stats.minutesToday;
    final ringText = switch (mins) {
      0 => "Let's read today!",
      _ when mins >= dailyGoalMinutes => 'You did it today!',
      _ when mins * 2 >= dailyGoalMinutes => '$mins of $dailyGoalMinutes minutes. Almost there!',
      _ => '$mins of $dailyGoalMinutes minutes. Keep going!',
    };
    final leafText = stats.storiesToNextLeaf == 1
        ? '1 more story until Buddy gets a new leaf'
        : '${stats.storiesToNextLeaf} more stories until Buddy gets a new leaf';
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(filipinoGreeting(now),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink2)),
                  Text('${stats.learner.nickname}!',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.15)),
                ],
              ),
            ),
            AppChip(
              label: '⭐ ${stats.learner.stars}',
              background: AppColors.sunLight,
              borderColor: AppColors.sun,
            ),
            const SizedBox(width: 8),
            AppChip(
              label: '🔥 ${stats.streakDays} ${stats.streakDays == 1 ? 'day' : 'days'}',
              background: AppColors.coralLight,
              borderColor: AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE6F6F3), Colors.white],
            ),
            boxShadow: const [BoxShadow(color: AppColors.line, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              const Buddy(size: 170),
              const SizedBox(height: 6),
              const Text('Buddy is growing!',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(leafText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2)),
              const SizedBox(height: 10),
              ProgressBar(value: stats.leafProgress, color: AppColors.teal),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Row(
            children: [
              _MinutesRing(minutes: mins, goal: dailyGoalMinutes),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's reading",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(ringText,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ChunkyButton(
          label: '📖 Read!',
          style: ChunkyStyle.sun,
          fontSize: 26,
          padding: const EdgeInsets.all(20),
          onPressed: onRead,
        ),
      ],
    );
  }
}

class _MinutesRing extends StatelessWidget {
  const _MinutesRing({required this.minutes, required this.goal});
  final int minutes;
  final int goal;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 64,
        height: 64,
        child: CustomPaint(
          painter: _RingPainter(min(minutes / goal, 1.0)),
          child: Center(
            child: Text('$minutes/$goal',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 26);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, stroke..color = const Color(0xFFECE6DA));
    if (value > 0) {
      canvas.drawArc(rect, -pi / 2, 2 * pi * value, false, stroke..color = AppColors.sun);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

/// Screen 4: Buddy's story picks for this reader (AGENT_SPEC §9).
class ShelfTab extends ConsumerWidget {
  const ShelfTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelf = ref.watch(shelfProvider).value;
    if (shelf == null) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Pick a story',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            Pill('Level ${shelf.level} · Just right',
                background: AppColors.skyLight, color: const Color(0xFF1F6FAE)),
          ],
        ),
        const SizedBox(height: 12),
        AgentCard(
          tag: 'Buddy picked these',
          onLongPress: () => showBuddyBrain(context),
          child: Text(shelf.reason),
        ),
        const SizedBox(height: 12),
        if (shelf.items.isEmpty)
          const AppCard(child: Text('No stories at this level yet.'))
        else
          // 2 × 2 covers; cards in a row share the taller card's height.
          for (var i = 0; i < shelf.items.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _StoryCard(item: shelf.items[i])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: i + 1 < shelf.items.length
                          ? _StoryCard(item: shelf.items[i + 1])
                          : const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.item});
  final ShelfItem item;

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[
      if (item.isNew) const Pill('New', background: AppColors.violetLight, color: AppColors.violet),
      if (item.story.language == 'FIL')
        const Pill('Filipino', background: AppColors.tealLight, color: AppColors.tealDark),
      if (item.soundLabel != null) Pill(item.soundLabel!, background: AppColors.sunLight),
      if (item.isFavorite) const Pill('★ Read again', background: Color(0xFFF1F1F1)),
    ].take(2).toList();
    return Semantics(
      button: true,
      label: item.story.title,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => startStory(context, item.story),
        child: AppCard(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StoryCover(story: item.story),
              const SizedBox(height: 8),
              Text(item.story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.2)),
              const SizedBox(height: 4),
              Wrap(spacing: 8, runSpacing: 4, children: pills),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings tab for now: readers on this phone. The full "Reading
/// comfort" screen (s10) comes in Phase 5.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentLearnerProvider).value;
    final readers = ref.watch(allLearnersProvider).value ?? const <Learner>[];
    return ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          children: [
            const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Readers on this phone',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                      AppChip(
                        label: '+ Add',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (ctx) => SetupScreen(
                            onCreated: (l) => afterSetup(ctx, l),
                          ),
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final r in readers)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: 56,
                      title: Text(r.nickname,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      subtitle: Text('Level ${r.currentLevel} · ⭐ ${r.stars}'),
                      trailing: r.id == current?.id
                          ? const Pill('Reading now', background: AppColors.tealLight, color: AppColors.tealDark)
                          : TextButton(
                              onPressed: () =>
                                  ref.read(currentLearnerProvider.notifier).select(r.id),
                              child: const Text('Switch'),
                            ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const AppCard(
              child: Text(
                'Reading comfort (dyslexia mode, text size, hint wait time) '
                'and the parent PIN are coming in a later update.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2),
              ),
            ),
          ],
        );
  }
}

/// Every reader on this phone, kept up to date by the database.
final allLearnersProvider = StreamProvider.autoDispose<List<Learner>>(
  (ref) => ref.watch(learnerRepositoryProvider).watchAll(),
);

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Buddy(size: 110),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink2)),
            ],
          ),
        ),
      );
}

/// What happens after a reader is set up. Step 4 adds the reading check
/// here; for now the new reader goes straight to Home at level 1.
void afterSetup(BuildContext context, Learner learner) {
  final nav = Navigator.of(context);
  if (nav.canPop()) nav.pop();
}
