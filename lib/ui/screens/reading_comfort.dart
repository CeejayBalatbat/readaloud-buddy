import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/current_learner.dart';
import '../../data/database_providers.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/learner_repository.dart';
import '../theme/app_colors.dart';
import '../theme/reading_style.dart';
import '../widgets/common.dart';
import '../widgets/story_text.dart';

/// Screen 10 "Reading comfort": a live preview and the current reader's
/// comfort settings (dyslexia mode, text size, contrast, read aloud, hint
/// wait). Saved on the reader, so each child on the phone has their own.
class ReadingComfortCards extends ConsumerWidget {
  const ReadingComfortCards({super.key});

  static const previewText = 'The kite went up, up, up!';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learner = ref.watch(currentLearnerProvider).value;
    if (learner == null) return const SizedBox.shrink();
    final style = ReadingStyle.of(learner);

    Future<void> save(Learner updated) async {
      await ref.read(learnerRepositoryProvider).update(updated);
      await ref.read(currentLearnerProvider.notifier).reload();
    }

    final scaleIndex = _nearest(textScales, learner.textScale);
    final wait = learner.hintWait();
    final tokens = previewText.split(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: style.highContrast ? style.page : AppColors.sunLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: style.highContrast ? Colors.black : AppColors.sun, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preview · ${learner.nickname}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink2)),
              const SizedBox(height: 10),
              StoryText(
                tokens: tokens,
                indexes: [for (var i = 0; i < tokens.length; i++) i],
                lookOf: (_) => WordLook.plain,
                fontSize: 26,
                style: style,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SwitchRow(
                title: 'Dyslexia-friendly mode',
                subtitle: 'Easier font, wider spacing, cream page',
                value: learner.dyslexiaMode,
                onChanged: (v) => save(learner.copyWith(dyslexiaMode: v)),
              ),
              const SizedBox(height: 8),
              _SliderRow(
                title: 'Text size',
                valueLabel: textScaleNames[scaleIndex],
                value: scaleIndex.toDouble(),
                max: (textScales.length - 1).toDouble(),
                divisions: textScales.length - 1,
                semantic: 'Text size',
                onChanged: (v) => save(learner.copyWith(textScale: textScales[v.round()])),
              ),
              _SwitchRow(
                title: 'High contrast',
                value: learner.highContrast,
                onChanged: (v) => save(learner.copyWith(highContrast: v)),
              ),
              _SwitchRow(
                title: 'Read instructions aloud',
                value: learner.readAloud,
                onChanged: (v) => save(learner.copyWith(readAloud: v)),
              ),
              const SizedBox(height: 8),
              _SliderRow(
                title: 'Wait before a hint',
                subtitle: learner.hintWaitSec == null
                    ? 'Automatic (longer in dyslexia mode)'
                    : 'More time for kids who need it',
                valueLabel: '${wait.round()} sec',
                value: wait.clamp(3, 12).toDouble(),
                min: 3,
                max: 12,
                divisions: 9,
                semantic: 'Wait before a hint',
                onChanged: (v) =>
                    save(learner.copyWith(hintWaitSec: Value(v.roundToDouble()))),
              ),
              if (learner.hintWaitSec != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => save(learner.copyWith(hintWaitSec: const Value(null))),
                    child: const Text('Use automatic'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static int _nearest(List<double> values, double v) {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if ((values[i] - v).abs() < (values[best] - v).abs()) best = i;
    }
    return best;
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.teal,
              ),
            ],
          ),
        ),
      );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.title,
    this.subtitle,
    required this.valueLabel,
    required this.value,
    this.min = 0,
    required this.max,
    required this.divisions,
    required this.semantic,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String semantic;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2)),
                  ],
                ),
              ),
              Text(valueLabel,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink2)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            semanticFormatterCallback: (_) => '$semantic: $valueLabel',
            activeColor: AppColors.teal,
            inactiveColor: AppColors.line,
            onChanged: onChanged,
          ),
        ],
      );
}
