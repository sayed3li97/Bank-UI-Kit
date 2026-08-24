import 'package:flutter/material.dart';

import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_icon_spec.dart';

// ---------------------------------------------------------------------------
// The kit's identity system: one size ladder, one colour derivation, one
// tinted-container anatomy — shared by every avatar, emblem, chip, and badge.
// ---------------------------------------------------------------------------

/// The identity size ladder.
///
/// Every avatar and emblem in the kit picks a rung here instead of naming a
/// diameter, so a beneficiary row, a transaction tile, and a transfer review
/// screen agree on how big "an identity" is.
///
/// The diameters are rungs of the spacing grid, and the glyph inside each one
/// is the nearest rung of the [BankTokens.iconXSmall]–[BankTokens.iconHero]
/// ladder to half the diameter (see [BankEmblem.glyphSizeFor]) — so the icon
/// inside an emblem and the icon beside it are drawn from the same ladder.
enum BankEmblemSize {
  /// 24 px — stacked group rails, inline mentions, dense metadata rows.
  xSmall(BankTokens.space6),

  /// 32 px — compact tiles and horizontal rails.
  small(BankTokens.space8),

  /// 40 px — the default list-row identity.
  medium(BankTokens.space10),

  /// 48 px — section headers and review screens, where the entity is the
  /// subject of the screen rather than one row of many.
  large(BankTokens.space12),

  /// 64 px — profile and detail headers: one per screen.
  xLarge(BankTokens.space16);

  const BankEmblemSize(this.diameter);

  /// Diameter of the emblem circle, in logical pixels.
  final double diameter;

  /// Size of the glyph drawn inside this rung.
  double get glyphSize => BankEmblem.glyphSizeFor(diameter);
}

/// An optional ring drawn around a [BankEmblem].
///
/// The ring is drawn **inside** the emblem's footprint and the content circle
/// shrinks to fit, so a ringed and an unringed emblem at the same rung occupy
/// exactly the same box. That is what keeps a rail mixing "current turn"
/// (ringed) and ordinary members on one baseline grid, and what makes the
/// overlap arithmetic in [BankEmblemStack] independent of ring state.
@immutable
class BankEmblemRing {
  /// Creates a ring description. Every field falls back to a theme value at
  /// paint time, so `const BankEmblemRing()` is the plain surface-coloured
  /// separator ring used between overlapping avatars.
  const BankEmblemRing({
    this.color,
    this.width,
    this.gap,
    this.gapColor,
  });

  /// Ring colour. Defaults to [BankThemeData.surface], which is what makes
  /// overlapping avatars read as separate discs rather than one blob.
  final Color? color;

  /// Ring stroke width. Defaults to twice [BankTokens.hairlineWidth] — a
  /// hairline disappears at avatar scale.
  final double? width;

  /// Gap between the ring and the content circle. Defaults to `0` (the ring
  /// hugs the disc); give it [BankTokens.hairlineWidth] or more for the
  /// detached "story ring" look.
  final double? gap;

  /// Fill of the [gap] band. Defaults to [BankThemeData.surface].
  final Color? gapColor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankEmblemRing &&
        other.color == color &&
        other.width == width &&
        other.gap == gap &&
        other.gapColor == gapColor;
  }

  @override
  int get hashCode => Object.hash(color, width, gap, gapColor);
}

/// One entity's identity, independent of the size it is drawn at.
///
/// [BankEmblemStack] renders a list of these at a uniform rung; a single
/// identity is normally passed to [BankEmblem] as constructor arguments
/// instead. The fields mirror [BankEmblem]'s content parameters exactly.
@immutable
class BankEmblemData {
  /// Creates an identity descriptor.
  const BankEmblemData({
    this.imageUrl,
    this.imageProvider,
    this.initialsFrom,
    this.icon,
    this.label,
    this.tintColor,
    this.backgroundColor,
    this.foregroundColor,
    this.ring,
    this.badgeCount,
    this.badgeOverlay,
    this.opacity,
    this.semanticLabel,
    this.onTap,
  });

  /// See [BankEmblem.imageUrl].
  final String? imageUrl;

  /// See [BankEmblem.imageProvider].
  final ImageProvider? imageProvider;

  /// See [BankEmblem.initialsFrom].
  final String? initialsFrom;

  /// See [BankEmblem.icon].
  final IconData? icon;

  /// See [BankEmblem.label].
  final String? label;

  /// See [BankEmblem.tintColor].
  final Color? tintColor;

  /// See [BankEmblem.backgroundColor].
  final Color? backgroundColor;

  /// See [BankEmblem.foregroundColor].
  final Color? foregroundColor;

  /// See [BankEmblem.ring]. A per-entity ring wins over the group ring passed
  /// to [BankEmblemStack].
  final BankEmblemRing? ring;

  /// See [BankEmblem.badgeCount].
  final int? badgeCount;

  /// See [BankEmblem.badgeOverlay].
  final Widget? badgeOverlay;

  /// Opacity applied to the whole emblem, for entities that are present but
  /// spent (a collected turn, a settled request). `null` means fully opaque.
  final double? opacity;

  /// See [BankEmblem.semanticLabel].
  final String? semanticLabel;

  /// See [BankEmblem.onTap].
  final VoidCallback? onTap;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankEmblemData &&
        other.imageUrl == imageUrl &&
        other.imageProvider == imageProvider &&
        other.initialsFrom == initialsFrom &&
        other.icon == icon &&
        other.label == label &&
        other.tintColor == tintColor &&
        other.backgroundColor == backgroundColor &&
        other.foregroundColor == foregroundColor &&
        other.ring == ring &&
        other.badgeCount == badgeCount &&
        other.badgeOverlay == badgeOverlay &&
        other.opacity == opacity &&
        other.semanticLabel == semanticLabel &&
        other.onTap == onTap;
  }

  @override
  int get hashCode => Object.hash(
        imageUrl,
        imageProvider,
        initialsFrom,
        icon,
        label,
        tintColor,
        backgroundColor,
        foregroundColor,
        ring,
        badgeCount,
        badgeOverlay,
        opacity,
        semanticLabel,
        onTap,
      );
}

/// A unified circular entity identifier (avatar / emblem) for payees,
/// merchants, beneficiaries, and accounts.
///
/// Use it anywhere a person, merchant, or institution needs a compact
/// visual identity: transaction rows, beneficiary pickers, transfer review
/// screens, and payment request cards.
///
/// ## Anatomy
///
/// Every emblem is the same tinted container: a low-alpha
/// ([BankTokens.alphaSoft]) wash of one hue with the *same* hue, darkened or
/// lightened until it clears WCAG AA, as the ink. There is deliberately no
/// second, saturated-fill species — a screen of grey monogram discs next to
/// saturated colour discs reads as two products.
///
/// ## Size
///
/// Prefer [tier], a rung of [BankEmblemSize]. [size] remains for the rare
/// off-ladder diameter and is ignored when [tier] is set.
///
/// ## Content
///
/// Content is resolved in this order:
///
/// 1. **Explicit provider**: [imageProvider], when given, is rendered
///    directly and takes precedence over [imageUrl].
/// 2. **URL image**: [imageUrl] is turned into a provider via
///    [BankUiScope.imageProviderFor] (the scope's
///    [BankUiScopeData.imageResolver] when set, [NetworkImage]
///    otherwise) and fades in over [BankTokens.durationFast] once
///    loaded. While loading, and if the request fails, the initials /
///    icon placeholder below is shown instead; a broken-image glyph is
///    never rendered.
/// 3. **Literal label**: [label], rendered verbatim — the `+3` of a stacked
///    group's overflow disc.
/// 4. **Initials**: the first letters of up to two words of [initialsFrom].
/// 5. **Icon**: [icon], falling back to [BankIcons.account] when no content
///    is given at all.
///
/// ## Colour
///
/// The hue is derived from the theme, not from a fixed palette: the brand's
/// own hue rotated by one of [identityBuckets] equal steps chosen by a stable
/// hash of [initialsFrom]. The same payee therefore keeps its colour across
/// sessions and platforms, two payees a step apart are 45° apart on the wheel,
/// and every emblem still belongs to the brand. Pass [tintColor] to name the
/// hue directly (semantic emblems — a fraud alert, a payment) or
/// [backgroundColor] / [foregroundColor] to bypass derivation entirely.
///
/// ## Decorations
///
/// [ring] draws an inset ring (see [BankEmblemRing]); [badgeCount] renders a
/// [BankTokens.danger] count bubble at the top-end corner, capped at `99+`;
/// [badgeOverlay] renders arbitrary content at the bottom-end corner (e.g. a
/// mini card-network logo). All three may be used together.
///
/// The emblem is excluded from semantics by default because it is
/// decorative. When [onTap] is provided it becomes a semantic button
/// labelled with [initialsFrom], and the widget reserves at least
/// [BankTokens.minTapTarget] logical pixels per side so the tap target
/// meets accessibility guidance (the visual circle keeps its diameter).
///
/// The image fade-in is skipped when [MediaQuery.disableAnimationsOf]
/// reports `true`.
///
/// ```dart
/// BankEmblem(
///   imageUrl: beneficiary.avatarUrl,
///   initialsFrom: beneficiary.name,
///   tier: BankEmblemSize.medium,
///   badgeCount: pendingRequestCount,
///   onTap: () => openBeneficiary(beneficiary),
/// )
/// ```
class BankEmblem extends StatelessWidget {
  /// Creates an emblem. Every parameter is optional; with none at all the
  /// widget renders [BankIcons.account] on a brand-tinted disc.
  const BankEmblem({
    super.key,
    this.imageUrl,
    this.imageProvider,
    this.initialsFrom,
    this.icon,
    this.label,
    this.tier,
    this.size = 40,
    this.tintColor,
    this.backgroundColor,
    this.foregroundColor,
    this.badgeCount,
    this.badgeOverlay,
    this.ring,
    this.border,
    this.onTap,
    this.initialsStyle,
    this.badgeColor,
    this.semanticLabel,
    this.animationDuration,
    this.animationCurve,
  });

  /// URL of the entity image (payee photo, merchant logo).
  ///
  /// Resolved via [BankUiScope.imageProviderFor], so a
  /// [BankUiScopeData.imageResolver] can substitute a custom provider;
  /// without one, [NetworkImage] is used. The initials / icon
  /// placeholder is shown while it loads and if loading fails. Ignored
  /// when [imageProvider] is set.
  final String? imageUrl;

  /// Explicit image provider, bypassing URL resolution entirely.
  ///
  /// Highest-priority content; takes precedence over [imageUrl].
  final ImageProvider? imageProvider;

  /// Source text for the initials fallback, typically the entity's
  /// display name. Also seeds the derived hue, and is used as the semantics
  /// label when [onTap] is set.
  final String? initialsFrom;

  /// Icon fallback shown when neither an image nor usable [label] /
  /// [initialsFrom] content is available.
  final IconData? icon;

  /// Literal text rendered in place of derived initials.
  ///
  /// For content that is not a name and must not be abbreviated — the `+3` of
  /// a stacked group's overflow disc, a currency code, a rank.
  final String? label;

  /// Rung of the identity size ladder. Wins over [size] when set; prefer it,
  /// so identities across screens stay on one ladder.
  final BankEmblemSize? tier;

  /// Diameter of the circle in logical pixels, for off-ladder sizes.
  ///
  /// Ignored when [tier] is set. The default matches
  /// [BankEmblemSize.medium].
  final double size;

  /// Hue the tinted container is derived from, overriding the hash-derived
  /// brand hue.
  ///
  /// Use it for emblems whose colour *means* something (a danger-tinted fraud
  /// alert, a gain-tinted payment) rather than identifying someone. The fill
  /// and the ink are still derived from it, so the anatomy stays the same.
  final Color? tintColor;

  /// Overrides the resolved background colour.
  final Color? backgroundColor;

  /// Overrides the resolved foreground (initials / icon) colour.
  ///
  /// Skips the contrast correction applied to derived inks, so a caller that
  /// sets this owns its own legibility.
  final Color? foregroundColor;

  /// When non-null and greater than zero, renders a [BankTokens.danger]
  /// count bubble at the top-end corner, capped at `99+`.
  final int? badgeCount;

  /// Arbitrary content rendered at the bottom-end corner, such as a mini
  /// card-network logo.
  final Widget? badgeOverlay;

  /// Optional inset ring; see [BankEmblemRing].
  final BankEmblemRing? ring;

  /// Optional border drawn on the content circle itself.
  ///
  /// Predates [ring] and paints *over* the content edge rather than insetting
  /// it. Prefer [ring] for state decorations (current turn, unpaid, online).
  final BoxBorder? border;

  /// Makes the emblem tappable and exposes it as a semantic button.
  final VoidCallback? onTap;

  /// Merged over the computed initials style ([BankTokens.labelLarge] sized
  /// to 40 % of the diameter, in the resolved foreground colour).
  final TextStyle? initialsStyle;

  /// Overrides [BankTokens.danger] as the [badgeCount] bubble colour.
  final Color? badgeColor;

  /// Overrides [initialsFrom] as the semantics label used when [onTap]
  /// makes the emblem a button.
  final String? semanticLabel;

  /// Overrides [BankTokens.durationFast] for the image fade-in.
  final Duration? animationDuration;

  /// Overrides [BankTokens.curveStandard] for the image fade-in.
  final Curve? animationCurve;

  // -------------------------------------------------------------------------
  // Identity colour derivation
  // -------------------------------------------------------------------------

  /// Number of distinct hues the identity palette rotates through.
  ///
  /// Eight steps put neighbouring buckets 45° apart — far enough that two
  /// adjacent avatars never read as the same person, close enough that the
  /// whole set still reads as one family.
  static const int identityBuckets = 8;

  /// WCAG AA contrast for normal-size text. Monogram initials are small and
  /// carry meaning, so they are held to the text threshold, not 3:1.
  static const double _minInkContrast = 4.5;

  /// Lightness the derived hue starts at before contrast correction.
  static const double _identityLightness = 0.45;

  /// Saturation floor and ceiling for derived hues.
  ///
  /// The floor keeps the palette usable for achromatic brands (a black or
  /// white primary has no hue to rotate, so unclamped every bucket would come
  /// back the same grey); the ceiling stops a neon brand from turning a wall
  /// of avatars into a highlighter set.
  static const double _identityMinSaturation = 0.42;
  static const double _identityMaxSaturation = 0.72;

  /// Lightness step and step budget for the contrast correction walk.
  static const double _inkStep = 0.04;
  static const int _inkStepBudget = 25;

  /// Monogram cap height as a fraction of the diameter.
  static const double _monogramRatio = 0.4;

  /// Glyph size as a fraction of the diameter, before snapping to the icon
  /// ladder.
  static const double _glyphRatio = 0.5;

  /// Count-bubble diameter as a fraction of the emblem diameter, before
  /// snapping to the icon ladder.
  static const double _badgeRatio = 0.42;

  /// Count-bubble label size as a fraction of the bubble diameter.
  static const double _badgeLabelRatio = 0.62;

  static const List<double> _iconLadder = <double>[
    BankTokens.iconXSmall,
    BankTokens.iconSmall,
    BankTokens.iconMedium,
    BankTokens.iconLarge,
    BankTokens.iconXLarge,
    BankTokens.iconHero,
  ];

  /// The rung of the icon ladder closest to [target].
  static double _nearestRung(double target) {
    var best = _iconLadder.first;
    var bestDelta = (best - target).abs();
    for (final rung in _iconLadder) {
      final delta = (rung - target).abs();
      if (delta < bestDelta) {
        best = rung;
        bestDelta = delta;
      }
    }
    return best;
  }

  /// The glyph size an emblem of [diameter] draws its icon at: the rung of
  /// the [BankTokens] icon ladder nearest half the diameter.
  static double glyphSizeFor(double diameter) =>
      _nearestRung(diameter * _glyphRatio);

  /// The deterministic identity hue for [seed] under [theme].
  ///
  /// The brand's own hue rotated by one of [identityBuckets] equal steps,
  /// picked by a platform-stable hash of [seed] — so the same payee keeps its
  /// colour across sessions, devices, and Dart versions.
  ///
  /// The result is a mid-lightness seed, not a finished ink: pass it through
  /// [inkFor] before painting text with it.
  static Color tintFor(BankThemeData theme, String seed) {
    final brand = HSLColor.fromColor(theme.primary);
    final bucket = _stableHash(seed) % identityBuckets;
    final hue = (brand.hue + bucket * (360 / identityBuckets)) % 360;
    final saturation =
        brand.saturation.clamp(_identityMinSaturation, _identityMaxSaturation);
    return HSLColor.fromAHSL(1, hue, saturation, _identityLightness).toColor();
  }

  /// The resting fill of a tinted container inked with [tint].
  ///
  /// [BankTokens.alphaSoft] of [tint] composited over [surface] (defaulting
  /// to [BankThemeData.surface]). Returned opaque, so callers can measure
  /// contrast against it.
  static Color fillFor(BankThemeData theme, Color tint, {Color? surface}) =>
      Color.alphaBlend(
        tint.withValues(alpha: BankTokens.alphaSoft),
        surface ?? theme.surface,
      );

  /// [tint] darkened (on light surfaces) or lightened (on dark ones) until it
  /// clears WCAG AA against [fillFor] of the same tint.
  ///
  /// A fixed lightness cannot do this: HSL lightness is not luminance, so a
  /// yellow and a blue at the same lightness differ by more than 2:1 of
  /// contrast. Walking the lightness axis until the measured ratio clears is
  /// the only way one derivation stays legible for every hue, both
  /// brightnesses, and all four presets.
  static Color inkFor(BankThemeData theme, Color tint, {Color? surface}) =>
      _legibleOn(tint, fillFor(theme, tint, surface: surface));

  static Color _legibleOn(Color seed, Color on) {
    if (_contrastRatio(seed, on) >= _minInkContrast) return seed;
    final towardBlack = on.computeLuminance() > 0.5;
    var hsl = HSLColor.fromColor(seed);
    for (var step = 0; step < _inkStepBudget; step++) {
      final next = (hsl.lightness + (towardBlack ? -_inkStep : _inkStep))
          .clamp(0, 1)
          .toDouble();
      if (next == hsl.lightness) break;
      hsl = hsl.withLightness(next);
      final candidate = hsl.toColor();
      if (_contrastRatio(candidate, on) >= _minInkContrast) return candidate;
    }
    return hsl.toColor();
  }

  static double _contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final diameter = tier?.diameter ?? size;

    final initials = initialsFrom == null ? '' : _initialsOf(initialsFrom!);
    final monogram = label ?? (initials.isEmpty ? null : initials);

    final seed = tintColor ??
        (initialsFrom != null && initialsFrom!.trim().isNotEmpty
            ? tintFor(theme, initialsFrom!)
            : theme.primary);

    final resolvedBackground = backgroundColor ?? fillFor(theme, seed);
    final resolvedForeground =
        foregroundColor ?? _legibleOn(seed, resolvedBackground);

    final placeholder = monogram != null
        ? Text(
            monogram,
            style: BankTokens.labelLarge
                .copyWith(
                  color: resolvedForeground,
                  fontSize: diameter * _monogramRatio,
                )
                .merge(initialsStyle),
            maxLines: 1,
          )
        : Icon(
            icon ?? BankIcons.account,
            color: resolvedForeground,
            size: glyphSizeFor(diameter),
          );

    Widget content = Center(child: placeholder);

    final resolvedImage = imageProvider ??
        (imageUrl == null
            ? null
            : BankUiScope.imageProviderFor(context, imageUrl!));

    if (resolvedImage != null) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          Image(
            image: resolvedImage,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: disableAnimations
                    ? Duration.zero
                    : animationDuration ?? BankTokens.durationFast,
                curve: animationCurve ?? BankTokens.curveStandard,
                child: child,
              );
            },
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ],
      );
    }

    Widget disc = DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackground,
        shape: BoxShape.circle,
        border: border,
      ),
      child: ClipOval(child: content),
    );

    final resolvedRing = ring;
    if (resolvedRing != null) {
      final ringWidth = resolvedRing.width ?? BankTokens.hairlineWidth * 2;
      final ringGap = resolvedRing.gap ?? 0;
      disc = Container(
        decoration: BoxDecoration(
          color: resolvedRing.gapColor ?? theme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: resolvedRing.color ?? theme.surface,
            width: ringWidth,
          ),
        ),
        padding: EdgeInsets.all(ringWidth + ringGap),
        child: disc,
      );
    }

    Widget emblem = SizedBox(
      width: diameter,
      height: diameter,
      child: disc,
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
              child: _EmblemCountBadge(
                count: badgeCount!,
                theme: theme,
                side: _nearestRung(diameter * _badgeRatio),
                color: badgeColor,
              ),
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
        diameter < BankTokens.minTapTarget ? BankTokens.minTapTarget : diameter;

    return Semantics(
      button: true,
      label: semanticLabel ?? initialsFrom,
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

/// A row of overlapping identities with a `+N` overflow disc.
///
/// The group answers "who is in this?" in one glance and in a bounded width:
/// at most [maxVisible] emblems are drawn and everyone else is folded into a
/// trailing overflow disc, so a seventh member can never fall off the edge of
/// a card.
///
/// Layout is directional, not mirrored geometry: the first identity sits on
/// the **leading** edge and is painted on top, each later one tucking behind
/// it toward the trailing edge. In RTL that reverses automatically, because
/// every offset is a [PositionedDirectional] `start`.
///
/// Set [overlap] to `0` and give [spacing] a value to get a spaced rail
/// instead of a pile — same overflow behaviour, same ladder.
///
/// ```dart
/// BankEmblemStack(
///   emblems: [for (final m in members) BankEmblemData(initialsFrom: m.name)],
///   tier: BankEmblemSize.small,
///   maxVisible: 5,
/// )
/// ```
class BankEmblemStack extends StatelessWidget {
  /// Creates a stacked identity group.
  const BankEmblemStack({
    required this.emblems,
    super.key,
    this.tier = BankEmblemSize.medium,
    this.size,
    this.maxVisible = 4,
    this.overlap = defaultOverlap,
    this.spacing = 0,
    this.ring,
    this.overflowCount,
    this.overflowTemplate = '+{n}',
    this.overflowTintColor,
    this.onOverflowTap,
    this.semanticLabel,
  });

  /// Fraction of each disc hidden by the one in front of it.
  ///
  /// A third is the point where the pile still reads as separate people but
  /// eight of them still fit a phone card; less looks like a broken rail,
  /// more hides the monograms.
  static const double defaultOverlap = 1 / 3;

  /// The identities to draw, in the order they should appear.
  final List<BankEmblemData> emblems;

  /// Rung every emblem in the group is drawn at. Ignored when [size] is set.
  final BankEmblemSize tier;

  /// Off-ladder diameter for the whole group. Prefer [tier].
  final double? size;

  /// Maximum number of identities drawn before the rest fold into the
  /// overflow disc.
  final int maxVisible;

  /// Fraction of a diameter each emblem is pulled back over the previous one,
  /// in the range `0..1`. Defaults to [defaultOverlap]; `0` gives a rail.
  final double overlap;

  /// Extra gap added between emblems, on top of whatever [overlap] leaves.
  /// Only meaningful when [overlap] is `0` or small.
  final double spacing;

  /// Ring applied to every emblem that does not carry its own.
  ///
  /// Defaults to the surface-coloured separator ring when [overlap] is
  /// greater than zero (discs need a cut line to stay legible when they
  /// touch) and to no ring at all when the group is a spaced rail.
  final BankEmblemRing? ring;

  /// Overrides the number shown in the overflow disc. Defaults to however
  /// many [emblems] did not fit within [maxVisible].
  final int? overflowCount;

  /// Template for the overflow label; `{n}` is substituted.
  final String overflowTemplate;

  /// Hue the overflow disc is tinted from. Defaults to
  /// [BankThemeData.onSurfaceVariant] — the overflow is a quantity, not an
  /// identity, so it stays neutral rather than borrowing a brand hue.
  final Color? overflowTintColor;

  /// Called when the overflow disc is tapped (typically opens the full list).
  final VoidCallback? onOverflowTap;

  /// Overrides the merged group semantics. Defaults to the visible
  /// identities' labels followed by the overflow label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final diameter = size ?? tier.diameter;

    final visibleCount =
        emblems.length < maxVisible ? emblems.length : maxVisible;
    final visible = emblems.take(visibleCount).toList();
    final hidden = overflowCount ?? emblems.length - visibleCount;
    final overflowLabel = overflowTemplate.replaceAll('{n}', '$hidden');
    final showOverflow = hidden > 0;

    final slots = visible.length + (showOverflow ? 1 : 0);
    if (slots == 0) return const SizedBox.shrink();

    final advance = diameter * (1 - overlap) + spacing;
    final groupRing = ring ?? (overlap > 0 ? const BankEmblemRing() : null);

    Widget at(int slot, Widget child) => PositionedDirectional(
          start: slot * advance,
          top: 0,
          width: diameter,
          height: diameter,
          child: child,
        );

    final children = <Widget>[
      // The overflow disc is painted first so the last identity overlaps it,
      // and the identities are painted back-to-front so the first one — the
      // one on the leading edge — ends up on top.
      if (showOverflow)
        at(
          visible.length,
          BankEmblem(
            label: overflowLabel,
            size: diameter,
            tintColor: overflowTintColor ?? theme.onSurfaceVariant,
            ring: groupRing,
            onTap: onOverflowTap,
            semanticLabel: overflowLabel,
          ),
        ),
      for (var i = visible.length - 1; i >= 0; i--)
        at(i, _emblemFor(visible[i], diameter, groupRing)),
    ];

    final labels = <String>[
      for (final item in visible)
        if (item.semanticLabel ?? item.initialsFrom ?? item.label
            case final String name)
          name,
      if (showOverflow) overflowLabel,
    ];

    // A group of decorative discs reads as noise, so it collapses to one
    // label — unless something in it is tappable, in which case the buttons
    // underneath have to stay reachable.
    final interactive =
        onOverflowTap != null || visible.any((item) => item.onTap != null);

    return Semantics(
      container: true,
      label: semanticLabel ?? labels.join(', '),
      excludeSemantics: !interactive,
      child: SizedBox(
        width: diameter + (slots - 1) * advance,
        height: diameter,
        child: Stack(children: children),
      ),
    );
  }

  Widget _emblemFor(
    BankEmblemData data,
    double diameter,
    BankEmblemRing? groupRing,
  ) {
    final Widget emblem = BankEmblem(
      imageUrl: data.imageUrl,
      imageProvider: data.imageProvider,
      initialsFrom: data.initialsFrom,
      icon: data.icon,
      label: data.label,
      size: diameter,
      tintColor: data.tintColor,
      backgroundColor: data.backgroundColor,
      foregroundColor: data.foregroundColor,
      badgeCount: data.badgeCount,
      badgeOverlay: data.badgeOverlay,
      ring: data.ring ?? groupRing,
      onTap: data.onTap,
      semanticLabel: data.semanticLabel,
    );
    final opacity = data.opacity;
    if (opacity == null) return emblem;
    return Opacity(opacity: opacity, child: emblem);
  }
}

/// The kit's one chip / badge anatomy.
///
/// Every inline chip and badge — an ownership role, a price change, a cycle
/// counter, an amount due — is the same object: a [minHeight]-tall pill of
/// one hue washed at [BankTokens.alphaSoft], inked in that same hue corrected
/// to WCAG AA, with an optional leading dot or glyph. Fixing the anatomy in
/// one place is what stopped four families of chip from each inventing their
/// own height, padding, radius, and ink.
///
/// It shares [BankEmblem]'s colour derivation, so a chip and the emblem beside
/// it tinted from the same hue land on the same fill and the same ink.
///
/// ```dart
/// BankTintChip(label: 'Primary', color: theme.primary, icon: Icons.star)
/// ```
class BankTintChip extends StatelessWidget {
  /// Creates a chip from a text [label].
  const BankTintChip({
    super.key,
    this.label,
    this.child,
    this.color,
    this.icon,
    this.showDot = false,
    this.backgroundColor,
    this.foregroundColor,
    this.surfaceColor,
    this.padding,
    this.radius,
    this.labelStyle,
    this.semanticLabel,
  }) : assert(
          label != null || child != null,
          'A BankTintChip needs either a label or a child.',
        );

  /// Minimum height of every chip in the kit.
  ///
  /// A minimum rather than a fixed height so the chip still grows under large
  /// text scales instead of clipping its own label.
  static const double minHeight = BankTokens.space6;

  /// Horizontal inset on both edges.
  static const double horizontalPadding = BankTokens.space2;

  /// Gap between the leading dot / glyph and the label.
  static const double leadingGap = BankTokens.space1;

  /// Diameter of the optional leading status dot.
  static const double dotSize = BankTokens.space2;

  /// Size of the optional leading glyph: the icon-ladder rung that sits
  /// inline with caption-sized text.
  static const double glyphSize = BankTokens.iconXSmall;

  /// Chip text. Ignored when [child] is given.
  final String? label;

  /// Arbitrary chip content, for chips carrying a formatted value (an amount,
  /// a masked number) rather than a plain string.
  final Widget? child;

  /// Hue the chip is derived from. Defaults to [BankThemeData.primary].
  final Color? color;

  /// Optional leading glyph.
  final IconData? icon;

  /// Whether to draw a leading status dot. Ignored when [icon] is set — a
  /// chip carries at most one leading mark.
  final bool showDot;

  /// Overrides the derived fill.
  final Color? backgroundColor;

  /// Overrides the derived ink, skipping the contrast correction.
  final Color? foregroundColor;

  /// Surface the chip is painted on, when it is not [BankThemeData.surface]
  /// (a chip on a tinted banner, say). Only affects the derived fill and ink.
  final Color? surfaceColor;

  /// Overrides the chip's inner padding.
  final EdgeInsetsGeometry? padding;

  /// Overrides the chip's corner radius. Defaults to
  /// [BankThemeData.chipRadius], so chip shape stays a brand decision.
  final BorderRadius? radius;

  /// Merged over the computed label style ([BankTokens.caption] in the
  /// resolved ink).
  final TextStyle? labelStyle;

  /// Overrides the chip's semantics. Defaults to [label].
  final String? semanticLabel;

  /// The ink [BankTintChip] would resolve for [color], for call sites that
  /// need to match it on a [child] they build themselves.
  static Color inkFor(
    BankThemeData theme,
    Color color, {
    Color? surface,
  }) =>
      BankEmblem.inkFor(theme, color, surface: surface);

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final seed = color ?? theme.primary;
    final fill = backgroundColor ??
        BankEmblem.fillFor(theme, seed, surface: surfaceColor);
    final ink = foregroundColor ??
        BankEmblem.inkFor(theme, seed, surface: surfaceColor);

    final resolvedStyle =
        BankTokens.caption.copyWith(color: ink).merge(labelStyle);

    final content = child ??
        Text(
          label!,
          style: resolvedStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

    return Semantics(
      label: semanticLabel ?? label,
      child: Container(
        constraints: const BoxConstraints(minHeight: minHeight),
        padding: padding ??
            const EdgeInsetsDirectional.symmetric(
              horizontal: horizontalPadding,
            ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: radius ?? theme.chipRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: glyphSize, color: ink),
              const SizedBox(width: leadingGap),
            ] else if (showDot) ...[
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
              ),
              const SizedBox(width: leadingGap),
            ],
            Flexible(child: content),
          ],
        ),
      ),
    );
  }
}

/// Danger-coloured unread / attention count bubble, capped at `99+`, ringed
/// with [BankThemeData.surface] so it separates cleanly from the emblem
/// content beneath it.
///
/// Unlike [BankTintChip] this is a solid-fill bubble: an alert count has to
/// survive being 16 px wide on top of a photograph, which a low-alpha wash
/// cannot do.
class _EmblemCountBadge extends StatelessWidget {
  const _EmblemCountBadge({
    required this.count,
    required this.theme,
    required this.side,
    this.color,
  });

  final int count;
  final BankThemeData theme;

  /// Bubble diameter, scaled to the emblem it sits on.
  final double side;

  /// Overrides [BankTokens.danger] as the bubble fill.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: BoxConstraints(minWidth: side, minHeight: side),
      padding: const EdgeInsets.symmetric(horizontal: BankTokens.space1),
      decoration: BoxDecoration(
        color: color ?? BankTokens.danger,
        borderRadius: const BorderRadius.all(
          Radius.circular(BankTokens.radiusFull),
        ),
        border: Border.all(
          color: theme.surface,
          width: BankTokens.hairlineWidth * 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: BankTokens.caption.copyWith(
          color: BankTokens.neutral0,
          fontSize: side * BankEmblem._badgeLabelRatio,
          height: BankTokens.lineHeightTight,
        ),
        maxLines: 1,
      ),
    );
  }
}
