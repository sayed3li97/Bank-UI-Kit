import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'component_registry.dart';

// ---------------------------------------------------------------------------
// ComponentDetailPage
// ---------------------------------------------------------------------------

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

          return isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    Expanded(
                      flex: 2,
                      child: _ControlsPanel(
                        entry: widget.entry,
                        params: _params,
                        onUpdate: _update,
                      ),
                    ),
                  ],
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _PreviewPanel(
                        entry: widget.entry,
                        params: _params,
                        isDark: _darkPreview,
                        onToggleDark: (v) => setState(() => _darkPreview = v),
                      ),
                    ),
                    if (widget.entry.params.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Divider(
                          height: 1,
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: _ControlsPanel(
                        entry: widget.entry,
                        params: _params,
                        onUpdate: _update,
                      ),
                    ),
                    if (widget.entry.codeExample != null)
                      SliverToBoxAdapter(
                        child: _CodeSnippet(code: widget.entry.codeExample!),
                      ),
                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: 32),
                    ),
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
  });

  final GalleryEntry entry;
  final Map<String, dynamic> params;
  final bool isDark;
  final ValueChanged<bool> onToggleDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);

    Widget preview;
    try {
      preview = entry.builder(context, params);
    } catch (e) {
      preview = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Preview error: $e',
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Preview',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
              const Spacer(),
              Tooltip(
                message: isDark ? 'Light background' : 'Dark background',
                child: IconButton(
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black45,
                  ),
                  onPressed: () => onToggleDark(!isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: entry.isFullScreen
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: preview,
                      )
                    : preview,
              ),
            ),
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
  });

  final GalleryEntry entry;
  final Map<String, dynamic> params;
  final void Function(String key, dynamic value) onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        // Description
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            entry.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (entry.params.isNotEmpty) ...[
          Text(
            'PARAMETERS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...entry.params.map((p) => _ParamControl(
                param: p,
                value: params[p.name] ?? p.defaultValue,
                onChanged: (v) => onUpdate(p.name, v),
              )),
        ],
        if (entry.codeExample != null) _CodeSnippet(code: entry.codeExample!),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual param control
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
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final subtitleStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget control;
    switch (param.type) {
      case ParamType.boolType:
        control = SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(param.label, style: labelStyle),
          subtitle: param.description != null
              ? Text(param.description!, style: subtitleStyle)
              : null,
          value: (value as bool?) ?? false,
          onChanged: onChanged,
        );

      case ParamType.enumType:
        final options = param.enumValues ?? const [];
        control = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Row(
                children: [
                  Text(param.label, style: labelStyle),
                  const Spacer(),
                  _TypeBadge(label: 'enum'),
                ],
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: options.map((opt) {
                final selected = value as String == opt;
                return FilterChip(
                  label: Text(opt),
                  selected: selected,
                  onSelected: (_) => onChanged(opt),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
          ],
        );

      case ParamType.doubleType:
        final min = param.min ?? 0;
        final max = param.max ?? 100;
        final current = (value as double?) ?? 0.0;
        control = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 2),
              child: Row(
                children: [
                  Text(param.label, style: labelStyle),
                  const Spacer(),
                  Text(
                    current.toStringAsFixed(current.abs() < 10 ? 2 : 0),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TypeBadge(label: 'double'),
                ],
              ),
            ),
            Slider(
              value: current.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ],
        );

      case ParamType.intType:
        final min = (param.min ?? 0).toInt();
        final max = (param.max ?? 10).toInt();
        final current = (value as int?) ?? min;
        control = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 2),
              child: Row(
                children: [
                  Text(param.label, style: labelStyle),
                  const Spacer(),
                  Text(
                    '$current',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TypeBadge(label: 'int'),
                ],
              ),
            ),
            Slider(
              value: current.toDouble().clamp(min.toDouble(), max.toDouble()),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (v) => onChanged(v.round()),
            ),
          ],
        );

      case ParamType.stringType:
        control = Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(param.label, style: labelStyle),
                  const Spacer(),
                  _TypeBadge(label: 'String'),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: value as String? ?? '',
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  hintText: param.description,
                ),
                onChanged: onChanged,
              ),
              const SizedBox(height: 4),
            ],
          ),
        );

      case ParamType.colorType:
        final colors = [
          Colors.transparent,
          const Color(0xFF1A237E),
          const Color(0xFF7C3AED),
          const Color(0xFF0052CC),
          const Color(0xFF00695C),
          const Color(0xFFC62828),
        ];
        control = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Row(
                children: [
                  Text(param.label, style: labelStyle),
                  const Spacer(),
                  _TypeBadge(label: 'Color'),
                ],
              ),
            ),
            Row(
              children: colors.map((c) {
                final selected = value == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(c),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c == Colors.transparent ? null : c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : Colors.grey.withAlpha(80),
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: c == Colors.transparent
                          ? const Icon(Icons.close, size: 14)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        );
    }

    return control;
  }
}

// ---------------------------------------------------------------------------
// Code snippet
// ---------------------------------------------------------------------------

class _CodeSnippet extends StatelessWidget {
  const _CodeSnippet({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'USAGE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 16),
                tooltip: 'Copy to clipboard',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(16),
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                color: Color(0xFFCDD6F4),
                height: 1.6,
              ),
            ),
          ),
        ],
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
        color: primary.withAlpha(20),
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
