import 'package:flutter/material.dart';
import '../theme.dart';

/// The official `projeqta` icon badge.
/// Consists of a royal blue rounded squircle container hosting a 2x2 grid:
/// - Top-left: White rounded square
/// - Top-right: White rounded square
/// - Bottom-left: White rounded square
/// - Bottom-right: Golden yellow circle accent
class ProjeqtaIcon extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;

  const ProjeqtaIcon({
    super.key,
    this.size = 40.0,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? (size * 0.25);
    final double padding = size * 0.22;
    final double innerSize = size - (padding * 2);
    final double gap = innerSize * 0.16;
    final double itemSize = (innerSize - gap) / 2;
    final double itemRadius = itemSize * 0.28;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB), // Official Brand Royal Blue
        borderRadius: BorderRadius.circular(radius),
        boxShadow: boxShadow ??
            const [
              BoxShadow(
                color: Color(0x262563EB),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
      ),
      child: Center(
        child: SizedBox(
          width: innerSize,
          height: innerSize,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row 1: Two white rounded squares
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: itemSize,
                    height: itemSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(itemRadius),
                    ),
                  ),
                  SizedBox(width: gap),
                  Container(
                    width: itemSize,
                    height: itemSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(itemRadius),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              // Row 2: One white rounded square and one yellow dot
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: itemSize,
                    height: itemSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(itemRadius),
                    ),
                  ),
                  SizedBox(width: gap),
                  Container(
                    width: itemSize,
                    height: itemSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B), // Brand Amber/Yellow dot
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The official `projeqta` logo combining the icon badge and lowercase wordmark.
class ProjeqtaLogo extends StatelessWidget {
  final double iconSize;
  final double? fontSize;
  final Color? textColor;
  final bool isDark;
  final Axis axis;
  final double spacing;

  const ProjeqtaLogo({
    super.key,
    this.iconSize = 36.0,
    this.fontSize,
    this.textColor,
    this.isDark = false,
    this.axis = Axis.horizontal,
    this.spacing = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final double calculatedFontSize = fontSize ?? (iconSize * 0.72);
    final Color effectiveTextColor = textColor ??
        (isDark ? Colors.white : AppTheme.deepSlate);

    final iconWidget = ProjeqtaIcon(size: iconSize);
    final textWidget = Text(
      'projeqta',
      style: AppTheme.heading(
        fontSize: calculatedFontSize,
        fontWeight: FontWeight.w700,
        color: effectiveTextColor,
        letterSpacing: -0.6,
      ),
    );

    if (axis == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          SizedBox(height: spacing),
          textWidget,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        SizedBox(width: spacing),
        textWidget,
      ],
    );
  }
}
