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
/// `variantOverride` to force a specific treatment: in particular
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
/// - **current**: an "Available" caption next to the masked number.
/// - **savings / isa**: the [rateLabel] slot (e.g. `'4.20%'`); its label
///   respects `islamicFinanceMode` from [BankUiScope] (Interest Rate vs
///   Profit Rate).
/// - **credit**: when [creditLimit] and [outstanding] are supplied, a
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

  /// Overrides the content padding. Defaults to a symmetric
  /// [BankTokens.space3] / [BankTokens.space2] inset.
  final EdgeInsetsGeometry? padding;

  /// Overrides the tile corner radius. Defaults to the theme
  /// `cardRadius`.
  final BorderRadius? radius;

  /// Overrides the tile background colour. Defaults to the theme
  /// `surface`.
  final Color? backgroundColor;

  /// Overrides the accent used for the leading tint, icon, selected
  /// outline and checkmark. Defaults to the theme `primary`.
  final Color? accentColor;

  /// Overrides the minimum row height. Defaults to 64.
  final double? minHeight;

  /// Replaces the default leading icon container entirely.
  final Widget? leading;

  /// Overrides the product-type glyph derived from the variant.
  final IconData? icon;

  /// Overrides the selection checkmark glyph. Defaults to
  /// [BankIcons.success].
  final IconData? selectedIcon;

  /// Merged over the account-name style ([BankTokens.labelLarge]).
  final TextStyle? titleStyle;

  /// Merged over the secondary-line style ([BankTokens.bodySmall]).
  final TextStyle? subtitleStyle;

  /// Merged over the balance style (theme `numeralSmall`).
  final TextStyle? amountStyle;

  /// Overrides the used portion of the credit bar. Defaults to
  /// [BankTokens.creditUsed].
  final Color? creditUsedColor;

  /// Overrides the track of the credit bar. Defaults to
  /// [BankTokens.creditAvailable] at 24% opacity.
  final Color? creditAvailableColor;

  /// Status chip label for closed accounts. Defaults to `'Closed'`.
  final String closedLabel;

  /// Accessibility label template for the credit bar; `{percent}` is
  /// replaced with the rounded usage percentage. Defaults to
  /// `'Credit used: {percent}%'`.
  final String creditUsedSemanticTemplate;

  /// Overrides the computed accessibility label of the whole row.
  final String? semanticLabel;

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
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.minHeight,
    this.leading,
    this.icon,
    this.selectedIcon,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.creditUsedColor,
    this.creditAvailableColor,
    this.closedLabel = 'Closed',
    this.creditUsedSemanticTemplate = 'Credit used: {percent}%',
    this.semanticLabel,
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
          closedLabel,
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
      label: creditUsedSemanticTemplate.replaceAll(
        '{percent}',
        '${(usedFraction * 100).round()}',
      ),
      child: SizedBox(
        height: BankTokens.space1,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(BankTokens.radiusSmall),
          ),
          child: ColoredBox(
            color: creditAvailableColor ??
                BankTokens.creditAvailable.withValues(alpha: 0.24),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: usedFraction,
                heightFactor: 1,
                child: ColoredBox(
                  color: creditUsedColor ?? BankTokens.creditUsed,
                ),
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
    final accent = accentColor ?? bankTheme.primary;
    final resolvedRadius = radius ?? bankTheme.cardRadius;

    // ── Leading 40px type icon on an 8% primary tint ──────────────────────
    final leadingWidget = leading ??
        DecoratedBox(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: bankTheme.chipRadius,
          ),
          child: SizedBox.square(
            dimension: _leadingSize,
            child: Icon(
              icon ?? _iconForVariant(variant),
              color: accent,
              size: BankTokens.space5,
            ),
          ),
        );

    // ── Secondary line: masked number (+ variant detail) ──────────────────
    final secondaryStyle = BankTokens.bodySmall
        .copyWith(color: bankTheme.onSurfaceVariant)
        .merge(subtitleStyle);
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
                style: BankTokens.labelLarge
                    .copyWith(color: bankTheme.onSurface)
                    .merge(titleStyle),
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
      padding: padding ??
          const EdgeInsetsDirectional.symmetric(
            horizontal: BankTokens.space3,
            vertical: BankTokens.space2,
          ),
      child: Row(
        children: [
          leadingWidget,
          const SizedBox(width: BankTokens.space3),
          Expanded(child: middle),
          if (showBalance) ...[
            const SizedBox(width: BankTokens.space2),
            BankBalanceText(
              money: account.balance,
              size: BankBalanceSize.small,
              style: bankTheme.numeralSmall
                  .copyWith(
                    color: account.balance.isNegative
                        ? bankTheme.negativeBalance
                        : bankTheme.onSurface,
                  )
                  .merge(amountStyle),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: BankTokens.space2),
            trailing!,
          ],
          if (selected) ...[
            const SizedBox(width: BankTokens.space2),
            Icon(
              selectedIcon ?? BankIcons.success,
              color: accent,
              size: BankTokens.space5,
            ),
          ],
        ],
      ),
    );

    final decoration = BoxDecoration(
      color: backgroundColor ?? bankTheme.surface,
      borderRadius: resolvedRadius,
      border: Border.all(
        color: selected ? accent : Colors.transparent,
        width: 1.5,
      ),
    );

    final tile = DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: resolvedRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: resolvedRadius,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight ?? _minHeight),
            child: content,
          ),
        ),
      ),
    );

    final resolvedSemanticLabel = semanticLabel ??
        '${account.name}, ${variant.name} product, '
            '${account.maskedNumber}, '
            'Status: ${account.status.name}';

    return Semantics(
      label: resolvedSemanticLabel,
      button: onTap != null,
      selected: selected,
      child: tile,
    );
  }
}
