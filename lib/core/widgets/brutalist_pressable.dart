import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class BrutalistPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final BorderRadius? borderRadius;

  const BrutalistPressable({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor = AppTheme.cardSurface,
    this.borderColor = AppTheme.borderSubtle,
    this.borderWidth = 1.0,
    this.shadowColor = const Color(0x0A0F172A),
    this.padding,
    this.margin,
    this.border,
    this.borderRadius,
  });

  @override
  State<BrutalistPressable> createState() => _BrutalistPressableState();
}

class _BrutalistPressableState extends State<BrutalistPressable> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    widget.onTap!();
  }

  void _onTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(12);

    return Container(
      margin: widget.margin,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: effectiveRadius,
              border:
                  widget.border ??
                  Border.all(
                    color: widget.borderColor,
                    width: widget.borderWidth,
                  ),
              boxShadow: const [AppTheme.softShadow],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
