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
    this.titleStyle,
    this.subtitleStyle,
    this.elevation,
    this.shadowColor,
    this.toolbarHeight,
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

  /// Merged over the computed [title] style (default:
  /// [BankTokens.headlineSmall] at w700 in the foreground colour).
  final TextStyle? titleStyle;

  /// Merged over the computed [subtitle] style (default:
  /// [BankTokens.bodySmall] in [BankThemeData.onSurfaceVariant]).
  final TextStyle? subtitleStyle;

  /// Overrides [BankThemeData.elevationLow] as the bar elevation.
  final double? elevation;

  /// Overrides [BankThemeData.outline] as the elevation shadow colour.
  final Color? shadowColor;

  /// Overrides [kToolbarHeight] as the toolbar height.
  final double? toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(
        (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final bg = backgroundColor ?? theme.surface;
    final fg = foregroundColor ?? theme.onSurface;

    final resolvedTitleStyle = BankTokens.headlineSmall
        .copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        )
        .merge(titleStyle);
    final resolvedSubtitleStyle = BankTokens.bodySmall
        .copyWith(color: theme.onSurfaceVariant)
        .merge(subtitleStyle);

    Widget? titleWidget;
    if (title != null) {
      if (subtitle != null) {
        titleWidget = Column(
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title!, style: resolvedTitleStyle),
            Text(subtitle!, style: resolvedSubtitleStyle),
          ],
        );
      } else {
        titleWidget = Text(title!, style: resolvedTitleStyle);
      }
    }

    return AppBar(
      leading: leading,
      title: titleWidget,
      centerTitle: centerTitle,
      actions: actions,
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: elevation ?? theme.elevationLow,
      shadowColor: shadowColor ?? theme.outline,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      bottom: bottom,
    );
  }
}
