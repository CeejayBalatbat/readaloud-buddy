import 'package:flutter/material.dart';

import '../../agent/agent.dart';
import '../theme/app_colors.dart';

/// How a word looks in the read-along text (`.w.ok`, `.w.hes`, `.w.now`,
/// `.w.next` in the mockup CSS).
enum WordLook { read, tookAWhile, practice, now, next, plain }

WordLook lookFor(WordResult? result, {required bool isCurrent}) {
  if (isCurrent) return WordLook.now;
  return switch (result) {
    null => WordLook.next,
    WordResult.correct => WordLook.read,
    WordResult.hesitated => WordLook.tookAWhile,
    // Not shown as "wrong" to the child: just marked for practice.
    WordResult.correctAfterHint ||
    WordResult.misread ||
    WordResult.skipped =>
      WordLook.practice,
    WordResult.unsure => WordLook.plain,
  };
}

/// One page of story text with per-word highlights.
class StoryText extends StatelessWidget {
  const StoryText({
    super.key,
    required this.tokens,
    required this.indexes,
    required this.lookOf,
    this.fontSize = 27,
    this.onTapWord,
    this.onLongPressWord,
  });

  /// All words as printed; [indexes] says which ones are on this page.
  final List<String> tokens;
  final List<int> indexes;
  final WordLook Function(int index) lookOf;
  final double fontSize;
  final void Function(int index)? onTapWord;
  final void Function(int index)? onLongPressWord;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: fontSize * 0.26,
        runSpacing: fontSize * 0.45,
        children: [
          for (final i in indexes)
            _Word(
              text: tokens[i],
              look: lookOf(i),
              fontSize: fontSize,
              onTap: onTapWord == null ? null : () => onTapWord!(i),
              onLongPress:
                  onLongPressWord == null ? null : () => onLongPressWord!(i),
            ),
        ],
      );
}

class _Word extends StatelessWidget {
  const _Word({
    required this.text,
    required this.look,
    required this.fontSize,
    this.onTap,
    this.onLongPress,
  });

  final String text;
  final WordLook look;
  final double fontSize;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: look == WordLook.next ? const Color(0xFF9AA3B5) : AppColors.ink,
    );
    final label = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: Text(text, style: style),
    );

    Widget word = switch (look) {
      WordLook.read => _lipped(label, AppColors.greenLight, AppColors.green),
      WordLook.tookAWhile =>
        _lipped(label, AppColors.amberLight, AppColors.amber),
      WordLook.practice =>
        _lipped(label, AppColors.coralLight, AppColors.coral),
      WordLook.now => Container(
          decoration: BoxDecoration(
            color: AppColors.sun,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: AppColors.sun, spreadRadius: 5),
              BoxShadow(color: Colors.white, spreadRadius: 3),
            ],
          ),
          child: label,
        ),
      WordLook.next || WordLook.plain => label,
    };

    if (onTap != null || onLongPress != null) {
      word = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: word,
      );
    }
    return Semantics(label: text, child: ExcludeSemantics(child: word));
  }

  /// Soft background with a 3px coloured edge at the bottom (the CSS
  /// `inset 0 -3px 0` shadow).
  Widget _lipped(Widget child, Color bg, Color edge) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: bg,
          child: Stack(
            children: [
              child,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 3,
                child: ColoredBox(color: edge),
              ),
            ],
          ),
        ),
      );
}
