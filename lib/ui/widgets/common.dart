import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'svg_art.dart';

/// Small building blocks shared by the child screens. Sizes and colours
/// follow the CSS classes in docs/mockups/screens_source.html.

/// `.card`: white, 20px corners, a 2px "line" edge underneath.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.paper,
    this.border,
    this.flat = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final BoxBorder? border;
  final bool flat;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: border,
          boxShadow: flat
              ? null
              : const [BoxShadow(color: AppColors.line, offset: Offset(0, 2))],
        ),
        child: child,
      );
}

enum ChunkyStyle { teal, sun, ghost }

/// `.btn`: big rounded button with a darker bottom edge. At least 56dp tall.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = ChunkyStyle.teal,
    this.fontSize = 20,
    this.padding = const EdgeInsets.all(16),
  });

  final String label;
  final VoidCallback? onPressed;
  final ChunkyStyle style;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (bg, fg, edge) = switch (widget.style) {
      ChunkyStyle.teal => (AppColors.teal, Colors.white, AppColors.tealDark),
      ChunkyStyle.sun => (AppColors.sun, AppColors.ink, AppColors.sunDark),
      ChunkyStyle.ghost => (Colors.white, AppColors.tealDark, AppColors.line),
    };
    final edgeHeight = widget.style == ChunkyStyle.ghost ? 4.0 : 5.0;
    final pressed = _down && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            margin: EdgeInsets.only(top: pressed ? edgeHeight : 0),
            constraints: const BoxConstraints(minHeight: 56),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: widget.style == ChunkyStyle.ghost
                  ? Border.all(color: AppColors.line, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(color: edge, offset: Offset(0, pressed ? 0 : edgeHeight)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.chip`: white pill with a 2px border; `selected` = teal `.chip.on`.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.background,
    this.borderColor,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? background;
  final Color? borderColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: selected ? AppColors.teal : (background ?? Colors.white),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.teal : (borderColor ?? AppColors.line),
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AppColors.ink,
        ),
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

/// `.pill`: small coloured label.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.background, this.color = AppColors.ink});

  final String label;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          softWrap: false,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
        ),
      );
}

/// `.agent`: the violet card for anything Buddy decides or explains.
class AgentCard extends StatelessWidget {
  const AgentCard({super.key, required this.tag, required this.child, this.onLongPress});

  final String tag;
  final Widget child;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.violetLight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SvgIcon(SvgArt.spark, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.66,
                        color: AppColors.violet,
                      ),
                    ),
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.4,
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// `.bubble`: white speech bubble next to Buddy.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: AppColors.line, offset: Offset(0, 2))],
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
        ),
      );
}

/// `.bar`: rounded progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color = AppColors.green});

  final double value; // 0–1
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 12,
          child: Stack(
            children: [
              Container(color: const Color(0xFFECE6DA)),
              FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// The round ✕ / "3 / 6" chips in screen headers.
class HeaderChip extends StatelessWidget {
  const HeaderChip({super.key, required this.label, this.onTap, this.semanticLabel});

  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.line, width: 2),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
}

/// Header row used by the reading screens: ✕ · title · right chip.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onClose,
    this.trailing,
    this.onTitleLongPress,
  });

  final String title;
  final VoidCallback? onClose;
  final Widget? trailing;
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          HeaderChip(label: '✕', onTap: onClose, semanticLabel: 'Close'),
          Expanded(
            child: GestureDetector(
              onLongPress: onTitleLongPress,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      );
}
