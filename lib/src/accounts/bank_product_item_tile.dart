import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../models/models.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_balance_text.dart';

/// The product family a [BankProductItemTile] renders.
///
/// Normally derived automatically from [BankAccountType]; pass
/// `variantOverride` to force a specific treatment — in particular
/// [credit], which has no [BankAccountType] equivalent and unlocks the
/// credit-utilisation progress bar.
enum BankProductItemVariant {
  /// Everyday current / checking account.
  current,

  /// Interest- or profit-bearing savings account.
  savings,

  /// Account shared between multiple owners.
  joint,

  /// Business banking account.
  business,

  /// Tax-wrapped savings (ISA) account.
  isa,

  /// Crypto-currency wallet account.
  crypto,

  /// Credit product (credit card, loan, overdraft facility).
  credit,
}

/// Per-product-type summary row for pickers, dashboards and `ListView`s.
///
/// Renders a leading 40 px product-type icon on an 8 % primary tint, the
/// account name with masked number, a type-specific secondary line, and a
/// right-aligned privacy-aware balance via [BankBalanceText]. A primary
/// checkmark appears when [selected] is `true`, and non-active accounts
/// show the same frozen / pending status chips as `BankAccountCard`.
///
/// Type-specific secondary content:
/// - **current** — an "Available" caption next to the masked number.
/// - **savings / isa** — the [rateLabel] slot (e.g. `'4.20%'`); its label
///   respects `islamicFinanceMode` from [BankUiScope] (Interest Rate vs
///   Profit Rate).
/// - **credit** — when [creditLimit] and [outstanding] are supplied, a
///   thin progress bar of used vs available credit coloured with
///   [BankTokens.creditUsed] / [BankTokens.creditAvailable].
///
/// ```dart
/// ListView(
///   children: accounts
///       .map((a) => BankProductItemTile(
///             account: a,
///             selected: a.id == selectedId,
///             rateLabel: a.type == BankAccountType.savings ? '4.20%' : null,
///             onTap: () => onSelect(a),
///           ))
///       .toList(),
/// )
/// ```
class BankProductItemTile extends StatelessWidget {
  /// The account this row summarises.
  final BankAccount account;

  /// Called when the row is tapped. If `null`, the row is inert.
  final VoidCallback? onTap;

  /// Whether this row is the current selection (shows a primary checkmark
  /// and a primary outline).
  final bool selected;

  /// Whether the right-aligned balance is rendered.
  final bool showBalance;

  /// Optional extra widget placed at the end of the row, after the balance
  /// and before the selection checkmark.
  final Widget? trailing;

  /// Forces a specific [BankProductItemVariant] instead of deriving one
  /// from [BankAccount.type]. Required to opt into
  /// [BankProductItemVariant.credit].
  final BankProductItemVariant? variantOverride;

  /// Pre-formatted rate figure (e.g. `'4.20%'`) shown on the secondary
  /// line for savings / ISA products. The accompanying label comes from
  /// `BankUiStrings` and respects Islamic finance mode.
  final String? rateLabel;

  /// Total credit line for credit products. Both this and [outstanding]
  /// must be non-null (and the limit positive) for the utilisation bar to
  /// render.
  final Money? creditLimit;

  /// Amount of the credit line already used.
  final Money? outstanding;

  const BankProductItemTile({
    required this.account,
    super.key,
    this.onTap,
    this.selected = false,
    this.showBalance = true,
    this.trailing,
    this.variantOverride,
    this.rateLabel,
    this.creditLimit,
    this.outstanding,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Minimum row height in logical pixels.
  static const double _minHeight = 64;

  /// Edge length of the leading product-type icon container.
  static const double _leadingSize = 40;

  BankProductItemVariant get _variant =>
      variantOverride ??
      switch (account.type) {
        BankAccountType.current => BankProductItemVariant.current,
        BankAccountType.savings => BankProductItemVariant.savings,
        BankAccountType.joint => BankProductItemVariant.joint,
        BankAccountType.business => BankProductItemVariant.business,
        BankAccountType.isa => BankProductItemVariant.isa,
        BankAccountType.crypto => BankProductItemVariant.crypto,
      };

  IconData _iconForVariant(BankProductItemVariant variant) => switch (variant) {
        BankProductItemVariant.savings => BankIcons.accountSavings,
        BankProductItemVariant.joint => BankIcons.accountJoint,
        BankProductItemVariant.business => BankIcons.accountBusiness,
        BankProductItemVariant.crypto => BankIcons.accountCrypto,
        BankProductItemVariant.credit => BankIcons.card,
        BankProductItemVariant.current ||
        BankProductItemVariant.isa =>
          BankIcons.account,
      };

  /// Fraction of the credit line already used, or `null` when the inputs
  /// are missing / invalid so no bar should render.
  double? get _creditUsedFraction {
    final limit = creditLimit;
    final used = outstanding;
    if (_variant != BankProductItemVariant.credit ||
        limit == null ||
        used == null ||
        limit.amount <= Decimal.zero) {
      return null;
    }
    return (used.amount / limit.amount).toDouble().clamp(0.0, 1.0);
  }

  /// Same visual language as the status chip in `BankAccountCard`.
  Widget _buildStatusChip(
    BuildContext context,
    BankAccountStatus status,
    BankThemeData bankTheme,
  ) {
    final data = BankUiScope.of(context);

    final (Color chipBackground, String label) = switch (status) {
      BankAccountStatus.frozen => (
          const Color(0xFFB3E5FC), // ice-blue
          data.strings.frozen,
        ),
      BankAccountStatus.restricted => (
          const Color(0xFFFFE082), // amber
          data.strings.restricted,
        ),
      BankAccountStatus.pending => (
          const Color(0xFFFFF9C4), // pale yellow
          data.strings.pending,
        ),
      BankAccountStatus.closed => (
          const Color(0xFFEEEEEE), // neutral grey
          'Closed',
        ),
      BankAccountStatus.active => (Colors.transparent, ''),
    };

    if (status == BankAccountStatus.active) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: BankTokens.space2,
        vertical: BankTokens.space1,
      ),
      decoration: BoxDecoration(
        color: chipBackground,
        borderRadius: bankTheme.chipRadius,
      ),
      child: Text(
        label,
        style: BankTokens.labelSmall.copyWith(color: const Color(0xFF333333)),
      ),
    );
  }

  /// Variant-specific caption appended after the masked number, or `null`
  /// when the variant has none.
  String? _secondaryDetail(BankUiScopeData data) {
    switch (_variant) {
      case BankProductItemVariant.current:
        return data.strings.available;
      case BankProductItemVariant.savings:
      case BankProductItemVariant.isa:
        final rate = rateLabel;
        if (rate == null) return null;
        final label = data.islamicFinanceMode
            ? data.strings.profitRate
            : data.strings.interestRate;
        return '$rate $label';
      case BankProductItemVariant.joint:
      case BankProductItemVariant.business:
      case BankProductItemVariant.crypto:
      case BankProductItemVariant.credit:
        return null;
    }
  }

  Widget _buildCreditBar(double usedFraction) {
    return Semantics(
      label: 'Credit used: ${(usedFraction * 100).round()}%',
      child: SizedBox(
        height: BankTokens.space1,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(BankTokens.radiusSmall),
          ),
          child: ColoredBox(
            color: BankTokens.creditAvailable.withValues(alpha: 0.24),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: usedFraction,
                heightFactor: 1,
                child: const ColoredBox(color: BankTokens.creditUsed),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final data = BankUiScope.of(context);
    final variant = _variant;
    final detail = _secondaryDetail(data);
    final usedFraction = _creditUsedFraction;

    // ── Leading 40px type icon on an 8% primary tint ──────────────────────
    final leading = DecoratedBox(
      decoration: BoxDecoration(
        color: bankTheme.primary.withValues(alpha: 0.08),
        borderRadius: bankTheme.chipRadius,
      ),
      child: SizedBox.square(
        dimension: _leadingSize,
        child: Icon(
          _iconForVariant(variant),
          color: bankTheme.primary,
          size: BankTokens.space5,
        ),
      ),
    );

    // ── Secondary line: masked number (+ variant detail) ──────────────────
    final secondaryStyle =
        BankTokens.bodySmall.copyWith(color: bankTheme.onSurfaceVariant);
    final secondaryLine = Row(
      children: [
        Text(
          account.maskedNumber,
          style: secondaryStyle,
          textDirection: TextDirection.ltr, // masked number always LTR
        ),
        if (detail != null)
          Flexible(
            child: Text(
              ' · $detail',
              style: secondaryStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    // ── Middle column: name + status chip, secondary, credit bar ──────────
    final middle = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                account.name,
                style:
                    BankTokens.labelLarge.copyWith(color: bankTheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (account.status != BankAccountStatus.active) ...[
              const SizedBox(width: BankTokens.space2),
              _buildStatusChip(context, account.status, bankTheme),
            ],
          ],
        ),
        const SizedBox(height: BankTokens.space1),
        secondaryLine,
        if (usedFraction != null) ...[
          const SizedBox(height: BankTokens.space2),
          _buildCreditBar(usedFraction),
        ],
      ],
    );

    // ── Assemble the row ───────────────────────────────────────────────────
    final content = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: BankTokens.space3,
        vertical: BankTokens.space2,
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: BankTokens.space3),
          Expanded(child: middle),
          if (showBalance) ...[
            const SizedBox(width: BankTokens.space2),
            BankBalanceText(
              money: account.balance,
              size: BankBalanceSize.small,
              style: bankTheme.numeralSmall.copyWith(
                color: account.balance.isNegative
                    ? bankTheme.negativeBalance
                    : bankTheme.onSurface,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: BankTokens.space2),
            trailing!,
          ],
          if (selected) ...[
            const SizedBox(width: BankTokens.space2),
            Icon(
              BankIcons.success,
              color: bankTheme.primary,
              size: BankTokens.space5,
            ),
          ],
        ],
      ),
    );

    final decoration = BoxDecoration(
      color: bankTheme.surface,
      borderRadius: bankTheme.cardRadius,
      border: Border.all(
        color: selected ? bankTheme.primary : Colors.transparent,
        width: 1.5,
      ),
    );

    final tile = DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: bankTheme.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: bankTheme.cardRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minHeight),
            child: content,
          ),
        ),
      ),
    );

    final semanticLabel = '${account.name}, ${variant.name} product, '
        '${account.maskedNumber}, '
        'Status: ${account.status.name}';

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      child: tile,
    );
  }
}
