import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/agent.dart';
import '../../app/buddy_brain.dart';
import '../../app/hint_mode.dart';
import '../../app/reading_controller.dart';
import '../../app/session_service.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/learner_repository.dart';
import '../../data/story_providers.dart';
import '../../speech/fake_speech_service.dart';
import '../../speech/fallback_speech_service.dart';
import '../../speech/hint_voice.dart';
import '../../speech/speech_providers.dart';
import '../theme/app_colors.dart';
import '../theme/reading_style.dart';
import '../widgets/buddy.dart';
import '../widgets/common.dart';
import '../widgets/story_text.dart';
import '../widgets/svg_art.dart';

/// Screen 2: the reading check. Up to 3 short passages from books closest
/// to difficulty 15, 40 and 65, stopping at the first Frustration
/// (AGENT_SPEC §6). It sets the starting reading score. No score is shown.
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key, required this.learner, required this.onDone});

  final Learner learner;

  /// Called after the starting score is saved (or the check was closed).
  final VoidCallback onDone;

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  ReadingCheck? _check; // created once the stories are loaded
  ReadingController? _c;
  PlacementPassage? _passage;
  DateTime _startedAt = DateTime.now();
  bool _done = false;
  bool _saving = false;
  (int, int)? _spokenHint;

  /// Which passage this is (1, 2 or 3).
  int get _number => (_check?.passages.length ?? 0) + (_c == null || _c!.isFinished ? 0 : 1);
  String get _language => widget.learner.languageList.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _next());
  }

  Future<void> _next() async {
    final check = _check ??= ReadingCheck(
      stories: await ref.read(storiesProvider.future),
      language: _language,
    );
    final story = check.isDone ? null : check.nextStory;
    final passage = story == null ? null : placementPassage(story);
    if (!mounted) return;
    if (passage == null) return _finish();
    _c?.removeListener(_changed);
    _c?.dispose();
    setState(() {
      _passage = passage;
      _startedAt = DateTime.now();
      _c = ReadingController(
        story: passage.story,
        words: passage.words,
        speech: ref.read(speechServiceProvider(passage.story.language)),
        hintWaitSec: widget.learner.hintWait(),
        startHintLevel: widget.learner.startHintLevel,
        autoHints: ref.read(hintModeProvider).value != HintMode.helpOnly,
        phonics: ref.read(phonicsProvider).value ?? PhonicsDictionary.empty,
        clock: ref.read(readingClockProvider)(),
      )..addListener(_changed);
    });
    await _c!.start();
  }

  void _changed() {
    final c = _c;
    if (!mounted || c == null) return;
    ref.read(buddyBrainProvider.notifier).showReading(c);
    final hint = c.hint;
    if (hint != null && _spokenHint != (c.currentIndex, hint.level)) {
      _spokenHint = (c.currentIndex, hint.level);
      speakHint(ref.read(ttsServiceProvider), c.speech, hint,
          language: _passage!.story.language, clips: ref.read(soundClipsProvider));
    }
    if (c.isFinished && !_saving) _passageDone(c);
    setState(() {});
  }

  Future<void> _passageDone(ReadingController c) async {
    _saving = true;
    final check = _check!;
    final outcome = await ref.read(sessionServiceProvider).savePlacementPassage(
          learner: widget.learner,
          check: check,
          passage: _passage!,
          outcomes: c.outcomes,
          readingSeconds: c.readingSeconds,
          hintAttempts: c.tracker.hintAttempts,
          startedAt: _startedAt,
        );
    final p = outcome.passage;
    final profile = const ReadingScorer().profileOf(check.startScore);
    ref.read(buddyBrainProvider.notifier).showDecision(BrainDecision(
          title: 'Reading check · passage ${check.passages.length} (${p.story.title})',
          scores: outcome.scores,
          philiri: PhilIriResult(p.wordLevel, p.wordLevel, p.wordLevel),
          bookDifficulty: p.story.difficulty,
          evidence: p.evidence,
          plan: check.isDone
              ? 'Check done: starting score ${check.startScore.toStringAsFixed(1)} '
                  '(${profile.label}, ${profile.rank})'
              : p.wordLevel == PhilIriLevel.frustration
                  ? 'Frustration: stop here'
                  : 'Not Frustration: try a harder passage',
          isPlacement: true,
        ));
    _saving = false;
    if (!mounted) return;
    if (check.isDone) {
      await _finish();
    } else {
      await _next();
    }
  }

  Future<void> _finish() async {
    _c?.removeListener(_changed);
    final check = _check;
    if (check != null) {
      await ref.read(sessionServiceProvider).finishPlacement(widget.learner, check);
    }
    if (mounted) setState(() => _done = true);
  }

  /// ✕: stop the check. Passages already read still set the starting
  /// score (the default score if none were read).
  Future<void> _close() async {
    await _finish();
    widget.onDone();
  }

  @override
  void dispose() {
    _c?.removeListener(_changed);
    _c?.dispose();
    super.dispose();
  }

  void _tapWord(int i) {
    final c = _c, s = _c == null ? null : tapToRead(_c!.speech);
    if (c == null || s == null) return;
    final ahead = i - c.currentIndex;
    if (ahead >= 0 && ahead <= c.config.lookAheadWords) s.hear(c.words[i].word);
  }

  void _longPressWord(int i) {
    final c = _c, s = _c == null ? null : tapToRead(_c!.speech);
    if (c == null || s == null || i != c.currentIndex) return;
    s.hear(FakeSpeechService.misreadWord);
  }

  String get _bubble {
    final name = widget.learner.nickname;
    final hint = _c?.hint;
    if (_c?.isQuiet ?? false) return "I can't hear you. Try reading a bit louder!";
    if (hint != null) {
      return buddySaysForHint(hint);
    }
    return switch (_check?.passages.length ?? 0) {
      0 => "Hi $name! Read this to me out loud. I'll find the stories that are just right for you.",
      1 => "Nice! Here's another one.",
      _ => 'Last one! Read it to me.',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _doneView();
    final c = _c;
    final total = _check?.total ?? const AgentConfig().readingCheckTargets.length;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: Column(
            children: [
              ScreenHeader(
                title: 'Reading check · ${_number.clamp(1, total)} of $total',
                onClose: _close,
              ),
              const SizedBox(height: 14),
              ProgressBar(
                value: c == null
                    ? 0
                    : ((_check?.passages.length ?? 0) +
                            (c.isFinished ? 0 : c.outcomes.length / c.words.length)) /
                        total,
                color: AppColors.violet,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Buddy(size: 78),
                          const SizedBox(width: 12),
                          Expanded(child: SpeechBubble(_bubble)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (c != null)
                        AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                          child: StoryText(
                            tokens: c.tokens,
                            indexes: [for (var i = 0; i < c.words.length; i++) i],
                            // No score for the child: only the current word shows.
                            lookOf: (i) => !c.isFinished && i == c.currentIndex
                                ? WordLook.now
                                : WordLook.plain,
                            fontSize: 25,
                            style: ReadingStyle.of(widget.learner),
                            onTapWord: _tapWord,
                            onLongPressWord: _longPressWord,
                          ),
                        ),
                      const SizedBox(height: 14),
                      AgentCard(
                        tag: 'Buddy is checking',
                        child: Text(
                          "Word accuracy sets ${widget.learner.nickname}'s starting "
                          'reading score. No score is shown to the child.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 28),
                child: Column(
                  children: [
                    SvgIcon(SvgArt.wave, size: 200, height: 40),
                    const SizedBox(height: 12),
                    Container(
                      width: 96,
                      height: 96,
                      margin: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.coralLight, spreadRadius: 12)],
                      ),
                      child: const SvgIcon(SvgArt.micWhite, size: 40),
                    ),
                    const Text('Buddy is listening…',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    // After the whole-word hint Buddy waits; never auto-skips.
                    if (c != null && c.canSkipWord) ...[
                      const SizedBox(height: 12),
                      ChunkyButton(
                          label: 'Next word →', style: ChunkyStyle.sun, onPressed: c.nextWord),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doneView() => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 40, 22, 28),
            child: Column(
              children: [
                const Buddy(size: 150),
                const SizedBox(height: 12),
                Text('All done, ${widget.learner.nickname}!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Thank you for reading to me. I found stories that are just right for you!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink2)),
                const Spacer(),
                ChunkyButton(
                  label: "📖 Let's read!",
                  style: ChunkyStyle.sun,
                  fontSize: 24,
                  onPressed: widget.onDone,
                ),
              ],
            ),
          ),
        ),
      );
}
