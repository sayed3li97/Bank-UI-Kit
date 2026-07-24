import 'dart:async';

import 'package:flutter/material.dart';

import '../common/bank_country_flag.dart';
import '../common/bank_country_picker.dart';
import '../common/bank_text_field.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// An immutable postal address captured by [BankAddressForm].
class BankAddress {
  const BankAddress({
    required this.line1,
    required this.city,
    required this.postalCode,
    required this.country,
    this.line2,
    this.region,
  });

  final String line1;
  final String? line2;
  final String city;

  /// State / province / emirate, when the country uses one.
  final String? region;

  final String postalCode;
  final BankCountry country;

  BankAddress copyWith({
    String? line1,
    String? line2,
    String? city,
    String? region,
    String? postalCode,
    BankCountry? country,
  }) =>
      BankAddress(
        line1: line1 ?? this.line1,
        line2: line2 ?? this.line2,
        city: city ?? this.city,
        region: region ?? this.region,
        postalCode: postalCode ?? this.postalCode,
        country: country ?? this.country,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankAddress &&
          other.line1 == line1 &&
          other.line2 == line2 &&
          other.city == city &&
          other.region == region &&
          other.postalCode == postalCode &&
          other.country.isoCode == country.isoCode;

  @override
  int get hashCode =>
      Object.hash(line1, line2, city, region, postalCode, country.isoCode);

  /// Lines in the country's conventional display order.
  List<String> displayLines() => [
        line1,
        if (line2 != null && line2!.isNotEmpty) line2!,
        [
          city,
          if (region != null && region!.isNotEmpty) region!,
          postalCode,
        ].join(', '),
        country.name,
      ];
}

/// Structured postal-address capture with per-country layout: US/CA get
/// a region dropdown and numeric ZIP handling, the UK gets postcode
/// formatting, everywhere else gets free-text region. Required-field
/// validation runs on focus loss with `BankTextField` danger states;
/// [onChanged] emits null while the address is incomplete.
///
/// When [onLookup] is provided, the first line becomes a debounced
/// type-ahead and selecting a suggestion fills every field.
///
/// ```dart
/// BankAddressForm(
///   defaultCountry: gcc.first,
///   onChanged: (address) => setState(() => _address = address),
/// )
/// ```
class BankAddressForm extends StatefulWidget {
  const BankAddressForm({
    required this.onChanged,
    required this.defaultCountry,
    super.key,
    this.initial,
    this.countryEditable = true,
    this.onLookup,
    this.countryLabel = 'Country',
    this.line1Label = 'Address line 1',
    this.line2Label = 'Address line 2 (optional)',
    this.cityLabel = 'City',
    this.regionLabel = 'State / region',
    this.postalCodeLabel = 'Postal code',
    this.requiredError = 'Required',
    this.postalCodeError = 'Enter a valid postal code',
    this.lookupDebounce,
    this.suggestionBackgroundColor,
    this.suggestionRadius,
    this.suggestionStyle,
    this.fieldSpacing,
  });

  /// Emits the complete address, or null while any required field is
  /// missing or invalid.
  final ValueChanged<BankAddress?> onChanged;

  final BankCountry defaultCountry;
  final BankAddress? initial;
  final bool countryEditable;

  /// Debounced (300 ms) address search; selecting a result fills all
  /// fields.
  final Future<List<BankAddress>> Function(String query)? onLookup;

  final String countryLabel;
  final String line1Label;
  final String line2Label;
  final String cityLabel;
  final String regionLabel;
  final String postalCodeLabel;
  final String requiredError;
  final String postalCodeError;

  /// Overrides the [onLookup] debounce. Defaults to 300 ms.
  final Duration? lookupDebounce;

  /// Fill of the suggestion dropdown. Defaults to the theme surface.
  final Color? suggestionBackgroundColor;

  /// Corner radius of the suggestion dropdown. Defaults to the theme
  /// buttonRadius.
  final BorderRadius? suggestionRadius;

  /// Merged over the computed suggestion row style (bodyMedium).
  final TextStyle? suggestionStyle;

  /// Vertical gap between form fields. Defaults to
  /// [BankTokens.space4].
  final double? fieldSpacing;

  @override
  State<BankAddressForm> createState() => _BankAddressFormState();
}

class _BankAddressFormState extends State<BankAddressForm> {
  static const _usStates = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', //
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
    'DC',
  ];
  static const _caProvinces = [
    'AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU', //
    'ON', 'PE', 'QC', 'SK', 'YT',
  ];

  late BankCountry _country;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _regionText;
  late final TextEditingController _postal;
  String? _regionDropdown;

  final Set<String> _touched = <String>{};
  Timer? _lookupDebounce;
  List<BankAddress> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _country = initial?.country ?? widget.defaultCountry;
    _line1 = TextEditingController(text: initial?.line1 ?? '');
    _line2 = TextEditingController(text: initial?.line2 ?? '');
    _city = TextEditingController(text: initial?.city ?? '');
    _regionText = TextEditingController(text: initial?.region ?? '');
    _postal = TextEditingController(text: initial?.postalCode ?? '');
    if (_hasRegionDropdown && _regionOptions.contains(initial?.region)) {
      _regionDropdown = initial?.region;
    }
  }

  @override
  void dispose() {
    _lookupDebounce?.cancel();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _regionText.dispose();
    _postal.dispose();
    super.dispose();
  }

  bool get _hasRegionDropdown =>
      _country.isoCode == 'US' || _country.isoCode == 'CA';

  List<String> get _regionOptions =>
      _country.isoCode == 'US' ? _usStates : _caProvinces;

  String? get _region =>
      _hasRegionDropdown ? _regionDropdown : _regionText.text.trim();

  bool get _postalValid {
    final value = _postal.text.trim();
    if (value.isEmpty) return false;
    return switch (_country.isoCode) {
      'US' => RegExp(r'^\d{5}(-\d{4})?$').hasMatch(value),
      'CA' => RegExp(r'^[A-Za-z]\d[A-Za-z] ?\d[A-Za-z]\d$').hasMatch(value),
      'GB' => RegExp(
          r'^[A-Za-z]{1,2}\d[A-Za-z\d]? ?\d[A-Za-z]{2}$',
        ).hasMatch(value),
      _ => value.length >= 3,
    };
  }

  bool get _regionValid => !_hasRegionDropdown || _regionDropdown != null;

  BankAddress? get _current {
    if (_line1.text.trim().isEmpty ||
        _city.text.trim().isEmpty ||
        !_postalValid ||
        !_regionValid) {
      return null;
    }
    return BankAddress(
      line1: _line1.text.trim(),
      line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
      city: _city.text.trim(),
      region: _region?.isEmpty ?? true ? null : _region,
      postalCode: _postal.text.trim(),
      country: _country,
    );
  }

  void _emit() => widget.onChanged(_current);

  void _markTouched(String field) {
    if (_touched.add(field)) setState(() {});
  }

  String? _errorFor(String field, bool valid) =>
      _touched.contains(field) && !valid ? widget.requiredError : null;

  void _onLine1Changed(String text) {
    _emit();
    final lookup = widget.onLookup;
    if (lookup == null) return;
    _lookupDebounce?.cancel();
    if (text.trim().length < 3) {
      setState(() => _suggestions = const []);
      return;
    }
    _lookupDebounce = Timer(
        widget.lookupDebounce ?? const Duration(milliseconds: 300), () async {
      List<BankAddress> results;
      try {
        results = await lookup(text.trim());
      } on Object {
        results = const [];
      }
      if (mounted) setState(() => _suggestions = results);
    });
  }

  void _applySuggestion(BankAddress address) {
    setState(() {
      _country = address.country;
      _line1.text = address.line1;
      _line2.text = address.line2 ?? '';
      _city.text = address.city;
      _postal.text = address.postalCode;
      if (_hasRegionDropdown && _regionOptions.contains(address.region)) {
        _regionDropdown = address.region;
      } else {
        _regionText.text = address.region ?? '';
      }
      _suggestions = const [];
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final gap = widget.fieldSpacing ?? BankTokens.space4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BankCountryPicker(
          onSelected: (country) {
            setState(() {
              _country = country;
              _regionDropdown = null;
            });
            _emit();
          },
          selected: _country,
          label: widget.countryLabel,
          enabled: widget.countryEditable,
        ),
        SizedBox(height: gap),
        Focus(
          onFocusChange: (focused) {
            if (!focused) _markTouched('line1');
          },
          child: BankTextField(
            controller: _line1,
            label: widget.line1Label,
            errorText: _errorFor('line1', _line1.text.trim().isNotEmpty),
            onChanged: _onLine1Changed,
          ),
        ),
        if (_suggestions.isNotEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: widget.suggestionBackgroundColor ?? theme.surface,
              border: Border.all(color: theme.outline),
              borderRadius: widget.suggestionRadius ?? theme.buttonRadius,
            ),
            child: Column(
              children: [
                for (final suggestion in _suggestions.take(4))
                  ListTile(
                    dense: true,
                    title: Text(
                      suggestion.displayLines().join(', '),
                      style: BankTokens.bodyMedium
                          .copyWith(color: theme.onSurface)
                          .merge(widget.suggestionStyle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _applySuggestion(suggestion),
                  ),
              ],
            ),
          ),
        SizedBox(height: gap),
        BankTextField(
          controller: _line2,
          label: widget.line2Label,
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Focus(
                onFocusChange: (focused) {
                  if (!focused) _markTouched('city');
                },
                child: BankTextField(
                  controller: _city,
                  label: widget.cityLabel,
                  errorText: _errorFor('city', _city.text.trim().isNotEmpty),
                  onChanged: (_) => _emit(),
                ),
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: _hasRegionDropdown
                  ? _RegionDropdown(
                      label: widget.regionLabel,
                      value: _regionDropdown,
                      options: _regionOptions,
                      errorText: _errorFor('region', _regionValid),
                      theme: theme,
                      onChanged: (value) {
                        setState(() => _regionDropdown = value);
                        _markTouched('region');
                        _emit();
                      },
                    )
                  : BankTextField(
                      controller: _regionText,
                      label: widget.regionLabel,
                      onChanged: (_) => _emit(),
                    ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Focus(
          onFocusChange: (focused) {
            if (!focused) _markTouched('postal');
          },
          child: BankTextField(
            controller: _postal,
            label: widget.postalCodeLabel,
            keyboardType: _country.isoCode == 'US'
                ? TextInputType.number
                : TextInputType.text,
            errorText: _touched.contains('postal') && !_postalValid
                ? widget.postalCodeError
                : null,
            onChanged: (_) => _emit(),
          ),
        ),
      ],
    );
  }
}

class _RegionDropdown extends StatelessWidget {
  const _RegionDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.errorText,
    required this.theme,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final String? errorText;
  final BankThemeData theme;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: BankTokens.space2),
          child: Text(
            label,
            style: BankTokens.labelMedium.copyWith(
              color: errorText != null ? BankTokens.danger : theme.onSurface,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: onChanged,
          style: BankTokens.bodyLarge.copyWith(color: theme.onSurface),
          dropdownColor: theme.surface,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.surface,
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space3,
            ),
            border: OutlineInputBorder(
              borderRadius: theme.buttonRadius,
              borderSide: BorderSide(color: theme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: theme.buttonRadius,
              borderSide: BorderSide(color: theme.outline),
            ),
          ),
        ),
      ],
    );
  }
}

/// Read-only address card for review steps, with an edit affordance.
/// Compose into `BankSummaryStack` rows via `valueWidget` or place it
/// standalone under a section header.
class BankAddressPreview extends StatelessWidget {
  const BankAddressPreview({
    required this.address,
    super.key,
    this.onEdit,
    this.editLabel = 'Edit',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.shadow,
    this.lineStyle,
    this.editLabelStyle,
  });

  final BankAddress address;
  final VoidCallback? onEdit;
  final String editLabel;

  /// Overrides the card content padding. Defaults to
  /// [BankTokens.space4] on all sides.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme
  /// cardRadius.
  final BorderRadius? radius;

  /// Overrides the card fill. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCard];
  /// pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Merged over the computed address line style (bodyMedium).
  final TextStyle? lineStyle;

  /// Merged over the computed edit button style (labelLarge, primary).
  final TextStyle? editLabelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final lines = address.displayLines();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.surface,
        borderRadius: radius ?? theme.cardRadius,
        border: Border.all(color: theme.outline),
        boxShadow: shadow ?? BankTokens.shadowCard,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(BankTokens.space4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nudge the 16 px chip to sit optically centred against the
            // ~20 px first line of bodyMedium address text.
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: BankCountryFlag(
                isoCode: address.country.isoCode,
                countryName: address.country.name,
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in lines)
                    Text(
                      line,
                      style: BankTokens.bodyMedium
                          .copyWith(color: theme.onSurface)
                          .merge(lineStyle),
                    ),
                ],
              ),
            ),
            if (onEdit != null)
              TextButton(
                onPressed: onEdit,
                child: Text(
                  editLabel,
                  style: BankTokens.labelLarge
                      .copyWith(color: theme.primary)
                      .merge(editLabelStyle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
