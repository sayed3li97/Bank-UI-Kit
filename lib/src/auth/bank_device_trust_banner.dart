import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/scope/bank_ui_strings.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankDeviceTrustState
// ---------------------------------------------------------------------------

/// The trust classification of the current device, supplied by the host app.
///
/// This package never performs device checks; trust state is always injected
/// externally.
enum BankDeviceTrustState {
  /// A previously unseen device has been detected.
  newDevice,

  /// The device shows signs of compromise (e.g. rooted/jailbroken).
  compromised,
}

// ---------------------------------------------------------------------------
// BankDeviceTrustBanner
// ---------------------------------------------------------------------------

/// A contextual security banner driven by an externally-supplied [state] flag.
///
/// - [BankDeviceTrustState.newDevice]: amber left-border banner with an info
///   icon, using [BankTokens.warning] (`#FF9500`) as the accent colour.
/// - [BankDeviceTrustState.compromised]: red left-border banner with a shield
///   icon, using [BankTokens.danger] as the accent colour.
///
/// The banner reads its localised strings from [strings] when provided, or
/// falls back to the ambient [BankUiScope] strings. The whole widget is
/// annotated as a `liveRegion` so assistive technology announces the message
/// when it appears.
///
/// ```dart
/// BankDeviceTrustBanner(
///   state: BankDeviceTrustState.newDevice,
///   onDismiss: () => setState(() => _showBanner = false),
///   onLearnMore: () => launchUrl(securityHelpUri),
/// )
/// ```
class BankDeviceTrustBanner extends StatelessWidget {
  /// The security classification that determines copy, colour, and icon.
  final BankDeviceTrustState state;

  /// When non-null, an `×` dismiss button is shown on the trailing edge.
  final VoidCallback? onDismiss;

  /// When non-null, a "Learn more" text button is shown below the body text.
  final VoidCallback? onLearnMore;

  /// Optional override for localised strings. Falls back to
  /// [BankUiScope.of(context).strings] when null.
  final BankUiStrings? strings;

  const BankDeviceTrustBanner({
    super.key,
    required this.state,
    this.onDismiss,
    this.onLearnMore,
    this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final BankThemeData bankTheme = BankThemeData.of(context);
    final BankUiStrings resolvedStrings =
        strings ?? BankUiScope.of(context).strings;

    final _BannerConfig config = _configForState(state, resolvedStrings);

    final String semanticLabel = '${config.title}. ${config.body}';

    return Semantics(
      liveRegion: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: bankTheme.surfaceVariant,
          borderRadius: bankTheme.cardRadius,
          border: Border(
            left: BorderSide(
              color: config.accentColor,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading icon
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                config.icon,
                color: config.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            // Title + body (+ optional learn more)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    config.title,
                    style: BankTokens.labelLarge.copyWith(
                      color: bankTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: BankTokens.space1),
                  Text(
                    config.body,
                    style: BankTokens.bodySmall.copyWith(
                      color: bankTheme.onSurfaceVariant,
                    ),
                  ),
                  if (onLearnMore != null) ...[
                    const SizedBox(height: BankTokens.space2),
                    GestureDetector(
                      onTap: onLearnMore,
                      child: Text(
                        'Learn more',
                        style: BankTokens.labelMedium.copyWith(
                          color: config.accentColor,
                          decoration: TextDecoration.underline,
                          decorationColor: config.accentColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Trailing dismiss button
            if (onDismiss != null) ...[
              const SizedBox(width: BankTokens.space2),
              Semantics(
                button: true,
                label: 'Dismiss security notice',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onDismiss,
                  child: SizedBox(
                    width: BankTokens.minTapTarget,
                    height: BankTokens.minTapTarget,
                    child: Icon(
                      BankIcons.close,
                      size: 18,
                      color: bankTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _BannerConfig _configForState(
    BankDeviceTrustState state,
    BankUiStrings strings,
  ) {
    return switch (state) {
      BankDeviceTrustState.newDevice => _BannerConfig(
          title: strings.newDevice,
          body: strings.newDeviceBody,
          icon: BankIcons.info,
          accentColor: BankTokens.warning,
        ),
      BankDeviceTrustState.compromised => _BannerConfig(
          title: strings.compromisedDevice,
          body: strings.compromisedDeviceBody,
          icon: BankIcons.shield,
          accentColor: BankTokens.danger,
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Internal config record
// ---------------------------------------------------------------------------

class _BannerConfig {
  const _BannerConfig({
    required this.title,
    required this.body,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accentColor;
}
