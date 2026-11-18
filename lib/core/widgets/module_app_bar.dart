import 'package:flutter/material.dart';
import '../theme.dart';

/// Unified module header matching the clean enterprise white top bar pattern.
class ModuleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ModuleAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.actions,
    this.onBack,
    this.showBackButton = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppTheme.pureWhite;
    final fg = foregroundColor ?? AppTheme.deepSlate;
    final borderColor = AppTheme.borderSubtle;

    return Material(
      color: bg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: borderColor, width: 1.0),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: IconTheme(
              data: IconThemeData(color: fg, size: 22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          Icons.arrow_back,
                          color: fg,
                        ),
                        tooltip: 'Back',
                        onPressed: onBack ?? () => Navigator.maybePop(context),
                      )
                    else
                      const SizedBox(width: 10),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                titleStyle ??
                                AppTheme.heading(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: fg,
                                ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body(
                                fontSize: 11.5,
                                color: AppTheme.mutedSlate,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (actions != null && actions!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

