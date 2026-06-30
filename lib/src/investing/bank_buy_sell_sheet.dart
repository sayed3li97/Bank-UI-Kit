import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/money_formatter.dart';
import '../../models/asset_quote.dart';
import '../../models/money.dart';
import '../../scope/bank_ui_scope.dart';
import '../../theme/bank_theme_data.dart';
import '../../theme/tokens.dart';

enum BankOrderSide { buy, sell }

enum BankOrderType { market, limit }

/// Order-entry sheet for buying or selling an asset.
class BankBuySellSheet extends StatefulWidget {
  final AssetQuote quote;
  final BankOrderSide initialSide;
  final bool allowLimitOrder;
  final Money? availableBalance;
  final Future<void> Function(
    BankOrderSide side,
    BankOrderType type,
    double amount,
    double? limitPrice,
  )? onSubmit;

  const BankBuySellSheet({
    super.key,
    required this.quote,
    this.initialSide = BankOrderSide.buy,
    this.allowLimitOrder = false,
    this.availableBalance,
    this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required AssetQuote quote,
    BankOrderSide initialSide = BankOrderSide.buy,
    Future<void> Function(BankOrderSide, BankOrderType, double, double?)?
        onSubmit,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankBuySellSheet(
          quote: quote,
          initialSide: initialSide,
          onSubmit: onSubmit,
        ),
      );

  @override
  State<BankBuySellSheet> createState() => _BankBuySellSheetState();
}

class _BankBuySellSheetState extends State<BankBuySellSheet> {
  late BankOrderSide _side;
  BankOrderType _orderType = BankOrderType.market;
  final _amountCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  double get _enteredAmount => double.tryParse(_amountCtrl.text) ?? 0;
  double get _limitPrice => double.tryParse(_limitCtrl.text) ?? 0;
  double get _currentPrice => widget.quote.price.amount.toDouble();
  double get _estimatedUnits =>
      _currentPrice > 0 ? _enteredAmount / _currentPrice : 0;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final priceStr = BankMoneyFormatter.format(
      amount: widget.quote.price.amount,
      currencyCode: widget.quote.price.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.sheetRadius,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(BankTokens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: BankTokens.space4),
                  decoration: BoxDecoration(
                    color: theme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SegmentedButton<BankOrderSide>(
                segments: const [
                  ButtonSegment(value: BankOrderSide.buy, label: Text('Buy')),
                  ButtonSegment(value: BankOrderSide.sell, label: Text('Sell')),
                ],
                selected: {_side},
                onSelectionChanged: (s) => setState(() => _side = s.first),
              ),
              const SizedBox(height: BankTokens.space4),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.surfaceVariant,
                    backgroundImage: widget.quote.logoUrl != null
                        ? NetworkImage(widget.quote.logoUrl!)
                        : null,
                    child: widget.quote.logoUrl == null
                        ? Text(
                            widget.quote.symbol.isNotEmpty
                                ? widget.quote.symbol[0]
                                : '?',
                            style: BankTokens.labelSmall
                                .copyWith(color: theme.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: BankTokens.space2),
                  Text(
                    widget.quote.symbol,
                    style:
                        BankTokens.labelLarge.copyWith(color: theme.onSurface),
                  ),
                  const Spacer(),
                  Text(
                    priceStr,
                    style: BankTokens.numeralSmall
                        .copyWith(color: theme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: BankTokens.space4),
              if (widget.allowLimitOrder) ...[
                SegmentedButton<BankOrderType>(
                  segments: const [
                    ButtonSegment(
                      value: BankOrderType.market,
                      label: Text('Market'),
                    ),
                    ButtonSegment(
                      value: BankOrderType.limit,
                      label: Text('Limit'),
                    ),
                  ],
                  selected: {_orderType},
                  onSelectionChanged: (s) =>
                      setState(() => _orderType = s.first),
                ),
                const SizedBox(height: BankTokens.space3),
              ],
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount (${widget.quote.price.currencyCode})',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_orderType == BankOrderType.limit) ...[
                const SizedBox(height: BankTokens.space3),
                TextField(
                  controller: _limitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Limit Price',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: BankTokens.space2),
              if (_enteredAmount > 0)
                Text(
                  '≈ ${_estimatedUnits.toStringAsFixed(4)} ${widget.quote.symbol}',
                  style: BankTokens.bodySmall
                      .copyWith(color: theme.onSurfaceVariant),
                  textAlign: TextAlign.end,
                ),
              if (widget.availableBalance != null)
                Padding(
                  padding: const EdgeInsets.only(top: BankTokens.space1),
                  child: Text(
                    'Available: ${BankMoneyFormatter.format(amount: widget.availableBalance!.amount, currencyCode: widget.availableBalance!.currencyCode)}',
                    style: BankTokens.bodySmall
                        .copyWith(color: theme.onSurfaceVariant),
                    textAlign: TextAlign.end,
                  ),
                ),
              const SizedBox(height: BankTokens.space4),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: (_enteredAmount > 0 && !_loading)
                      ? () async {
                          setState(() => _loading = true);
                          await widget.onSubmit?.call(
                            _side,
                            _orderType,
                            _enteredAmount,
                            _orderType == BankOrderType.limit
                                ? _limitPrice
                                : null,
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      : null,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _side == BankOrderSide.buy ? 'Review Buy' : 'Review Sell',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
