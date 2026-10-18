import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/agent.dart';
import '../../app/buddy_brain.dart';
import '../../speech/speech_service.dart';
import '../../speech/speech_timing.dart';
import '../theme/app_colors.dart';
import 'svg_art.dart';

/// Opens the hidden "Buddy's brain" debug panel (long-press Buddy).
void showBuddyBrain(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scroll) => BuddyBrainPanel(scrollController: scroll),
    ),
  );
}

/// Shows what the agent perceives and decides, for demos and debugging.
class BuddyBrainPanel extends ConsumerWidget {
  const BuddyBrainPanel({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brain = ref.watch(buddyBrainProvider);
    final insights = ref.watch(learnerInsightsProvider);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            SvgIcon(SvgArt.spark, size: 32),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Buddy's brain",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text('What the agent perceives, believes and decides',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink2)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // While reading, the live word results matter most; afterwards,
        // Buddy's decision does.
        if (brain.reading?.currentIndex != null || brain.last == null) ...[
          _ReadingSection(brain.reading),
          if (brain.last != null) _DecisionSection(brain.last!),
        ] else ...[
          _DecisionSection(brain.last!),
          _ReadingSection(brain.reading),
        ],
        insights.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _Section(
            title: 'Learner model',
            children: [Text('Could not load: $e')],
          ),
          data: (i) => i == null
              ? const _Section(
                  title: 'Learner model',
                  children: [_Muted('No reader set up yet.')],
                )
              : _LearnerSection(i),
        ),
      ],
    );
  }
}

class _ReadingSection extends StatelessWidget {
  const _ReadingSection(this.reading);
  final BrainReading? reading;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    if (r == null) {
      return const _Section(
        title: 'Percepts · word results (§1)',
        children: [_Muted('Nothing read yet in this session.')],
      );
    }
    final counts = <WordResult, int>{};
    for (final o in r.outcomes) {
      counts[o.result] = (counts[o.result] ?? 0) + 1;
    }
    final live = SessionScores.fromResults(
      r.outcomes,
      readingSeconds: r.readingSeconds,
      questionsCorrect: 0,
    );
    final wordLevel = const PhilIriClassifier().wordLevel(live.accuracy);
    return _Section(
      title: 'Percepts · word results (§1)',
      subtitle: '${r.title} · ${r.outcomes.length} of ${r.tokens.length} words'
          '${r.currentIndex != null ? ' · now on "${r.tokens[r.currentIndex!]}"' : ''}'
          '${r.hintLevel > 0 ? ' · hint level ${r.hintLevel}' : ''}',
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (i, o) in r.outcomes.indexed)
              _ResultChip(word: r.tokens[i], result: o.result, hint: o.hintLevel),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final res in WordResult.values)
              _Stat('${_resultName(res)}: ${counts[res] ?? 0}', _resultColor(res)),
          ],
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 6),
        _KeyValue('Hearing', r.tapMode
            ? 'Tap to read (no microphone)${r.speech.notice != null ? ': offline listening is off' : ''}'
            : '${switch (r.speech.status) {
                MicStatus.listening => 'listening',
                MicStatus.starting => 'starting',
                MicStatus.off => 'off',
                MicStatus.noPermission => 'no mic permission',
                MicStatus.unavailable => 'recognizer not available',
              }} · Vosk offline, page words only'),
        if (!r.tapMode) ...[
          _KeyValue('Recognizer heard', r.speech.transcript.isEmpty ? '…' : '"${r.speech.transcript}"'),
          ..._speed(r.speech.speed),
          if (r.speech.lastError != null) _KeyValue('Last recognizer message', r.speech.lastError!),
        ],
        _KeyValue('Accuracy so far (§3)',
            '${_pct(live.accuracy)}  (${live.wordsCorrect}/${live.wordsTotal}, unsure excluded)'),
        _KeyValue('Words correct per minute', live.wcpm.toStringAsFixed(1)),
        _KeyValue('Word level so far (§4)', wordLevel.label),
      ],
    );
  }
}

/// The speed meter: how long from the child's voice to the screen.
List<Widget> _speed(SpeedSummary? s) {
  String v(int? ms) => ms == null ? '?' : '$ms ms';
  const build = kReleaseMode
      ? 'release'
      : kProfileMode
          ? 'profile'
          : 'debug (screen is slower; try flutter run --release)';
  return [
    const _KeyValue('App build', build),
    if (s == null || s.words == 0)
      const _KeyValue('Speed', 'read a few words to measure')
    else ...[
      _KeyValue('Speed, said → on screen (median of ${s.words} words)',
          '${v(s.totalMs)} = recognizer ${v(s.recognizerMs)} + settling '
          '${v(s.settlingMs)} + screen ${v(s.screenMs)}'),
      if (s.last != null) _KeyValue('Last word', s.last!),
    ],
  ];
}

class _DecisionSection extends StatelessWidget {
  const _DecisionSection(this.d);
  final BrainDecision d;

  @override
  Widget build(BuildContext context) {
    final dec = d.decision;
    return _Section(
      title: d.isPlacement
          ? 'Last placement passage (§6)'
          : 'Last story decision (§3–§5)',
      subtitle: d.title,
      children: [
        _KeyValue('Accuracy', _pct(d.scores.accuracy)),
        _KeyValue('WCPM', d.scores.wcpm.toStringAsFixed(1)),
        if (!d.isPlacement)
          _KeyValue('Comprehension',
              '${d.scores.questionsCorrect}/${d.scores.questionsTotal} (${_pct(d.scores.comprehension)})'),
        _KeyValue('Phil-IRI word level', d.philiri.word.label),
        if (!d.isPlacement)
          _KeyValue('Phil-IRI comprehension', d.philiri.comprehension.label),
        _KeyValue('Phil-IRI overall', d.philiri.overall.label, strong: true),
        if (dec != null) ...[
          _KeyValue(
            'Level decision',
            '${dec.move.name.toUpperCase()}  (level ${dec.levelBefore} → ${dec.levelAfter})',
            strong: true,
          ),
          _KeyValue('Results counted at this level',
              d.resultsAtLevel.isEmpty ? '(reset after level change)' : d.resultsAtLevel.map((l) => l.label).join(', ')),
        ],
        if (d.plan != null) _KeyValue("Buddy's plan (shown to child)", d.plan!),
        if (d.newTrickyWords.isNotEmpty)
          _KeyValue('New tricky words (§8)', d.newTrickyWords.join(', ')),
        if (d.flags.isNotEmpty) _KeyValue('Teacher flag (§10)', d.flags.join('; ')),
      ],
    );
  }
}

class _LearnerSection extends StatelessWidget {
  const _LearnerSection(this.i);
  final LearnerInsights i;

  @override
  Widget build(BuildContext context) {
    final weak = i.weakestSounds.take(6).toList();
    final h = i.hintStats;
    return Column(
      children: [
        _Section(
          title: 'Learner model · ${i.learner.nickname}',
          children: [
            _KeyValue('Current level', '${i.levelState.level}'),
            _KeyValue(
              'Streak since last level change (§5)',
              i.levelState.resultsAtLevel.isEmpty
                  ? 'none yet'
                  : i.levelState.resultsAtLevel.map((l) => l.label).join(' → '),
            ),
            _KeyValue('Hint wait', '${i.learner.hintWaitSec ?? (i.learner.dyslexiaMode ? 8 : 5)} s'),
          ],
        ),
        _Section(
          title: 'Weakest sounds (§7, BKT mastery)',
          children: [
            if (weak.isEmpty) const _Muted('No sounds practised yet.'),
            for (final e in weak) _MasteryRow(code: e.key, m: e.value, obs: i.mastery.observationsOf(e.key)),
          ],
        ),
        _Section(
          title: 'Hint learning (§2)',
          children: [
            for (final level in [1, 2, 3])
              _KeyValue(
                'Level $level hints',
                h.uses(level) == 0
                    ? 'not used yet'
                    : '${h.successes(level)}/${h.uses(level)} worked (${_pct(h.successRate(level))})',
              ),
            _KeyValue('Starts at hint level', '${h.startLevel()}', strong: true),
          ],
        ),
        _Section(
          title: 'Tricky words (§8) and teacher flags (§10)',
          children: [
            _KeyValue('Tricky words',
                i.trickyWords.isEmpty ? 'none' : i.trickyWords.join(', ')),
            _KeyValue('Teacher flags',
                i.flags.isEmpty ? 'none' : i.flags.join('; ')),
          ],
        ),
      ],
    );
  }
}

class _MasteryRow extends StatelessWidget {
  const _MasteryRow({required this.code, required this.m, required this.obs});
  final String code;
  final double m;
  final int obs;

  @override
  Widget build(BuildContext context) {
    final status = SoundMastery.statusFor(m);
    final color = switch (status) {
      MasteryStatus.mastered => AppColors.green,
      MasteryStatus.learning => AppColors.amber,
      MasteryStatus.needsHelp => AppColors.coral,
    };
    final label = kidPatternLabels[code] ?? code;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text('$code\n"$label"',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(
                value: m,
                minHeight: 10,
                color: color,
                backgroundColor: const Color(0xFFECE6DA),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Text(
              '${m.toStringAsFixed(2)} · ${switch (status) {
                MasteryStatus.mastered => 'Mastered',
                MasteryStatus.learning => 'Learning',
                MasteryStatus.needsHelp => 'Needs help',
              }}\n$obs reads',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.subtitle, required this.children});
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.violetLight, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.violet)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2)),
            ],
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.k, this.v, {this.strong = false});
  final String k;
  final String v;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2)),
            ),
            Expanded(
              flex: 6,
              child: Text(v,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
                      color: strong ? AppColors.violet : AppColors.ink)),
            ),
          ],
        ),
      );
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2));
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.word, required this.result, required this.hint});
  final String word;
  final WordResult result;
  final int hint;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _resultColor(result).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _resultColor(result), width: 1.5),
        ),
        child: Text(
          '$word · ${_resultName(result)}${hint > 0 ? ' (h$hint)' : ''}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      );
}

String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

String _resultName(WordResult r) => switch (r) {
      WordResult.correct => 'correct',
      WordResult.hesitated => 'hesitated',
      WordResult.correctAfterHint => 'after hint',
      WordResult.misread => 'misread',
      WordResult.skipped => 'skipped',
      WordResult.unsure => 'unsure',
    };

Color _resultColor(WordResult r) => switch (r) {
      WordResult.correct => AppColors.green,
      WordResult.hesitated => AppColors.amber,
      WordResult.correctAfterHint => AppColors.violet,
      WordResult.misread => AppColors.coral,
      WordResult.skipped => AppColors.coral,
      WordResult.unsure => AppColors.ink2,
    };
