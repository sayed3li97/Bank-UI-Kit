import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// One suggested prompt rendered as a tappable chip inside
/// [BankAssistantPanel].
@immutable
class BankAssistantPrompt {
  /// Creates an immutable suggested-prompt descriptor.
  const BankAssistantPrompt({
    required this.id,
    required this.label,
    this.icon,
  });

  /// Stable identifier passed back through `onPromptTap`.
  final String id;

  /// User-visible chip label, e.g. `'Spending this month'`.
  final String label;

  /// Optional leading glyph rendered before [label].
  final IconData? icon;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankAssistantPrompt &&
        other.id == id &&
        other.label == label &&
        other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(id, label, icon);

  @override
  String toString() => 'BankAssistantPrompt(id: $id, label: $label)';
}

/// Entry surface for an in-app banking assistant: a greeting with an
/// avatar, suggested prompt chips, a free-text ask field with an
/// optional voice button, recent queries, and an optional disclaimer.
///
/// Embed it in a bottom sheet or a dedicated screen as the front door
/// to an assistant experience (in the spirit of ila's Ask Fatema or
/// BofA's Erica). The panel is pure presentation: it performs no
/// networking and contains no AI logic, it only fires callbacks.
///
/// While the assistant is working, set [isThinking] to show a
/// three-dot pulsing indicator beside the avatar; the dots render
/// statically when the platform requests reduced motion.
///
/// ```dart
/// BankAssistantPanel(
///   assistantName: 'Aya',
///   prompts: const [
///     BankAssistantPrompt(id: 'spend', label: 'Spending this month'),
///     BankAssistantPrompt(id: 'freeze', label: 'Freeze my card'),
///     BankAssistantPrompt(id: 'bills', label: 'Upcoming bills'),
///     BankAssistantPrompt(id: 'rate', label: 'Best savings rate'),
///   ],
///   recentQueries: const [
///     'How much did I spend on dining?',
///     'Show my subscriptions',
///   ],
///   disclaimerText:
///       'Aya is an AI assistant. For urgent card issues call us.',
///   onPromptTap: (prompt) => openAssistant(prompt.label),
///   onSubmitted: openAssistant,
///   onMicTap: startVoiceInput,
/// )
/// ```
class BankAssistantPanel extends StatefulWidget {
  /// Creates an assistant entry panel.
  const BankAssistantPanel({
    required this.assistantName,
    super.key,
    this.greetingTemplate = 'Hi, I am {name}. How can I help?',
    this.avatar,
    this.prompts = const <BankAssistantPrompt>[],
    this.onPromptTap,
    this.inputHint = 'Ask anything about your money',
    this.onSubmitted,
    this.onMicTap,
    this.micSemanticLabel = 'Voice input',
    this.disclaimerText,
    this.recentQueries = const <String>[],
    this.recentTitle = 'Recent',
    this.onRecentTap,
    this.isThinking = false,
    this.header,
    this.footer,
    this.padding,
    this.radius,
    this.chipRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.accentColor,
    this.gradient,
    this.shadow,
    this.chipBackgroundColor,
    this.inputBackgroundColor,
    this.greetingStyle,
    this.chipLabelStyle,
    this.recentTitleStyle,
    this.recentQueryStyle,
    this.disclaimerStyle,
    this.avatarIcon,
    this.micIcon,
    this.recentIcon,
    this.avatarSize,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  });

  /// Display name of the assistant, e.g. `'Fatema'`. Substituted into
  /// [greetingTemplate] and used in the panel semantics label.
  final String assistantName;

  /// Greeting text; every `{name}` occurrence is replaced with
  /// [assistantName].
  final String greetingTemplate;

  /// Replaces the default avatar (a circle filled with the theme
  /// accent gradient, or primary colour, holding [avatarIcon]).
  final Widget? avatar;

  /// Suggested prompts rendered as tappable chips. Empty hides the
  /// section.
  final List<BankAssistantPrompt> prompts;

  /// Fired when a suggestion chip is tapped. Chips render but do not
  /// respond when null.
  final ValueChanged<BankAssistantPrompt>? onPromptTap;

  /// Placeholder shown in the free-text field.
  final String inputHint;

  /// Fired with the trimmed text when the user submits the field; the
  /// field is cleared afterwards.
  final ValueChanged<String>? onSubmitted;

  /// When set, a microphone button is shown inside the text field.
  final VoidCallback? onMicTap;

  /// Semantics label for the microphone button.
  final String micSemanticLabel;

  /// Optional quiet legal or safety line under the panel content,
  /// e.g. `'Fatema is an AI assistant. For urgent card issues call
  /// us.'`. Hidden when null.
  final String? disclaimerText;

  /// Previously asked queries rendered as quiet rows. Empty hides the
  /// section.
  final List<String> recentQueries;

  /// Heading above [recentQueries].
  final String recentTitle;

  /// Fired when a recent query row is tapped.
  final ValueChanged<String>? onRecentTap;

  /// Shows a three-dot pulsing indicator beside the avatar while the
  /// assistant is working. Dots render statically when animations are
  /// disabled.
  final bool isThinking;

  /// Slot rendered above the greeting row.
  final Widget? header;

  /// Slot rendered below all panel content.
  final Widget? footer;

  /// Overrides the panel content padding. Defaults to
  /// [BankTokens.space4] on all sides.
  final EdgeInsetsGeometry? padding;

  /// Overrides the panel corner radius. Defaults to
  /// [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Overrides the suggestion-chip radius. Defaults to
  /// [BankThemeData.chipRadius].
  final BorderRadius? chipRadius;

  /// Overrides the panel background. Defaults to
  /// [BankThemeData.surface].
  final Color? backgroundColor;

  /// Overrides the primary text colour. Defaults to
  /// [BankThemeData.onSurface].
  final Color? foregroundColor;

  /// Overrides the accent used for the avatar fill, chip icons, the
  /// mic button, and the thinking dots. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Overrides the default avatar gradient. Defaults to
  /// [BankThemeData.accentGradient]; when both are null the avatar is
  /// filled with the accent colour.
  final Gradient? gradient;

  /// Overrides the panel shadow. Defaults to [BankTokens.shadowCard];
  /// pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the suggestion-chip fill. Defaults to
  /// [BankThemeData.surfaceVariant].
  final Color? chipBackgroundColor;

  /// Overrides the text-field fill. Defaults to
  /// [BankThemeData.surfaceVariant].
  final Color? inputBackgroundColor;

  /// Merged over the greeting style ([BankTokens.headlineSmall]).
  final TextStyle? greetingStyle;

  /// Merged over the chip label style ([BankTokens.labelLarge]).
  final TextStyle? chipLabelStyle;

  /// Merged over the recent-section title style
  /// ([BankTokens.labelMedium]).
  final TextStyle? recentTitleStyle;

  /// Merged over the recent-query row style ([BankTokens.bodyMedium]).
  final TextStyle? recentQueryStyle;

  /// Merged over the disclaimer style ([BankTokens.bodySmall]).
  final TextStyle? disclaimerStyle;

  /// Glyph inside the default avatar. Defaults to a sparkle
  /// ([Icons.auto_awesome]). Ignored when [avatar] is set.
  final IconData? avatarIcon;

  /// Glyph on the microphone button. Defaults to
  /// [Icons.mic_none_outlined].
  final IconData? micIcon;

  /// Glyph leading each recent-query row. Defaults to
  /// [Icons.history].
  final IconData? recentIcon;

  /// Diameter of the default avatar. Defaults to 48. Ignored when
  /// [avatar] is set.
  final double? avatarSize;

  /// One pulse cycle of the thinking dots. Defaults to
  /// [BankTokens.durationXSlow].
  final Duration? animationDuration;

  /// Easing applied to the thinking-dot pulse. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// Overrides the panel container semantics label. Defaults to
  /// `'<assistantName> assistant'`.
  final String? semanticLabel;

  @override
  State<BankAssistantPanel> createState() => _BankAssistantPanelState();
}

class _BankAssistantPanelState extends State<BankAssistantPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late CurvedAnimation _curvedPulse;
  final TextEditingController _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? BankTokens.durationXSlow,
    );
    _curvedPulse = CurvedAnimation(
      parent: _pulse,
      curve: widget.animationCurve ?? BankTokens.curveStandard,
    );
  }

  @override
  void didUpdateWidget(BankAssistantPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pulse.duration = widget.animationDuration ?? BankTokens.durationXSlow;
    if (widget.animationCurve != oldWidget.animationCurve) {
      _curvedPulse.dispose();
      _curvedPulse = CurvedAnimation(
        parent: _pulse,
        curve: widget.animationCurve ?? BankTokens.curveStandard,
      );
    }
    _syncPulse();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void dispose() {
    _curvedPulse.dispose();
    _pulse.dispose();
    _input.dispose();
    super.dispose();
  }

  bool get _animationsDisabled =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  void _syncPulse() {
    final shouldAnimate = widget.isThinking && !_animationsDisabled;
    if (shouldAnimate) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else if (_pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  void _submit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    widget.onSubmitted?.call(text);
    _input.clear();
  }

  Widget _defaultAvatar(BankThemeData theme, Color accent) {
    final size = widget.avatarSize ?? 48;
    final avatarGradient = widget.gradient ?? theme.accentGradient;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: avatarGradient,
          color: avatarGradient == null ? accent : null,
        ),
        child: Center(
          child: Icon(
            widget.avatarIcon ?? Icons.auto_awesome,
            size: size * 0.5,
            color: theme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _promptChip(
    BankAssistantPrompt prompt,
    BankThemeData theme,
    Color accent,
    Color foreground,
  ) {
    final resolvedChipRadius = widget.chipRadius ?? theme.chipRadius;
    final chipFill = widget.chipBackgroundColor ?? theme.surfaceVariant;
    final labelStyle = BankTokens.labelLarge
        .copyWith(color: foreground)
        .merge(widget.chipLabelStyle);
    final onTap = widget.onPromptTap;
    return Semantics(
      button: true,
      label: prompt.label,
      child: Material(
        color: chipFill,
        borderRadius: resolvedChipRadius,
        child: InkWell(
          onTap: onTap == null ? null : () => onTap(prompt),
          borderRadius: resolvedChipRadius,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: BankTokens.minTapTarget,
            ),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: BankTokens.space3,
            ),
            alignment: AlignmentDirectional.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prompt.icon != null) ...[
                  Icon(prompt.icon, size: 18, color: accent),
                  const SizedBox(width: BankTokens.space2),
                ],
                Text(prompt.label, style: labelStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recentRow(String query, BankThemeData theme) {
    final rowStyle = BankTokens.bodyMedium
        .copyWith(color: theme.onSurfaceVariant)
        .merge(widget.recentQueryStyle);
    final onTap = widget.onRecentTap;
    return Semantics(
      button: true,
      label: query,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap(query),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: BankTokens.minTapTarget,
          ),
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            children: [
              Icon(
                widget.recentIcon ?? Icons.history,
                size: 16,
                color: theme.onSurfaceVariant,
              ),
              const SizedBox(width: BankTokens.space2),
              Expanded(
                child: Text(
                  query,
                  style: rowStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputRow(BankThemeData theme, Color accent, Color foreground) {
    return TextField(
      controller: _input,
      onSubmitted: _submit,
      textInputAction: TextInputAction.send,
      style: BankTokens.bodyLarge.copyWith(color: foreground),
      decoration: InputDecoration(
        hintText: widget.inputHint,
        hintStyle: BankTokens.bodyLarge.copyWith(color: theme.onSurfaceVariant),
        filled: true,
        fillColor: widget.inputBackgroundColor ?? theme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: theme.buttonRadius,
          borderSide: BorderSide.none,
        ),
        suffixIcon: widget.onMicTap == null
            ? null
            : Semantics(
                button: true,
                label: widget.micSemanticLabel,
                child: IconButton(
                  onPressed: widget.onMicTap,
                  iconSize: 22,
                  constraints: const BoxConstraints(
                    minWidth: BankTokens.minTapTarget,
                    minHeight: BankTokens.minTapTarget,
                  ),
                  icon: Icon(
                    widget.micIcon ?? Icons.mic_none_outlined,
                    color: accent,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final accent = widget.accentColor ?? theme.primary;
    final foreground = widget.foregroundColor ?? theme.onSurface;
    final resolvedPadding =
        widget.padding ?? const EdgeInsetsDirectional.all(BankTokens.space4);
    final resolvedRadius = widget.radius ?? theme.cardRadius;
    final resolvedShadow = widget.shadow ?? BankTokens.shadowCard;
    final greeting =
        widget.greetingTemplate.replaceAll('{name}', widget.assistantName);
    final greetingTextStyle = BankTokens.headlineSmall
        .copyWith(color: foreground)
        .merge(widget.greetingStyle);

    return Semantics(
      container: true,
      label: widget.semanticLabel ?? '${widget.assistantName} assistant',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? theme.surface,
          borderRadius: resolvedRadius,
          boxShadow: resolvedShadow,
        ),
        child: Padding(
          padding: resolvedPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.header != null) ...[
                widget.header!,
                const SizedBox(height: BankTokens.space4),
              ],
              Row(
                children: [
                  widget.avatar ?? _defaultAvatar(theme, accent),
                  if (widget.isThinking)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: BankTokens.space2,
                      ),
                      child: ExcludeSemantics(
                        child: _ThinkingDots(
                          color: accent,
                          animation: _animationsDisabled ? null : _curvedPulse,
                        ),
                      ),
                    ),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Text(greeting, style: greetingTextStyle),
                  ),
                ],
              ),
              if (widget.prompts.isNotEmpty) ...[
                const SizedBox(height: BankTokens.space4),
                Wrap(
                  spacing: BankTokens.space2,
                  runSpacing: BankTokens.space2,
                  children: [
                    for (final prompt in widget.prompts)
                      _promptChip(prompt, theme, accent, foreground),
                  ],
                ),
              ],
              const SizedBox(height: BankTokens.space4),
              _inputRow(theme, accent, foreground),
              if (widget.recentQueries.isNotEmpty) ...[
                const SizedBox(height: BankTokens.space4),
                Text(
                  widget.recentTitle,
                  style: BankTokens.labelMedium
                      .copyWith(color: theme.onSurfaceVariant)
                      .merge(widget.recentTitleStyle),
                ),
                const SizedBox(height: BankTokens.space1),
                for (final query in widget.recentQueries)
                  _recentRow(query, theme),
              ],
              if (widget.disclaimerText != null) ...[
                const SizedBox(height: BankTokens.space3),
                Text(
                  widget.disclaimerText!,
                  style: BankTokens.bodySmall
                      .copyWith(color: theme.onSurfaceVariant)
                      .merge(widget.disclaimerStyle),
                ),
              ],
              if (widget.footer != null) ...[
                const SizedBox(height: BankTokens.space4),
                widget.footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Three pulsing dots shown while the assistant is thinking.
///
/// Pass a null [animation] to render the dots statically (reduced
/// motion).
class _ThinkingDots extends StatelessWidget {
  const _ThinkingDots({
    required this.color,
    this.animation,
  });

  final Color color;
  final Animation<double>? animation;

  static const double _dotSize = 6;

  Widget _dot(double opacity) => SizedBox(
        width: _dotSize,
        height: _dotSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      );

  Widget _row(List<double> opacities) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(opacities[0]),
          const SizedBox(width: BankTokens.space1),
          _dot(opacities[1]),
          const SizedBox(width: BankTokens.space1),
          _dot(opacities[2]),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final pulse = animation;
    if (pulse == null) return _row(const [0.35, 0.6, 1]);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        double opacityAt(int index) {
          final phase = (pulse.value + index / 3) % 1;
          final wave = 0.5 + 0.5 * math.sin(phase * 2 * math.pi);
          return 0.25 + 0.75 * wave;
        }

        return _row([opacityAt(0), opacityAt(1), opacityAt(2)]);
      },
    );
  }
}
