import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_amount_input_field.dart';
import '../common/bank_emblem.dart';
import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/extensions.dart';
import '../theme/presets/heritage.dart';
import '../theme/tokens.dart';

/// A charity that can receive donations through [BankDonationHubCard].
///
/// Immutable value object; two charities are equal when all fields match.
@immutable
class BankCharity {
  const BankCharity({
    required this.id,
    required this.name,
    this.logoUrl,
    this.causeLabel,
    this.verified = false,
  });

  /// Stable identifier passed back through `onDonate`.
  final String id;

  /// Display name of the charity.
  final String name;

  /// Optional logo image URL, rendered through [BankEmblem] with an
  /// initials fallback.
  final String? logoUrl;

  /// Optional short cause description, e.g. `'Water wells'`.
  final String? causeLabel;

  /// Whether the charity is verified by the bank; verified charities show
  /// a check badge on their emblem.
  final bool verified;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankCharity &&
        other.id == id &&
        other.name == name &&
        other.logoUrl == logoUrl &&
        other.causeLabel == causeLabel &&
        other.verified == verified;
  }

  @override
  int get hashCode => Object.hash(id, name, logoUrl, causeLabel, verified);
}

/// A charity giving hub: pick a cause, pick an amount, donate.
///
/// Use it as the entry point of a Sadaqah or general giving flow. The card
/// shows a title, a horizontal strip of selectable charities (each a
/// [BankEmblem] with name and an optional verified check badge), a row of
/// quick-amount chips plus a custom amount entry revealed through
/// [BankAmountInputField], and a donate button that stays disabled until
/// both a charity and a positive amount are chosen. When [onRoundUpChanged]
/// is provided, a round-up pledge toggle row is appended.
///
/// The selected charity is highlighted with a ring: muted gold
/// ([BankHeritageTheme.gold]) when the ambient [BankUiScope] preset is
/// [BankPreset.heritage], otherwise [BankThemeData.primary].
///
/// [onDonate] receives the selected charity id and the chosen amount as a
/// [Money] in [currencyCode]. Quick-amount chips render static suggested
/// values, so they are not privacy-masked.
///
/// ```dart
/// BankDonationHubCard(
///   charities: const [
///     BankCharity(
///       id: 'crescent',
///       name: 'Red Crescent',
///       causeLabel: 'Emergency relief',
///       verified: true,
///     ),
///     BankCharity(id: 'wells', name: 'Water Wells Trust'),
///   ],
///   onDonate: (charityId, amount) => submitDonation(charityId, amount),
///   currencyCode: 'AED',
///   roundUpEnabled: user.roundUpToDonate,
///   onRoundUpChanged: setRoundUpToDonate,
/// )
/// ```
class BankDonationHubCard extends StatefulWidget {
  const BankDonationHubCard({
    required this.charities,
    required this.onDonate,
    required this.currencyCode,
    super.key,
    this.quickAmounts = const <double>[10, 50, 100],
    this.roundUpEnabled = false,
    this.onRoundUpChanged,
    this.title = 'Give Sadaqah',
    this.roundUpLabel = 'Round up purchases to donate',
    this.customAmountLabel = 'Custom',
    this.donateLabel = 'Donate',
    this.verifiedLabel = 'Verified charity',
  });

  /// Charities available for selection, in display order.
  final List<BankCharity> charities;

  /// Called when the donate button is pressed with the selected charity id
  /// and the chosen amount in [currencyCode].
  final void Function(String charityId, Money amount) onDonate;

  /// ISO 4217 currency code for quick amounts and the custom amount entry.
  final String currencyCode;

  /// Suggested donation amounts rendered as selectable chips.
  final List<double> quickAmounts;

  /// Current state of the round-up pledge toggle.
  final bool roundUpEnabled;

  /// Enables the round-up toggle row when non-null; called with the new
  /// value when the user flips the switch.
  final ValueChanged<bool>? onRoundUpChanged;

  /// Card heading.
  final String title;

  /// Label of the round-up toggle row.
  final String roundUpLabel;

  /// Label of the chip that reveals the custom amount entry.
  final String customAmountLabel;

  /// Label of the donate button.
  final String donateLabel;

  /// Semantics suffix announced for verified charities.
  final String verifiedLabel;

  @override
  State<BankDonationHubCard> createState() => _BankDonationHubCardState();
}

class _BankDonationHubCardState extends State<BankDonationHubCard> {
  String? _selectedCharityId;
  double? _selectedQuickAmount;
  bool _customRevealed = false;
  Decimal? _customAmount;

  static Decimal _decimalOf(double value) =>
      Decimal.parse(value.toStringAsFixed(2));

  Decimal? get _resolvedAmount {
    if (_customRevealed) return _customAmount;
    final quick = _selectedQuickAmount;
    return quick == null ? null : _decimalOf(quick);
  }

  @override
  void didUpdateWidget(BankDonationHubCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selectedCharityId;
    if (selected != null &&
        !widget.charities.any((charity) => charity.id == selected)) {
      _selectedCharityId = null;
    }
    final quick = _selectedQuickAmount;
    if (quick != null && !widget.quickAmounts.contains(quick)) {
      _selectedQuickAmount = null;
    }
  }

  void _selectCharity(String id) {
    setState(() => _selectedCharityId = id);
  }

  void _selectQuickAmount(double value) {
    setState(() {
      _selectedQuickAmount = value;
      _customRevealed = false;
    });
  }

  void _revealCustomAmount() {
    setState(() {
      _customRevealed = true;
      _selectedQuickAmount = null;
    });
  }

  void _handleDonate() {
    final charityId = _selectedCharityId;
    final amount = _resolvedAmount;
    if (charityId == null || amount == null) return;
    widget.onDonate(
      charityId,
      Money(amount: amount, currencyCode: widget.currencyCode),
    );
  }

  String _quickLabel(double value, BankUiScopeData scope) {
    final isWhole = value == value.roundToDouble();
    return BankMoneyFormatter.format(
      amount: _decimalOf(value),
      currencyCode: widget.currencyCode,
      numeralStyle: scope.numeralStyle,
      hideFraction: isWhole,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final ringColor = scope.preset == BankPreset.heritage
        ? BankHeritageTheme.gold
        : theme.primary;

    final amount = _resolvedAmount;
    final canDonate =
        _selectedCharityId != null && amount != null && amount > Decimal.zero;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
      color: theme.surface,
      elevation: theme.elevationLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: BankTokens.headlineSmall.copyWith(
                color: theme.onSurface,
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final charity in widget.charities) ...[
                    _CharityChip(
                      charity: charity,
                      selected: charity.id == _selectedCharityId,
                      ringColor: ringColor,
                      verifiedLabel: widget.verifiedLabel,
                      onTap: () => _selectCharity(charity.id),
                    ),
                    if (charity != widget.charities.last)
                      const SizedBox(width: BankTokens.space2),
                  ],
                ],
              ),
            ),
            const SizedBox(height: BankTokens.space4),
            Wrap(
              spacing: BankTokens.space2,
              runSpacing: BankTokens.space2,
              children: [
                for (final value in widget.quickAmounts)
                  _AmountChip(
                    label: _quickLabel(value, scope),
                    selected: !_customRevealed && value == _selectedQuickAmount,
                    onTap: () => _selectQuickAmount(value),
                  ),
                _AmountChip(
                  label: widget.customAmountLabel,
                  selected: _customRevealed,
                  onTap: _revealCustomAmount,
                ),
              ],
            ),
            AnimatedSize(
              duration:
                  disableAnimations ? Duration.zero : BankTokens.durationBase,
              curve: BankTokens.curveEmphasized,
              alignment: AlignmentDirectional.topStart,
              child: _customRevealed
                  ? Padding(
                      padding: const EdgeInsets.only(top: BankTokens.space3),
                      child: BankAmountInputField(
                        currencyCode: widget.currencyCode,
                        onChanged: (value) =>
                            setState(() => _customAmount = value),
                        initialAmount: _customAmount,
                        autofocus: true,
                        displaySize: BankBalanceSize.medium,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: BankTokens.space4),
            SizedBox(
              width: double.infinity,
              height: BankTokens.space12,
              child: FilledButton(
                onPressed: canDonate ? _handleDonate : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  disabledBackgroundColor: theme.surfaceVariant,
                  disabledForegroundColor: theme.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: theme.buttonRadius,
                  ),
                  textStyle: BankTokens.labelLarge,
                ),
                child: Text(widget.donateLabel),
              ),
            ),
            if (widget.onRoundUpChanged != null) ...[
              const SizedBox(height: BankTokens.space2),
              MergeSemantics(
                child: Row(
                  children: [
                    Icon(
                      BankIcons.roundUp,
                      size: BankTokens.space5,
                      color: theme.primary,
                    ),
                    const SizedBox(width: BankTokens.space3),
                    Expanded(
                      child: Text(
                        widget.roundUpLabel,
                        style: BankTokens.bodyMedium.copyWith(
                          color: theme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: BankTokens.space2),
                    Switch(
                      value: widget.roundUpEnabled,
                      onChanged: widget.onRoundUpChanged,
                      activeTrackColor: theme.primary,
                      thumbColor:
                          WidgetStatePropertyAll<Color>(theme.onPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A selectable charity column: ringed [BankEmblem], name, and optional
/// cause label. Verified charities carry a primary check badge.
class _CharityChip extends StatelessWidget {
  const _CharityChip({
    required this.charity,
    required this.selected,
    required this.ringColor,
    required this.verifiedLabel,
    required this.onTap,
  });

  final BankCharity charity;
  final bool selected;
  final Color ringColor;
  final String verifiedLabel;
  final VoidCallback onTap;

  static const double _emblemSize = 56;
  static const double _chipWidth = 84;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final badge = charity.verified
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: theme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: theme.surface, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.check,
                size: 10,
                color: theme.onPrimary,
              ),
            ),
          )
        : null;

    final semanticsLabel = [
      charity.name,
      if (charity.causeLabel != null) charity.causeLabel!,
      if (charity.verified) verifiedLabel,
    ].join(', ');

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _chipWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? ringColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BankTokens.space1 / 2),
                  child: BankEmblem(
                    imageUrl: charity.logoUrl,
                    initialsFrom: charity.name,
                    size: _emblemSize,
                    badgeOverlay: badge,
                  ),
                ),
              ),
              const SizedBox(height: BankTokens.space2),
              Text(
                charity.name,
                style: BankTokens.labelMedium.copyWith(
                  color: selected ? ringColor : theme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (charity.causeLabel != null)
                Text(
                  charity.causeLabel!,
                  style: BankTokens.bodySmall.copyWith(
                    color: theme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A selectable pill chip for quick and custom donation amounts.
class _AmountChip extends StatelessWidget {
  const _AmountChip({
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

    final background = selected ? theme.primary : theme.surfaceVariant;
    final foreground = selected ? theme.onPrimary : theme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: BankTokens.minTapTarget,
            minWidth: BankTokens.minTapTarget,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: theme.chipRadius,
              border: Border.all(
                color: selected ? theme.primary : theme.outline,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space3,
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: BankTokens.labelLarge.copyWith(color: foreground),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
