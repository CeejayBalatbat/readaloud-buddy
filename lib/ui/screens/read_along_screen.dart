import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/agent.dart';
import '../../app/buddy_brain.dart';
import '../../app/reading_controller.dart';
import '../../data/story.dart';
import '../../speech/fake_speech_service.dart';
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

/// Screens 5 (read-along) and 6 (hint). The hint layout replaces the
/// normal one while Buddy is giving a hint on the current word.
///
/// With [FakeSpeechService]: tap a word = read it correctly (tapping 1–2
/// words ahead skips the ones in between), long-press the yellow word =
/// misread it, wait = hesitation and then hints.
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

  @override
  void initState() {
    super.initState();
    c = ReadingController(
      story: widget.story,
      words: widget.words,
      speech: ref.read(speechServiceProvider(widget.story.language)),
      hintWaitSec: widget.hintWaitSec,
      startHintLevel: widget.startHintLevel,
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
    if (c.isFinished && !_reported) {
      _reported = true;
      widget.onFinished(c);
    }
    setState(() {});
  }

  void _speakHint(Hint hint) => speakOverMic(
        ref.read(ttsServiceProvider),
        c.speech,
        hint.parts.join(', '),
        language: widget.story.language,
        slow: true,
      );

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

  WordLook _look(int i) =>
      lookFor(c.resultOf(i), isCurrent: !c.isFinished && i == c.currentIndex);

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
          child: hint == null
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
                  const SizedBox(height: 12),
                  const _Legend(),
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
                  onTap: c.isPaused ? null : c.help,
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
              Expanded(child: SpeechBubble(_encouragement(hint))),
            ],
          ),
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

  String get _micLabel {
    if (c.isPaused) return 'Paused';
    return switch (c.micStatus) {
      MicStatus.listening || MicStatus.off => 'Listening',
      MicStatus.starting => 'Getting ready…',
      MicStatus.noPermission => 'Mic is off',
      MicStatus.unavailable => 'Mic not ready',
    };
  }

  String _encouragement(Hint hint) => switch (hint.level) {
        1 => 'It starts with "${hint.parts.first}". Try the whole word!',
        2 => hint.parts.length == 2
            ? 'Say the two parts, then put them together. You can do it!'
            : 'Say each part, then put them together. You can do it!',
        _ => 'This word is "${hint.parts.first}". Say it with me!',
      };

  static String _secs(double s) =>
      s == s.roundToDouble() ? s.toInt().toString() : s.toStringAsFixed(1);
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.hint, required this.onHear});

  final Hint hint;
  final VoidCallback onHear;

  @override
  Widget build(BuildContext context) {
    const big = TextStyle(fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 2);
    final title = switch (hint.level) {
      1 => 'LISTEN TO THE FIRST SOUND',
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(TextSpan(style: big, children: spans)),
            ),
          ),
          AppChip(
            label: '🔊 Hear the sounds',
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
