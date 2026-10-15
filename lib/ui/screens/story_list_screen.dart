import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/story.dart';
import '../../data/story_providers.dart';
import '../story_flow.dart';
import '../theme/app_colors.dart';

/// Phase 0 check screen: lists every story so we know the content loads.
/// The real story shelf (screen 4) comes in Phase 3.
class StoryListScreen extends ConsumerWidget {
  const StoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All stories')),
      body: stories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load stories:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _StoryTile(story: list[i]),
        ),
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final isFilipino = story.language == 'FIL';
    final card = Container(
      // Card with the chunky bottom edge from the mockups.
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.line, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(story.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _Chip(
                label: 'Level ${story.level}',
                fg: AppColors.sky,
                bg: AppColors.skyLight,
              ),
              _Chip(
                label: isFilipino ? 'Filipino' : 'English',
                fg: isFilipino ? AppColors.tealDark : AppColors.ink,
                bg: isFilipino ? AppColors.tealLight : AppColors.sunLight,
              ),
              _Chip(
                label: '${story.words.length} words',
                fg: AppColors.ink2,
                bg: AppColors.cream,
              ),
            ],
          ),
        ],
      ),
    );
    return GestureDetector(onTap: () => startStory(context, story), child: card);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
      ),
    );
  }
}
