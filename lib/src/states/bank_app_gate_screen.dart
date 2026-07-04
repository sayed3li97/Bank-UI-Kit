import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The reason a [BankAppGateScreen] is blocking entry to the app.
///
/// Each reason ships a default icon, title, and body copy. The
/// adversarial security reasons ([rootedDevice], [vpnDetected],
/// [emulatorDetected], [tamperDetected], and [geoRestricted]) keep
/// their copy deliberately vague so attackers learn nothing, and lean
/// on a reference code for support conversations. The fixable causes
/// ([clockSkew] and [developerMode]) name the exact problem and pair
/// with default numbered remediation steps.
enum BankAppGateReason {
  /// Scheduled or emergency maintenance; warm, specific copy.
  maintenance,

  /// The user's device has no internet connection.
  offline,

  /// This app version is no longer supported and must be updated.
  forceUpdate,

  /// The device appears rooted or jailbroken. Copy stays vague.
  rootedDevice,

  /// A VPN or proxy was detected. Copy stays vague.
  vpnDetected,

  /// The app is running inside an emulator. Copy stays vague.
  emulatorDetected,

  /// The app binary or runtime looks tampered with. Copy stays vague.
  tamperDetected,

  /// Access is not available from the current region. Copy stays vague.
  geoRestricted,

  /// The device clock is wrong; fixable, with default steps.
  clockSkew,

  /// Developer mode is enabled; fixable, with default steps.
  developerMode,

  /// Sign-in demand is high and the user is waiting in a queue.
  queueFull,
}

/// Full-screen blocking gate shown before the app can be used.
///
/// [BankAppGateScreen] is the kit's single unified "you cannot come in
/// right now" screen. It covers scheduled maintenance, connectivity
/// loss, forced updates, security blocks, fixable device issues, and
/// sign-in queues, selected via [reason] (a [BankAppGateReason]).
///
/// The widget performs no detection or networking itself: the host app
/// decides when to show it and injects [reason], [queuePosition], and
/// [resumesAt]. Every piece of copy has a calm English default per
/// reason and every one of them is overridable.
///
/// Layout: a vertically centred, scrollable column on a
/// [BankThemeData.background] [ColoredBox] inside a [SafeArea]: icon
/// or [illustration], title, body, then (when supplied) remediation
/// [steps], the queue block, or the [resumesAt] countdown, a
/// [stillWorking] checklist card, a tappable [referenceCode] chip that
/// copies via [Clipboard], primary and secondary actions, a support
/// row, and a version footer pinned to the bottom with a [Spacer].
///
/// The whole column fades and slides in 12 px on mount; the entrance
/// and all [AnimatedSwitcher] transitions are skipped when
/// [MediaQuery.disableAnimationsOf] is `true`. No looping or pulsing
/// decoration is ever used: money-blocked screens stay calm. All state
/// distinctions are conveyed by icon plus text, never colour alone.
///
/// ```dart
/// BankAppGateScreen.maintenance(
///   resumesAt: DateTime.now().add(const Duration(minutes: 45)),
///   appVersion: '4.12.0',
///   supportPhoneLabel: 'Call us on 0800 123 456',
///   onContactSupport: () => launchSupportChat(),
/// )
/// ```
class BankAppGateScreen extends StatefulWidget {
  /// Why the app is blocked. Drives every default on this screen.
  final BankAppGateReason reason;

  /// Overrides the default title for [reason].
  final String? title;

  /// Overrides the default body copy for [reason].
  final String? body;

  /// Overrides the default icon for [reason].
  final IconData? icon;

  /// Replaces the icon block entirely when non-null. Shown with a
  /// maximum height of 180 px.
  final Widget? illustration;

  /// Label for the primary [FilledButton]. The button is shown only
  /// when both this and [onPrimaryAction] are non-null.
  final String? primaryActionLabel;

  /// Called when the primary action is tapped. The button is hidden
  /// when this is null.
  final VoidCallback? onPrimaryAction;

  /// Label for the secondary [TextButton] below the primary action.
  final String? secondaryActionLabel;

  /// Called when the secondary action is tapped. The button is hidden
  /// when this is null.
  final VoidCallback? onSecondaryAction;

  /// Numbered remediation steps rendered start-aligned between the
  /// body and the actions. Defaults to fix-it steps for
  /// [BankAppGateReason.clockSkew] and [BankAppGateReason.developerMode].
  final List<String>? steps;

  /// Items for the "Still working" checklist card, rendered with
  /// [BankIcons.success] bullets (e.g. `['Card payments',
  /// 'ATM withdrawals', 'Phone banking']`).
  final List<String>? stillWorking;

  /// Heading of the [stillWorking] card. Defaults to 'Still working'.
  final String stillWorkingTitle;

  /// Short reassurance line in [BankTokens.bodySmall]. Defaults to
  /// 'Your money is safe.' for [BankAppGateReason.maintenance] and
  /// [BankAppGateReason.offline], and to nothing otherwise.
  final String? moneySafetyLine;

  /// Support reference code rendered as a tappable chip that copies
  /// the code to the clipboard.
  final String? referenceCode;

  /// Helper line under the [referenceCode] chip. Defaults to
  /// 'Quote this code if you contact us'.
  final String referenceCodeHint;

  /// Transient label shown for two seconds after the [referenceCode]
  /// is copied. Defaults to 'Copied'.
  final String copiedLabel;

  /// Free-form support slot rendered instead of the built-in support
  /// row when non-null.
  final Widget? supportContact;

  /// Label of the built-in support row (e.g. a phone number). The row
  /// is hidden when both this and [supportContact] are null.
  final String? supportPhoneLabel;

  /// Called when the built-in support row is tapped. When null the
  /// row renders as plain text.
  final VoidCallback? onContactSupport;

  /// Icon of the built-in support row. Defaults to
  /// [Icons.phone_outlined].
  final IconData? supportIcon;

  /// App version shown muted in the footer (e.g. 'Version 4.12.0').
  final String? appVersion;

  /// Prefix of the [appVersion] footer line. Defaults to 'Version'.
  final String versionPrefix;

  /// Timestamp of the last status update, shown in the footer via
  /// [BankDateFormatter.formatTime] as 'Last updated HH:mm'.
  final DateTime? lastUpdatedAt;

  /// Prefix of the [lastUpdatedAt] footer line. Defaults to
  /// 'Last updated'.
  final String lastUpdatedPrefix;

  /// When the service is expected back. Renders [backByLabel] plus
  /// [BankDateFormatter.formatTime] and a live countdown driven by a
  /// [Timer] that ticks every second while under one minute remains
  /// and every minute otherwise.
  final DateTime? resumesAt;

  /// Prefix of the [resumesAt] line. Defaults to 'Back by around'.
  final String backByLabel;

  /// Shown instead of a negative countdown once [resumesAt] passes.
  /// Defaults to 'Taking a little longer than expected'.
  final String overrunLabel;

  /// Time source for the [resumesAt] countdown. Defaults to
  /// [DateTime.now]; inject a fixed clock in tests and screenshots.
  final DateTime Function()? clock;

  /// Current queue position for [BankAppGateReason.queueFull].
  final int? queuePosition;

  /// Queue position when the user joined; when provided (with
  /// [queuePosition]) a determinate [LinearProgressIndicator] shows
  /// progress towards the front of the queue.
  final int? queueInitialPosition;

  /// Estimated remaining wait, appended to the queue position line.
  final Duration? estimatedWait;

  /// Reassurance line under the queue block. Defaults to
  /// "We'll bring you in automatically. Your place is saved."
  final String queueKeepPlaceLine;

  /// Builds the queue position line from [queuePosition] and
  /// [estimatedWait]. When null a default English line is used, e.g.
  /// 'You are number 214 in line, about 2 minutes'.
  final String Function(int position, Duration? estimatedWait)?
      queuePositionLine;

  /// Overrides the outer content padding. Defaults to
  /// `EdgeInsets.symmetric(horizontal: BankTokens.space8)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the screen background. Defaults to
  /// [BankThemeData.background].
  final Color? backgroundColor;

  /// Tints the icon block and the queue progress bar. Defaults to
  /// [BankTokens.danger] for the adversarial security reasons and
  /// [BankThemeData.primary] otherwise.
  final Color? accentColor;

  /// Merged over the computed title style
  /// ([BankTokens.headlineMedium] in [BankThemeData.onBackground]).
  final TextStyle? titleStyle;

  /// Merged over the computed body style ([BankTokens.bodyMedium] in
  /// [BankThemeData.onSurfaceVariant]).
  final TextStyle? bodyStyle;

  /// Duration of the entrance fade and queue transitions. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Curve of the entrance fade and queue transitions. Defaults to
  /// [BankTokens.curveDecelerate].
  final Curve? animationCurve;

  /// Overrides the root semantics label. Defaults to
  /// '`<resolved title>`. `<resolved body>`'.
  final String? semanticLabel;

  /// Creates an app gate screen for [reason].
  ///
  /// Only [reason] is required; every default (icon, title, body,
  /// steps, safety line) is derived from it and can be overridden.
  const BankAppGateScreen({
    required this.reason,
    super.key,
    this.title,
    this.body,
    this.icon,
    this.illustration,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.steps,
    this.stillWorking,
    this.stillWorkingTitle = _kStillWorkingTitle,
    this.moneySafetyLine,
    this.referenceCode,
    this.referenceCodeHint = _kReferenceCodeHint,
    this.copiedLabel = _kCopiedLabel,
    this.supportContact,
    this.supportPhoneLabel,
    this.onContactSupport,
    this.supportIcon,
    this.appVersion,
    this.versionPrefix = _kVersionPrefix,
    this.lastUpdatedAt,
    this.lastUpdatedPrefix = _kLastUpdatedPrefix,
    this.resumesAt,
    this.backByLabel = _kBackByLabel,
    this.overrunLabel = _kOverrunLabel,
    this.clock,
    this.queuePosition,
    this.queueInitialPosition,
    this.estimatedWait,
    this.queueKeepPlaceLine = _kQueueKeepPlaceLine,
    this.queuePositionLine,
    this.padding,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.bodyStyle,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  });

  /// Maintenance gate: warm copy, an expected-back countdown via
  /// [resumesAt], a default "Still working" checklist, and the money
  /// safety line switched on.
  const BankAppGateScreen.maintenance({
    super.key,
    this.resumesAt,
    this.title,
    this.body,
    this.icon,
    this.illustration,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.steps,
    this.stillWorking = _kStillWorkingDefaults,
    this.stillWorkingTitle = _kStillWorkingTitle,
    this.moneySafetyLine,
    this.referenceCode,
    this.referenceCodeHint = _kReferenceCodeHint,
    this.copiedLabel = _kCopiedLabel,
    this.supportContact,
    this.supportPhoneLabel,
    this.onContactSupport,
    this.supportIcon,
    this.appVersion,
    this.versionPrefix = _kVersionPrefix,
    this.lastUpdatedAt,
    this.lastUpdatedPrefix = _kLastUpdatedPrefix,
    this.backByLabel = _kBackByLabel,
    this.overrunLabel = _kOverrunLabel,
    this.clock,
    this.queuePosition,
    this.queueInitialPosition,
    this.estimatedWait,
    this.queueKeepPlaceLine = _kQueueKeepPlaceLine,
    this.queuePositionLine,
    this.padding,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.bodyStyle,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  }) : reason = BankAppGateReason.maintenance;

  /// Offline gate: explains the connection is the cause and wires a
  /// 'Try again' primary action to [onRetry].
  const BankAppGateScreen.offline({
    super.key,
    VoidCallback? onRetry,
    this.title,
    this.body,
    this.icon,
    this.illustration,
    this.primaryActionLabel = 'Try again',
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.steps,
    this.stillWorking,
    this.stillWorkingTitle = _kStillWorkingTitle,
    this.moneySafetyLine,
    this.referenceCode,
    this.referenceCodeHint = _kReferenceCodeHint,
    this.copiedLabel = _kCopiedLabel,
    this.supportContact,
    this.supportPhoneLabel,
    this.onContactSupport,
    this.supportIcon,
    this.appVersion,
    this.versionPrefix = _kVersionPrefix,
    this.lastUpdatedAt,
    this.lastUpdatedPrefix = _kLastUpdatedPrefix,
    this.resumesAt,
    this.backByLabel = _kBackByLabel,
    this.overrunLabel = _kOverrunLabel,
    this.clock,
    this.queuePosition,
    this.queueInitialPosition,
    this.estimatedWait,
    this.queueKeepPlaceLine = _kQueueKeepPlaceLine,
    this.queuePositionLine,
    this.padding,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.bodyStyle,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  })  : reason = BankAppGateReason.offline,
        onPrimaryAction = onRetry;

  /// Force-update gate: a single store call to action wired to
  /// [onOpenStore], [installedVersion] piped into the version footer,
  /// and a help escape hatch as the default secondary label.
  const BankAppGateScreen.forceUpdate({
    required VoidCallback onOpenStore,
    super.key,
    String? installedVersion,
    this.title,
    this.body,
    this.icon,
    this.illustration,
    this.primaryActionLabel = 'Update now',
    this.secondaryActionLabel = _kUpdateHelpLabel,
    this.onSecondaryAction,
    this.steps,
    this.stillWorking,
    this.stillWorkingTitle = _kStillWorkingTitle,
    this.moneySafetyLine,
    this.referenceCode,
    this.referenceCodeHint = _kReferenceCodeHint,
    this.copiedLabel = _kCopiedLabel,
    this.supportContact,
    this.supportPhoneLabel,
    this.onContactSupport,
    this.supportIcon,
    this.versionPrefix = _kVersionPrefix,
    this.lastUpdatedAt,
    this.lastUpdatedPrefix = _kLastUpdatedPrefix,
    this.resumesAt,
    this.backByLabel = _kBackByLabel,
    this.overrunLabel = _kOverrunLabel,
    this.clock,
    this.queuePosition,
    this.queueInitialPosition,
    this.estimatedWait,
    this.queueKeepPlaceLine = _kQueueKeepPlaceLine,
    this.queuePositionLine,
    this.padding,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.bodyStyle,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  })  : reason = BankAppGateReason.forceUpdate,
        onPrimaryAction = onOpenStore,
        appVersion = installedVersion;

  /// Rooted-device gate: deliberately vague copy that leans on the
  /// optional [referenceCode] for support conversations.
  const BankAppGateScreen.rootedDevice({
    super.key,
    this.referenceCode,
    this.title,
    this.body,
    this.icon,
    this.illustration,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.steps,
    this.stillWorking,
    this.stillWorkingTitle = _kStillWorkingTitle,
    this.moneySafetyLine,
    this.referenceCodeHint = _kReferenceCodeHint,
    this.copiedLabel = _kCopiedLabel,
    this.supportContact,
    this.supportPhoneLabel,
    this.onContactSupport,
    this.supportIcon,
    this.appVersion,
    this.versionPrefix = _kVersionPrefix,
    this.lastUpdatedAt,
    this.lastUpdatedPrefix = _kLastUpdatedPrefix,
    this.resumesAt,
    this.backByLabel = _kBackByLabel,
    this.overrunLabel = _kOverrunLabel,
    this.clock,
    this.queuePosition,
    this.queueInitialPosition,
    this.estimatedWait,
    this.queueKeepPlaceLine = _kQueueKeepPlaceLine,
    this.queuePositionLine,
    this.padding,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.bodyStyle,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  }) : reason = BankAppGateReason.rootedDevice;

  /// VPN-detected gate: deliberately vague copy that leans on the
  /// optional [referenceCode] for support conversations.
  const BankAppGateScreen.vpnDetected({
    super.key,
    this.referenceCode,
    this.title,
    this.body,
    this.icon,
    this.illustration,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.steps,
    this.stillWorking,
    this.stillWorkingTitle = _kStillWorkingTitle,
    this.moneySafetyLine,
    this.referenceCodeHint = _kReferenceCodeHint,
    this.copiedLabel = _kCopiedLabel,
    this.supportContact,
    this.supportPhoneLabel,
    this.onContactSupport,
    this.supportIcon,
    this.appVersion,
    this.versionPrefix = _kVersionPrefix,
    this.lastUpdatedAt,
    this.lastUpdatedPrefix = _kLastUpdatedPrefix,
    this.resumesAt,
    this.backByLabel = _kBackByLabel,
    this.overrunLabel = _kOverrunLabel,
    this.clock,
    this.queuePosition,
    this.queueInitialPosition,
    this.estimatedWait,
    this.queueKeepPlaceLine = _kQueueKeepPlaceLine,
    this.queuePositionLine,
    this.padding,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.bodyStyle,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  }) : reason = BankAppGateReason.vpnDetected;

  // ---------------------------------------------------------------------------
  // Default copy shared by the constructors
  // ---------------------------------------------------------------------------

  static const String _kStillWorkingTitle = 'Still working';
  static const String _kReferenceCodeHint = 'Quote this code if you contact us';
  static const String _kCopiedLabel = 'Copied';
  static const String _kVersionPrefix = 'Version';
  static const String _kLastUpdatedPrefix = 'Last updated';
  static const String _kBackByLabel = 'Back by around';
  static const String _kOverrunLabel = 'Taking a little longer than expected';
  static const String _kQueueKeepPlaceLine =
      "We'll bring you in automatically. Your place is saved.";
  static const String _kUpdateHelpLabel = 'Get help with updating';
  static const List<String> _kStillWorkingDefaults = [
    'Card payments',
    'ATM withdrawals',
    'Phone banking',
  ];

  @override
  State<BankAppGateScreen> createState() => _BankAppGateScreenState();
}

class _BankAppGateScreenState extends State<BankAppGateScreen> {
  Timer? _countdownTimer;
  Duration _tickInterval = Duration.zero;
  Timer? _copiedResetTimer;
  bool _copied = false;

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // Reason-driven defaults
  // ---------------------------------------------------------------------------

  bool get _isAdversarialReason => switch (widget.reason) {
        BankAppGateReason.rootedDevice ||
        BankAppGateReason.vpnDetected ||
        BankAppGateReason.emulatorDetected ||
        BankAppGateReason.tamperDetected ||
        BankAppGateReason.geoRestricted =>
          true,
        _ => false,
      };

  IconData get _defaultIcon => switch (widget.reason) {
        BankAppGateReason.maintenance => Icons.build_circle_outlined,
        BankAppGateReason.offline => Icons.cloud_off_outlined,
        BankAppGateReason.forceUpdate => Icons.system_update_outlined,
        BankAppGateReason.rootedDevice ||
        BankAppGateReason.emulatorDetected ||
        BankAppGateReason.tamperDetected =>
          BankIcons.shield,
        BankAppGateReason.vpnDetected => Icons.vpn_lock_outlined,
        BankAppGateReason.geoRestricted => BankIcons.location,
        BankAppGateReason.clockSkew => BankIcons.schedule,
        BankAppGateReason.developerMode => Icons.developer_mode_outlined,
        BankAppGateReason.queueFull => Icons.hourglass_top_outlined,
      };

  String get _defaultTitle => switch (widget.reason) {
        BankAppGateReason.maintenance => 'Maintenance in progress',
        BankAppGateReason.offline => 'No internet connection',
        BankAppGateReason.forceUpdate => 'Time to update',
        BankAppGateReason.rootedDevice ||
        BankAppGateReason.emulatorDetected ||
        BankAppGateReason.tamperDetected =>
          "We can't open the app",
        BankAppGateReason.vpnDetected ||
        BankAppGateReason.geoRestricted =>
          "We can't log you in",
        BankAppGateReason.clockSkew => 'Check your date and time',
        BankAppGateReason.developerMode => 'Developer mode is on',
        BankAppGateReason.queueFull => 'You are in the queue',
      };

  String get _defaultBody => switch (widget.reason) {
        BankAppGateReason.maintenance =>
          'We are making some important updates. We will be back as '
              'soon as we can.',
        BankAppGateReason.offline =>
          'Your device seems to be offline. Check your Wi-Fi or '
              'mobile data, then try again.',
        BankAppGateReason.forceUpdate =>
          'Update needed to keep your money safe. This version of the '
              'app is no longer supported.',
        BankAppGateReason.rootedDevice ||
        BankAppGateReason.emulatorDetected ||
        BankAppGateReason.tamperDetected =>
          "We can't open the app on this device right now.",
        BankAppGateReason.vpnDetected ||
        BankAppGateReason.geoRestricted =>
          "We can't log you in right now, please try again later.",
        BankAppGateReason.clockSkew =>
          "Your device's clock looks wrong, so we can't connect "
              'securely. Setting it back to automatic usually fixes '
              'this.',
        BankAppGateReason.developerMode =>
          'For your security the app cannot run while developer mode '
              'is switched on. Turning it off fixes this.',
        BankAppGateReason.queueFull =>
          'A lot of people are signing in right now, so we are '
              'letting everyone in gradually.',
      };

  List<String>? get _defaultSteps => switch (widget.reason) {
        BankAppGateReason.clockSkew => const [
            'Open your device Settings',
            'Go to Date and Time',
            'Turn on Set automatically',
            'Come back to the app',
          ],
        BankAppGateReason.developerMode => const [
            'Open your device Settings',
            'Go to Developer options',
            'Switch developer mode off',
            'Come back to the app',
          ],
        _ => null,
      };

  String? get _defaultMoneySafetyLine => switch (widget.reason) {
        BankAppGateReason.maintenance ||
        BankAppGateReason.offline =>
          'Your money is safe.',
        _ => null,
      };

  // ---------------------------------------------------------------------------
  // Countdown timer
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _syncCountdownTimer();
  }

  @override
  void didUpdateWidget(BankAppGateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resumesAt != oldWidget.resumesAt) {
      _syncCountdownTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _copiedResetTimer?.cancel();
    super.dispose();
  }

  void _syncCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    final resumesAt = widget.resumesAt;
    if (resumesAt == null) {
      return;
    }
    final remaining = resumesAt.difference(_now);
    if (remaining <= Duration.zero) {
      return;
    }
    _tickInterval = _intervalFor(remaining);
    _countdownTimer = Timer.periodic(_tickInterval, _handleCountdownTick);
  }

  void _handleCountdownTick(Timer timer) {
    final resumesAt = widget.resumesAt;
    if (resumesAt == null) {
      timer.cancel();
      return;
    }
    final remaining = resumesAt.difference(_now);
    setState(() {
      // The countdown text derives from the clock inside build.
    });
    if (remaining <= Duration.zero) {
      timer.cancel();
      _countdownTimer = null;
      return;
    }
    if (_intervalFor(remaining) != _tickInterval) {
      _syncCountdownTimer();
    }
  }

  Duration _intervalFor(Duration remaining) =>
      remaining <= const Duration(minutes: 1)
          ? const Duration(seconds: 1)
          : const Duration(minutes: 1);

  String _formatCountdown(Duration remaining) {
    if (remaining.inHours >= 1) {
      final minutes = remaining.inMinutes % 60;
      return '${remaining.inHours}h ${minutes}m';
    }
    if (remaining.inMinutes >= 1) {
      return '${remaining.inMinutes}m';
    }
    return '${remaining.inSeconds}s';
  }

  /// Minute-granularity variant used for the countdown semantics
  /// label, so assistive tech is not spammed every second.
  String _formatCountdownMinutes(Duration remaining) {
    final totalMinutes = (remaining.inSeconds / 60).ceil();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours >= 1) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // ---------------------------------------------------------------------------
  // Reference code copying
  // ---------------------------------------------------------------------------

  void _copyReferenceCode() {
    final code = widget.referenceCode;
    if (code == null) {
      return;
    }
    unawaited(Clipboard.setData(ClipboardData(text: code)));
    _copiedResetTimer?.cancel();
    setState(() => _copied = true);
    _copiedResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Queue helpers
  // ---------------------------------------------------------------------------

  String _defaultQueueLine(int position, Duration? wait) {
    final base = 'You are number $position in line';
    if (wait == null) {
      return base;
    }
    return '$base, about ${_formatWait(wait)}';
  }

  String _formatWait(Duration wait) {
    if (wait.inMinutes < 1) {
      return 'less than a minute';
    }
    if (wait.inMinutes == 1) {
      return '1 minute';
    }
    if (wait.inMinutes < 60) {
      return '${wait.inMinutes} minutes';
    }
    final minutes = wait.inMinutes % 60;
    return '${wait.inHours}h ${minutes}m';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final resolvedDuration =
        widget.animationDuration ?? BankTokens.durationBase;
    final resolvedCurve = widget.animationCurve ?? BankTokens.curveDecelerate;
    final entranceDuration =
        disableAnimations ? Duration.zero : resolvedDuration;

    final resolvedTitle = widget.title ?? _defaultTitle;
    final resolvedBody = widget.body ?? _defaultBody;
    final resolvedSteps = widget.steps ?? _defaultSteps;
    final resolvedSafetyLine =
        widget.moneySafetyLine ?? _defaultMoneySafetyLine;
    final accent = widget.accentColor ??
        (_isAdversarialReason ? BankTokens.danger : theme.primary);
    final resolvedPadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: BankTokens.space8);

    final titleStyle = BankTokens.headlineMedium
        .copyWith(color: theme.onBackground)
        .merge(widget.titleStyle);
    final bodyStyle = BankTokens.bodyMedium
        .copyWith(color: theme.onSurfaceVariant)
        .merge(widget.bodyStyle);
    final mutedSmall =
        BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant);

    final showPrimary =
        widget.primaryActionLabel != null && widget.onPrimaryAction != null;
    final showSecondary =
        widget.secondaryActionLabel != null && widget.onSecondaryAction != null;
    final supportRow = _buildSupportRow(theme);
    final footer = _buildFooter(mutedSmall);
    final showStillWorking =
        widget.stillWorking != null && widget.stillWorking!.isNotEmpty;

    final content = <Widget>[
      const SizedBox(height: BankTokens.space6),
      const Spacer(),
      Center(child: _buildHeader(accent)),
      const SizedBox(height: BankTokens.space6),
      Text(resolvedTitle, style: titleStyle, textAlign: TextAlign.center),
      const SizedBox(height: BankTokens.space3),
      Text(resolvedBody, style: bodyStyle, textAlign: TextAlign.center),
      if (resolvedSafetyLine != null) ...[
        const SizedBox(height: BankTokens.space3),
        Text(
          resolvedSafetyLine,
          style: mutedSmall,
          textAlign: TextAlign.center,
        ),
      ],
      if (widget.resumesAt != null) ...[
        const SizedBox(height: BankTokens.space6),
        _buildCountdown(theme, mutedSmall),
      ],
      if (widget.reason == BankAppGateReason.queueFull) ...[
        const SizedBox(height: BankTokens.space6),
        _buildQueueBlock(theme, accent, disableAnimations, mutedSmall),
      ],
      if (resolvedSteps != null && resolvedSteps.isNotEmpty) ...[
        const SizedBox(height: BankTokens.space6),
        _buildSteps(theme, resolvedSteps),
      ],
      if (showStillWorking) ...[
        const SizedBox(height: BankTokens.space6),
        _buildStillWorkingCard(theme),
      ],
      if (widget.referenceCode != null) ...[
        const SizedBox(height: BankTokens.space6),
        Center(child: _buildReferenceChip(theme)),
        const SizedBox(height: BankTokens.space2),
        ExcludeSemantics(
          child: Text(
            widget.referenceCodeHint,
            style: mutedSmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
      if (showPrimary) ...[
        const SizedBox(height: BankTokens.space8),
        _buildPrimaryAction(theme),
      ],
      if (showSecondary) ...[
        const SizedBox(height: BankTokens.space2),
        _buildSecondaryAction(theme),
      ],
      if (supportRow != null) ...[
        const SizedBox(height: BankTokens.space4),
        Center(child: supportRow),
      ],
      const Spacer(),
      if (footer.isNotEmpty) ...[
        const SizedBox(height: BankTokens.space4),
        ...footer,
      ],
      const SizedBox(height: BankTokens.space4),
    ];

    return Semantics(
      container: true,
      liveRegion: true,
      label: widget.semanticLabel ?? '$resolvedTitle. $resolvedBody',
      child: ColoredBox(
        color: widget.backgroundColor ?? theme.background,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: resolvedPadding,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: entranceDuration,
                      curve: resolvedCurve,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 12),
                          child: child,
                        ),
                      ),
                      child: Column(children: content),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildHeader(Color accent) {
    final illustration = widget.illustration;
    if (illustration != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: illustration,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space5),
        child: Icon(
          widget.icon ?? _defaultIcon,
          size: 48,
          color: accent,
        ),
      ),
    );
  }

  Widget _buildCountdown(BankThemeData theme, TextStyle mutedSmall) {
    final resumesAt = widget.resumesAt!;
    final remaining = resumesAt.difference(_now);
    if (remaining <= Duration.zero) {
      return Text(
        widget.overrunLabel,
        style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
        textAlign: TextAlign.center,
      );
    }
    final backBy =
        '${widget.backByLabel} ${BankDateFormatter.formatTime(resumesAt)}';
    return Semantics(
      label: '$backBy. ${_formatCountdownMinutes(remaining)}',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            backBy,
            style:
                BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BankTokens.space1),
          Text(
            _formatCountdown(remaining),
            style: theme.numeralMedium.copyWith(color: theme.onBackground),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQueueBlock(
    BankThemeData theme,
    Color accent,
    bool disableAnimations,
    TextStyle mutedSmall,
  ) {
    final position = widget.queuePosition;
    final initial = widget.queueInitialPosition;
    final children = <Widget>[];
    if (position != null) {
      final line =
          widget.queuePositionLine?.call(position, widget.estimatedWait) ??
              _defaultQueueLine(position, widget.estimatedWait);
      final positionText = Text(
        line,
        key: ValueKey<String>(line),
        style: BankTokens.bodyLarge.copyWith(
          color: theme.onBackground,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      );
      if (disableAnimations) {
        children.add(positionText);
      } else {
        children.add(
          AnimatedSwitcher(
            duration: widget.animationDuration ?? BankTokens.durationBase,
            switchInCurve: widget.animationCurve ?? BankTokens.curveStandard,
            switchOutCurve: widget.animationCurve ?? BankTokens.curveStandard,
            child: positionText,
          ),
        );
      }
      if (initial != null && initial > 0) {
        final progress = (1 - position / initial).clamp(0, 1).toDouble();
        children.addAll(<Widget>[
          const SizedBox(height: BankTokens.space4),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: theme.surfaceVariant,
            color: accent,
            borderRadius: theme.chipRadius,
          ),
        ]);
      }
    }
    if (children.isNotEmpty) {
      children.add(const SizedBox(height: BankTokens.space3));
    }
    children.add(
      Text(
        widget.queueKeepPlaceLine,
        style: mutedSmall,
        textAlign: TextAlign.center,
      ),
    );
    return Column(children: children);
  }

  Widget _buildSteps(BankThemeData theme, List<String> steps) {
    final numberStyle =
        BankTokens.labelLarge.copyWith(color: theme.onBackground);
    final stepStyle = BankTokens.bodyMedium.copyWith(color: theme.onBackground);
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: BankTokens.space2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: BankTokens.space6,
                    child: Text('${i + 1}.', style: numberStyle),
                  ),
                  Expanded(child: Text(steps[i], style: stepStyle)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStillWorkingCard(BankThemeData theme) {
    final itemStyle = BankTokens.bodyMedium.copyWith(color: theme.onSurface);
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: theme.cardRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(BankTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.stillWorkingTitle,
                style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
              ),
              for (final item in widget.stillWorking!)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: BankTokens.space2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        BankIcons.success,
                        size: 20,
                        color: BankTokens.success,
                      ),
                      const SizedBox(width: BankTokens.space2),
                      Expanded(child: Text(item, style: itemStyle)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceChip(BankThemeData theme) {
    final code = widget.referenceCode!;
    return Semantics(
      button: true,
      label: '$code. ${widget.referenceCodeHint}',
      excludeSemantics: true,
      child: Material(
        color: theme.surfaceVariant,
        borderRadius: theme.chipRadius,
        child: InkWell(
          onTap: _copyReferenceCode,
          borderRadius: theme.chipRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BankTokens.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style:
                        BankTokens.labelLarge.copyWith(color: theme.onSurface),
                  ),
                  const SizedBox(width: BankTokens.space2),
                  Icon(
                    _copied ? BankIcons.success : BankIcons.copy,
                    size: 18,
                    color:
                        _copied ? BankTokens.success : theme.onSurfaceVariant,
                  ),
                  if (_copied) ...[
                    const SizedBox(width: BankTokens.space1),
                    Text(
                      widget.copiedLabel,
                      style: BankTokens.labelMedium.copyWith(
                        color: BankTokens.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(BankThemeData theme) {
    return Semantics(
      button: true,
      label: widget.primaryActionLabel,
      child: FilledButton(
        onPressed: widget.onPrimaryAction,
        style: FilledButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.onPrimary,
          minimumSize: const Size(double.infinity, BankTokens.minTapTarget),
          shape: RoundedRectangleBorder(borderRadius: theme.buttonRadius),
          textStyle: BankTokens.labelLarge,
        ),
        child: Text(widget.primaryActionLabel!),
      ),
    );
  }

  Widget _buildSecondaryAction(BankThemeData theme) {
    return Semantics(
      button: true,
      label: widget.secondaryActionLabel,
      child: TextButton(
        onPressed: widget.onSecondaryAction,
        style: TextButton.styleFrom(
          foregroundColor: theme.onSurfaceVariant,
          minimumSize: const Size(double.infinity, BankTokens.minTapTarget),
          shape: RoundedRectangleBorder(borderRadius: theme.buttonRadius),
          textStyle: BankTokens.labelLarge,
        ),
        child: Text(widget.secondaryActionLabel!),
      ),
    );
  }

  Widget? _buildSupportRow(BankThemeData theme) {
    if (widget.supportContact != null) {
      return widget.supportContact;
    }
    final label = widget.supportPhoneLabel;
    if (label == null) {
      return null;
    }
    final icon = Icon(
      widget.supportIcon ?? Icons.phone_outlined,
      size: 18,
      color: theme.onSurfaceVariant,
    );
    if (widget.onContactSupport == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: BankTokens.space2),
          Text(
            label,
            style: BankTokens.labelLarge.copyWith(
              color: theme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    return Semantics(
      button: true,
      label: label,
      child: TextButton.icon(
        onPressed: widget.onContactSupport,
        style: TextButton.styleFrom(
          foregroundColor: theme.onSurfaceVariant,
          minimumSize: const Size(
            BankTokens.minTapTarget,
            BankTokens.minTapTarget,
          ),
          textStyle: BankTokens.labelLarge,
        ),
        icon: icon,
        label: Text(label),
      ),
    );
  }

  List<Widget> _buildFooter(TextStyle mutedSmall) {
    return <Widget>[
      if (widget.appVersion != null)
        Text(
          '${widget.versionPrefix} ${widget.appVersion}',
          style: mutedSmall,
          textAlign: TextAlign.center,
        ),
      if (widget.lastUpdatedAt != null) ...[
        if (widget.appVersion != null)
          const SizedBox(height: BankTokens.space1),
        Text(
          '${widget.lastUpdatedPrefix} '
          '${BankDateFormatter.formatTime(widget.lastUpdatedAt!)}',
          style: mutedSmall,
          textAlign: TextAlign.center,
        ),
      ],
    ];
  }
}
