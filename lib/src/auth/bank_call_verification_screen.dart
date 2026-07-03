import 'package:flutter/material.dart';

import '../common/bank_emblem.dart';
import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankCallStatus
// ---------------------------------------------------------------------------

/// The verified call state rendered by [BankCallVerificationScreen].
///
/// The state is always supplied by the host app (typically from a backend
/// endpoint that knows whether a genuine agent call is in progress); this
/// package never inspects the device's telephony state.
enum BankCallStatus {
  /// The bank is not calling the customer right now. Anyone currently on
  /// the phone claiming to be the bank is a scammer.
  noActiveCall,

  /// A verified call between the customer and a bank agent is in progress.
  activeCall,

  /// No call is in progress, but a recently completed call was verified.
  recentCall,
}

// ---------------------------------------------------------------------------
// BankCallVerificationScreen
// ---------------------------------------------------------------------------

/// An anti-vishing call verification surface: a live answer to "is
/// this call really from my bank?".
///
/// Place it behind a prominent security entry point so a customer who
/// receives a suspicious phone call can immediately check whether the bank
/// is really calling:
///
/// - [BankCallStatus.noActiveCall]: a large shield-off illustration, the
///   bold headline "We are NOT calling you", body copy warning that any
///   current caller is a scammer, and a [BankTokens.danger] report button
///   wired to [onReportScam] (pass `null` to render it disabled).
/// - [BankCallStatus.activeCall]: a positive shield-check illustration,
///   "You are speaking with {bank}", and an agent card ([BankEmblem]
///   initials, agent name, staff ID, and call start time).
/// - [BankCallStatus.recentCall]: a neutral summary of the most recent
///   verified call, reusing the agent card with a full date and time.
///
/// A refresh [IconButton] appears when [onRefresh] is provided; tapping it
/// spins the icon once (skipped when animations are disabled) and invokes
/// the callback. Status changes are announced to assistive technology via
/// a `liveRegion` around the headline and body copy.
///
/// The screen intentionally uses only plain surface colours and
/// full-strength semantic colours (no gradients, glows, or decorative
/// tints) so it stays legible under every preset, including high-contrast
/// themes.
///
/// All user-facing copy can be overridden through constructor parameters
/// for localisation; English defaults are built in.
///
/// ```dart
/// BankCallVerificationScreen(
///   status: BankCallStatus.activeCall,
///   agentName: 'Amira Hassan',
///   agentId: 'AH-2041',
///   callStartedAt: DateTime.now(),
///   bankName: 'Vault Bank',
///   onReportScam: () => openScamReportFlow(),
///   onRefresh: () => bloc.add(const RefreshCallStatusEvent()),
/// )
/// ```
class BankCallVerificationScreen extends StatefulWidget {
  const BankCallVerificationScreen({
    required this.status,
    super.key,
    this.agentName,
    this.agentId,
    this.callStartedAt,
    this.onReportScam,
    this.onRefresh,
    this.bankName = 'your bank',
    this.screenTitle = 'Call status',
    this.noCallHeadline = 'We are NOT calling you',
    this.noCallBody,
    this.activeCallHeadline,
    this.activeCallBody,
    this.recentCallHeadline = 'Your last call was verified',
    this.recentCallBody,
    this.reportScamLabel = 'Report a scam call',
    this.refreshLabel = 'Refresh call status',
    this.staffIdLabel = 'Staff ID',
    this.callStartedLabel = 'Call started',
  });

  /// The verified call state to display.
  final BankCallStatus status;

  /// Display name of the agent on the (current or most recent) verified
  /// call. Shown on the agent card and used for the [BankEmblem] initials.
  final String? agentName;

  /// Internal staff identifier of the agent, shown on the agent card so
  /// the customer can quote it back to the bank.
  final String? agentId;

  /// When the (current or most recent) verified call started.
  final DateTime? callStartedAt;

  /// Called when the customer taps the danger report button in the
  /// [BankCallStatus.noActiveCall] state. When `null` the button renders
  /// disabled.
  final VoidCallback? onReportScam;

  /// Called when the customer taps the refresh button. When `null` the
  /// refresh button is not shown.
  final VoidCallback? onRefresh;

  /// The bank's display name, interpolated into the default copy.
  final String bankName;

  /// Heading shown at the top of the screen.
  final String screenTitle;

  /// Headline for the [BankCallStatus.noActiveCall] state.
  final String noCallHeadline;

  /// Body copy for the [BankCallStatus.noActiveCall] state. Defaults to a
  /// warning that any current caller is a scammer.
  final String? noCallBody;

  /// Headline for the [BankCallStatus.activeCall] state. Defaults to
  /// `'You are speaking with $bankName'`.
  final String? activeCallHeadline;

  /// Reassurance copy for the [BankCallStatus.activeCall] state.
  final String? activeCallBody;

  /// Headline for the [BankCallStatus.recentCall] state.
  final String recentCallHeadline;

  /// Body copy for the [BankCallStatus.recentCall] state.
  final String? recentCallBody;

  /// Label for the danger report button.
  final String reportScamLabel;

  /// Tooltip and semantics label for the refresh button.
  final String refreshLabel;

  /// Label prefixed to [agentId] on the agent card.
  final String staffIdLabel;

  /// Label prefixed to the formatted [callStartedAt] on the agent card.
  final String callStartedLabel;

  @override
  State<BankCallVerificationScreen> createState() =>
      _BankCallVerificationScreenState();
}

class _BankCallVerificationScreenState extends State<BankCallVerificationScreen>
    with SingleTickerProviderStateMixin {
  /// Diameter of the illustration circle.
  static const double _illustrationSize = 96;

  /// Size of the illustration glyph inside the circle.
  static const double _illustrationIconSize = 48;

  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: BankTokens.durationXSlow,
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!disableAnimations) {
      _spinController.forward(from: 0);
    }
    widget.onRefresh?.call();
  }

  // ---------------------------------------------------------------------------
  // Copy resolution
  // ---------------------------------------------------------------------------

  _CallStatusContent _resolveContent() {
    switch (widget.status) {
      case BankCallStatus.noActiveCall:
        return _CallStatusContent(
          icon: BankIcons.fraud,
          accent: BankTokens.danger,
          headline: widget.noCallHeadline,
          body: widget.noCallBody ??
              'If the person on the phone right now says they are calling '
                  'from ${widget.bankName}, hang up: they are a scammer. '
                  'Genuine staff will never pressure you to move money or '
                  'share security codes.',
        );
      case BankCallStatus.activeCall:
        return _CallStatusContent(
          icon: Icons.verified_user_outlined,
          accent: BankTokens.success,
          headline: widget.activeCallHeadline ??
              'You are speaking with ${widget.bankName}',
          body: widget.activeCallBody ??
              'This call has been verified. Our team member will never ask '
                  'for your PIN, your password, or a one time passcode.',
        );
      case BankCallStatus.recentCall:
        return _CallStatusContent(
          icon: BankIcons.schedule,
          accent: BankTokens.frozen,
          headline: widget.recentCallHeadline,
          body: widget.recentCallBody ??
              'No call is in progress right now. Below is a summary of your '
                  'most recent verified call with ${widget.bankName}.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final content = _resolveContent();

    final hasAgentDetails = widget.agentName != null ||
        widget.agentId != null ||
        widget.callStartedAt != null;
    final showAgentCard =
        widget.status != BankCallStatus.noActiveCall && hasAgentDetails;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(BankTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(theme),
          const SizedBox(height: BankTokens.space8),
          _buildIllustration(content),
          const SizedBox(height: BankTokens.space5),
          Semantics(
            liveRegion: true,
            container: true,
            label: '${content.headline}. ${content.body}',
            excludeSemantics: true,
            child: Column(
              children: [
                Text(
                  content.headline,
                  style: BankTokens.headlineMedium.copyWith(
                    color: theme.onBackground,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: BankTokens.space3),
                Text(
                  content.body,
                  style: BankTokens.bodyMedium.copyWith(
                    color: theme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (showAgentCard) ...[
            const SizedBox(height: BankTokens.space6),
            _buildAgentCard(theme),
          ],
          if (widget.status == BankCallStatus.noActiveCall) ...[
            const SizedBox(height: BankTokens.space8),
            _buildReportScamButton(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BankThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              widget.screenTitle,
              style: BankTokens.headlineSmall.copyWith(
                color: theme.onBackground,
              ),
            ),
          ),
        ),
        if (widget.onRefresh != null)
          Semantics(
            button: true,
            label: widget.refreshLabel,
            excludeSemantics: true,
            child: IconButton(
              onPressed: _handleRefresh,
              tooltip: widget.refreshLabel,
              iconSize: BankTokens.space6,
              constraints: const BoxConstraints(
                minWidth: BankTokens.minTapTarget,
                minHeight: BankTokens.minTapTarget,
              ),
              icon: RotationTransition(
                turns: CurvedAnimation(
                  parent: _spinController,
                  curve: BankTokens.curveEmphasized,
                ),
                child: Icon(
                  Icons.refresh,
                  color: theme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIllustration(_CallStatusContent content) {
    return Center(
      child: SizedBox(
        width: _illustrationSize,
        height: _illustrationSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: content.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            content.icon,
            color: content.accent,
            size: _illustrationIconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildAgentCard(BankThemeData theme) {
    final startedAt = widget.callStartedAt;
    final String? timeText;
    if (startedAt == null) {
      timeText = null;
    } else {
      final formatted = widget.status == BankCallStatus.activeCall
          ? BankDateFormatter.formatTime(startedAt)
          : BankDateFormatter.formatLong(startedAt);
      timeText = '${widget.callStartedLabel} $formatted';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: theme.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(BankTokens.space4),
        child: Row(
          children: [
            BankEmblem(
              initialsFrom: widget.agentName ?? widget.bankName,
              size: BankTokens.space12,
            ),
            const SizedBox(width: BankTokens.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.agentName != null)
                    Text(
                      widget.agentName!,
                      style: BankTokens.labelLarge.copyWith(
                        color: theme.onSurface,
                      ),
                    ),
                  if (widget.agentId != null) ...[
                    const SizedBox(height: BankTokens.space1),
                    Text(
                      '${widget.staffIdLabel}: ${widget.agentId}',
                      style: BankTokens.bodySmall.copyWith(
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (timeText != null) ...[
                    const SizedBox(height: BankTokens.space1),
                    Text(
                      timeText,
                      style: BankTokens.bodySmall.copyWith(
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportScamButton(BankThemeData theme) {
    return Semantics(
      button: true,
      enabled: widget.onReportScam != null,
      label: widget.reportScamLabel,
      child: FilledButton(
        onPressed: widget.onReportScam,
        style: FilledButton.styleFrom(
          backgroundColor: BankTokens.danger,
          foregroundColor: const Color(0xFFFFFFFF),
          minimumSize: const Size(
            double.infinity,
            BankTokens.minTapTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: theme.buttonRadius,
          ),
          textStyle: BankTokens.labelLarge,
        ),
        child: Text(widget.reportScamLabel),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal per-status content
// ---------------------------------------------------------------------------

/// Resolved icon, accent colour, and copy for one [BankCallStatus].
class _CallStatusContent {
  const _CallStatusContent({
    required this.icon,
    required this.accent,
    required this.headline,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final String headline;
  final String body;
}
