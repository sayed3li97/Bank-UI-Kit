import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A single navigation destination for [BankBottomNavBar].
class BankNavItem {
  const BankNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  final IconData icon;

  /// Substituted for [icon] when this item is selected. Falls back to [icon].
  final IconData? activeIcon;

  final String label;
}

/// A bottom navigation bar themed from [BankThemeData].
///
/// Active items receive a pill-shaped highlight in [BankThemeData.primary] at
/// 12 % opacity; the icon switches to [BankNavItem.activeIcon] and the label
/// weight increases to [FontWeight.w700].
///
/// ```dart
/// BankBottomNavBar(
///   currentIndex: _tab,
///   onTap: (i) => setState(() => _tab = i),
///   items: const [
///     BankNavItem(icon: Icons.home_outlined, label: 'Home'),
///     BankNavItem(icon: Icons.credit_card_outlined, label: 'Cards'),
///     BankNavItem(icon: Icons.swap_horiz_rounded, label: 'Transfers'),
///     BankNavItem(icon: Icons.bar_chart_rounded, label: 'Insights'),
///     BankNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
///   ],
/// )
/// ```
class BankBottomNavBar extends StatelessWidget {
  const BankBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.backgroundColor,
    this.borderColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.indicatorColor,
    this.indicatorRadius,
    this.labelStyle,
    this.iconSize,
    this.height,
    this.animationDuration,
    this.animationCurve,
  });

  final List<BankNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Overrides [BankThemeData.surface] as the bar background.
  final Color? backgroundColor;

  /// Overrides [BankThemeData.outline] as the top hairline colour.
  final Color? borderColor;

  /// Overrides [BankThemeData.primary] as the selected icon and
  /// label colour.
  final Color? selectedItemColor;

  /// Overrides [BankThemeData.onSurfaceVariant] as the unselected icon
  /// and label colour.
  final Color? unselectedItemColor;

  /// Overrides the active pill fill (default: the selected item colour
  /// at 12 % opacity).
  final Color? indicatorColor;

  /// Overrides [BankThemeData.chipRadius] as the active pill radius.
  final BorderRadius? indicatorRadius;

  /// Merged over the computed label style (default:
  /// [BankTokens.labelSmall] with a selection-dependent weight).
  final TextStyle? labelStyle;

  /// Overrides the 22 px item icon size.
  final double? iconSize;

  /// Overrides the fixed 60 px bar height.
  final double? height;

  /// Overrides [BankTokens.durationFast] for the pill highlight
  /// animation.
  final Duration? animationDuration;

  /// Overrides [BankTokens.curveStandard] for the pill highlight
  /// animation.
  final Curve? animationCurve;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final bg = backgroundColor ?? theme.surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: borderColor ?? theme.outline, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height ?? 60,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                    theme: theme,
                    selectedColor: selectedItemColor,
                    unselectedColor: unselectedItemColor,
                    indicatorColor: indicatorColor,
                    indicatorRadius: indicatorRadius,
                    labelStyle: labelStyle,
                    iconSize: iconSize,
                    animationDuration: animationDuration,
                    animationCurve: animationCurve,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.theme,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.indicatorRadius,
    this.labelStyle,
    this.iconSize,
    this.animationDuration,
    this.animationCurve,
  });

  final BankNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final BankThemeData theme;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? indicatorColor;
  final BorderRadius? indicatorRadius;
  final TextStyle? labelStyle;
  final double? iconSize;
  final Duration? animationDuration;
  final Curve? animationCurve;

  @override
  Widget build(BuildContext context) {
    final active = selectedColor ?? theme.primary;
    final color =
        selected ? active : (unselectedColor ?? theme.onSurfaceVariant);
    final pillColor = indicatorColor ?? active.withValues(alpha: 0.12);

    return Semantics(
      selected: selected,
      label: item.label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: animationDuration ?? BankTokens.durationFast,
              curve: animationCurve ?? BankTokens.curveStandard,
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space1,
              ),
              decoration: BoxDecoration(
                color: selected ? pillColor : Colors.transparent,
                borderRadius: indicatorRadius ?? theme.chipRadius,
              ),
              child: Icon(
                selected ? (item.activeIcon ?? item.icon) : item.icon,
                color: color,
                size: iconSize ?? 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: BankTokens.labelSmall
                  .copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  )
                  .merge(labelStyle),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
