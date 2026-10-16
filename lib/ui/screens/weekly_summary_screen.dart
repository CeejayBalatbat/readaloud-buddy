import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tricky_words_print.dart';
import '../../app/weekly_summary.dart';
import '../../app/weekly_summary_text.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Screen 11: the parent's weekly summary for the current reader. Reached
/// from Settings, so it is behind the grown-up PIN.
class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key, this.filipino});

  /// Start in Filipino (default: Filipino only for FIL-only readers).
  final bool? filipino;

  @override
  ConsumerState<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  bool? _filipino;

  static const _page = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(weeklySummaryProvider).value;
    final patterns = ref.watch(soundPatternsProvider).value ?? const {};
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: summary == null
            ? const Center(child: CircularProgressIndicator())
            : _body(SummaryText(summary,
                filipino: _filipino ?? widget.filipino ?? false, patterns: patterns)),
      ),
    );
  }

  Widget _body(SummaryText t) {
    final s = t.summary;
    final change = s.wcpmChange;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        Row(
          children: [
            HeaderChip(
                label: '←', semanticLabel: 'Back', onTap: () => Navigator.of(context).maybePop()),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.kicker,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink2)),
                  Text(t.title,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900, height: 1.15)),
                ],
              ),
            ),
            AppChip(
              label: 'EN',
              selected: !t.filipino,
              onTap: () => setState(() => _filipino = false),
            ),
            const SizedBox(width: 6),
            AppChip(
              label: 'FIL',
              selected: t.filipino,
              onTap: () => setState(() => _filipino = true),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _StatTile('${s.minutes}', t.minutesLabel),
            const SizedBox(width: 10),
            _StatTile('${s.stories}', t.storiesLabel),
            const SizedBox(width: 10),
            _StatTile(t.wcpmValue, t.wcpmLabel,
                color: change != null && change >= 0.5 ? AppColors.green : AppColors.ink),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(t.levelTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  Pill(t.levelBadge, background: AppColors.skyLight, color: const Color(0xFF1C6FB0)),
                ],
              ),
              const SizedBox(height: 12),
              ProgressBar(value: s.levelProgress, color: AppColors.sky),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StripeCard(color: AppColors.sun, title: t.celebrateTitle, text: t.celebrate),
        const SizedBox(height: 12),
        _StripeCard(color: AppColors.teal, title: t.tipTitle, text: t.tip),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          child: GestureDetector(
            onTap: s.trickyWords.isEmpty
                ? null
                : () => ref.read(trickyWordsPrinterProvider).print(
                      title: t.sheetTitle,
                      hint: t.sheetHint,
                      words: s.trickyWords,
                    ),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.tealLight, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.print_outlined, color: AppColors.tealDark, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.printTitle,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        Text(t.printSubtitle,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink2)),
                      ],
                    ),
                  ),
                  if (s.trickyWords.isNotEmpty)
                    const Icon(Icons.chevron_right, color: AppColors.teal),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.value, this.label, {this.color = AppColors.ink});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            children: [
              FittedBox(
                child: Text(value,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color)),
              ),
              FittedBox(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink2)),
              ),
            ],
          ),
        ),
      );
}

/// A card with a colored stripe on the left (Celebrate, Try at home).
class _StripeCard extends StatelessWidget {
  const _StripeCard({required this.color, required this.title, required this.text});
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            boxShadow: [BoxShadow(color: AppColors.line, offset: Offset(0, 2))],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 7, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink2)),
                        const SizedBox(height: 6),
                        Text(text,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700, height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
