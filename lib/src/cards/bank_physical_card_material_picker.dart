import 'package:flutter/material.dart';

import '../../bank_ui_kit.dart';
import '../../core.dart';

// ---------------------------------------------------------------------------
// Enums & Data Models
// ---------------------------------------------------------------------------

enum BankCardMaterial { plastic, metal }

/// Describes a single card-design option shown in the material picker.
class BankCardDesignOption {
  final String id;
  final String label;
  final BankCardMaterial material;
  final Color primaryColor;
  final Color? secondaryColor;

  /// Optional URL for a richer card preview image.
  /// Rendered with [Image.network] when non-null.
  final String? previewImageUrl;

  const BankCardDesignOption({
    required this.id,
    required this.label,
    required this.material,
    required this.primaryColor,
    this.secondaryColor,
    this.previewImageUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankCardDesignOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// BankPhysicalCardMaterialPicker
// ---------------------------------------------------------------------------

/// Horizontal card-design picker for the order-a-card flow.
///
/// Displays each [BankCardDesignOption] as a mini card preview (80 × 50 px)
/// with a material badge and a label below. The currently selected option is
/// ringed in [BankThemeData.primary]. Metal options show a diagonal shimmer
/// band using [ShaderMask].
///
/// Accessibility: each card option is wrapped in a [Semantics] node that
/// describes the design name, material, and selected state.
class BankPhysicalCardMaterialPicker extends StatelessWidget {
  final List<BankCardDesignOption> options;
  final String? selectedId;
  final ValueChanged<BankCardDesignOption> onSelected;

  /// Overrides the list's outer padding. Defaults to
  /// [BankTokens.space4] horizontally.
  final EdgeInsetsGeometry? padding;

  /// Overrides the gap between options. Defaults to [BankTokens.space3].
  final double? itemSpacing;

  /// Overrides the mini card preview width. Defaults to 80.
  final double? previewWidth;

  /// Overrides the mini card preview height. Defaults to 50.
  final double? previewHeight;

  /// Overrides the preview corner radius. Defaults to 6.
  final double? previewRadius;

  /// Overrides the selection ring and selected label color. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Overrides the metal badge background. Defaults to the neutral grey
  /// `Color(0xFF8E8E93)`.
  final Color? metalBadgeColor;

  /// Overrides the plastic badge background. Defaults to the indigo
  /// `Color(0xFF6C63FF)`.
  final Color? plasticBadgeColor;

  /// Badge text for metal options. Defaults to 'METAL'.
  final String metalBadgeLabel;

  /// Badge text for plastic options. Defaults to 'PLASTIC'.
  final String plasticBadgeLabel;

  /// Merged over the badge text style ([BankTokens.labelSmall] in white
  /// at 8 px), so partial overrides work.
  final TextStyle? badgeStyle;

  /// Merged over the option label style ([BankTokens.bodySmall] in the
  /// selection-dependent color and weight).
  final TextStyle? labelStyle;

  /// Overrides the static metal shimmer gradient. Defaults to the kit's
  /// diagonal white highlight band.
  final Gradient? shimmerGradient;

  /// Template for each option's semantics label; `{label}` and
  /// `{material}` are replaced. Defaults to '{label}, {material} card'.
  final String optionSemanticTemplate;

  /// Suffix appended to the selected option's semantics label. Defaults
  /// to 'selected'.
  final String selectedSemanticLabel;

  /// Semantics label wrapping the whole picker. Defaults to none.
  final String? semanticLabel;

  const BankPhysicalCardMaterialPicker({
    required this.options,
    required this.onSelected,
    super.key,
    this.selectedId,
    this.padding,
    this.itemSpacing,
    this.previewWidth,
    this.previewHeight,
    this.previewRadius,
    this.accentColor,
    this.metalBadgeColor,
    this.plasticBadgeColor,
    this.metalBadgeLabel = 'METAL',
    this.plasticBadgeLabel = 'PLASTIC',
    this.badgeStyle,
    this.labelStyle,
    this.shimmerGradient,
    this.optionSemanticTemplate = '{label}, {material} card',
    this.selectedSemanticLabel = 'selected',
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final resolvedPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: BankTokens.space4);
    final resolvedSpacing = itemSpacing ?? BankTokens.space3;
    final resolvedPreviewWidth = previewWidth ?? _CardOptionTile._previewWidth;
    final resolvedPreviewHeight =
        previewHeight ?? _CardOptionTile._previewHeight;
    final resolvedPreviewRadius = previewRadius ?? _CardOptionTile._cardRadius;
    final resolvedAccentColor = accentColor ?? bankTheme.primary;
    final resolvedMetalBadgeColor = metalBadgeColor ?? const Color(0xFF8E8E93);
    final resolvedPlasticBadgeColor =
        plasticBadgeColor ?? const Color(0xFF6C63FF);
    final resolvedShimmerGradient =
        shimmerGradient ?? _MetalShimmerOverlay.defaultGradient;
    final totalHeight = resolvedPreviewHeight +
        BankTokens.space2 +
        _CardOptionTile._labelHeight;

    final list = SizedBox(
      height: totalHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: resolvedPadding,
        itemCount: options.length,
        separatorBuilder: (_, __) => SizedBox(width: resolvedSpacing),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.id == selectedId;
          return _CardOptionTile(
            option: option,
            isSelected: isSelected,
            bankTheme: bankTheme,
            onTap: () => onSelected(option),
            previewWidth: resolvedPreviewWidth,
            previewHeight: resolvedPreviewHeight,
            cardRadius: resolvedPreviewRadius,
            accentColor: resolvedAccentColor,
            metalBadgeColor: resolvedMetalBadgeColor,
            plasticBadgeColor: resolvedPlasticBadgeColor,
            metalBadgeLabel: metalBadgeLabel,
            plasticBadgeLabel: plasticBadgeLabel,
            shimmerGradient: resolvedShimmerGradient,
            optionSemanticTemplate: optionSemanticTemplate,
            selectedSemanticLabel: selectedSemanticLabel,
            badgeStyle: badgeStyle,
            labelStyle: labelStyle,
          );
        },
      ),
    );

    if (semanticLabel == null) return list;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: list,
    );
  }
}

// ---------------------------------------------------------------------------
// _CardOptionTile
// ---------------------------------------------------------------------------

class _CardOptionTile extends StatelessWidget {
  static const double _previewWidth = 80;
  static const double _previewHeight = 50;
  static const double _cardRadius = 6;
  static const double _selectionBorderWidth = 2;
  static const double _labelHeight = 36;

  final BankCardDesignOption option;
  final bool isSelected;
  final BankThemeData bankTheme;
  final VoidCallback onTap;
  final double previewWidth;
  final double previewHeight;
  final double cardRadius;
  final Color accentColor;
  final Color metalBadgeColor;
  final Color plasticBadgeColor;
  final String metalBadgeLabel;
  final String plasticBadgeLabel;
  final Gradient shimmerGradient;
  final String optionSemanticTemplate;
  final String selectedSemanticLabel;
  final TextStyle? badgeStyle;
  final TextStyle? labelStyle;

  const _CardOptionTile({
    required this.option,
    required this.isSelected,
    required this.bankTheme,
    required this.onTap,
    required this.previewWidth,
    required this.previewHeight,
    required this.cardRadius,
    required this.accentColor,
    required this.metalBadgeColor,
    required this.plasticBadgeColor,
    required this.metalBadgeLabel,
    required this.plasticBadgeLabel,
    required this.shimmerGradient,
    required this.optionSemanticTemplate,
    required this.selectedSemanticLabel,
    this.badgeStyle,
    this.labelStyle,
  });

  // ---------------------------------------------------------------------------
  // Badge colour per material
  // ---------------------------------------------------------------------------

  Color get _badgeBackground => option.material == BankCardMaterial.metal
      ? metalBadgeColor // neutral grey for metal by default
      : plasticBadgeColor; // indigo for plastic by default

  // ---------------------------------------------------------------------------
  // Card preview
  // ---------------------------------------------------------------------------

  Widget _buildCardPreview(BuildContext context) {
    Widget preview;

    if (option.previewImageUrl != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Image(
          image: BankUiScope.imageProviderFor(
            context,
            option.previewImageUrl!,
          ),
          width: previewWidth,
          height: previewHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildColorPreview(),
        ),
      );
    } else {
      preview = _buildColorPreview();
    }

    // Apply shimmer for metal cards.
    if (option.material == BankCardMaterial.metal) {
      preview = _MetalShimmerOverlay(
        width: previewWidth,
        height: previewHeight,
        borderRadius: cardRadius,
        gradient: shimmerGradient,
        child: preview,
      );
    }

    // Selection ring.
    if (isSelected) {
      preview = Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(cardRadius + _selectionBorderWidth),
          border: Border.all(
            color: accentColor,
            width: _selectionBorderWidth,
          ),
        ),
        padding: const EdgeInsets.all(_selectionBorderWidth),
        child: preview,
      );
    }

    return preview;
  }

  Widget _buildColorPreview() {
    return Container(
      width: previewWidth,
      height: previewHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        gradient: option.secondaryColor != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [option.primaryColor, option.secondaryColor!],
              )
            : null,
        color: option.secondaryColor == null ? option.primaryColor : null,
      ),
      // Minimal card content: chip rectangle
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: Container(
            width: 18,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Material badge
  // ---------------------------------------------------------------------------

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space1 + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _badgeBackground,
        borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
      ),
      child: Text(
        option.material == BankCardMaterial.metal
            ? metalBadgeLabel
            : plasticBadgeLabel,
        style: BankTokens.labelSmall
            .copyWith(
              color: Colors.white,
              fontSize: 8,
              letterSpacing: 0.8,
            )
            .merge(badgeStyle),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    var semanticLabel = optionSemanticTemplate
        .replaceAll('{label}', option.label)
        .replaceAll('{material}', option.material.name);
    if (isSelected) {
      semanticLabel = '$semanticLabel, $selectedSemanticLabel';
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Preview ──────────────────────────────────────────────────────
            _buildCardPreview(context),

            const SizedBox(height: BankTokens.space2),

            // ── Badge ────────────────────────────────────────────────────────
            _buildBadge(),

            const SizedBox(height: 4),

            // ── Label ────────────────────────────────────────────────────────
            SizedBox(
              width: previewWidth + _selectionBorderWidth * 2,
              child: Text(
                option.label,
                style: BankTokens.bodySmall
                    .copyWith(
                      color:
                          isSelected ? accentColor : bankTheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    )
                    .merge(labelStyle),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MetalShimmerOverlay
// ---------------------------------------------------------------------------

/// Applies a static diagonal highlight band to simulate a metallic surface.
///
/// The shimmer is a fixed [ShaderMask] (not animated) on the picker preview;
/// for the animated variant see [BankCardSurface.metallicSweep] in
/// [BankVirtualCardWidget].
class _MetalShimmerOverlay extends StatelessWidget {
  /// Default diagonal white highlight band painted over metal previews.
  static const Gradient defaultGradient = LinearGradient(
    begin: Alignment(-1.2, -1.2),
    end: Alignment.center,
    colors: [
      Colors.transparent,
      Color(0x55FFFFFF),
      Colors.transparent,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  final double width;
  final double height;
  final double borderRadius;
  final Gradient gradient;
  final Widget child;

  const _MetalShimmerOverlay({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.gradient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: gradient.createShader,
      child: child,
    );
  }
}
