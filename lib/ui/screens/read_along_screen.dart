import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/agent.dart';
import '../../app/buddy_brain.dart';
import '../../app/feedback_mode.dart';
import '../../app/hint_mode.dart';
import '../../app/reading_controller.dart';
import '../../data/story.dart';
import '../../data/story_providers.dart';
import '../../speech/fake_speech_service.dart';
import '../../speech/hint_voice.dart';
import '../../speech/speech_providers.dart';
import '../../speech/speech_service.dart';
import '../../speech/tts_service.dart';
import '../theme/app_colors.dart';
import '../widgets/buddy.dart';
import '../widgets/buddy_brain_sheet.dart';
import '../widgets/common.dart';
import '../widgets/story_cover.dart';
import '../widgets/story_text.dart';
import '../widgets/svg_art.dart';

/// Screens 5 (read-along), 6 (hint) and 5b (page review). The hint layout
/// replaces the normal one while Buddy is giving a hint on the current
/// word; the review layout replaces it after a page with missed words
/// (read-first mode, the default).
///
/// With [FakeSpeechService]: tap a word = read it correctly (tapping 1–2
/// words ahead skips the ones in between), long-press the yellow word =
/// misread it, wait = hesitation and then hints.
///
/// Hints follow AGENT_SPEC §2: the first word of a page is never timed,
/// a silent mic pauses the timer (Buddy asks the child to read louder),
/// and after the whole-word hint Buddy waits for the child or for the
/// "Next word" button.
class ReadAlongScreen extends ConsumerStatefulWidget {
  const ReadAlongScreen({
    super.key,
    required this.story,
    required this.onFinished,
    this.words,
    this.hintWaitSec,
    this.startHintLevel = 1,
  });

  final Story story;

  /// Only these words (a placement passage); default = the whole story.
  final List<StoryWord>? words;
  final double? hintWaitSec;
  final int startHintLevel;

  /// Called once when every word has a result.
  final void Function(ReadingController controller) onFinished;

  @override
  ConsumerState<ReadAlongScreen> createState() => _ReadAlongScreenState();
}

class _ReadAlongScreenState extends ConsumerState<ReadAlongScreen> {
  late final ReadingController c;
  bool _reported = false;
  (int, int)? _spokenHint; // (word index, level) last read aloud
  bool _saidQuiet = false; // "can't hear you" was said for this quiet spell
  int? _introducedReview; // page whose review Buddy already introduced

  static const quietMessage = "I can't hear you. Try reading a bit louder!";
  static const reviewIntro = "Let's practise these words. Tap one to hear it, then say it!";

  @override
  void initState() {
    super.initState();
    c = ReadingController(
      story: widget.story,
      words: widget.words,
      speech: ref.read(speechServiceProvider(widget.story.language)),
      hintWaitSec: widget.hintWaitSec,
      startHintLevel: widget.startHintLevel,
      autoHints: ref.read(hintModeProvider).value != HintMode.helpOnly,
      reviewAfterPage: ref.read(feedbackModeProvider).value != FeedbackMode.live,
      phonics: ref.read(phonicsProvider).value ?? PhonicsDictionary.empty,
      clock: ref.read(readingClockProvider)(),
    )..addListener(_changed);
    // Start after the first frame: starting the mic updates shared state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) c.start();
    });
  }

  void _changed() {
    if (!mounted) return;
    ref.read(buddyBrainProvider.notifier).showReading(c);
    final hint = c.hint;
    if (hint != null && _spokenHint != (c.currentIndex, hint.level)) {
      _spokenHint = (c.currentIndex, hint.level);
      _speakHint(hint);
    }
    if (c.isQuiet && !_saidQuiet) {
      _say(quietMessage);
    }
    _saidQuiet = c.isQuiet;
    if (c.isReviewing && _introducedReview != c.pageIndex) {
      _introducedReview = c.pageIndex;
      _say(reviewIntro);
    }
    if (c.isFinished && !c.isReviewing && !_reported) {
      _reported = true;
      widget.onFinished(c);
    }
    setState(() {});
  }

  void _speakHint(Hint hint) => speakHint(
        ref.read(ttsServiceProvider),
        c.speech,
        hint,
        language: widget.story.language,
        clips: ref.read(soundClipsProvider),
      );

  void _say(String text) => speakOverMic(ref.read(ttsServiceProvider), c.speech, text,
      language: 'EN');

  /// Review: Buddy says the word, and the mic listens for it.
  void _hear(int i) {
    c.practise(i);
    speakOverMic(ref.read(ttsServiceProvider), c.speech, c.words[i].word,
        language: widget.story.language, slow: true);
  }

  /// Help: the next hint step, or the whole word again after level 3.
  void _help() {
    if (c.help()) return;
    final hint = c.hint;
    if (hint != null && hint.level == 3) _speakHint(hint);
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    c.dispose();
    super.dispose();
  }

  FakeSpeechService? get _fake {
    final s = c.speech;
    return s is FakeSpeechService ? s : null;
  }

  void _tapWord(int i) {
    final fake = _fake;
    if (fake == null || c.isPaused) return;
    final ahead = i - c.currentIndex;
    if (ahead < 0 || ahead > c.config.lookAheadWords) return;
    fake.hear(c.words[i].word);
  }

  void _longPressWord(int i) {
    final fake = _fake;
    if (fake == null || c.isPaused || i != c.currentIndex) return;
    fake.hear(FakeSpeechService.misreadWord);
  }

  WordLook _look(int i) {
    final current = !c.isFinished && i == c.currentIndex;
    // Read first: only a soft "you are here" marker, no right/wrong colors.
    if (c.reviewAfterPage) return current ? WordLook.marker : WordLook.plain;
    return lookFor(c.resultOf(i), isCurrent: current);
  }

  @override
  Widget build(BuildContext context) {
    final page = c.pageIndex;
    final header = ScreenHeader(
      title: widget.story.title,
      onClose: () => Navigator.of(context).maybePop(),
      onTitleLongPress: () => showBuddyBrain(context),
      trailing: HeaderChip(label: '${page + 1} / ${c.pages.length}'),
    );
    final hint = c.hint;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: c.isReviewing
              ? _review(header)
              : hint == null
                  ? _reading(header, page)
                  : _hinting(header, page, hint),
        ),
      ),
    );
  }

  Widget _storyCard(int page, {double fontSize = 27, bool dim = false}) =>
      Opacity(
        opacity: dim ? 0.55 : 1,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: StoryText(
            tokens: c.tokens,
            indexes: c.pages[page],
            lookOf: _look,
            fontSize: fontSize,
            onTapWord: _tapWord,
            onLongPressWord: _longPressWord,
          ),
        ),
      );

  Widget _reading(Widget header, int page) => Column(
        children: [
          header,
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  StoryCover(story: widget.story, height: 150),
                  const SizedBox(height: 12),
                  _storyCard(page),
                  if (!c.reviewAfterPage) ...[
                    const SizedBox(height: 12),
                    const _Legend(),
                  ],
                  if (c.isQuiet) ...[
                    const SizedBox(height: 12),
                    const _BuddySays(quietMessage),
                  ],
                  if (c.micStatus == MicStatus.noPermission ||
                      c.micStatus == MicStatus.unavailable) ...[
                    const SizedBox(height: 12),
                    _MicProblem(c.micStatus),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _RoundButton(
                  label: 'Help',
                  icon: SvgArt.bulb,
                  onTap: c.isPaused ? null : _help,
                ),
                _MicButton(
                  active: !c.isPaused && c.micStatus == MicStatus.listening,
                  label: _micLabel,
                  onTap: c.isPaused
                      ? c.resume
                      : (c.micStatus == MicStatus.noPermission ||
                              c.micStatus == MicStatus.unavailable)
                          ? c.retryMic
                          : c.pause,
                ),
                _RoundButton(
                  label: c.isPaused ? 'Go on' : 'Pause',
                  icon: c.isPaused ? SvgArt.play : SvgArt.pause,
                  onTap: c.isPaused ? c.resume : c.pause,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _hinting(Widget header, int page, Hint hint) {
    final steps = c.tracker.startHintLevel;
    return SingleChildScrollView(
      child: Column(
        children: [
          header,
          const SizedBox(height: 12),
          _storyCard(page, fontSize: 24, dim: true),
          const SizedBox(height: 12),
          _HintCard(hint: hint, onHear: () => _speakHint(hint)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Buddy(size: 70),
              const SizedBox(width: 12),
              Expanded(
                  child: SpeechBubble(c.isQuiet ? quietMessage : _encouragement(hint))),
            ],
          ),
          // Never auto-skip: after the whole word Buddy waits for this tap.
          if (c.canSkipWord) ...[
            const SizedBox(height: 12),
            ChunkyButton(label: 'Next word →', style: ChunkyStyle.sun, onPressed: c.nextWord),
          ],
          const SizedBox(height: 12),
          ChunkyButton(label: '💡 Help', style: ChunkyStyle.ghost, onPressed: _help),
          // Sight words have one hint only, so no steps to show.
          if (!hint.sight) ...[
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Buddy's hint steps",
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink2)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final (n, name) in [(1, 'Sound'), (2, 'Parts'), (3, 'Word')])
                        if (n < hint.level)
                          Pill(n < steps ? '$n · $name' : '✓ $n · $name',
                              background: n < steps ? const Color(0xFFF0F0F0) : AppColors.greenLight,
                              color: n < steps ? const Color(0xFF9AA3B5) : const Color(0xFF1C7A46))
                        else if (n == hint.level)
                          Pill('$n · $name', background: AppColors.sun)
                        else
                          Pill('$n · $name',
                              background: const Color(0xFFF0F0F0),
                              color: const Color(0xFF9AA3B5)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            c.hintFromHelp
                ? 'You asked Buddy for help'
                : 'Hint appeared after ${_secs(c.hintWaitSec)} seconds on this word',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Screen 5b: the page is done; practise its missed words.
  Widget _review(Widget header) {
    final allDone = c.reviewWords.every(c.practised.contains);
    return Column(
      children: [
        header,
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _BuddySays(allDone ? 'Great job! On to the next page.' : reviewIntro),
                const SizedBox(height: 12),
                for (final i in c.reviewWords) ...[
                  _ReviewWord(
                    word: c.words[i].word,
                    done: c.practised.contains(i),
                    listening: c.retryTarget == i,
                    onHear: () => _hear(i),
                    onSay: _fake == null ? null : () => _fake!.hear(c.words[i].word),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 28),
          child: ChunkyButton(
            label: c.reviewingLastPage ? 'All done ✓' : 'Next page →',
            style: allDone ? ChunkyStyle.sun : ChunkyStyle.teal,
            onPressed: c.endReview,
          ),
        ),
      ],
    );
  }

  String get _micLabel {
    if (c.isPaused) return 'Paused';
    return switch (c.micStatus) {
      MicStatus.listening || MicStatus.off => 'Listening',
      MicStatus.starting => 'Getting ready…',
      MicStatus.noPermission => 'Mic is off',
      MicStatus.unavailable => 'Mic not ready',
    };
  }

  String _encouragement(Hint hint) => buddySaysForHint(hint, child: true);

  static String _secs(double s) =>
      s == s.roundToDouble() ? s.toInt().toString() : s.toStringAsFixed(1);
}

/// One missed word on the review screen: hear it, then say it again.
class _ReviewWord extends StatelessWidget {
  const _ReviewWord({
    required this.word,
    required this.done,
    required this.listening,
    required this.onHear,
    this.onSay,
  });

  final String word;
  final bool done;
  final bool listening;
  final VoidCallback onHear;

  /// Tap-to-read only: tapping the word "says" it.
  final VoidCallback? onSay;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: listening && !done ? Border.all(color: AppColors.sun, width: 3) : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onSay,
                    child: Semantics(
                      label: word,
                      excludeSemantics: true,
                      child: Text(word,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  Text(
                    done
                        ? '✓ You said it!'
                        : listening
                            ? 'Say it now…'
                            : 'Tap 🔊, then say it',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: done ? const Color(0xFF1C7A46) : AppColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            AppChip(
              label: '🔊 Hear it',
              background: AppColors.sunLight,
              borderColor: AppColors.sun,
              fontSize: 15,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: onHear,
            ),
          ],
        ),
      );
}

/// Buddy with a speech bubble, e.g. when the mic hears nothing.
class _BuddySays extends StatelessWidget {
  const _BuddySays(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Buddy(size: 60),
          const SizedBox(width: 12),
          Expanded(child: SpeechBubble(text)),
        ],
      );
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.hint, required this.onHear});

  final Hint hint;
  final VoidCallback onHear;

  @override
  Widget build(BuildContext context) {
    const big = TextStyle(fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 2);
    final title = switch (hint.level) {
      _ when hint.sight => 'WE JUST KNOW THIS ONE',
      1 when hint.keyword != null => 'IT STARTS LIKE',
      1 => 'LOOK AT HOW IT STARTS',
      2 => "LET'S BREAK IT UP",
      _ => 'THE WORD IS',
    };
    final spans = <TextSpan>[];
    if (hint.level == 1) {
      final whole = HintLadder.hintFor(hint.word, 3, 'EN').parts.first;
      spans
        ..add(TextSpan(text: hint.parts.first, style: const TextStyle(color: AppColors.coral)))
        ..add(TextSpan(
            text: whole.substring(hint.parts.first.length.clamp(0, whole.length)),
            style: const TextStyle(color: Color(0xFFC9CED8))));
    } else if (hint.level == 2) {
      for (final (i, p) in hint.parts.indexed) {
        if (i > 0) {
          spans.add(const TextSpan(text: ' · ', style: TextStyle(color: Color(0xFFC9CED8))));
        }
        spans.add(TextSpan(
            text: p, style: TextStyle(color: i.isEven ? AppColors.coral : AppColors.teal)));
      }
    } else {
      spans.add(TextSpan(text: hint.parts.first, style: const TextStyle(color: AppColors.teal)));
      if (hint.sight) spans.add(const TextSpan(text: ' ❤️'));
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      border: Border.all(color: AppColors.sun, width: 3),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.65,
                  color: AppColors.ink2)),
          // Level 1: the keyword picture ("hat 🎩"), never a lone sound.
          if (hint.level == 1 && hint.keyword != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(hint.emoji ?? '', style: const TextStyle(fontSize: 44)),
                  const SizedBox(width: 10),
                  Text(hint.keyword!,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(TextSpan(style: big, children: spans)),
            ),
          ),
          AppChip(
            label: '🔊 Hear it again',
            background: AppColors.sunLight,
            borderColor: AppColors.sun,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            onTap: onHear,
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        item(AppColors.green, 'Read'),
        item(AppColors.amber, 'Took a while'),
        item(AppColors.sun, 'Read now'),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final String icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.4 : 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line, width: 3),
                  ),
                  child: SvgIcon(icon, size: icon == SvgArt.bulb ? 30 : 26),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.active, required this.label, required this.onTap});

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$label. Tap to ${active ? 'pause' : 'go on'}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                margin: const EdgeInsets.all(10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.coral : const Color(0xFFCFD5DF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: active ? AppColors.coralLight : const Color(0xFFEEF0F4),
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const SvgIcon(SvgArt.micWhite, size: 40),
              ),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}

/// Shown when Buddy can't hear: what a grown-up can do about it.
class _MicProblem extends StatelessWidget {
  const _MicProblem(this.status);
  final MicStatus status;

  @override
  Widget build(BuildContext context) => AppCard(
        color: AppColors.coralLight,
        flat: true,
        child: Text(
          status == MicStatus.noPermission
              ? "Buddy can't hear you yet. Tap the microphone and choose "
                  "Allow. If nothing happens, a grown-up can turn on the "
                  "microphone for ReadAloud Buddy in the phone's Settings → Apps."
              : "The phone's speech recognizer isn't ready for this "
                  'language. Tap the microphone to try again, or a grown-up '
                  'can switch to "Tap to read" in Settings.',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.4),
        ),
      );
}
