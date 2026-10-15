import 'package:flutter/material.dart';

import '../../data/story.dart';
import '../theme/app_colors.dart';

/// Simple coloured placeholder cover until we have real story art:
/// sky, sun, a hill and the story's first letter.
class StoryCover extends StatelessWidget {
  const StoryCover({super.key, required this.story, this.height = 116});

  final Story story;
  final double height;

  static const _skies = [
    AppColors.skyLight,
    AppColors.sunLight,
    AppColors.coralLight,
    AppColors.violetLight,
    AppColors.tealLight,
    AppColors.greenLight,
  ];
  static const _hills = [
    Color(0xFF8FD19E),
    Color(0xFF4AA8F0),
    Color(0xFFF7D9A8),
    Color(0xFF9BD5A6),
    Color(0xFF8FD19E),
    Color(0xFFF7D9A8),
  ];
  static const _accents = [
    AppColors.coral,
    AppColors.teal,
    AppColors.violet,
    AppColors.sky,
    AppColors.coral,
    AppColors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    final n = int.tryParse(story.id.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final i = n % _skies.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _CoverPainter(
            sky: _skies[i],
            hill: _hills[i],
            accent: _accents[i],
            sunRight: n.isEven,
          ),
          child: Center(
            child: Container(
              width: height * 0.42,
              height: height * 0.42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _accents[i].withValues(alpha: 0.35), offset: const Offset(0, 3)),
                ],
              ),
              child: Text(
                story.title.characters.first.toUpperCase(),
                style: TextStyle(
                  fontSize: height * 0.24,
                  fontWeight: FontWeight.w900,
                  color: _accents[i],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter({
    required this.sky,
    required this.hill,
    required this.accent,
    required this.sunRight,
  });

  final Color sky;
  final Color hill;
  final Color accent;
  final bool sunRight;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = sky);
    canvas.drawCircle(
      Offset(sunRight ? w * 0.82 : w * 0.18, h * 0.22),
      h * 0.11,
      Paint()..color = AppColors.sun,
    );
    final ground = Path()
      ..moveTo(0, h * 0.83)
      ..quadraticBezierTo(w * 0.25, h * 0.65, w * 0.5, h * 0.78)
      ..quadraticBezierTo(w * 0.75, h * 0.9, w, h * 0.75)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = hill);
  }

  @override
  bool shouldRepaint(_CoverPainter old) =>
      old.sky != sky || old.hill != hill || old.accent != accent;
}
