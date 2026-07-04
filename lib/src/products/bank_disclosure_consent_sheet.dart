import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A single pre-signature disclosure rendered as an accordion panel in a
/// [BankDisclosureConsentSheet].
///
/// When [required] is `true`, the disclosure must be expanded (acknowledged)
/// before the continue action is enabled. This encodes the regulatory
/// expectation that certain terms have been surfaced to the applicant.
@immutable
class BankDisclosure {
  /// Creates an immutable disclosure panel.
  const BankDisclosure({
    required this.title,
    required this.body,
    this.required = false,
    this.richBody,
  });

  /// Accordion header text, e.g. 'Representative example'.
  final String title;

  /// Plain-text disclosure body. Ignored when [richBody] is provided.
  final String body;

  /// When `true`, the applicant must expand this panel (acknowledge it)
  /// before continuing. Defaults to `false`.
  final bool required;

  /// Optional rich body widget (links, tables, imagery slots) rendered in
  /// place of [body] when set.
  final Widget? richBody;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankDisclosure &&
        other.title == title &&
        other.body == body &&
        other.required == required &&
        other.richBody == richBody;
  }

  @override
  int get hashCode => Object.hash(title, body, required, richBody);
}

/// A single consent checkbox rendered in the unbundled consent group of a
/// [BankDisclosureConsentSheet].
///
/// To honour no-dark-patterns rules, a [required] consent is never
/// pre-ticked regardless of [preTicked]: the applicant must make an active,
/// affirmative choice.
@immutable
class BankConsentItem {
  /// Creates an immutable consent item.
  const BankConsentItem({
    required this.id,
    required this.label,
    this.required = false,
    this.preTicked = false,
  });

  /// Stable identifier emitted through
  /// [BankDisclosureConsentSheet.onChanged] when ticked.
  final String id;

  /// Checkbox label describing what the applicant is agreeing to.
  final String label;

  /// When `true`, this consent must be ticked before continuing. Required
  /// consents are never pre-ticked. Defaults to `false`.
  final bool required;

  /// Initial ticked state for optional consents. Ignored (treated as
  /// `false`) when [required] is `true`. Defaults to `false`.
  final bool preTicked;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankConsentItem &&
        other.id == id &&
        other.label == label &&
        other.required == required &&
        other.preTicked == preTicked;
  }

  @override
  int get hashCode => Object.hash(id, label, required, preTicked);
}

// ---------------------------------------------------------------------------
// Sheet
// ---------------------------------------------------------------------------

/// The pre-signature disclosures and consent step of a product application.
///
/// Renders a list of [BankDisclosure] panels as a theme-styled accordion
/// followed by an UNbundled group of [BankConsentItem] checkboxes (each a
/// separate, individually revocable choice, never bundled into one master
/// tick). The continue action ([continueLabel], [onAgree]) stays disabled
/// until every required disclosure has been expanded (acknowledged) and
/// every required consent is ticked. The current set of ticked consent ids
/// is emitted through [onChanged] on each change.
///
/// Required consents are never pre-ticked, honouring no-dark-patterns
/// rules. An optional [footer] (or [footerText]) slot carries legal
/// microcopy beneath the consents.
///
/// Use [BankDisclosureConsentSheet.show] to present it as a modal bottom
/// sheet.
///
/// ```dart
/// BankDisclosureConsentSheet.show(
///   context,
///   disclosures: const [
///     BankDisclosure(
///       title: 'Representative example',
///       body: 'Borrow 10,000 over 48 months at 5.9% APR ...',
///       required: true,
///     ),
///   ],
///   consents: const [
///     BankConsentItem(
///       id: 'terms',
///       label: 'I agree to the loan terms and conditions',
///       required: true,
///     ),
///     BankConsentItem(
///       id: 'marketing',
///       label: 'Send me product news and offers',
///     ),
///   ],
///   onChanged: (ids) => debugPrint('ticked: $ids'),
///   onAgree: () => Navigator.of(context).pop(),
/// );
/// ```
class BankDisclosureConsentSheet extends StatefulWidget {
  /// Creates a disclosures and consent sheet.
  const BankDisclosureConsentSheet({
    required this.disclosures,
    required this.consents,
    required this.onChanged,
    required this.onAgree,
    super.key,
    this.title = 'Review and agree',
    this.subtitle,
    this.continueLabel = 'Agree and continue',
    this.requiredBadgeLabel = 'Required',
    this.footerText,
    this.header,
    this.footer,
    this.semanticLabel,
    this.showHandle = true,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.dividerColor,
    this.shadow,
    this.titleStyle,
    this.subtitleStyle,
    this.disclosureTitleStyle,
    this.disclosureBodyStyle,
    this.consentLabelStyle,
    this.footerStyle,
    this.expandIcon,
    this.acknowledgedIcon,
    this.animationDuration,
    this.animationCurve,
  });

  /// Disclosure panels rendered as the accordion, in order.
  final List<BankDisclosure> disclosures;

  /// Consent checkboxes rendered as the unbundled group, in order.
  final List<BankConsentItem> consents;

  /// Called with the full set of ticked consent ids whenever a checkbox is
  /// toggled.
  final ValueChanged<Set<String>> onChanged;

  /// Called when the applicant taps the continue action. Only reachable
  /// once all required disclosures are acknowledged and all required
  /// consents are ticked.
  final VoidCallback onAgree;

  /// Sheet heading. Defaults to 'Review and agree'.
  final String title;

  /// Optional supporting line under [title].
  final String? subtitle;

  /// Label of the continue action. Defaults to 'Agree and continue'.
  final String continueLabel;

  /// Badge text shown next to required disclosures and consents. Defaults
  /// to 'Required'.
  final String requiredBadgeLabel;

  /// Legal microcopy shown beneath the consents. Ignored when [footer] is
  /// provided.
  final String? footerText;

  /// Optional slot rendered above the disclosures (e.g. a product summary).
  final Widget? header;

  /// Optional legal microcopy slot rendered beneath the consents. Takes
  /// precedence over [footerText].
  final Widget? footer;

  /// Semantics label for the whole sheet. Defaults to [title].
  final String? semanticLabel;

  /// Whether to draw the drag handle at the top. Defaults to `true`.
  final bool showHandle;

  /// Outer content padding. Defaults to [BankTokens.space4] horizontally
  /// with vertical spacing around the sections.
  final EdgeInsetsGeometry? padding;

  /// Corner radius of the sheet. Defaults to the theme sheetRadius.
  final BorderRadius? radius;

  /// Fill colour of the sheet. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Accent used for the checkboxes, chevrons, and acknowledged ticks.
  /// Defaults to the theme primary.
  final Color? accentColor;

  /// Divider colour between accordion panels and consents. Defaults to the
  /// theme outline.
  final Color? dividerColor;

  /// Shadow of the sheet surface. Defaults to none (the modal barrier
  /// provides separation); pass [BankTokens.shadowFloating] to elevate.
  final List<BoxShadow>? shadow;

  /// Merged over the computed heading style
  /// ([BankTokens.headlineSmall] in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the computed subtitle style
  /// ([BankTokens.bodyMedium] in onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the computed disclosure title style
  /// ([BankTokens.bodyLarge], w600, in onSurface).
  final TextStyle? disclosureTitleStyle;

  /// Merged over the computed disclosure body style
  /// ([BankTokens.bodyMedium] in onSurfaceVariant).
  final TextStyle? disclosureBodyStyle;

  /// Merged over the computed consent label style
  /// ([BankTokens.bodyMedium] in onSurface).
  final TextStyle? consentLabelStyle;

  /// Merged over the computed footer microcopy style
  /// ([BankTokens.bodySmall] in onSurfaceVariant).
  final TextStyle? footerStyle;

  /// Expand chevron on each disclosure. Defaults to [BankIcons.expand].
  final IconData? expandIcon;

  /// Glyph marking an acknowledged required disclosure. Defaults to
  /// [Icons.check_circle].
  final IconData? acknowledgedIcon;

  /// Duration of the accordion expand and collapse. Defaults to
  /// [BankTokens.durationBase] (chevron: [BankTokens.durationFast]).
  final Duration? animationDuration;

  /// Curve of the accordion expand and collapse. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// Shows the sheet as a modal bottom sheet and completes when dismissed.
  static Future<void> show(
    BuildContext context, {
    required List<BankDisclosure> disclosures,
    required List<BankConsentItem> consents,
    required ValueChanged<Set<String>> onChanged,
    required VoidCallback onAgree,
    String title = 'Review and agree',
    String? subtitle,
    String continueLabel = 'Agree and continue',
    Widget? header,
    Widget? footer,
    String? footerText,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankDisclosureConsentSheet(
          disclosures: disclosures,
          consents: consents,
          onChanged: onChanged,
          onAgree: onAgree,
          title: title,
          subtitle: subtitle,
          continueLabel: continueLabel,
          header: header,
          footer: footer,
          footerText: footerText,
        ),
      );

  @override
  State<BankDisclosureConsentSheet> createState() =>
      _BankDisclosureConsentSheetState();
}

class _BankDisclosureConsentSheetState
    extends State<BankDisclosureConsentSheet> {
  final Set<int> _expanded = <int>{};
  final Set<int> _acknowledged = <int>{};
  late Set<String> _ticked;

  @override
  void initState() {
    super.initState();
    _ticked = _initialTicked();
  }

  @override
  void didUpdateWidget(BankDisclosureConsentSheet old) {
    super.didUpdateWidget(old);
    if (old.consents != widget.consents) {
      _ticked = _initialTicked();
    }
  }

  Set<String> _initialTicked() => <String>{
        for (final item in widget.consents)
          if (item.preTicked && !item.required) item.id,
      };

  void _toggleDisclosure(int index) {
    setState(() {
      if (!_expanded.add(index)) {
        _expanded.remove(index);
      } else {
        _acknowledged.add(index);
      }
    });
  }

  void _toggleConsent(BankConsentItem item, bool ticked) {
    setState(() {
      if (ticked) {
        _ticked.add(item.id);
      } else {
        _ticked.remove(item.id);
      }
    });
    widget.onChanged(Set<String>.of(_ticked));
  }

  bool get _canContinue {
    for (var i = 0; i < widget.disclosures.length; i++) {
      if (widget.disclosures[i].required && !_acknowledged.contains(i)) {
        return false;
      }
    }
    for (final item in widget.consents) {
      if (item.required && !_ticked.contains(item.id)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final accent = widget.accentColor ?? theme.primary;
    final divider = widget.dividerColor ?? theme.outline;
    final duration = widget.animationDuration ?? BankTokens.durationBase;
    final curve = widget.animationCurve ?? BankTokens.curveStandard;
    final contentPadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: BankTokens.space4);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Semantics(
        container: true,
        label: widget.semanticLabel ?? widget.title,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? theme.surface,
              borderRadius: widget.radius ?? theme.sheetRadius,
              boxShadow: widget.shadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showHandle) const _SheetHandleBar(),
                _Heading(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  titleStyle: widget.titleStyle,
                  subtitleStyle: widget.subtitleStyle,
                  theme: theme,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.header != null) widget.header!,
                        for (var i = 0; i < widget.disclosures.length; i++) ...[
                          _DisclosurePanel(
                            disclosure: widget.disclosures[i],
                            expanded: _expanded.contains(i),
                            acknowledged: _acknowledged.contains(i),
                            requiredBadgeLabel: widget.requiredBadgeLabel,
                            accent: accent,
                            theme: theme,
                            host: widget,
                            duration: duration,
                            curve: curve,
                            onToggle: () => _toggleDisclosure(i),
                          ),
                          Divider(height: 1, color: divider),
                        ],
                        const SizedBox(height: BankTokens.space2),
                        for (final item in widget.consents)
                          _ConsentRow(
                            item: item,
                            ticked: _ticked.contains(item.id),
                            requiredBadgeLabel: widget.requiredBadgeLabel,
                            accent: accent,
                            theme: theme,
                            labelStyle: widget.consentLabelStyle,
                            onChanged: (value) =>
                                _toggleConsent(item, value ?? false),
                          ),
                        if (widget.footer != null) ...[
                          const SizedBox(height: BankTokens.space3),
                          widget.footer!,
                        ] else if (widget.footerText != null) ...[
                          const SizedBox(height: BankTokens.space3),
                          Text(
                            widget.footerText!,
                            style: BankTokens.bodySmall
                                .copyWith(color: theme.onSurfaceVariant)
                                .merge(widget.footerStyle),
                          ),
                        ],
                        const SizedBox(height: BankTokens.space4),
                      ],
                    ),
                  ),
                ),
                _ContinueBar(
                  label: widget.continueLabel,
                  enabled: _canContinue,
                  onAgree: widget.onAgree,
                  padding: contentPadding,
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SheetHandleBar extends StatelessWidget {
  const _SheetHandleBar();

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BankTokens.space2),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.outline,
            borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.theme,
  });

  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BankTokens.space4,
        BankTokens.space3,
        BankTokens.space4,
        BankTokens.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BankTokens.headlineSmall
                .copyWith(color: theme.onSurface)
                .merge(titleStyle),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: BankTokens.space1),
            Text(
              subtitle!,
              style: BankTokens.bodyMedium
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(subtitleStyle),
            ),
          ],
        ],
      ),
    );
  }
}

class _DisclosurePanel extends StatelessWidget {
  const _DisclosurePanel({
    required this.disclosure,
    required this.expanded,
    required this.acknowledged,
    required this.requiredBadgeLabel,
    required this.accent,
    required this.theme,
    required this.host,
    required this.duration,
    required this.curve,
    required this.onToggle,
  });

  final BankDisclosure disclosure;
  final bool expanded;
  final bool acknowledged;
  final String requiredBadgeLabel;
  final Color accent;
  final BankThemeData theme;
  final BankDisclosureConsentSheet host;
  final Duration duration;
  final Curve curve;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final showTick = disclosure.required && acknowledged;
    return Semantics(
      button: true,
      expanded: expanded,
      label: disclosure.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: BankTokens.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: BankTokens.space3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disclosure.title,
                            style: BankTokens.bodyLarge
                                .copyWith(
                                  color: theme.onSurface,
                                  fontWeight: FontWeight.w600,
                                )
                                .merge(host.disclosureTitleStyle),
                          ),
                          if (disclosure.required)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: BankTokens.space1,
                              ),
                              child: _RequiredBadge(
                                label: requiredBadgeLabel,
                                satisfied: acknowledged,
                                accent: accent,
                                theme: theme,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showTick)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: BankTokens.space2,
                        ),
                        child: Icon(
                          host.acknowledgedIcon ?? Icons.check_circle,
                          size: 18,
                          color: accent,
                        ),
                      ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: BankTokens.durationFast,
                      child: Icon(
                        host.expandIcon ?? BankIcons.expand,
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: curve,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(
                      bottom: BankTokens.space3,
                    ),
                    child: disclosure.richBody ??
                        Text(
                          disclosure.body,
                          style: BankTokens.bodyMedium
                              .copyWith(color: theme.onSurfaceVariant)
                              .merge(host.disclosureBodyStyle),
                        ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge({
    required this.label,
    required this.satisfied,
    required this.accent,
    required this.theme,
  });

  final String label;
  final bool satisfied;
  final Color accent;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = satisfied ? theme.positiveBalance : accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space2,
          vertical: 2,
        ),
        child: Text(
          label,
          style: BankTokens.labelSmall.copyWith(color: color),
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.item,
    required this.ticked,
    required this.requiredBadgeLabel,
    required this.accent,
    required this.theme,
    required this.labelStyle,
    required this.onChanged,
  });

  final BankConsentItem item;
  final bool ticked;
  final String requiredBadgeLabel;
  final Color accent;
  final BankThemeData theme;
  final TextStyle? labelStyle;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: ticked,
      label: item.label,
      child: InkWell(
        onTap: () => onChanged(!ticked),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: BankTokens.minTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: BankTokens.space1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: ticked,
                  onChanged: onChanged,
                  activeColor: accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: BankTokens.space2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: BankTokens.bodyMedium
                              .copyWith(color: theme.onSurface)
                              .merge(labelStyle),
                        ),
                        if (item.required)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: BankTokens.space1,
                            ),
                            child: _RequiredBadge(
                              label: requiredBadgeLabel,
                              satisfied: ticked,
                              accent: accent,
                              theme: theme,
                            ),
                          ),
                      ],
                    ),
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

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({
    required this.label,
    required this.enabled,
    required this.onAgree,
    required this.padding,
    required this.theme,
  });

  final String label;
  final bool enabled;
  final VoidCallback onAgree;
  final EdgeInsetsGeometry padding;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding.add(
        const EdgeInsets.symmetric(vertical: BankTokens.space3),
      ),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: FilledButton(
          onPressed: enabled ? onAgree : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, BankTokens.minTapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: theme.buttonRadius,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
