import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

/// Displays a user's profile photo when available and valid, with an
/// automatic initials fallback on missing or failed network images.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final double? fontSize;
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final bool singleInitial;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 36,
    this.backgroundColor = const Color(0xFFE2E8F0),
    this.textColor = AppTheme.mutedSlate,
    this.fontSize,
    this.border,
    this.borderRadius,
    this.singleInitial = false,
  });

  static String computeInitials(String name, {bool singleInitial = false}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    if (singleInitial) return trimmed[0].toUpperCase();
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _buildInitialsFallback() {
    final initials = computeInitials(name, singleInitial: singleInitial);
    final effectiveFontSize = fontSize ?? (size * 0.36).clamp(8.0, 24.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
        border: border,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: effectiveFontSize,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ApiClient().resolveMediaUrl(photoUrl);
    final hasValidUrl =
        resolved != null &&
        resolved.isNotEmpty &&
        (resolved.startsWith('http://') || resolved.startsWith('https://'));

    if (!hasValidUrl) {
      return _buildInitialsFallback();
    }

    final cachePx = (size * 3).round().clamp(48, 256);
    final clippedImage = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      child: Image.network(
        resolved,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: cachePx,
        cacheHeight: cachePx,
        errorBuilder: (_, _, _) => _buildInitialsFallback(),
      ),
    );

    if (border == null) {
      return clippedImage;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
        border: border,
      ),
      child: clippedImage,
    );
  }
}

