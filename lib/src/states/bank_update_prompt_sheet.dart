import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Soft, dismissible "an update is available" bottom sheet: the skippable
/// tier of the two-tier server-driven update pattern.
///
/// The hard, blocking tier of that pattern is the app gate screen (force
/// update); keep the two separate. Soft prompts are frequency-capped and
/// skippable, hard gates are neither, so this sheet must never be turned
/// into a blocker. When the server wants to escalate during the final days
/// before a version is retired, pass [unsupportedAfter] to render a warning
/// strip and, if needed, set [hideNotNow] to drop the dismiss button while
/// the sheet itself stays drag-dismissible.
///
/// The widget performs no version comparison and no store lookups: the host
/// decides when to show it and wires [onUpdate] to its store listing
/// (itms-apps://, market://details?id=, or a Play in-app update flow), since
/// the kit has no URL-launching dependency. [onNotNow] fires after the sheet
/// pops so the host can stamp its frequency cap.
///
/// Present with [BankUpdatePromptSheet.show], which returns the sheet future
/// so hosts can log dismissal, or embed an instance in a custom container.
///
/// ```dart
/// await BankUpdatePromptSheet.show(
///   context,
///   onUpdate: openStoreListing,
///   onNotNow: stampUpdatePromptCap,
///   availableVersion: '4.13.0',
///   installedVersion: '4.12.0',
///   highlights: const [
///     'Faster sign-in with passkeys',
///     'Fixes a crash when exporting statements',
///   ],
///   unsupportedAfter: DateTime(2026, 9, 30),
/// );
/// ```
class BankUpdatePromptSheet extends StatelessWidget {
  /// Called when the user taps the update button. The host wires this to
  /// its store listing or in-app update flow.
  final VoidCallback onUpdate;

  /// Called after the sheet pops when the user taps the "Not now" button,
  /// so the host can stamp its frequency cap. The button pops regardless.
  final VoidCallback? onNotNow;

  /// Sheet title. Defaults to 'A new version is ready'.
  final String title;

  /// Supporting copy under the title.
  final String body;

  /// Label of the primary update button. Defaults to 'Update now'.
  final String updateLabel;

  /// Label of the dismiss button. Defaults to 'Not now'.
  final String notNowLabel;

  /// Optional short what's-new bullet list, rendered start-aligned with
  /// [BankIcons.success] bullets tinted with the accent colour.
  final List<String>? highlights;

  /// Version offered by the store, shown in the muted footer line.
  final String? availableVersion;

  /// Version currently installed, shown in the muted footer line.
  final String? installedVersion;

  /// Glyph shown in the tinted circle. Defaults to
  /// [Icons.system_update_outlined].
  final IconData? icon;

  /// When non-null, renders a warning strip announcing the date this
  /// version stops working (the mandated soft-warning period that precedes
  /// any hard gate flip).
  final DateTime? unsupportedAfter;

  /// Template for the [unsupportedAfter] strip; '{date}' is replaced with
  /// [BankDateFormatter.formatFull] of [unsupportedAfter].
  final String unsupportedAfterTemplate;

  /// Drops the "Not now" button (server flag for the final days). The sheet
  /// itself stays drag-dismissible: true blocking belongs to the gate
  /// screen, never to this sheet.
  final bool hideNotNow;

  /// Template for the available-version footer segment; '{version}' is
  /// replaced with [availableVersion]. Defaults to 'Version {version}'.
  final String availableVersionTemplate;

  /// Template for the installed-version footer segment; '{version}' is
  /// replaced with [installedVersion]. Defaults to 'you have {version}'.
  final String installedVersionTemplate;

  /// Overrides the content padding. Defaults to
  /// `EdgeInsetsDirectional.fromSTEB(space6, space3, space6, space6)`.
  final EdgeInsetsGeometry? padding;

  /// Paints a [BankThemeData.sheetRadius] background behind the content.
  /// Only needed when hosts embed the widget outside [show], which already
  /// paints [BankThemeData.surface] on the modal sheet.
  final Color? backgroundColor;

  /// Tint of the icon circle and highlight bullets. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Merged over the computed title style ([BankTokens.headlineSmall] in
  /// [BankThemeData.onSurface]).
  final TextStyle? titleStyle;

  /// Merged over the computed body style ([BankTokens.bodyMedium] in
  /// [BankThemeData.onSurfaceVariant]).
  final TextStyle? bodyStyle;

  /// Bullet glyph for [highlights]. Defaults to [BankIcons.success].
  final IconData? highlightIcon;

  /// Glyph of the [unsupportedAfter] strip. Defaults to [BankIcons.warning].
  final IconData? warningIcon;

  /// Duration of the one-shot icon scale-in. Defaults to 200 milliseconds.
  final Duration? animationDuration;

  /// Curve of the one-shot icon scale-in. Defaults to
  /// [BankTokens.curveEmphasized].
  final Curve? animationCurve;

  /// Replaces the drag handle plus icon-circle block.
  final Widget? header;

  /// Replaces the version footer line.
  final Widget? footer;

  /// Overrides the sheet's semantics label. Defaults to '$title. $body'.
  final String? semanticLabel;

  const BankUpdatePromptSheet({
    required this.onUpdate,
    super.key,
    this.onNotNow,
    this.title = _defaultTitle,
    this.body = _defaultBody,
    this.updateLabel = _defaultUpdateLabel,
    this.notNowLabel = _defaultNotNowLabel,
    this.highlights,
    this.availableVersion,
    this.installedVersion,
    this.icon,
    this.unsupportedAfter,
    this.unsupportedAfterTemplate = _defaultUnsupportedAfterTemplate,
    this.hideNotNow = false,
    this.availableVersionTemplate = _defaultAvailableVersionTemplate,
    this.installedVersionTemplate = _defaultInstalledVersionTemplate,
    this.padding,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.bodyStyle,
    this.highlightIcon,
    this.warningIcon,
    this.animationDuration,
    this.animationCurve,
    this.header,
    this.footer,
    this.semanticLabel,
  });

  static const String _defaultTitle = 'A new version is ready';
  static const String _defaultBody =
      'This update includes fixes and improvements to keep the app fast '
      'and secure.';
  static const String _defaultUpdateLabel = 'Update now';
  static const String _defaultNotNowLabel = 'Not now';
  static const String _defaultUnsupportedAfterTemplate =
      'This version stops working on {date}';
  static const String _defaultAvailableVersionTemplate = 'Version {version}';
  static const String _defaultInstalledVersionTemplate = 'you have {version}';

  static const Duration _defaultAnimationDuration = Duration(milliseconds: 200);

  // ---------------------------------------------------------------------------
  // Convenience presenter
  // ---------------------------------------------------------------------------

  /// Presents the sheet with [showModalBottomSheet] using the ambient
  /// [BankThemeData.sheetRadius] shape and [BankThemeData.surface]
  /// background (or [backgroundColor] when provided).
  ///
  /// Returns the sheet future so hosts can log dismissal.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUpdate,
    VoidCallback? onNotNow,
    String title = _defaultTitle,
    String body = _defaultBody,
    String updateLabel = _defaultUpdateLabel,
    String notNowLabel = _defaultNotNowLabel,
    List<String>? highlights,
    String? availableVersion,
    String? installedVersion,
    IconData? icon,
    DateTime? unsupportedAfter,
    String unsupportedAfterTemplate = _defaultUnsupportedAfterTemplate,
    bool hideNotNow = false,
    String availableVersionTemplate = _defaultAvailableVersionTemplate,
    String installedVersionTemplate = _defaultInstalledVersionTemplate,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? accentColor,
    TextStyle? titleStyle,
    TextStyle? bodyStyle,
    IconData? highlightIcon,
    IconData? warningIcon,
    Duration? animationDuration,
    Curve? animationCurve,
    Widget? header,
    Widget? footer,
    String? semanticLabel,
  }) {
    final theme = BankThemeData.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: backgroundColor ?? theme.surface,
      shape: RoundedRectangleBorder(borderRadius: theme.sheetRadius),
      builder: (_) => BankUpdatePromptSheet(
        onUpdate: onUpdate,
        onNotNow: onNotNow,
        title: title,
        body: body,
        updateLabel: updateLabel,
        notNowLabel: notNowLabel,
        highlights: highlights,
        availableVersion: availableVersion,
        installedVersion: installedVersion,
        icon: icon,
        unsupportedAfter: unsupportedAfter,
        unsupportedAfterTemplate: unsupportedAfterTemplate,
        hideNotNow: hideNotNow,
        availableVersionTemplate: availableVersionTemplate,
        installedVersionTemplate: installedVersionTemplate,
        padding: padding,
        accentColor: accentColor,
        titleStyle: titleStyle,
        bodyStyle: bodyStyle,
        highlightIcon: highlightIcon,
        warningIcon: warningIcon,
        animationDuration: animationDuration,
        animationCurve: animationCurve,
        header: header,
        footer: footer,
        semanticLabel: semanticLabel,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final accent = accentColor ?? theme.primary;
    final resolvedPadding = padding ??
        const EdgeInsetsDirectional.fromSTEB(
          BankTokens.space6,
          BankTokens.space3,
          BankTokens.space6,
          BankTokens.space6,
        );
    final resolvedTitleStyle = BankTokens.headlineSmall
        .copyWith(color: theme.onSurface)
        .merge(titleStyle);
    final resolvedBodyStyle = BankTokens.bodyMedium
        .copyWith(color: theme.onSurfaceVariant)
        .merge(bodyStyle);
    final versionLine = _versionLine();
    final resolvedHighlights = highlights;

    Widget content = Padding(
      padding: resolvedPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header ?? _buildDefaultHeader(theme, accent, disableAnimations),
          const SizedBox(height: BankTokens.space4),
          Text(title, style: resolvedTitleStyle, textAlign: TextAlign.center),
          const SizedBox(height: BankTokens.space2),
          Text(body, style: resolvedBodyStyle, textAlign: TextAlign.center),
          if (resolvedHighlights != null && resolvedHighlights.isNotEmpty) ...[
            const SizedBox(height: BankTokens.space2),
            for (final highlight in resolvedHighlights)
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(top: BankTokens.space2),
                child: _buildHighlightRow(theme, accent, highlight),
              ),
          ],
          if (unsupportedAfter != null) ...[
            const SizedBox(height: BankTokens.space4),
            _buildUnsupportedStrip(theme, unsupportedAfter!),
          ],
          const SizedBox(height: BankTokens.space6),
          Semantics(
            button: true,
            label: updateLabel,
            child: FilledButton(
              onPressed: onUpdate,
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: theme.buttonRadius,
                ),
                textStyle: BankTokens.labelLarge,
              ),
              child: Text(updateLabel),
            ),
          ),
          if (!hideNotNow) ...[
            const SizedBox(height: BankTokens.space2),
            Semantics(
              button: true,
              label: notNowLabel,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onNotNow?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.onSurfaceVariant,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: theme.buttonRadius,
                  ),
                  textStyle: BankTokens.labelLarge,
                ),
                child: Text(notNowLabel),
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: BankTokens.space3),
            footer!,
          ] else if (versionLine != null) ...[
            const SizedBox(height: BankTokens.space3),
            Text(
              versionLine,
              style: BankTokens.bodySmall.copyWith(
                color: theme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (backgroundColor != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: theme.sheetRadius,
        ),
        child: content,
      );
    }

    return Semantics(
      container: true,
      label: semanticLabel ?? '$title. $body',
      child: content,
    );
  }

  // ---------------------------------------------------------------------------
  // Pieces
  // ---------------------------------------------------------------------------

  Widget _buildDefaultHeader(
    BankThemeData theme,
    Color accent,
    bool disableAnimations,
  ) {
    Widget circle = SizedBox(
      width: 72,
      height: 72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon ?? Icons.system_update_outlined,
            size: 40,
            color: accent,
          ),
        ),
      ),
    );

    // One-shot scale-in; skipped (scale fixed at 1.0) when the platform
    // asks for reduced motion.
    if (!disableAnimations) {
      circle = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.85, end: 1),
        duration: animationDuration ?? _defaultAnimationDuration,
        curve: animationCurve ?? BankTokens.curveEmphasized,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: circle,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.outline,
              borderRadius: const BorderRadius.all(
                Radius.circular(BankTokens.radiusFull),
              ),
            ),
          ),
        ),
        const SizedBox(height: BankTokens.space5),
        circle,
      ],
    );
  }

  Widget _buildHighlightRow(
    BankThemeData theme,
    Color accent,
    String highlight,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(highlightIcon ?? BankIcons.success, size: 18, color: accent),
        const SizedBox(width: BankTokens.space2),
        Expanded(
          child: Text(
            highlight,
            style: BankTokens.bodyMedium.copyWith(color: theme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildUnsupportedStrip(BankThemeData theme, DateTime date) {
    final text = unsupportedAfterTemplate.replaceAll(
      '{date}',
      BankDateFormatter.formatFull(date),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BankTokens.warning.withValues(alpha: 0.12),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(BankTokens.space3),
        child: Row(
          children: [
            Icon(
              warningIcon ?? BankIcons.warning,
              size: 20,
              color: BankTokens.warning,
            ),
            const SizedBox(width: BankTokens.space2),
            Expanded(
              child: Text(
                text,
                style: BankTokens.bodySmall.copyWith(color: theme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _versionLine() {
    final available = availableVersion;
    final installed = installedVersion;
    final segments = <String>[
      if (available != null)
        availableVersionTemplate.replaceAll('{version}', available),
      if (installed != null)
        installedVersionTemplate.replaceAll('{version}', installed),
    ];
    if (segments.isEmpty) return null;
    return segments.join(', ');
  }
}
