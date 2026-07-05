import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'flagship_data.dart';

/// Auto Finance product detail for the Meridian flagship demo.
///
/// Presents the featured [Flagship.autoFinance] product with a rate hero,
/// feature list, representative example, and a fees/eligibility summary. A
/// conventional/Shariah segmented control at the top swaps the whole body to
/// the Murabaha variant ([Flagship.murabahaAuto]), demonstrating how one
/// screen serves both propositions. A pinned bottom bar carries the primary
/// "Check eligibility" call to action.
class FlagshipProductDetail extends StatefulWidget {
  const FlagshipProductDetail({super.key});

  @override
  State<FlagshipProductDetail> createState() => _FlagshipProductDetailState();
}

class _FlagshipProductDetailState extends State<FlagshipProductDetail> {
  bool _islamic = false;

  FlagshipProduct get _product =>
      _islamic ? Flagship.murabahaAuto : Flagship.autoFinance;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final product = _product;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: BankAppBar(
        title: 'Auto Finance',
        subtitle: 'Meridian',
      ),
      bottomNavigationBar: _StickyCta(theme: theme),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BankTokens.space4,
            BankTokens.space4,
            BankTokens.space4,
            BankTokens.space8,
          ),
          children: [
            _FinanceToggle(
              theme: theme,
              islamic: _islamic,
              onChanged: (value) => setState(() => _islamic = value),
            ),
            const SizedBox(height: BankTokens.space5),
            _RateHero(theme: theme, product: product, islamic: _islamic),
            const SizedBox(height: BankTokens.space5),
            Text(
              product.tagline,
              style: BankTokens.bodyLarge.copyWith(
                color: theme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: BankTokens.space4),
            _FeatureList(theme: theme, features: product.features),
            const SizedBox(height: BankTokens.space6),
            _SectionHeader(theme: theme, title: 'Representative example'),
            const SizedBox(height: BankTokens.space3),
            _RepresentativeExample(theme: theme, product: product),
            const SizedBox(height: BankTokens.space6),
            _SectionHeader(theme: theme, title: 'At a glance'),
            const SizedBox(height: BankTokens.space3),
            _SummaryCard(theme: theme, islamic: _islamic),
            const SizedBox(height: BankTokens.space4),
            _RatesNote(theme: theme),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conventional / Shariah segmented control
// ---------------------------------------------------------------------------

class _FinanceToggle extends StatelessWidget {
  const _FinanceToggle({
    required this.theme,
    required this.islamic,
    required this.onChanged,
  });

  final BankThemeData theme;
  final bool islamic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BankTokens.space1),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(BankTokens.radiusLarge),
        border: Border.all(color: theme.outline),
      ),
      child: Row(
        children: [
          _ToggleChip(
            theme: theme,
            label: 'Conventional',
            icon: Icons.percent_rounded,
            selected: !islamic,
            onTap: () => onChanged(false),
          ),
          _ToggleChip(
            theme: theme,
            label: 'Shariah',
            icon: Icons.verified_rounded,
            selected: islamic,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.theme,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final BankThemeData theme;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? theme.onPrimary : theme.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: BankTokens.space3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: BankTokens.space2),
                  Text(
                    label,
                    style: BankTokens.labelLarge.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rate hero
// ---------------------------------------------------------------------------

class _RateHero extends StatelessWidget {
  const _RateHero({
    required this.theme,
    required this.product,
    required this.islamic,
  });

  final BankThemeData theme;
  final FlagshipProduct product;
  final bool islamic;

  @override
  Widget build(BuildContext context) {
    final rate = product.rate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BankTokens.space5),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline),
        boxShadow: BankTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rate.label.toUpperCase(),
            style: BankTokens.labelSmall.copyWith(
              color: theme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: BankTokens.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                rate.value,
                style: BankTokens.numeralHero.copyWith(
                  color: theme.primary,
                  fontFamily: theme.fontFamily,
                ),
              ),
              const SizedBox(width: BankTokens.space2),
              if (rate.caption != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: BankTokens.space1),
                    child: Text(
                      rate.caption!,
                      style: BankTokens.bodySmall.copyWith(
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: BankTokens.space3),
          Row(
            children: [
              if (islamic)
                const BankShariahBadge(size: BankShariahBadgeSize.small)
              else
                _RepresentativePill(theme: theme),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepresentativePill extends StatelessWidget {
  const _RepresentativePill({required this.theme});

  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space3,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: theme.chipRadius,
        border: Border.all(color: theme.outline),
      ),
      child: Text(
        'Representative APR',
        style: BankTokens.labelSmall.copyWith(color: theme.onSurfaceVariant),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature list
// ---------------------------------------------------------------------------

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.theme, required this.features});

  final BankThemeData theme;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: BankTokens.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: theme.positiveBalance,
                ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Text(
                    feature,
                    style: BankTokens.bodyMedium.copyWith(
                      color: theme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Representative example (quiet card)
// ---------------------------------------------------------------------------

class _RepresentativeExample extends StatelessWidget {
  const _RepresentativeExample({required this.theme, required this.product});

  final BankThemeData theme;
  final FlagshipProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BankTokens.space4),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: theme.cardRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 20,
            color: theme.onSurfaceVariant,
          ),
          const SizedBox(width: BankTokens.space3),
          Expanded(
            child: Text(
              product.representativeExample,
              style: BankTokens.bodySmall.copyWith(
                color: theme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fees / eligibility summary
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.theme, required this.islamic});

  final BankThemeData theme;
  final bool islamic;

  @override
  Widget build(BuildContext context) {
    final items = <BankSummaryItem>[
      BankSummaryItem(
        label: islamic ? 'Finance amount' : 'Loan amount',
        value: '3,000 to 60,000 GBP',
      ),
      const BankSummaryItem(label: 'Term', value: '1 to 7 years'),
      const BankSummaryItem(label: 'Arrangement fee', value: 'None'),
      BankSummaryItem(
        label: 'Early settlement',
        value: islamic ? 'Rebate (ibra) available' : 'No fee',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space4,
        vertical: BankTokens.space2,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline),
      ),
      child: BankSummaryStack(items: items),
    );
  }
}

// ---------------------------------------------------------------------------
// Rates note
// ---------------------------------------------------------------------------

class _RatesNote extends StatelessWidget {
  const _RatesNote({required this.theme});

  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: theme.onSurfaceVariant,
        ),
        const SizedBox(width: BankTokens.space2),
        Expanded(
          child: Text(
            'Rates as of 4 Jul 2026. Your rate depends on your circumstances '
            'and may differ from the representative rate.',
            style: BankTokens.labelSmall.copyWith(
              color: theme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky bottom call to action
// ---------------------------------------------------------------------------

class _StickyCta extends StatelessWidget {
  const _StickyCta({required this.theme});

  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(BankTokens.space4),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: theme.buttonRadius,
                ),
              ),
              child: Text(
                'Check eligibility',
                style: BankTokens.labelLarge.copyWith(
                  color: theme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.theme, required this.title});

  final BankThemeData theme;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: BankTokens.labelLarge.copyWith(
        color: theme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
