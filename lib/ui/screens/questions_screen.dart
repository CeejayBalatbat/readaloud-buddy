import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/story.dart';
import '../../speech/speech_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/buddy.dart';
import '../widgets/common.dart';
import '../widgets/svg_art.dart';

/// Screen 7: the story's 3 comprehension questions with picture answers.
/// One try per question (Phil-IRI style); Buddy says if it was right.
class QuestionsScreen extends ConsumerStatefulWidget {
  const QuestionsScreen({
    super.key,
    required this.story,
    required this.onDone,
    this.readAloud = true,
  });

  final Story story;

  /// Called with the number of questions answered correctly.
  final void Function(int correct) onDone;
  final bool readAloud;

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  int _index = 0;
  int _correct = 0;
  int? _picked; // index into _choices

  Question get _q => widget.story.questions[_index];

  /// The answers in a mixed order (the correct one is first in the data),
  /// the same order every time this question is shown.
  late List<AnswerChoice> _choices;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  void _prepare() {
    final seed = _q.id.codeUnits.fold<int>(0, (a, b) => a * 31 + b);
    _choices = [..._q.choices]..shuffle(Random(seed));
    _picked = null;
    if (widget.readAloud) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakQuestion());
    }
  }

  void _speakQuestion() {
    if (!mounted) return;
    ref.read(ttsServiceProvider).speak(_q.question, language: widget.story.language);
  }

  void _pick(int i) {
    if (_picked != null) return;
    setState(() {
      _picked = i;
      if (_choices[i].correct) _correct++;
    });
    if (widget.readAloud) {
      ref.read(ttsServiceProvider).speak(
            _feedback.replaceAll(' 🎉', ''),
            language: widget.story.language,
          );
    }
  }

  void _next() {
    if (_index + 1 >= widget.story.questions.length) {
      widget.onDone(_correct);
      return;
    }
    setState(() {
      _index++;
      _prepare();
    });
  }

  bool get _fil => widget.story.language == 'FIL';

  String get _feedback {
    final right = _choices[_picked!].correct;
    if (_fil) {
      return right ? 'Tama! ${_q.answer}. 🎉' : 'Magaling na subok! Ang sagot ay: ${_q.answer}.';
    }
    return right ? 'Yes! ${_q.answer}. 🎉' : 'Good try! The answer is: ${_q.answer}.';
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.story.questions.length;
    final last = _index + 1 == total;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: Column(
            children: [
              ScreenHeader(
                title: 'Story questions · ${_index + 1} of $total',
                onClose: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 14),
              ProgressBar(value: (_index + 1) / total, color: AppColors.violet),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Semantics(
                              button: true,
                              label: 'Read the question aloud',
                              child: GestureDetector(
                                onTap: _speakQuestion,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: AppColors.sun,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const SvgIcon(SvgArt.speaker, size: 26),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _q.question,
                                style: const TextStyle(
                                    fontSize: 23, fontWeight: FontWeight.w800, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final (i, choice) in _choices.indexed) ...[
                        _AnswerCard(
                          choice: choice,
                          tint: const [AppColors.skyLight, AppColors.sunLight, AppColors.greenLight][i % 3],
                          state: _stateOf(i),
                          onTap: () => _pick(i),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              if (_picked != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Buddy(size: 62),
                    const SizedBox(width: 12),
                    Expanded(child: SpeechBubble(_feedback)),
                  ],
                ),
                const SizedBox(height: 14),
                ChunkyButton(
                  label: last ? 'See how I did →' : 'Next question →',
                  onPressed: _next,
                ),
              ],
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  _AnswerState _stateOf(int i) {
    if (_picked == null) return _AnswerState.open;
    if (_choices[i].correct) return _AnswerState.right;
    if (i == _picked) return _AnswerState.wrong;
    return _AnswerState.closed;
  }
}

enum _AnswerState { open, right, wrong, closed }

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.choice,
    required this.tint,
    required this.state,
    required this.onTap,
  });

  final AnswerChoice choice;
  final Color tint;
  final _AnswerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (border, bg) = switch (state) {
      _AnswerState.right => (AppColors.green, AppColors.greenLight),
      _AnswerState.wrong => (AppColors.coral, AppColors.coralLight),
      _ => (Colors.transparent, AppColors.paper),
    };
    return Semantics(
      button: state == _AnswerState.open,
      label: choice.text,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: state == _AnswerState.open ? onTap : null,
        child: Opacity(
          opacity: state == _AnswerState.closed ? 0.6 : 1,
          child: AppCard(
            color: bg,
            border: Border.all(color: border, width: 3),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(choice.emoji, style: const TextStyle(fontSize: 34)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(choice.text,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                ),
                if (state == _AnswerState.right || state == _AnswerState.wrong)
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: state == _AnswerState.right ? AppColors.green : AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      state == _AnswerState.right ? Icons.check_rounded : Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
