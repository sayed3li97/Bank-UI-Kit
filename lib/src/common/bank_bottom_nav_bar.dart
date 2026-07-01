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
  });

  final List<BankNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Overrides [BankThemeData.surface] as the bar background.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final bg = backgroundColor ?? theme.surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: theme.outline, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                    theme: theme,
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
  });

  final BankNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = selected ? theme.primary : theme.onSurfaceVariant;

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
              duration: BankTokens.durationFast,
              curve: BankTokens.curveStandard,
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space1,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? theme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: theme.chipRadius,
              ),
              child: Icon(
                selected ? (item.activeIcon ?? item.icon) : item.icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: BankTokens.labelSmall.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
