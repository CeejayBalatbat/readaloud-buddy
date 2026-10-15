import 'package:flutter/material.dart';

import '../../agent/agent.dart';
import '../../app/session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/buddy.dart';
import '../widgets/buddy_brain_sheet.dart';
import '../widgets/common.dart';

/// Screen 8: how the reading went, and Buddy's plan.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.nickname,
    required this.outcome,
    required this.onNextStory,
  });

  final String nickname;
  final StoryOutcome outcome;
  final VoidCallback onNextStory;

  @override
  Widget build(BuildContext context) {
    final sc = outcome.scores;
    final great = outcome.philiri.overall != PhilIriLevel.frustration;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Buddy(size: 110),
                      const SizedBox(height: 6),
                      Text(
                        great ? 'Great reading, $nickname!' : 'Good try, $nickname!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900, height: 1.15),
                      ),
                      const SizedBox(height: 4),
                      _Stars(outcome.stars),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _Tile('${(sc.accuracy * 100).round()}%', 'words right',
                              AppColors.green),
                          const SizedBox(width: 10),
                          _Tile('${sc.wcpm.round()}', 'words a minute', AppColors.sky),
                          const SizedBox(width: 10),
                          _Tile('${sc.questionsCorrect} / ${sc.questionsTotal}',
                              'questions', AppColors.violet),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AgentCard(
                        tag: "Buddy's plan",
                        onLongPress: () => showBuddyBrain(context),
                        child: Text(outcome.plan),
                      ),
                      if (outcome.newTrickyWords.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('New tricky words for your games',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink2)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final w in outcome.newTrickyWords)
                                    AppChip(label: w, fontSize: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 28),
                child: Row(
                  children: [
                    Expanded(
                      child: ChunkyButton(
                        label: '🧩 Word game',
                        style: ChunkyStyle.ghost,
                        fontSize: 17,
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Word games are coming soon!')),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChunkyButton(
                        label: 'Next story →',
                        fontSize: 17,
                        onPressed: onNextStory,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$count of 3 stars',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: i < count ? AppColors.sun : AppColors.line,
                ),
              ),
          ],
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink2)),
              ),
            ],
          ),
        ),
      );
}
