import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'flagship_data.dart';

/// The Products / Explore catalogue for the flagship Meridian demo.
///
/// Presents the full product suite: a category grid, a featured Auto Finance
/// product, the loans line-up, and a pointer to the Shariah-compliant
/// variant. Composed entirely from Bank UI Kit widgets so it inherits the
/// active preset, privacy, RTL, and numeral styling.
class FlagshipCatalog extends StatelessWidget {
  const FlagshipCatalog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return BankUiScope(
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: BankAppBar(
          title: 'Explore',
          subtitle: Flagship.tagline,
          actions: [
            IconButton(
              icon: Icon(Icons.search_rounded, color: theme.onSurface),
              onPressed: () {},
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            BankTokens.space4,
            BankTokens.space4,
            BankTokens.space4,
            BankTokens.space12,
          ),
          children: [
            // 1. Short intro line.
            Text(
              'Products chosen for you. Rates as of 4 Jul 2026.',
              style: BankTokens.bodyMedium.copyWith(
                color: theme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BankTokens.space6),

            // 2. Category grid: all categories, two per row.
            _SectionHeader(theme: theme, title: 'Browse by category'),
            const SizedBox(height: BankTokens.space3),
            _CategoryGrid(),
            const SizedBox(height: BankTokens.space8),

            // 3. Featured product.
            _SectionHeader(theme: theme, title: 'Featured'),
            const SizedBox(height: BankTokens.space3),
            BankProductCard(
              title: Flagship.autoFinance.name,
              subtitle: Flagship.autoFinance.tagline,
              leadingIcon: Icons.directions_car_outlined,
              rate: Flagship.autoFinance.rate,
              features: Flagship.autoFinance.features,
              badges: Flagship.autoFinance.productBadges,
              highlighted: true,
              ctaLabel: 'View details',
              onTap: () {},
              secondaryLabel: 'Check eligibility',
              onSecondary: () {},
            ),
            const SizedBox(height: BankTokens.space8),

            // 4. Loans line-up (Auto Finance already featured above).
            _SectionHeader(theme: theme, title: 'Loans'),
            const SizedBox(height: BankTokens.space3),
            for (final product in _otherLoans) ...[
              BankProductCard(
                title: product.name,
                subtitle: product.tagline,
                leadingIcon: _loanIcon(product.id),
                rate: product.rate,
                features: product.features.take(3).toList(),
                badges: product.productBadges,
                ctaLabel: 'View details',
                onTap: () {},
              ),
              const SizedBox(height: BankTokens.space4),
            ],
            const SizedBox(height: BankTokens.space2),

            // 5. Shariah-compliant variant pointer.
            _ShariahNote(theme: theme),
          ],
        ),
      ),
    );
  }

  /// Loans other than the featured Auto Finance, to avoid showing it twice.
  static List<FlagshipProduct> get _otherLoans =>
      Flagship.loans.where((p) => p.id != Flagship.autoFinance.id).toList();

  static IconData _loanIcon(String id) {
    switch (id) {
      case 'personal_loan':
        return Icons.request_quote_outlined;
      case 'heloc':
        return Icons.home_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}

// ---------------------------------------------------------------------------
// Category grid
// ---------------------------------------------------------------------------

class _CategoryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const categories = Flagship.categories;
    final rows = <Widget>[];
    for (var i = 0; i < categories.length; i += 2) {
      final left = categories[i];
      final right = i + 1 < categories.length ? categories[i + 1] : null;
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: BankTokens.space3));
      }
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _categoryTile(left)),
              const SizedBox(width: BankTokens.space3),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _categoryTile(right),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _categoryTile(FlagshipCategory category) {
    return BankProductCategoryTile(
      icon: category.icon,
      title: category.title,
      subtitle: category.subtitle,
      count: category.count,
      onTap: () {},
    );
  }
}

// ---------------------------------------------------------------------------
// Shariah note
// ---------------------------------------------------------------------------

class _ShariahNote extends StatelessWidget {
  const _ShariahNote({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BankShariahBadge(),
            const SizedBox(height: BankTokens.space3),
            Text(
              'Shariah-compliant variants available',
              style: BankTokens.labelLarge.copyWith(
                color: theme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BankTokens.space1),
            Text(
              'Prefer Islamic finance? ${Flagship.murabahaAuto.name} offers '
              'the same vehicle finance at a fixed, disclosed profit rate with '
              'no interest, fully Shariah-board approved.',
              style: BankTokens.bodyMedium.copyWith(
                color: theme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View ${Flagship.murabahaAuto.name}',
                      style: BankTokens.labelLarge.copyWith(
                        color: theme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: BankTokens.space1),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: BankTokens.space4,
                      color: theme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
