import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG artwork copied from docs/mockups/screens_source.html, so Buddy and
/// the icons look exactly like the approved design.
abstract final class SvgArt {
  /// Buddy, the owl-like reading friend holding a coral book.
  static const buddy = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
<ellipse cx="50" cy="94" rx="28" ry="4" fill="#000" opacity=".08"/>
<path d="M50 6c4 0 8 4 7 9-3-1-6-1-7 1-1-2-4-2-7-1-1-5 3-9 7-9z" fill="#2FA866"/>
<path d="M50 14C28 14 16 32 16 54c0 22 15 38 34 38s34-16 34-38C84 32 72 14 50 14z" fill="#1F9E8F"/>
<path d="M50 44c-14 0-22 10-22 24 0 13 10 22 22 22s22-9 22-22c0-14-8-24-22-24z" fill="#DDF3EF"/>
<circle cx="36" cy="40" r="13" fill="#fff"/><circle cx="64" cy="40" r="13" fill="#fff"/>
<circle cx="38" cy="42" r="6.5" fill="#26324A"/><circle cx="62" cy="42" r="6.5" fill="#26324A"/>
<circle cx="40" cy="40" r="2.2" fill="#fff"/><circle cx="64" cy="40" r="2.2" fill="#fff"/>
<path d="M45 52l5 6 5-6z" fill="#FFC93C"/>
<rect x="34" y="66" width="32" height="20" rx="3" fill="#FF7A59"/><path d="M50 66v20" stroke="#fff" stroke-width="2"/>
<path d="M38 71h8M38 75h8M54 71h8M54 75h8" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".8"/>
</svg>''';

  static const spark = '''
<svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg"><circle cx="15" cy="15" r="15" fill="#7C6CF2"/><path d="M15 6l2.2 6.3L23.5 15l-6.3 2.2L15 23.5l-2.2-6.3L6.5 15l6.3-2.7z" fill="#fff"/></svg>''';

  static const micWhite = '''
<svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round" xmlns="http://www.w3.org/2000/svg"><rect x="9" y="3" width="6" height="11" rx="3" fill="#fff"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>''';

  static const bulb = '''
<svg viewBox="0 0 24 24" fill="none" stroke="#F2A20C" stroke-width="2.2" stroke-linecap="round" xmlns="http://www.w3.org/2000/svg"><path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2V16h5v-.1c0-.8.4-1.5 1-2A6 6 0 0 0 12 3z" fill="#FFF1C7"/></svg>''';

  static const pause = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><rect x="6" y="5" width="4" height="14" rx="1.5" fill="#26324A"/><rect x="14" y="5" width="4" height="14" rx="1.5" fill="#26324A"/></svg>''';

  static const play = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M8 5.5v13a1 1 0 0 0 1.5.86l10.5-6.5a1 1 0 0 0 0-1.72L9.5 4.64A1 1 0 0 0 8 5.5z" fill="#26324A"/></svg>''';

  static const speaker = '''
<svg viewBox="0 0 24 24" fill="none" stroke="#26324A" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="M4 10v4h4l5 4V6L8 10z" fill="#26324A"/><path d="M16 9a4 4 0 0 1 0 6M18.5 6.5a7.5 7.5 0 0 1 0 11"/></svg>''';

  // Tab icons use currentColor, so we set the colour when drawing them.
  static String home(String color) => '''
<svg viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2.2" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"/></svg>''';

  static String book(String color) => '''
<svg viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2.2" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="M12 6c-2-1.5-5-2-8-1.5v14c3-.5 6 0 8 1.5 2-1.5 5-2 8-1.5v-14c-3-.5-6 0-8 1.5zM12 6v14"/></svg>''';

  static String puzzle(String color) => '''
<svg viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2.2" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="M4 8h4a2 2 0 1 1 4 0h4v4a2 2 0 1 1 0 4v4H4z"/></svg>''';

  static String gear(String color) => '''
<svg viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2.2" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="3.2"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/></svg>''';

  /// Microphone waveform shown while Buddy listens (reading check).
  static String get wave {
    const h = [8, 14, 22, 30, 18, 26, 34, 20, 12, 28, 36, 24, 16, 30, 22, 34, 26, 14, 20, 30, 18, 10, 16, 8, 6];
    final bars = StringBuffer();
    for (var i = 0; i < h.length; i++) {
      final y = 20 - h[i] / 2;
      bars.write('<rect x="${i * 8}" y="$y" width="5" height="${h[i]}" '
          'rx="2.5" fill="#FF7A59" opacity="${(.45 + h[i] / 70).toStringAsFixed(2)}"/>');
    }
    return '<svg viewBox="0 0 200 40" xmlns="http://www.w3.org/2000/svg">$bars</svg>';
  }
}

/// Draws one of the [SvgArt] strings at a fixed size.
class SvgIcon extends StatelessWidget {
  const SvgIcon(this.svg, {super.key, required this.size, this.height});

  final String svg;
  final double size;
  final double? height;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(svg, width: size, height: height ?? size);
}
