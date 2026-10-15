import 'package:flutter/material.dart';

import 'buddy_brain_sheet.dart';
import 'svg_art.dart';

/// Buddy the mascot. Long-press opens the hidden "Buddy's brain" panel.
class Buddy extends StatelessWidget {
  const Buddy({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Buddy',
        image: true,
        child: GestureDetector(
          onLongPress: () => showBuddyBrain(context),
          child: SvgIcon(SvgArt.buddy, size: size),
        ),
      );
}
