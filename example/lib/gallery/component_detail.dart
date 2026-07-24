import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'component_registry.dart';

// ---------------------------------------------------------------------------
// ComponentDetailPage
// ---------------------------------------------------------------------------

/// Interactive detail page for a single [GalleryEntry].
///
/// On wide screens (>700 dp) shows a side-by-side split:
///   - Left: live preview panel with light/dark background toggle.
///   - Right: scrollable params panel + code snippet.
///
/// On narrow screens all sections stack vertically inside a [CustomScrollView].
class ComponentDetailPage extends StatefulWidget {
  const ComponentDetailPage({required this.entry, super.key});

  final GalleryEntry entry;

  @override
  State<ComponentDetailPage> createState() => _ComponentDetailPageState();
}

class _ComponentDetailPageState extends State<ComponentDetailPage> {
  late Map<String, dynamic> _params;
  bool _darkPreview = false;

  @override
  void initState() {
    super.initState();
    _params = {
      for (final p in widget.entry.params) p.name: p.defaultValue,
    };
  }

  void _update(String key, dynamic value) =>
      setState(() => _params[key] = value);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colorScheme.outlineVariant),
        ),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 700;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left: preview ──────────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: _PreviewPanel(
                    entry: widget.entry,
                    params: _params,
                    isDark: _darkPreview,
                    onToggleDark: (v) => setState(() => _darkPreview = v),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: colorScheme.outlineVariant,
                ),
                // ── Right: controls + code ─────────────────────────────────
                Expanded(
                  flex: 2,
                  child: _ControlsPanel(
                    entry: widget.entry,
                    params: _params,
                    onUpdate: _update,
                    includeCodeSnippet: true,
                  ),
                ),
              ],
            );
          }

          // Narrow: vertical scroll
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _PreviewPanel(
                  entry: widget.entry,
                  params: _params,
                  isDark: _darkPreview,
                  onToggleDark: (v) => setState(() => _darkPreview = v),
                  fixedHeight: 300,
                ),
              ),
              SliverToBoxAdapter(
                child: Divider(height: 1, color: colorScheme.outlineVariant),
              ),
              SliverToBoxAdapter(
                child: _ControlsPanel(
                  entry: widget.entry,
                  params: _params,
                  onUpdate: _update,
                  includeCodeSnippet: true,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview panel
// ---------------------------------------------------------------------------

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.entry,
    required this.params,
    required this.isDark,
    required this.onToggleDark,
    this.fixedHeight,
  });

  final GalleryEntry entry;
  final Map<String, dynamic> params;
  final bool isDark;
  final ValueChanged<bool> onToggleDark;

  /// If non-null the panel constrains itself to this height (narrow layout).
  final double? fixedHeight;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);

    Widget preview;
    try {
      preview = entry.builder(context, params);
    } catch (e, st) {
      preview = _PreviewError(error: e, stackTrace: st);
    }

    final header = Row(
      children: [
        Text(
          'PREVIEW',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
        ),
        const Spacer(),
        Tooltip(
          message: isDark
              ? 'Switch to light background'
              : 'Switch to dark background',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.light_mode_outlined,
                size: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              Switch(
                value: isDark,
                onChanged: onToggleDark,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Icon(
                Icons.dark_mode_outlined,
                size: 14,
                color: isDark ? Colors.white70 : Colors.black38,
              ),
            ],
          ),
        ),
      ],
    );

    final previewContent = entry.isFullScreen
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: preview,
          )
        : preview;

    if (fixedHeight != null) {
      return Container(
        height: fixedHeight,
        color: bgColor,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: previewContent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: previewContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview error widget
// ---------------------------------------------------------------------------

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            'Preview error',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Controls panel
// ---------------------------------------------------------------------------

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.entry,
    required this.params,
    required this.onUpdate,
    this.includeCodeSnippet = false,
  });

  final GalleryEntry entry;
  final Map<String, dynamic> params;
  final void Function(String key, dynamic value) onUpdate;
  final bool includeCodeSnippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        // ── Component description ──────────────────────────────────────────
        Text(
          entry.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        // ── Parameters section ─────────────────────────────────────────────
        if (entry.params.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'PARAMETERS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...entry.params.map(
            (p) => _ParamControl(
              param: p,
              value: params[p.name] ?? p.defaultValue,
              onChanged: (v) => onUpdate(p.name, v),
            ),
          ),
        ],

        // ── Code snippet ───────────────────────────────────────────────────
        if (includeCodeSnippet && entry.codeExample != null) ...[
          const SizedBox(height: 4),
          _CodeSnippet(code: entry.codeExample!),
        ],

        const SizedBox(height: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual param control row
// ---------------------------------------------------------------------------

class _ParamControl extends StatelessWidget {
  const _ParamControl({
    required this.param,
    required this.value,
    required this.onChanged,
  });

  final GalleryParam param;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    Widget control;

    switch (param.type) {
      // ── Bool ──────────────────────────────────────────────────────────────
      case ParamType.boolType:
        control = Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(param.label, style: labelStyle),
                        ),
                        const SizedBox(width: 6),
                        _TypeBadge(label: 'bool'),
                        if (param.isRequired) ...[
                          const SizedBox(width: 4),
                          _RequiredBadge(),
                        ],
                      ],
                    ),
                    _DefaultValueLabel(defaultValue: param.defaultValue),
                  ],
                ),
              ),
              Switch(
                value: (value as bool?) ?? false,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        );

      // ── String ────────────────────────────────────────────────────────────
      case ParamType.stringType:
        control = Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(param.label, style: labelStyle)),
                  const SizedBox(width: 6),
                  _TypeBadge(label: 'String'),
                  if (param.isRequired) ...[
                    const SizedBox(width: 4),
                    _RequiredBadge(),
                  ],
                ],
              ),
              _DefaultValueLabel(defaultValue: param.defaultValue),
              const SizedBox(height: 6),
              _DebouncedTextField(
                initialValue: value as String? ?? '',
                hint: param.description,
                onChanged: onChanged,
              ),
            ],
          ),
        );

      // ── Double ────────────────────────────────────────────────────────────
      case ParamType.doubleType:
        final min = param.min ?? 0.0;
        final max = param.max ?? 100.0;
        final current = ((value as double?) ?? min).clamp(min, max);
        final displayVal = current.abs() < 10
            ? current.toStringAsFixed(2)
            : current
                .toStringAsFixed(current.truncateToDouble() == current ? 0 : 1);
        control = Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(param.label, style: labelStyle)),
                  const SizedBox(width: 6),
                  _TypeBadge(label: 'double'),
                  if (param.isRequired) ...[
                    const SizedBox(width: 4),
                    _RequiredBadge(),
                  ],
                  const Spacer(),
                  Text(
                    displayVal,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              _DefaultValueLabel(defaultValue: param.defaultValue),
              Slider(
                value: current,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ],
          ),
        );

      // ── Int ───────────────────────────────────────────────────────────────
      case ParamType.intType:
        final min = (param.min ?? 0).toInt();
        final max = (param.max ?? 10).toInt();
        final current = ((value as int?) ?? min).clamp(min, max);
        control = Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(param.label, style: labelStyle)),
                  const SizedBox(width: 6),
                  _TypeBadge(label: 'int'),
                  if (param.isRequired) ...[
                    const SizedBox(width: 4),
                    _RequiredBadge(),
                  ],
                  const Spacer(),
                  Text(
                    '$current',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              _DefaultValueLabel(defaultValue: param.defaultValue),
              Slider(
                value: current.toDouble().clamp(min.toDouble(), max.toDouble()),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min).clamp(1, 1000),
                onChanged: (v) => onChanged(v.round()),
              ),
            ],
          ),
        );

      // ── Enum ──────────────────────────────────────────────────────────────
      case ParamType.enumType:
        final options = param.enumValues ?? const <String>[];
        control = Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(param.label, style: labelStyle)),
                  const SizedBox(width: 6),
                  _TypeBadge(label: 'enum'),
                  if (param.isRequired) ...[
                    const SizedBox(width: 4),
                    _RequiredBadge(),
                  ],
                ],
              ),
              _DefaultValueLabel(defaultValue: param.defaultValue),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: options.map((opt) {
                  final isSelected = (value as String?) == opt;
                  return Tooltip(
                    // Keep the raw API value discoverable for developers.
                    message: opt,
                    child: FilterChip(
                      label: Text(
                        _humanizeEnumValue(opt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => onChanged(opt),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );

      // ── Color ─────────────────────────────────────────────────────────────
      case ParamType.colorType:
        const colors = <Color>[
          Colors.transparent,
          Color(0xFF1A237E),
          Color(0xFF7C3AED),
          Color(0xFF0052CC),
          Color(0xFF00695C),
          Color(0xFFC62828),
          Color(0xFFFF6F00),
          Color(0xFF1B5E20),
        ];
        control = Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(param.label, style: labelStyle)),
                  const SizedBox(width: 6),
                  _TypeBadge(label: 'Color'),
                  if (param.isRequired) ...[
                    const SizedBox(width: 4),
                    _RequiredBadge(),
                  ],
                ],
              ),
              _DefaultValueLabel(defaultValue: param.defaultValue),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colors.map((c) {
                  final isSelected = value == c;
                  return GestureDetector(
                    onTap: () => onChanged(c),
                    child: Tooltip(
                      message: c == Colors.transparent
                          ? 'Transparent'
                          : '#${_colorHex(c)}',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c == Colors.transparent ? null : c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withAlpha(60),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: c == Colors.transparent
                            ? Icon(
                                Icons.close,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        control,
        Divider(
          height: 16,
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Default value label
// ---------------------------------------------------------------------------

class _DefaultValueLabel extends StatelessWidget {
  const _DefaultValueLabel({required this.defaultValue});

  final dynamic defaultValue;

  @override
  Widget build(BuildContext context) {
    final label = switch (defaultValue) {
      final String s => '"$s"',
      final bool b => b ? 'true' : 'false',
      final double d => d.toString(),
      final int i => i.toString(),
      _ => defaultValue?.toString() ?? 'null',
    };

    return Text(
      'Default: $label',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(160),
            fontFamily: 'monospace',
            fontSize: 10,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Type badge
// ---------------------------------------------------------------------------

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withAlpha(22),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: primary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Required badge
// ---------------------------------------------------------------------------

class _RequiredBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(22),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'required',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.red,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debounced text field
// ---------------------------------------------------------------------------

class _DebouncedTextField extends StatefulWidget {
  const _DebouncedTextField({
    required this.initialValue,
    required this.onChanged,
    this.hint,
  });

  final String initialValue;
  final String? hint;
  final ValueChanged<String> onChanged;

  @override
  State<_DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<_DebouncedTextField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  static const _kDelay = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_DebouncedTextField old) {
    super.didUpdateWidget(old);
    // Sync only when the external value differs from what we have, so that
    // mid-typing we don't clobber the cursor position.
    if (old.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_kDelay, () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        hintText: widget.hint,
      ),
      onChanged: _onChanged,
    );
  }
}

// ---------------------------------------------------------------------------
// Enum label helpers
// ---------------------------------------------------------------------------

/// Turns a camelCase enum value into readable copy for chip labels:
/// 'balanceLeft' → 'Balance left', 'tapToFlip' → 'Tap to flip'.
String _humanizeEnumValue(String name) {
  final buffer = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final ch = name[i];
    final isUpper = ch.toUpperCase() == ch && ch.toLowerCase() != ch;
    if (i == 0) {
      buffer.write(ch.toUpperCase());
    } else if (isUpper) {
      buffer
        ..write(' ')
        ..write(ch.toLowerCase());
    } else {
      buffer.write(ch);
    }
  }
  return buffer.toString();
}

// ---------------------------------------------------------------------------
// Color helpers
// ---------------------------------------------------------------------------

/// Returns a 6-character uppercase hex string (RRGGBB) for [color].
String _colorHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '$r$g$b'.toUpperCase();
}

// ---------------------------------------------------------------------------
// Code snippet
// ---------------------------------------------------------------------------

class _CodeSnippet extends StatefulWidget {
  const _CodeSnippet({required this.code});

  final String code;

  @override
  State<_CodeSnippet> createState() => _CodeSnippetState();
}

class _CodeSnippetState extends State<_CodeSnippet> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'USAGE',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _copied
                    ? Row(
                        key: const ValueKey('copied'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Copied',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : IconButton(
                        key: const ValueKey('copy'),
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        tooltip: 'Copy to clipboard',
                        onPressed: _copy,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withAlpha(15),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                widget.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: Color(0xFFCDD6F4),
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
