/// Display metadata for a currency, following each currency's own
/// presentation guidelines: official symbol, ISO 4217 minor units, and
/// symbol placement.
///
/// Notable entries:
/// - SAR uses the official Saudi riyal symbol (U+20C1) introduced by
///   SAMA in 2025 and standardized in Unicode 17.
/// - Gulf dinars and rials that subdivide into 1000 (KWD, BHD, OMR,
///   JOD, IQD, TND, LYD) carry three decimal places.
/// - Zero-decimal currencies (JPY, KRW, VND, CLP, ISK) never render a
///   fraction.
/// - Arabic-script symbols are wrapped in Unicode directional isolates
///   when composed, so they render correctly inside LTR layouts.
class BankCurrency {
  const BankCurrency({
    required this.code,
    required this.symbol,
    required this.name,
    this.decimalDigits = 2,
    this.symbolBeforeAmount = true,
    this.spaceBetweenSymbolAndAmount = false,
    this.symbolIsRtlScript = false,
  });

  /// ISO 4217 alphabetic code, e.g. `'SAR'`.
  final String code;

  /// Official display symbol, e.g. `'⃁'` for the Saudi riyal.
  final String symbol;

  /// English currency name.
  final String name;

  /// ISO 4217 minor units (0, 2, or 3).
  final int decimalDigits;

  /// Whether the symbol precedes the amount per that currency's
  /// convention in Latin-script contexts.
  final bool symbolBeforeAmount;

  /// Whether a thin gap separates symbol and amount.
  final bool spaceBetweenSymbolAndAmount;

  /// Symbol is written in an RTL script and needs directional
  /// isolation when embedded in LTR text.
  final bool symbolIsRtlScript;

  /// The symbol as it should be embedded in composed strings:
  /// RTL-script symbols are wrapped in FSI/PDI isolates.
  String get embeddableSymbol =>
      symbolIsRtlScript ? '\u2068$symbol\u2069' : symbol;
}

/// Registry of currency display metadata used by `BankMoneyFormatter`,
/// `BankAmountInputField`, and every money-rendering widget.
///
/// Unknown codes degrade gracefully: [of] returns a generic entry that
/// renders as `CODE amount` with two decimals. Host apps can register
/// additional or overriding entries at startup via [register].
abstract final class BankCurrencies {
  static final Map<String, BankCurrency> _custom = {};

  /// Resolves display metadata for [code], falling back to a generic
  /// `CODE amount` presentation for unknown currencies.
  static BankCurrency of(String code) {
    final upper = code.toUpperCase();
    return _custom[upper] ??
        _builtIn[upper] ??
        BankCurrency(code: upper, symbol: '$upper ', name: upper);
  }

  /// Registers or overrides a currency at runtime (e.g. a loyalty
  /// currency or a corrected symbol).
  static void register(BankCurrency currency) {
    _custom[currency.code.toUpperCase()] = currency;
  }

  /// Whether [code] is a known (built-in or registered) currency.
  static bool isKnown(String code) {
    final upper = code.toUpperCase();
    return _custom.containsKey(upper) || _builtIn.containsKey(upper);
  }

  /// All known currencies — built-in plus any registered at runtime — sorted
  /// by ISO code. Useful for building a currency picker or a formatting demo.
  static List<BankCurrency> get all {
    final merged = <String, BankCurrency>{..._builtIn, ..._custom};
    final codes = merged.keys.toList()..sort();
    return [for (final c in codes) merged[c]!];
  }

  /// All known ISO 4217 codes, sorted.
  static List<String> get codes => [for (final c in all) c.code];

  static const Map<String, BankCurrency> _builtIn = {
    // ── Americas ─────────────────────────────────────────────────────
    'USD': BankCurrency(code: 'USD', symbol: r'$', name: 'US Dollar'),
    'CAD': BankCurrency(code: 'CAD', symbol: r'CA$', name: 'Canadian Dollar'),
    'BRL': BankCurrency(code: 'BRL', symbol: r'R$', name: 'Brazilian Real'),
    'MXN': BankCurrency(code: 'MXN', symbol: r'MX$', name: 'Mexican Peso'),
    'ARS': BankCurrency(code: 'ARS', symbol: r'AR$', name: 'Argentine Peso'),
    'CLP': BankCurrency(
      code: 'CLP',
      symbol: r'CLP$',
      name: 'Chilean Peso',
      decimalDigits: 0,
    ),
    'COP': BankCurrency(code: 'COP', symbol: r'COL$', name: 'Colombian Peso'),

    // ── Europe ───────────────────────────────────────────────────────
    'EUR': BankCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
    'GBP': BankCurrency(code: 'GBP', symbol: '£', name: 'Pound Sterling'),
    'CHF': BankCurrency(
      code: 'CHF',
      symbol: 'CHF',
      name: 'Swiss Franc',
      spaceBetweenSymbolAndAmount: true,
    ),
    'SEK': BankCurrency(
      code: 'SEK',
      symbol: 'kr',
      name: 'Swedish Krona',
      symbolBeforeAmount: false,
      spaceBetweenSymbolAndAmount: true,
    ),
    'NOK': BankCurrency(
      code: 'NOK',
      symbol: 'kr',
      name: 'Norwegian Krone',
      symbolBeforeAmount: false,
      spaceBetweenSymbolAndAmount: true,
    ),
    'DKK': BankCurrency(
      code: 'DKK',
      symbol: 'kr',
      name: 'Danish Krone',
      symbolBeforeAmount: false,
      spaceBetweenSymbolAndAmount: true,
    ),
    'PLN': BankCurrency(
      code: 'PLN',
      symbol: 'zł',
      name: 'Polish Zloty',
      symbolBeforeAmount: false,
      spaceBetweenSymbolAndAmount: true,
    ),
    'CZK': BankCurrency(
      code: 'CZK',
      symbol: 'Kč',
      name: 'Czech Koruna',
      symbolBeforeAmount: false,
      spaceBetweenSymbolAndAmount: true,
    ),
    'HUF': BankCurrency(
      code: 'HUF',
      symbol: 'Ft',
      name: 'Hungarian Forint',
      symbolBeforeAmount: false,
      spaceBetweenSymbolAndAmount: true,
    ),
    'ISK': BankCurrency(
      code: 'ISK',
      symbol: 'kr',
      name: 'Icelandic Krona',
      decimalDigits: 0,
      symbolBeforeAmount: false,
      spaceBetweenSymbolAndAmount: true,
    ),
    'TRY': BankCurrency(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    'RUB': BankCurrency(
      code: 'RUB',
      symbol: '₽',
      name: 'Russian Ruble',
      symbolBeforeAmount: false,
      spaceBetweenSymbolAndAmount: true,
    ),
    'UAH': BankCurrency(code: 'UAH', symbol: '₴', name: 'Ukrainian Hryvnia'),

    // ── Gulf & Middle East ───────────────────────────────────────────
    // SAR defaults to the traditional abbreviation because the official
    // riyal symbol (U+20C1, adopted 2025) is still missing from most
    // shipped fonts and would render as a placeholder box. Apps whose
    // bundled font contains the glyph can opt in:
    //   BankCurrencies.register(BankCurrency(
    //     code: 'SAR',
    //     symbol: '\u20C1',
    //     name: 'Saudi Riyal',
    //     spaceBetweenSymbolAndAmount: true,
    //   ));
    'SAR': BankCurrency(
      code: 'SAR',
      symbol: '\u0631.\u0633',
      name: 'Saudi Riyal',
      spaceBetweenSymbolAndAmount: true,
      symbolIsRtlScript: true,
    ),
    'AED': BankCurrency(
      code: 'AED',
      symbol: 'د.إ',
      name: 'UAE Dirham',
      spaceBetweenSymbolAndAmount: true,
      symbolIsRtlScript: true,
    ),
    'QAR': BankCurrency(
      code: 'QAR',
      symbol: 'ر.ق',
      name: 'Qatari Riyal',
      spaceBetweenSymbolAndAmount: true,
      symbolIsRtlScript: true,
    ),
    'KWD': BankCurrency(
      code: 'KWD',
      symbol: 'د.ك',
      name: 'Kuwaiti Dinar',
      decimalDigits: 3,
      spaceBetweenSymbolAndAmount: true,
      symbolIsRtlScript: true,
    ),
    'BHD': BankCurrency(
      code: 'BHD',
      symbol: 'د.ب',
      name: 'Bahraini Dinar',
      decimalDigits: 3,
      spaceBetweenSymbolAndAmount: true,
      symbolIsRtlScript: true,
    ),
    'OMR': BankCurrency(
      code: 'OMR',
      symbol: 'ر.ع.',
      name: 'Omani Rial',
      decimalDigits: 3,
      spaceBetweenSymbolAndAmount: true,
      symbolIsRtlScript: true,
    ),
    'JOD': BankCurrency(
      code: 'JOD',
      symbol: 'د.أ',
      name: 'Jordanian Dinar',
      decimalDigits: 3,
      spaceBetweenSymbolAndAmount: true,
      symbolIsRtlScript: true,
    ),
    'IQD': BankCurrency(
      code: 'IQD',
      symbol: 'ع.د',
      name: 'Iraqi Dinar',
      decimalDigits: 3,
      spaceBetweenSymbolAndAmount: true,
      symbolIsRtlScript: true,
    ),
    'EGP': BankCurrency(
      code: 'EGP',
      symbol: 'E£',
      name: 'Egyptian Pound',
    ),
    'ILS': BankCurrency(code: 'ILS', symbol: '₪', name: 'Israeli New Shekel'),
    'TND': BankCurrency(
      code: 'TND',
      symbol: 'د.ت',
      name: 'Tunisian Dinar',
      decimalDigits: 3,
      spaceBetweenSymbolAndAmount: true,
      symbolIsRtlScript: true,
    ),
    'MAD': BankCurrency(
      code: 'MAD',
      symbol: 'د.م.',
      name: 'Moroccan Dirham',
      spaceBetweenSymbolAndAmount: true,
      symbolIsRtlScript: true,
    ),

    // ── Africa ───────────────────────────────────────────────────────
    'NGN': BankCurrency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
    'ZAR': BankCurrency(
      code: 'ZAR',
      symbol: 'R',
      name: 'South African Rand',
      spaceBetweenSymbolAndAmount: true,
    ),
    'KES': BankCurrency(
      code: 'KES',
      symbol: 'KSh',
      name: 'Kenyan Shilling',
      spaceBetweenSymbolAndAmount: true,
    ),
    'GHS': BankCurrency(code: 'GHS', symbol: 'GH₵', name: 'Ghanaian Cedi'),

    // ── Asia-Pacific ─────────────────────────────────────────────────
    'JPY': BankCurrency(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      decimalDigits: 0,
    ),
    'CNY': BankCurrency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    'HKD': BankCurrency(code: 'HKD', symbol: r'HK$', name: 'Hong Kong Dollar'),
    'TWD': BankCurrency(
      code: 'TWD',
      symbol: r'NT$',
      name: 'New Taiwan Dollar',
    ),
    'KRW': BankCurrency(
      code: 'KRW',
      symbol: '₩',
      name: 'South Korean Won',
      decimalDigits: 0,
    ),
    'INR': BankCurrency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    'PKR': BankCurrency(
      code: 'PKR',
      symbol: 'Rs',
      name: 'Pakistani Rupee',
      spaceBetweenSymbolAndAmount: true,
    ),
    'BDT': BankCurrency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    'LKR': BankCurrency(
      code: 'LKR',
      symbol: 'Rs',
      name: 'Sri Lankan Rupee',
      spaceBetweenSymbolAndAmount: true,
    ),
    'VND': BankCurrency(
      code: 'VND',
      symbol: '₫',
      name: 'Vietnamese Dong',
      decimalDigits: 0,
      symbolBeforeAmount: false,
    ),
    'IDR': BankCurrency(
      code: 'IDR',
      symbol: 'Rp',
      name: 'Indonesian Rupiah',
      decimalDigits: 0,
    ),
    'MYR': BankCurrency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
    'SGD': BankCurrency(code: 'SGD', symbol: r'S$', name: 'Singapore Dollar'),
    'THB': BankCurrency(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    'PHP': BankCurrency(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
    'AUD': BankCurrency(code: 'AUD', symbol: r'A$', name: 'Australian Dollar'),
    'NZD': BankCurrency(
      code: 'NZD',
      symbol: r'NZ$',
      name: 'New Zealand Dollar',
    ),

    // ── Crypto (display conventions) ─────────────────────────────────
    'BTC': BankCurrency(
      code: 'BTC',
      symbol: '₿',
      name: 'Bitcoin',
      decimalDigits: 8,
    ),
    'ETH': BankCurrency(
      code: 'ETH',
      symbol: 'Ξ',
      name: 'Ether',
      decimalDigits: 6,
    ),
    'USDT': BankCurrency(code: 'USDT', symbol: '₮', name: 'Tether'),
  };
}
