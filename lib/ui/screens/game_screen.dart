import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/agent.dart';
import '../../app/current_learner.dart';
import '../../app/home_data.dart';
import '../../app/session_service.dart';
import '../../data/story_providers.dart';
import '../../speech/speech_providers.dart';
import '../theme/app_colors.dart';
import '../theme/reading_style.dart';
import '../widgets/buddy.dart';
import '../widgets/common.dart';

/// Screen 9 "Build the word": Buddy says a word from the child's tricky
/// list; the child taps (or drags) letter tiles into the slots.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.plan, this.onDone});

  final GamePlan plan;

  /// Called after the game was saved (or closed).
  final VoidCallback? onDone;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  static const instruction = 'Listen, then tap the letters to build the word.';

  int _index = 0;
  late BuildRound _round = _newRound(0);
  final _results = <(GameWord, bool)>[];
  int? _wrongTile;
  Timer? _wrongTimer;
  GameOutcome? _outcome;
  bool _saving = false;

  List<GameWord> get _words => widget.plan.words;

  BuildRound _newRound(int i) => BuildRound(_words[i], WordGame.tiles(_words[i].word));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.plan.learner.readAloud) await _speak(instruction, 'EN');
      _sayWord();
    });
  }

  @override
  void dispose() {
    _wrongTimer?.cancel();
    super.dispose();
  }

  Future<void> _speak(String text, String language) =>
      ref.read(ttsServiceProvider).speak(text, language: language, slow: true);

  /// Buddy says the word being built.
  void _sayWord() {
    final w = _round.target;
    final phonics = ref.read(phonicsProvider).value ?? PhonicsDictionary.empty;
    _speak(w.language == 'FIL' ? w.word : HintLadder.sayWord(w.word, phonics), w.language);
  }

  void _tapTile(int i) {
    if (_round.isDone) return;
    final right = _round.place(i);
    setState(() => _wrongTile = right ? null : i);
    if (!right) {
      _wrongTimer?.cancel();
      _wrongTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _wrongTile = null);
      });
    }
    if (_round.isDone) {
      _results.add((_round.target, _round.isClean));
      _sayWord();
    }
  }

  Future<void> _next() async {
    if (_index + 1 < _words.length) {
      setState(() {
        _index++;
        _round = _newRound(_index);
        _wrongTile = null;
      });
      _sayWord();
    } else {
      await _save();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    final outcome = await ref.read(sessionServiceProvider).finishGame(
          learner: widget.plan.learner,
          results: _results,
        );
    await ref.read(currentLearnerProvider.notifier).reload();
    ref.invalidate(gamePlanProvider);
    ref.invalidate(homeStatsProvider);
    if (mounted) setState(() => _outcome = outcome);
  }

  Future<void> _close() async {
    if (_results.isNotEmpty && _outcome == null) await _save();
    widget.onDone?.call();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(readingStyleProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: _outcome != null ? _done(_outcome!) : _playing(style),
        ),
      ),
    );
  }

  Widget _playing(ReadingStyle style) {
    final round = _round;
    final word = round.target.word;
    final letter = style.text(30).copyWith(fontWeight: FontWeight.w800);
    return Column(
      children: [
        ScreenHeader(
          title: 'Build the word',
          onClose: _close,
          trailing: HeaderChip(label: '${_index + 1} / ${_words.length}'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                AppCard(
                  child: Column(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Hear the word',
                        child: GestureDetector(
                          onTap: _sayWord,
                          child: Container(
                            width: 130,
                            height: 130,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                color: AppColors.sunLight, shape: BoxShape.circle),
                            child: Text(round.isDone ? '✅' : '🔊',
                                style: const TextStyle(fontSize: 56)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppChip(
                        label: '🔊 Listen again',
                        background: AppColors.sunLight,
                        borderColor: AppColors.sun,
                        fontSize: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        onTap: _sayWord,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // The slots: a drop target for dragged tiles.
                DragTarget<int>(
                  onAcceptWithDetails: (d) => _tapTile(d.data),
                  builder: (context, _, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        for (var i = 0; i < word.length; i++)
                          _Slot(
                            letter: i < round.placed.length ? round.placed[i] : null,
                            done: round.isDone,
                            style: letter,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  round.isDone
                      ? (round.isClean ? 'You built "$word"! 🎉' : 'You built "$word"!')
                      : _wrongTile != null
                          ? 'Not that one. Listen again!'
                          : 'Tap the letters to make the word you hear',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink2),
                ),
                const SizedBox(height: 14),
                if (!round.isDone)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < round.tiles.length; i++)
                        if (!round.isUsed(i))
                          _Tile(
                            letter: round.tiles[i],
                            style: letter,
                            wrong: _wrongTile == i,
                            index: i,
                            onTap: () => _tapTile(i),
                          ),
                    ],
                  )
                else
                  ChunkyButton(
                    label: _index + 1 < _words.length ? 'Next word →' : 'Finish ✓',
                    style: ChunkyStyle.sun,
                    onPressed: _next,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AgentCard(tag: 'Why this game?', child: Text(widget.plan.why)),
      ],
    );
  }

  Widget _done(GameOutcome outcome) {
    final built = _results.length;
    return Column(
      children: [
        const Spacer(),
        const Buddy(size: 150),
        const SizedBox(height: 12),
        Text('You built $built ${built == 1 ? 'word' : 'words'}!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (outcome.stars > 0)
          Pill('+${outcome.stars} ⭐ for practising', background: AppColors.sunLight),
        if (outcome.wordsLearned.isNotEmpty) ...[
          const SizedBox(height: 12),
          AgentCard(
            tag: 'Buddy learned',
            child: Text(
                'No longer tricky: ${outcome.wordsLearned.map((w) => '"$w"').join(', ')}. '
                'Built well twice!'),
          ),
        ],
        const Spacer(),
        ChunkyButton(label: 'Done', style: ChunkyStyle.sun, onPressed: _close),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.letter, required this.done, required this.style});
  final String? letter;
  final bool done;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: letter == null ? Colors.transparent : (done ? AppColors.green : AppColors.teal),
          borderRadius: BorderRadius.circular(14),
          border: letter == null ? Border.all(color: const Color(0xFFD6CDBA), width: 3) : null,
        ),
        child: letter == null ? null : Text(letter!, style: style.copyWith(color: Colors.white)),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.letter,
    required this.style,
    required this.wrong,
    required this.index,
    required this.onTap,
  });

  final String letter;
  final TextStyle style;
  final bool wrong;
  final int index;
  final VoidCallback onTap;

  Widget _face({double opacity = 1}) => Opacity(
        opacity: opacity,
        child: Container(
          width: 60,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: wrong ? AppColors.coralLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: wrong ? AppColors.coral : AppColors.line, width: 2),
            boxShadow: const [BoxShadow(color: AppColors.line, offset: Offset(0, 4))],
          ),
          child: Text(letter, style: style),
        ),
      );

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Letter $letter',
        excludeSemantics: true,
        child: Draggable<int>(
          data: index,
          feedback: Material(color: Colors.transparent, child: _face()),
          childWhenDragging: _face(opacity: 0.3),
          child: GestureDetector(onTap: onTap, child: _face()),
        ),
      );
}
