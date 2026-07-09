import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import '../demo/flagship/flagship_apply.dart';
import '../demo/flagship/flagship_catalog.dart';
import '../demo/flagship/flagship_home.dart';
import '../demo/flagship/flagship_my_cards.dart';
import '../demo/flagship/flagship_my_products.dart';
import '../demo/flagship/flagship_product_detail.dart';
import 'device_frame.dart';
import 'showcase.dart';

/// Presents the Meridian flagship app inside a device mockup, with a chip row
/// to jump between its screens. The preview reflects the live appearance
/// controls.
class FlagshipSection extends StatefulWidget {
  const FlagshipSection({required this.settings, super.key});

  final ShowcaseSettings settings;

  @override
  State<FlagshipSection> createState() => _FlagshipSectionState();
}

class _FlagshipSectionState extends State<FlagshipSection> {
  int _screen = 0;

  static final List<({String label, String caption, Widget Function() build})>
      _screens = [
    (
      label: 'Home',
      caption: 'Total position, accounts, and a pre-qualified offer.',
      build: FlagshipHome.new,
    ),
    (
      label: 'Explore',
      caption: 'The product catalogue with a featured line and Shariah note.',
      build: FlagshipCatalog.new,
    ),
    (
      label: 'Product detail',
      caption: 'Auto Finance with a conventional / Shariah toggle.',
      build: FlagshipProductDetail.new,
    ),
    (
      label: 'Apply',
      caption: 'The end-to-end lending journey, on the personalised offer.',
      build: () => const FlagshipApplyFlow(initialStep: 2),
    ),
    (
      label: 'My cards',
      caption: 'A swipeable card wallet with live balance tiles.',
      build: FlagshipMyCards.new,
    ),
    (
      label: 'My products',
      caption: 'Servicing: holdings and a live application tracker.',
      build: FlagshipMyProducts.new,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final current = _screens[_screen];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BankTokens.space6,
            BankTokens.space6,
            BankTokens.space6,
            BankTokens.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meridian — a complete reference bank',
                style: BankTokens.headlineSmall.copyWith(
                  color: theme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: BankTokens.space1),
              Text(
                current.caption,
                style: BankTokens.bodyMedium
                    .copyWith(color: theme.onSurfaceVariant),
              ),
              const SizedBox(height: BankTokens.space4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < _screens.length; i++) ...[
                      _ScreenChip(
                        label: _screens[i].label,
                        selected: i == _screen,
                        onTap: () => setState(() => _screen = i),
                      ),
                      const SizedBox(width: BankTokens.space2),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: BankTokens.space5),
            child: ThemedContent(
              settings: widget.settings,
              // Key by screen + settings so the previewed app rebuilds cleanly.
              child: DeviceFrame(
                key: ValueKey('$_screen-${widget.settings.preset}-'
                    '${widget.settings.dark}-${widget.settings.rtl}'),
                child: current.build(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenChip extends StatelessWidget {
  const _ScreenChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Material(
      color: selected ? theme.primary : theme.surface,
      borderRadius: BorderRadius.circular(BankTokens.radiusFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BankTokens.radiusFull),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : theme.outline.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            label,
            style: BankTokens.labelMedium.copyWith(
              color: selected ? theme.onPrimary : theme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
