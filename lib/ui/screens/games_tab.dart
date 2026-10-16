import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/home_data.dart';
import '../theme/app_colors.dart';
import '../widgets/buddy.dart';
import '../widgets/common.dart';
import 'game_screen.dart';

/// The Games tab: "Build the word" with the reader's tricky words.
class GamesTab extends ConsumerWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(gamePlanProvider).value;
    if (plan == null) return const Center(child: CircularProgressIndicator());
    final fromList = plan.words.where((w) => w.fromTrickyList).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        const Text('Games', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              const Text('🧩', style: TextStyle(fontSize: 56)),
              const Text('Build the word',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Listen to a word, then build it with letter tiles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink2)),
              const SizedBox(height: 8),
              Pill(
                fromList > 0
                    ? '$fromList of ${plan.words.length} words from your tricky list'
                    : '${plan.words.length} words with sounds you are learning',
                background: AppColors.tealLight,
                color: AppColors.tealDark,
              ),
              const SizedBox(height: 14),
              if (plan.words.isEmpty)
                const Text('Read a story first, then come back to play!',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))
              else
                ChunkyButton(
                  label: '▶ Play',
                  style: ChunkyStyle.sun,
                  fontSize: 24,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => GameScreen(plan: plan)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AgentCard(tag: 'Why these words?', child: Text(plan.why)),
        const SizedBox(height: 20),
        const Center(child: Buddy(size: 110)),
      ],
    );
  }
}
