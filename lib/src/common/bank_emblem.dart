import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_icon_spec.dart';

/// A unified circular entity identifier (avatar / emblem) for payees,
/// merchants, beneficiaries, and accounts.
///
/// Use it anywhere a person, merchant, or institution needs a compact
/// visual identity: transaction rows, beneficiary pickers, transfer review
/// screens, and payment request cards.
///
/// Content is resolved in this order:
///
/// 1. **Network image** — [imageUrl] fades in over
///    [BankTokens.durationFast] once loaded. While loading, and if the
///    request fails, the initials / icon placeholder below is shown
///    instead; a broken-image glyph is never rendered.
/// 2. **Initials** — the first letters of up to two words of
///    [initialsFrom], on a background colour derived from a stable hash of
///    [initialsFrom] across an eight-colour palette, so the same payee
///    always receives the same colour.
/// 3. **Icon** — [icon] tinted [BankThemeData.primary] on an 8 % primary
///    tint; [BankIcons.account] is used when no content is given at all.
///
/// [badgeCount] renders a [BankTokens.danger] count bubble at the top-end
/// corner, capped at `99+`. [badgeOverlay] renders arbitrary content at
/// the bottom-end corner (e.g. a mini card-network logo); both corners may
/// be used together.
///
/// The emblem is excluded from semantics by default because it is
/// decorative. When [onTap] is provided it becomes a semantic button
/// labelled with [initialsFrom], and the widget reserves at least
/// [BankTokens.minTapTarget] logical pixels per side so the tap target
/// meets accessibility guidance (the visual circle keeps its [size]).
///
/// The image fade-in is skipped when [MediaQuery.disableAnimationsOf]
/// reports `true`.
///
/// ```dart
/// BankEmblem(
///   imageUrl: beneficiary.avatarUrl,
///   initialsFrom: beneficiary.name,
///   badgeCount: pendingRequestCount,
///   onTap: () => openBeneficiary(beneficiary),
/// )
/// ```
class BankEmblem extends StatelessWidget {
  const BankEmblem({
    super.key,
    this.imageUrl,
    this.initialsFrom,
    this.icon,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.badgeCount,
    this.badgeOverlay,
    this.border,
    this.onTap,
  });

  /// URL of the entity image (payee photo, merchant logo).
  ///
  /// Highest-priority content; the initials / icon placeholder is shown
  /// while it loads and if loading fails.
  final String? imageUrl;

  /// Source text for the initials fallback, typically the entity's
  /// display name. Also used as the semantics label when [onTap] is set.
  final String? initialsFrom;

  /// Icon fallback shown when neither [imageUrl] nor usable
  /// [initialsFrom] content is available.
  final IconData? icon;

  /// Diameter of the circle in logical pixels.
  final double size;

  /// Overrides the resolved background colour.
  final Color? backgroundColor;

  /// Overrides the resolved foreground (initials / icon) colour.
  final Color? foregroundColor;

  /// When non-null and greater than zero, renders a [BankTokens.danger]
  /// count bubble at the top-end corner, capped at `99+`.
  final int? badgeCount;

  /// Arbitrary content rendered at the bottom-end corner, such as a mini
  /// card-network logo.
  final Widget? badgeOverlay;

  /// Optional border drawn around the circle.
  final BoxBorder? border;

  /// Makes the emblem tappable and exposes it as a semantic button.
  final VoidCallback? onTap;

  /// Deterministic initials palette — eight hues dark enough to keep the
  /// automatically chosen foreground legible in light and dark themes.
  static const List<Color> _initialsPalette = <Color>[
    Color(0xFF3B5BDB),
    Color(0xFF1971C2),
    Color(0xFF0B7285),
    Color(0xFF2B8A3E),
    Color(0xFFE67700),
    Color(0xFFD9480F),
    Color(0xFFA61E4D),
    Color(0xFF862E9C),
  ];

  /// First letters of up to two whitespace-separated words, upper-cased.
  static String _initialsOf(String source) {
    final words = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    return words.map((word) => word.substring(0, 1).toUpperCase()).join();
  }

  /// Platform-stable hash so a payee keeps its colour across sessions.
  static int _stableHash(String source) {
    var hash = 17;
    for (final unit in source.codeUnits) {
      hash = (hash * 31 + unit) & 0x3FFFFFFF;
    }
    return hash;
  }

  static Color _contrastOn(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final initials = initialsFrom == null ? '' : _initialsOf(initialsFrom!);
    final hasInitials = initials.isNotEmpty;

    final resolvedBackground = backgroundColor ??
        (hasInitials
            ? _initialsPalette[
                _stableHash(initialsFrom!) % _initialsPalette.length]
            : theme.primary.withValues(alpha: 0.08));

    final resolvedForeground = foregroundColor ??
        (hasInitials ? _contrastOn(resolvedBackground) : theme.primary);

    final placeholder = hasInitials
        ? Text(
            initials,
            style: BankTokens.labelLarge.copyWith(
              color: resolvedForeground,
              fontSize: size * 0.4,
            ),
            maxLines: 1,
          )
        : Icon(
            icon ?? BankIcons.account,
            color: resolvedForeground,
            size: size * 0.5,
          );

    Widget content = Center(child: placeholder);

    if (imageUrl != null) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration:
                    disableAnimations ? Duration.zero : BankTokens.durationFast,
                curve: BankTokens.curveStandard,
                child: child,
              );
            },
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ],
      );
    }

    Widget emblem = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: resolvedBackground,
          shape: BoxShape.circle,
          border: border,
        ),
        child: ClipOval(child: content),
      ),
    );

    final hasCountBadge = badgeCount != null && badgeCount! > 0;
    if (hasCountBadge || badgeOverlay != null) {
      emblem = Stack(
        clipBehavior: Clip.none,
        children: [
          emblem,
          if (hasCountBadge)
            PositionedDirectional(
              top: -BankTokens.space1,
              end: -BankTokens.space1,
              child: _EmblemCountBadge(count: badgeCount!, theme: theme),
            ),
          if (badgeOverlay != null)
            PositionedDirectional(
              bottom: -BankTokens.space1,
              end: -BankTokens.space1,
              child: badgeOverlay!,
            ),
        ],
      );
    }

    if (onTap == null) {
      return ExcludeSemantics(child: emblem);
    }

    final targetSide =
        size < BankTokens.minTapTarget ? BankTokens.minTapTarget : size;

    return Semantics(
      button: true,
      label: initialsFrom,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: targetSide,
          height: targetSide,
          child: Center(child: emblem),
        ),
      ),
    );
  }
}

/// Danger-coloured unread / attention count bubble, capped at `99+`,
/// ringed with [BankThemeData.surface] so it separates cleanly from the
/// emblem content beneath it.
class _EmblemCountBadge extends StatelessWidget {
  const _EmblemCountBadge({
    required this.count,
    required this.theme,
  });

  final int count;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: BankTokens.space1),
      decoration: BoxDecoration(
        color: BankTokens.danger,
        borderRadius: const BorderRadius.all(
          Radius.circular(BankTokens.radiusFull),
        ),
        border: Border.all(color: theme.surface, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: BankTokens.labelSmall.copyWith(
          color: const Color(0xFFFFFFFF),
          height: 1,
        ),
        maxLines: 1,
      ),
    );
  }
}
