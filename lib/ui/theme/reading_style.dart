import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/current_learner.dart';
import '../../data/db/app_database.dart';
import 'app_colors.dart';

/// Text size steps on the Reading comfort screen (s10).
const textScales = [0.85, 1.0, 1.2, 1.4];
const textScaleNames = ['Small', 'Medium', 'Large', 'Extra large'];

/// How story text looks for one reader (screen 10 "Reading comfort").
@immutable
class ReadingStyle {
  const ReadingStyle({this.dyslexia = false, this.scale = 1.0, this.highContrast = false});

  factory ReadingStyle.of(Learner? learner) => learner == null
      ? const ReadingStyle()
      : ReadingStyle(
          dyslexia: learner.dyslexiaMode,
          scale: learner.textScale,
          highContrast: learner.highContrast,
        );

  /// Dyslexia-friendly mode: Lexend, wider spacing, cream page.
  final bool dyslexia;
  final double scale;
  final bool highContrast;

  String get fontFamily => dyslexia ? 'Lexend' : 'Nunito';
  FontWeight get weight => dyslexia ? FontWeight.w500 : FontWeight.w700;

  /// Extra space between letters, as a share of the font size.
  double get letterSpacing => dyslexia ? 0.06 : 0;

  /// Space between words and between lines, as a share of the font size.
  double get wordGap => dyslexia ? 0.5 : 0.26;
  double get lineGap => dyslexia ? 0.7 : 0.45;

  Color get page => highContrast
      ? const Color(0xFFFFFFFF)
      : dyslexia
          ? const Color(0xFFFFF6DD)
          : AppColors.paper;
  Color get ink => highContrast ? const Color(0xFF000000) : AppColors.ink;

  /// Words not read yet (live mode).
  Color get upcoming => highContrast ? const Color(0xFF3A3A3A) : const Color(0xFF9AA3B5);

  /// A visible frame around the story in high contrast.
  Border? get border =>
      highContrast ? Border.all(color: const Color(0xFF000000), width: 2) : null;

  TextStyle text(double fontSize) => TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize * scale,
        fontWeight: weight,
        letterSpacing: fontSize * scale * letterSpacing,
        color: ink,
      );
}

/// The current reader's style.
final readingStyleProvider = Provider<ReadingStyle>(
  (ref) => ReadingStyle.of(ref.watch(currentLearnerProvider).value),
);
