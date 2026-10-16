import 'dart:math';

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

/// Buddy with the leaves he has grown (one per few stories read). He gets
/// a little bigger at each growth stage.
class GrowingBuddy extends StatelessWidget {
  const GrowingBuddy({super.key, required this.leaves, required this.stage});

  final int leaves;
  final int stage; // 0–3

  /// Leaves drawn around Buddy; more are shown as a number.
  static const maxShown = 10;

  @override
  Widget build(BuildContext context) {
    final size = 140.0 + stage * 14;
    final box = size + 70;
    final shown = leaves.clamp(0, maxShown);
    return Semantics(
      label: 'Buddy with $leaves ${leaves == 1 ? 'leaf' : 'leaves'}',
      excludeSemantics: true,
      child: SizedBox(
        width: box,
        height: box * 0.86,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Leaves on an arc over Buddy's head, left to right.
            for (var i = 0; i < shown; i++)
              Align(
                alignment: Alignment(
                  -cos(pi * (i + 1) / (shown + 1)) * 0.95,
                  -sin(pi * (i + 1) / (shown + 1)) * 0.95 + 0.1,
                ),
                child: Transform.rotate(
                  angle: (i.isEven ? -0.3 : 0.3),
                  child: const Text('🌿', style: TextStyle(fontSize: 24)),
                ),
              ),
            Align(alignment: const Alignment(0, 0.35), child: Buddy(size: size)),
            if (leaves > maxShown)
              Align(
                alignment: Alignment.topRight,
                child: Text('🌿×$leaves',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }
}
