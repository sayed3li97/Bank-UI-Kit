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

  const BankPhysicalCardMaterialPicker({
    required this.options,
    required this.onSelected,
    super.key,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: _CardOptionTile._totalHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: BankTokens.space3),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.id == selectedId;
          return _CardOptionTile(
            option: option,
            isSelected: isSelected,
            bankTheme: bankTheme,
            onTap: () => onSelected(option),
          );
        },
      ),
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
  static const double _totalHeight =
      _previewHeight + BankTokens.space2 + _labelHeight;

  final BankCardDesignOption option;
  final bool isSelected;
  final BankThemeData bankTheme;
  final VoidCallback onTap;

  const _CardOptionTile({
    required this.option,
    required this.isSelected,
    required this.bankTheme,
    required this.onTap,
  });

  // ---------------------------------------------------------------------------
  // Badge colour per material
  // ---------------------------------------------------------------------------

  Color get _badgeBackground => option.material == BankCardMaterial.metal
      ? const Color(0xFF8E8E93) // neutral grey for metal
      : const Color(0xFF6C63FF); // indigo for plastic

  // ---------------------------------------------------------------------------
  // Card preview
  // ---------------------------------------------------------------------------

  Widget _buildCardPreview() {
    Widget preview;

    if (option.previewImageUrl != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Image.network(
          option.previewImageUrl!,
          width: _previewWidth,
          height: _previewHeight,
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
        width: _previewWidth,
        height: _previewHeight,
        borderRadius: _cardRadius,
        child: preview,
      );
    }

    // Selection ring.
    if (isSelected) {
      preview = Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(_cardRadius + _selectionBorderWidth),
          border: Border.all(
            color: bankTheme.primary,
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
      width: _previewWidth,
      height: _previewHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cardRadius),
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
        option.material == BankCardMaterial.metal ? 'METAL' : 'PLASTIC',
        style: BankTokens.labelSmall.copyWith(
          color: Colors.white,
          fontSize: 8,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final semanticLabel = '${option.label}, ${option.material.name} card'
        '${isSelected ? ', selected' : ''}';

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
            _buildCardPreview(),

            const SizedBox(height: BankTokens.space2),

            // ── Badge ────────────────────────────────────────────────────────
            _buildBadge(),

            const SizedBox(height: 4),

            // ── Label ────────────────────────────────────────────────────────
            SizedBox(
              width: _previewWidth + _selectionBorderWidth * 2,
              child: Text(
                option.label,
                style: BankTokens.bodySmall.copyWith(
                  color: isSelected
                      ? bankTheme.primary
                      : bankTheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
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
  final double width;
  final double height;
  final double borderRadius;
  final Widget child;

  const _MetalShimmerOverlay({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment(-1.2, -1.2),
        end: Alignment.center,
        colors: [
          Colors.transparent,
          Color(0x55FFFFFF),
          Colors.transparent,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: child,
    );
  }
}
