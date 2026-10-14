import 'package:flutter/painting.dart';

/// Colors from the approved design (docs/SCREENS.md, docs/mockups/screens_source.html).
/// The `*Light` variants are the soft backgrounds used behind chips and cards.
abstract final class AppColors {
  static const ink = Color(0xFF26324A);
  static const ink2 = Color(0xFF5B6680);
  static const line = Color(0xFFE6E0D4);
  static const cream = Color(0xFFFFF8EC);
  static const paper = Color(0xFFFFFFFF);

  static const teal = Color(0xFF1F9E8F); // primary
  static const tealDark = Color(0xFF167A6E); // button bottom edge
  static const tealLight = Color(0xFFDDF3EF);

  static const sun = Color(0xFFFFC93C); // big "Read!" button, current word
  static const sunDark = Color(0xFFD9A21A);
  static const sunLight = Color(0xFFFFF1C7);

  static const coral = Color(0xFFFF7A59); // mic
  static const coralLight = Color(0xFFFFE3DA);

  static const green = Color(0xFF2FA866); // read correctly
  static const greenLight = Color(0xFFDDF5E7);

  static const amber = Color(0xFFF2A20C); // took a while
  static const amberLight = Color(0xFFFFF0CF);

  static const violet = Color(0xFF7C6CF2); // anything Buddy decides or explains
  static const violetLight = Color(0xFFECE9FF);

  static const sky = Color(0xFF4AA8F0);
  static const skyLight = Color(0xFFE1F1FD);
}
