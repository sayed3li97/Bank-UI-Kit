import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

/// The Meridian "Currencies" screen: proof that the kit renders **one** amount
/// across every ISO 4217 convention — and any currency you register yourself.
///
/// A single [Decimal] (`1,234,567.891`) is fed to [BankMoneyFormatter] for each
/// currency; the differences you see (decimal places, symbol glyph, symbol
/// placement, right-to-left isolation, numeral script) are entirely
/// currency-driven, not locale-driven. A Western / Arabic-Indic toggle rebuilds
/// every row so you can see the numeral system swap live.
///
/// It relies on the ambient BankUiScope / BankThemeData / Directionality from
/// the showcase harness — it creates none of its own.
class FlagshipCurrencies extends StatefulWidget {
  const FlagshipCurrencies({super.key});

  @override
  State<FlagshipCurrencies> createState() => _FlagshipCurrenciesState();
}

class _FlagshipCurrenciesState extends State<FlagshipCurrencies> {
  NumeralStyle _numerals = NumeralStyle.western;

  /// The shared amount every "money" row formats. Deliberately three-decimal so
  /// 3-decimal currencies (KWD/OMR/BHD) show all three places while 2- and
  /// 0-decimal currencies round correctly.
  static final Decimal _shared = Decimal.parse('1234567.891');

  /// A right-sized amount for high-precision assets (crypto), where the shared
  /// millions would drown the fractional detail.
  static final Decimal _crypto = Decimal.parse('1.23456789');

  @override
  void initState() {
    super.initState();
    // Demonstrate that ANY currency the kit doesn't ship can be added in one
    // call — here an airline loyalty currency with no decimals and a trailing
    // symbol. Registered once, it formats through the exact same pipeline as
    // USD or JPY. Idempotent, so safe across hot reloads / rebuilds.
    BankCurrencies.register(
      const BankCurrency(
        code: 'AVMILES',
        symbol: 'miles',
        name: 'Meridian Miles',
        decimalDigits: 0,
        symbolBeforeAmount: false,
        spaceBetweenSymbolAndAmount: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: BankAppBar(
        title: 'Currencies',
        actions: [
          _NumeralToggle(
            value: _numerals,
            onChanged: (v) => setState(() => _numerals = v),
          ),
          const SizedBox(width: BankTokens.space2),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BankTokens.space4,
          BankTokens.space5,
          BankTokens.space4,
          BankTokens.space10,
        ),
        children: [
          _Intro(shared: _shared, numerals: _numerals),
          const SizedBox(height: BankTokens.space6),
          for (final group in _groups) ...[
            _GroupCard(
              group: group,
              numerals: _numerals,
              shared: _shared,
              crypto: _crypto,
            ),
            const SizedBox(height: BankTokens.space4),
          ],
        ],
      ),
    );
  }

  /// Representative currencies grouped by the behaviour they demonstrate. Each
  /// group is a "best scenario" for one formatting dimension.
  static const List<_Group> _groups = [
    _Group(
      title: 'Two decimals · symbol leads',
      note: 'The default. Symbol before the amount, grouped thousands.',
      rows: [
        _Row('USD'),
        _Row('EUR'),
        _Row('GBP'),
        _Row('INR'),
      ],
    ),
    _Group(
      title: 'Zero decimals · no fraction',
      note: 'Yen, won and dong have no minor unit — the fraction is dropped, '
          'not shown as .00.',
      rows: [
        _Row('JPY'),
        _Row('KRW'),
        _Row('VND'),
      ],
    ),
    _Group(
      title: 'Three decimals · Gulf minor units',
      note: 'Dinars and rials that subdivide into 1000 keep all three places.',
      rows: [
        _Row('KWD'),
        _Row('OMR'),
        _Row('BHD'),
      ],
    ),
    _Group(
      title: 'Symbol trails the amount',
      note: 'Nordic krona, złoty and franc place the symbol after, with a '
          'non-breaking gap.',
      rows: [
        _Row('SEK'),
        _Row('PLN'),
        _Row('CHF'),
      ],
    ),
    _Group(
      title: 'Right-to-left script symbols',
      note: 'Arabic-script symbols are wrapped in Unicode directional isolates '
          'so they stay intact inside a left-to-right layout.',
      rows: [
        _Row('SAR'),
        _Row('AED'),
        _Row('QAR'),
      ],
    ),
    _Group(
      title: 'Crypto & anything you register',
      note: 'Bitcoin (8 dp) and Ether (6 dp) ship in the box. "Meridian Miles" '
          'is registered by this screen via BankCurrencies.register().',
      rows: [
        _Row('BTC', useCrypto: true),
        _Row('ETH', useCrypto: true),
        _Row('AVMILES'),
      ],
    ),
  ];
}

class _Intro extends StatelessWidget {
  const _Intro({required this.shared, required this.numerals});

  final Decimal shared;
  final NumeralStyle numerals;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    // The bare number, un-symboled, so the reader sees the single source value
    // that every row below re-dresses.
    final raw = numerals.convert(shared.toString());

    return Container(
      padding: const EdgeInsets.all(BankTokens.space5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary.withValues(alpha: 0.16),
            theme.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'One amount, every convention',
            style: BankTokens.headlineSmall.copyWith(
              color: theme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: BankTokens.space2),
          Text(
            'Every value below is the same number —',
            style:
                BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
          ),
          const SizedBox(height: BankTokens.space2),
          Text(
            raw,
            style: BankTokens.numeralMedium.copyWith(
              color: theme.primary,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: BankTokens.space2),
          Text(
            'formatted for each currency by BankMoneyFormatter. Nothing here '
            'depends on the device locale — decimals, symbol and placement are '
            'driven by the currency code alone.',
            style:
                BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.numerals,
    required this.shared,
    required this.crypto,
  });

  final _Group group;
  final NumeralStyle numerals;
  final Decimal shared;
  final Decimal crypto;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BankTokens.space4,
              BankTokens.space4,
              BankTokens.space4,
              BankTokens.space2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.title,
                  style: BankTokens.labelLarge.copyWith(
                    color: theme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BankTokens.space1),
                Text(
                  group.note,
                  style: BankTokens.bodySmall
                      .copyWith(color: theme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          for (var i = 0; i < group.rows.length; i++)
            _CurrencyRow(
              row: group.rows[i],
              numerals: numerals,
              amount: group.rows[i].useCrypto ? crypto : shared,
              divider: i < group.rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.row,
    required this.numerals,
    required this.amount,
    required this.divider,
  });

  final _Row row;
  final NumeralStyle numerals;
  final Decimal amount;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final currency = BankCurrencies.of(row.code);
    final formatted = BankMoneyFormatter.format(
      amount: amount,
      currencyCode: row.code,
      numeralStyle: numerals,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space4,
        vertical: BankTokens.space3,
      ),
      decoration: BoxDecoration(
        border: divider
            ? Border(
                bottom: BorderSide(
                  color: theme.outline.withValues(alpha: 0.35),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          _CodeBadge(code: currency.code),
          const SizedBox(width: BankTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BankTokens.bodyMedium.copyWith(
                    color: theme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${currency.decimalDigits} dp'
                  '${currency.symbolBeforeAmount ? ' · symbol first' : ' · symbol last'}',
                  style: BankTokens.labelSmall
                      .copyWith(color: theme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: BankTokens.space3),
          // The formatted money — the actual output under test. Tabular figures
          // keep the columns aligned across rows.
          Text(
            formatted,
            textAlign: TextAlign.end,
            style: BankTokens.numeralSmall.copyWith(
              color: theme.onSurface,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Container(
      width: 46,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
      ),
      child: Text(
        code.length > 4 ? code.substring(0, 4) : code,
        style: BankTokens.labelSmall.copyWith(
          color: theme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _NumeralToggle extends StatelessWidget {
  const _NumeralToggle({required this.value, required this.onChanged});

  final NumeralStyle value;
  final ValueChanged<NumeralStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Semantics(
      label: 'Numeral style',
      button: true,
      child: Material(
        color: theme.surface,
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
        child: InkWell(
          borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          onTap: () => onChanged(
            value == NumeralStyle.western
                ? NumeralStyle.easternArabicIndic
                : NumeralStyle.western,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space3,
              vertical: BankTokens.space1,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BankTokens.radiusFull),
              border:
                  Border.all(color: theme.outline.withValues(alpha: 0.7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate_rounded, size: 15, color: theme.primary),
                const SizedBox(width: BankTokens.space1),
                Text(
                  value == NumeralStyle.western ? '123' : '١٢٣',
                  style: BankTokens.labelMedium.copyWith(
                    color: theme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A behaviour-themed group of currency rows.
class _Group {
  const _Group({required this.title, required this.note, required this.rows});
  final String title;
  final String note;
  final List<_Row> rows;
}

/// One currency to render. [useCrypto] swaps in the small high-precision amount.
class _Row {
  const _Row(this.code, {this.useCrypto = false});
  final String code;
  final bool useCrypto;
}
