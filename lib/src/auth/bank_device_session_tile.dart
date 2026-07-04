import 'package:flutter/material.dart';

import '../common/money_formatter.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The hardware class of a signed-in device session.
enum BankDeviceKind { phone, tablet, desktop, watch, unknown }

/// An active or trusted device session shown in the security center.
class BankDeviceSession {
  const BankDeviceSession({
    required this.id,
    required this.deviceName,
    required this.kind,
    required this.lastActiveAt,
    this.location,
    this.isCurrentDevice = false,
    this.isTrusted = false,
  });

  final String id;

  /// Display name, e.g. `'iPhone 16 Pro'`.
  final String deviceName;

  final BankDeviceKind kind;

  /// Last observed activity; rendered as a relative time.
  final DateTime lastActiveAt;

  /// Coarse sign-in location, e.g. `'Riyadh'`.
  final String? location;

  /// Marks the session rendering this list.
  final bool isCurrentDevice;

  /// Device passed the trust enrolment (shows a shield micro-icon).
  final bool isTrusted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankDeviceSession &&
          other.id == id &&
          other.deviceName == deviceName &&
          other.kind == kind &&
          other.lastActiveAt == lastActiveAt &&
          other.location == location &&
          other.isCurrentDevice == isCurrentDevice &&
          other.isTrusted == isTrusted;

  @override
  int get hashCode => Object.hash(
        id,
        deviceName,
        kind,
        lastActiveAt,
        location,
        isCurrentDevice,
        isTrusted,
      );
}

/// A trusted-device / active-session row for the security center,
/// completing the device-trust story alongside `BankDeviceTrustBanner`.
///
/// Shows a device-kind icon, name, location and relative last-active
/// time, a `This device` chip on the current session, a shield icon on
/// trusted devices, and: for other devices: an async revoke ("sign
/// out") affordance with a confirmation dialog.
///
/// ```dart
/// BankDeviceSessionTile(
///   session: session,
///   onRevoke: () => api.revokeSession(session.id),
/// )
/// ```
class BankDeviceSessionTile extends StatefulWidget {
  const BankDeviceSessionTile({
    required this.session,
    super.key,
    this.onRevoke,
    this.onTap,
    this.flagged = false,
    this.currentDeviceLabel = 'This device',
    this.revokeLabel = 'Sign out',
    this.revokeConfirmTitle = 'Sign out this device?',
    this.revokeConfirmBody =
        'The device will need to sign in again to access the account.',
    this.cancelLabel = 'Cancel',
    this.padding,
    this.minHeight,
    this.accentColor,
    this.dangerColor,
    this.deviceIcon,
    this.trustedIcon,
    this.leading,
    this.titleStyle,
    this.subtitleStyle,
    this.semanticLabel,
  });

  final BankDeviceSession session;

  /// Revokes the session on the backend; return `true` on success. The
  /// affordance is hidden on the current device or when null. After a
  /// successful revoke the host removes the row (animate removal in the
  /// parent list).
  final Future<bool> Function()? onRevoke;

  final VoidCallback? onTap;

  /// Renders the row with a danger accent for compromised sessions.
  final bool flagged;

  final String currentDeviceLabel;
  final String revokeLabel;
  final String revokeConfirmTitle;
  final String revokeConfirmBody;
  final String cancelLabel;

  /// Overrides the row content padding. Defaults to [BankTokens.space4]
  /// horizontal, [BankTokens.space2] vertical.
  final EdgeInsetsGeometry? padding;

  /// Overrides the minimum row height. Defaults to `64`.
  final double? minHeight;

  /// Overrides the device icon accent. Defaults to
  /// [BankThemeData.primary], or the danger colour when [flagged].
  final Color? accentColor;

  /// Overrides the danger colour used for the revoke affordances and the
  /// [flagged] accent. Defaults to [BankTokens.danger].
  final Color? dangerColor;

  /// Overrides the device-kind glyph. Defaults to a glyph matched to
  /// [BankDeviceSession.kind].
  final IconData? deviceIcon;

  /// Overrides the trusted-device micro glyph. Defaults to
  /// [Icons.verified_user_outlined].
  final IconData? trustedIcon;

  /// Replaces the leading device icon box entirely when non-null.
  final Widget? leading;

  /// Merged over the computed device name style ([BankTokens.bodyLarge]).
  final TextStyle? titleStyle;

  /// Merged over the computed secondary line style
  /// ([BankTokens.bodySmall]).
  final TextStyle? subtitleStyle;

  /// Overrides the computed semantics label for the row.
  final String? semanticLabel;

  @override
  State<BankDeviceSessionTile> createState() => _BankDeviceSessionTileState();
}

class _BankDeviceSessionTileState extends State<BankDeviceSessionTile> {
  bool _revoking = false;

  IconData get _kindIcon => switch (widget.session.kind) {
        BankDeviceKind.phone => Icons.smartphone_outlined,
        BankDeviceKind.tablet => Icons.tablet_mac_outlined,
        BankDeviceKind.desktop => Icons.desktop_windows_outlined,
        BankDeviceKind.watch => Icons.watch_outlined,
        BankDeviceKind.unknown => Icons.devices_other_outlined,
      };

  Future<void> _confirmRevoke() async {
    final theme = BankThemeData.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          widget.revokeConfirmTitle,
          style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
        ),
        content: Text(
          widget.revokeConfirmBody,
          style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(widget.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              widget.revokeLabel,
              style: TextStyle(color: widget.dangerColor ?? BankTokens.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _revoking = true);
    var succeeded = false;
    try {
      succeeded = await widget.onRevoke!();
    } on Object {
      succeeded = false;
    }
    if (mounted && !succeeded) setState(() => _revoking = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final session = widget.session;

    final danger = widget.dangerColor ?? BankTokens.danger;
    final accent =
        widget.accentColor ?? (widget.flagged ? danger : theme.primary);
    final secondary = [
      if (session.location != null) session.location!,
      BankDateFormatter.formatRelative(session.lastActiveAt),
    ].join(' · ');

    final showRevoke = widget.onRevoke != null && !session.isCurrentDevice;

    return Opacity(
      opacity: _revoking ? 0.4 : 1,
      child: Semantics(
        label: widget.semanticLabel ??
            '${session.deviceName}, $secondary'
                '${session.isCurrentDevice ? ', ' : ''}'
                '${session.isCurrentDevice ? widget.currentDeviceLabel : ''}',
        child: InkWell(
          onTap: _revoking ? null : widget.onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minHeight ?? 64),
            child: Padding(
              padding: widget.padding ??
                  const EdgeInsetsDirectional.symmetric(
                    horizontal: BankTokens.space4,
                    vertical: BankTokens.space2,
                  ),
              child: Row(
                children: [
                  widget.leading ??
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: theme.chipRadius,
                        ),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            widget.deviceIcon ?? _kindIcon,
                            size: 22,
                            color: accent,
                          ),
                        ),
                      ),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                session.deviceName,
                                style: BankTokens.bodyLarge
                                    .copyWith(color: theme.onSurface)
                                    .merge(widget.titleStyle),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (session.isTrusted) ...[
                              const SizedBox(width: BankTokens.space1),
                              Icon(
                                widget.trustedIcon ??
                                    Icons.verified_user_outlined,
                                size: 14,
                                color: theme.positiveBalance,
                              ),
                            ],
                            if (session.isCurrentDevice) ...[
                              const SizedBox(width: BankTokens.space2),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.12),
                                  borderRadius: theme.chipRadius,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: BankTokens.space2,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    widget.currentDeviceLabel,
                                    style: BankTokens.labelSmall
                                        .copyWith(color: theme.primary),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          secondary,
                          style: BankTokens.bodySmall
                              .copyWith(color: theme.onSurfaceVariant)
                              .merge(widget.subtitleStyle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_revoking)
                    const Padding(
                      padding: EdgeInsets.all(BankTokens.space3),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (showRevoke)
                    TextButton(
                      onPressed: _confirmRevoke,
                      child: Text(
                        widget.revokeLabel,
                        style: BankTokens.labelLarge.copyWith(color: danger),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
