import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/bank_icon_spec.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// The kind of account identifier rendered by [BankAccountNumberText].
///
/// Each kind selects a display grouping in [BankAccountNumberFormatter]:
/// - [iban] / [bban] / [pan] → groups of 4 separated by spaces
/// - [sortCode] → pairs separated by hyphens (`NN-NN-NN`)
/// - [routing] / [swiftBic] → rendered without grouping
enum BankAccountNumberKind {
  /// International Bank Account Number (e.g. `GB29 NWBK 6016 1331 9268 19`).
  iban,

  /// Basic Bank Account Number: the domestic part of an IBAN.
  bban,

  /// Primary Account Number: the long card number.
  pan,

  /// UK sort code, displayed as `NN-NN-NN`.
  sortCode,

  /// US ABA routing number, displayed ungrouped.
  routing,

  /// SWIFT/BIC code, displayed ungrouped.
  swiftBic,
}

/// Formats and masks account identifiers for display.
///
/// Used internally by [BankAccountNumberText]; also reusable by other
/// widgets (e.g. a card back face or a receipt view) that need the same
/// grouping rules without the copy affordance.
///
/// ```dart
/// BankAccountNumberFormatter.format(
///   'GB29NWBK60161331926819',
///   BankAccountNumberKind.iban,
/// ); // 'GB29 NWBK 6016 1331 9268 19'
///
/// BankAccountNumberFormatter.mask(
///   '4111111111111111',
///   BankAccountNumberKind.pan,
/// ); // '•••• •••• •••• 1111'
/// ```
abstract final class BankAccountNumberFormatter {
  static final RegExp _separators = RegExp(r'[\s-]');

  /// Strips spaces and hyphens, returning the raw identifier: the exact
  /// string [BankAccountNumberText] places on the clipboard.
  static String normalize(String value) => value.replaceAll(_separators, '');

  /// Groups [value] for display according to [kind].
  ///
  /// The input is normalised first, so already-grouped values are safe.
  static String format(String value, BankAccountNumberKind kind) {
    final raw = normalize(value);
    return switch (kind) {
      BankAccountNumberKind.iban ||
      BankAccountNumberKind.bban ||
      BankAccountNumberKind.pan =>
        _group(raw, 4, ' '),
      BankAccountNumberKind.sortCode => _group(raw, 2, '-'),
      BankAccountNumberKind.routing || BankAccountNumberKind.swiftBic => raw,
    };
  }

  /// Replaces all but the last four characters of [value] with `•` bullets,
  /// then applies the same grouping as [format].
  ///
  /// Values of four characters or fewer are returned fully visible.
  static String mask(String value, BankAccountNumberKind kind) {
    final raw = normalize(value);
    if (raw.length <= 4) return format(raw, kind);
    final hidden = '•' * (raw.length - 4);
    final visible = raw.substring(raw.length - 4);
    return format('$hidden$visible', kind);
  }

  static String _group(String raw, int size, String separator) {
    if (raw.isEmpty) return raw;
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i += size) {
      if (i > 0) buffer.write(separator);
      final end = (i + size > raw.length) ? raw.length : i + size;
      buffer.write(raw.substring(i, end));
    }
    return buffer.toString();
  }
}

/// Display widget for account identifiers: IBANs, card numbers, sort
/// codes, routing numbers and SWIFT/BIC codes: with kind-aware grouping,
/// masking and a one-tap copy affordance.
///
/// Use it anywhere an account detail is surfaced: account detail sheets,
/// share-my-details screens, card back faces and receipts.
///
/// - Grouping follows [kind] via [BankAccountNumberFormatter] (IBAN/PAN in
///   groups of 4, sort code as `NN-NN-NN`).
/// - When [masked] is `true`: or privacy mode is active on the ambient
///   [BankUiScope]: only the last four characters are shown; the rest are
///   replaced with `•` bullets.
/// - When [copyEnabled] is `true`, a copy icon (44 px tap target) copies
///   the **unformatted** full value to the clipboard, swaps to a success
///   check for 1.5 s, and fires [onCopied] so the host can confirm with a
///   toast.
/// - Screen readers announce the characters individually
///   (`G B 2 9 N W B K…`), never as one large number.
/// - Digits respect the ambient [NumeralStyle]; the identifier itself is
///   always laid out left-to-right, even in RTL locales.
///
/// ```dart
/// BankAccountNumberText(
///   value: 'GB29NWBK60161331926819',
///   kind: BankAccountNumberKind.iban,
///   label: 'IBAN',
///   onCopied: () => messenger.showToast('IBAN copied'),
/// )
/// ```
class BankAccountNumberText extends StatefulWidget {
  /// The raw identifier. Spaces and hyphens are tolerated and stripped
  /// before formatting and copying.
  final String value;

  /// Which kind of identifier [value] is; controls the display grouping.
  final BankAccountNumberKind kind;

  /// When `true`, only the last four characters are shown; the rest are
  /// replaced with bullets. Masking is also forced while privacy mode is
  /// active on the ambient [BankUiScope].
  final bool masked;

  /// Whether to render the copy affordance next to the identifier.
  final bool copyEnabled;

  /// Called after the value has been copied to the clipboard, so the host
  /// can surface a confirmation (e.g. a toast banner).
  final VoidCallback? onCopied;

  /// Override for the identifier text style. Defaults to the theme's
  /// medium numeral style in the on-surface colour.
  final TextStyle? style;

  /// Optional caption rendered above the identifier (e.g. `'IBAN'`).
  final String? label;

  /// Accessibility label for the copy button.
  final String copySemanticLabel;

  /// Merged over the caption style ([BankTokens.labelMedium] in the
  /// on-surface-variant colour).
  final TextStyle? labelStyle;

  /// Overrides the copy glyph. Defaults to [BankIcons.copy].
  final IconData? copyIcon;

  /// Overrides the post-copy success glyph. Defaults to
  /// [BankIcons.success].
  final IconData? copiedIcon;

  /// Overrides the idle copy-icon colour. Defaults to the theme
  /// `onSurfaceVariant`.
  final Color? copyIconColor;

  /// Overrides the post-copy icon colour. Defaults to
  /// [BankTokens.success].
  final Color? copiedIconColor;

  /// Overrides the icon cross-fade duration. Defaults to
  /// [BankTokens.durationFast].
  final Duration? animationDuration;

  /// Overrides the icon cross-fade curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// How long the success check stays visible after a copy. Defaults to
  /// 1.5 seconds.
  final Duration? confirmDuration;

  /// Overrides the computed (spelled-out) accessibility label.
  final String? semanticLabel;

  const BankAccountNumberText({
    required this.value,
    required this.kind,
    super.key,
    this.masked = false,
    this.copyEnabled = true,
    this.onCopied,
    this.style,
    this.label,
    this.copySemanticLabel = 'Copy',
    this.labelStyle,
    this.copyIcon,
    this.copiedIcon,
    this.copyIconColor,
    this.copiedIconColor,
    this.animationDuration,
    this.animationCurve,
    this.confirmDuration,
    this.semanticLabel,
  });

  @override
  State<BankAccountNumberText> createState() => _BankAccountNumberTextState();
}

class _BankAccountNumberTextState extends State<BankAccountNumberText> {
  static const Duration _confirmFor = Duration(milliseconds: 1500);

  Timer? _resetTimer;
  bool _copied = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: BankAccountNumberFormatter.normalize(widget.value)),
    );
    if (!mounted) return;
    setState(() => _copied = true);
    widget.onCopied?.call();
    _resetTimer?.cancel();
    _resetTimer = Timer(widget.confirmDuration ?? _confirmFor, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  /// Spells out every character of [display] individually so assistive
  /// technologies never read the identifier as a single large number.
  String _spellOut(String display) =>
      display.split('').where((c) => c != ' ' && c != '-').join(' ');

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final effectiveMasked = widget.masked || scope.privacyEnabled;
    final western = effectiveMasked
        ? BankAccountNumberFormatter.mask(widget.value, widget.kind)
        : BankAccountNumberFormatter.format(widget.value, widget.kind);
    final display = scope.numeralStyle.convert(western);

    final resolvedStyle =
        widget.style ?? theme.numeralMedium.copyWith(color: theme.onSurface);

    final spelledOut = _spellOut(western);
    final semanticLabel = widget.semanticLabel ??
        (widget.label == null ? spelledOut : '${widget.label}: $spelledOut');

    final identifier = Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: BankTokens.labelMedium
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(widget.labelStyle),
            ),
            const SizedBox(height: BankTokens.space1),
          ],
          Text(
            display,
            textDirection: TextDirection.ltr,
            style: resolvedStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (!widget.copyEnabled) return identifier;

    final copyButton = Semantics(
      button: true,
      label: widget.copySemanticLabel,
      onTap: _copy,
      excludeSemantics: true,
      child: SizedBox(
        width: BankTokens.minTapTarget,
        height: BankTokens.minTapTarget,
        child: InkResponse(
          onTap: _copy,
          radius: BankTokens.minTapTarget / 2,
          child: AnimatedSwitcher(
            duration: disableAnimations
                ? Duration.zero
                : widget.animationDuration ?? BankTokens.durationFast,
            switchInCurve: widget.animationCurve ?? BankTokens.curveStandard,
            switchOutCurve: widget.animationCurve ?? BankTokens.curveStandard,
            child: Icon(
              _copied
                  ? (widget.copiedIcon ?? BankIcons.success)
                  : (widget.copyIcon ?? BankIcons.copy),
              key: ValueKey<bool>(_copied),
              size: 20,
              color: _copied
                  ? (widget.copiedIconColor ?? BankTokens.success)
                  : (widget.copyIconColor ?? theme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: identifier),
        const SizedBox(width: BankTokens.space1),
        // InkResponse needs a Material ancestor for its ink splash.
        Material(type: MaterialType.transparency, child: copyButton),
      ],
    );
  }
}
