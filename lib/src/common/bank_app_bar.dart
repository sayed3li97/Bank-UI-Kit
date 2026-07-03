import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A themed [AppBar] that reads colours and elevation from [BankThemeData].
///
/// Renders an optional two-line title (title + subtitle), suppresses the
/// Material 3 surface tint so the bar stays a solid brand colour, and
/// uses [BankThemeData.elevationLow] for shadow depth.
///
/// ```dart
/// BankAppBar(
///   title: 'Accounts',
///   actions: [
///     IconButton(icon: Icon(Icons.search_rounded), onPressed: () {}),
///   ],
/// )
/// ```
class BankAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BankAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = false,
    this.bottom,
  });

  /// Primary app-bar heading.
  final String? title;

  /// Optional sub-heading rendered below [title] in a smaller style.
  final String? subtitle;

  final Widget? leading;
  final List<Widget>? actions;

  /// Overrides [BankThemeData.surface] as the background colour.
  final Color? backgroundColor;

  /// Overrides [BankThemeData.onSurface] as the foreground colour.
  final Color? foregroundColor;

  final bool centerTitle;

  /// Optional tab bar or search bar attached below the toolbar.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final bg = backgroundColor ?? theme.surface;
    final fg = foregroundColor ?? theme.onSurface;

    Widget? titleWidget;
    if (title != null) {
      if (subtitle != null) {
        titleWidget = Column(
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title!,
              style: BankTokens.headlineSmall.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle!,
              style:
                  BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant),
            ),
          ],
        );
      } else {
        titleWidget = Text(
          title!,
          style: BankTokens.headlineSmall.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
          ),
        );
      }
    }

    return AppBar(
      leading: leading,
      title: titleWidget,
      centerTitle: centerTitle,
      actions: actions,
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: theme.elevationLow,
      shadowColor: theme.outline,
      surfaceTintColor: Colors.transparent,
      bottom: bottom,
    );
  }
}
