import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'component_detail.dart';
import 'component_registry.dart';

// ---------------------------------------------------------------------------
// Preset data
// ---------------------------------------------------------------------------

enum GalleryPreset { studio, voltage, bloom }

extension on GalleryPreset {
  String get label => switch (this) {
        GalleryPreset.studio => 'Studio',
        GalleryPreset.voltage => 'Voltage',
        GalleryPreset.bloom => 'Bloom',
      };

  BankPreset get bankPreset => switch (this) {
        GalleryPreset.studio => BankPreset.studio,
        GalleryPreset.voltage => BankPreset.voltage,
        GalleryPreset.bloom => BankPreset.bloom,
      };
}

// ---------------------------------------------------------------------------
// GalleryApp — root widget
// ---------------------------------------------------------------------------

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  GalleryPreset _preset = GalleryPreset.studio;
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    final bankPreset = _preset.bankPreset;
    final baseLight = ThemeData.light(useMaterial3: true);
    final baseDark = ThemeData.dark(useMaterial3: true);
    return BankUiScope(
      initialData: const BankUiScopeData(preset: BankPreset.studio),
      child: MaterialApp(
        title: 'Bank UI Kit — Gallery',
        debugShowCheckedModeBanner: false,
        theme: bankPreset.apply(baseLight),
        darkTheme: bankPreset.apply(baseDark),
        themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
        home: GalleryHome(
          preset: _preset,
          isDark: _isDark,
          onPresetChanged: (p) => setState(() => _preset = p),
          onBrightnessChanged: (d) => setState(() => _isDark = d),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GalleryHome
// ---------------------------------------------------------------------------

class GalleryHome extends StatefulWidget {
  const GalleryHome({
    required this.preset,
    required this.isDark,
    required this.onPresetChanged,
    required this.onBrightnessChanged,
    super.key,
  });

  final GalleryPreset preset;
  final bool isDark;
  final ValueChanged<GalleryPreset> onPresetChanged;
  final ValueChanged<bool> onBrightnessChanged;

  @override
  State<GalleryHome> createState() => _GalleryHomeState();
}

class _GalleryHomeState extends State<GalleryHome> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GalleryEntry> get _results {
    if (_query.isEmpty) return const [];
    final q = _query.toLowerCase();
    return kGalleryEntries.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          e.category.label.toLowerCase().contains(q);
    }).toList();
  }

  Map<GalleryCategory, List<GalleryEntry>> get _byCategory {
    final map = <GalleryCategory, List<GalleryEntry>>{};
    for (final e in kGalleryEntries) {
      map.putIfAbsent(e.category, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank UI Kit'),
        centerTitle: false,
        actions: [
          _PresetSelector(
            selected: widget.preset,
            onChanged: widget.onPresetChanged,
          ),
          IconButton(
            tooltip:
                widget.isDark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: Icon(
              widget.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => widget.onBrightnessChanged(!widget.isDark),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search ${kGalleryEntries.length} components…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
              elevation: const WidgetStatePropertyAll(2),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? _CategoryGrid(
                    byCategory: _byCategory,
                    colorScheme: colorScheme,
                  )
                : _SearchResults(results: _results, query: _query),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category grid
// ---------------------------------------------------------------------------

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.byCategory,
    required this.colorScheme,
  });

  final Map<GalleryCategory, List<GalleryEntry>> byCategory;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final categories = GalleryCategory.values
        .where((c) => byCategory.containsKey(c))
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: categories.length,
      itemBuilder: (ctx, i) {
        final cat = categories[i];
        final entries = byCategory[cat]!;
        return _CategoryCard(category: cat, entryCount: entries.length);
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.entryCount});

  final GalleryCategory category;
  final int entryCount;

  // Consistent color per category from the theme's surface variants
  Color _iconColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _iconColor(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _CategoryScreen(category: category),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              Text(
                category.label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$entryCount components',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category screen (drilled into from home)
// ---------------------------------------------------------------------------

class _CategoryScreen extends StatelessWidget {
  const _CategoryScreen({required this.category});

  final GalleryCategory category;

  @override
  Widget build(BuildContext context) {
    final entries =
        kGalleryEntries.where((e) => e.category == category).toList();

    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _ComponentListTile(entry: entries[i]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search results
// ---------------------------------------------------------------------------

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.query});

  final List<GalleryEntry> results;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No results for "$query"',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _ComponentListTile(entry: results[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Component list tile (used in search results + category screen)
// ---------------------------------------------------------------------------

class _ComponentListTile extends StatelessWidget {
  const _ComponentListTile({required this.entry});

  final GalleryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(entry.category.icon, color: primary, size: 20),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          entry.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ComponentDetailPage(entry: entry),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preset selector
// ---------------------------------------------------------------------------

class _PresetSelector extends StatelessWidget {
  const _PresetSelector({required this.selected, required this.onChanged});

  final GalleryPreset selected;
  final ValueChanged<GalleryPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<GalleryPreset>(
      tooltip: 'Switch preset',
      initialValue: selected,
      onSelected: onChanged,
      itemBuilder: (_) => GalleryPreset.values
          .map((p) => PopupMenuItem(value: p, child: Text(p.label)))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.palette_outlined, size: 20),
            const SizedBox(width: 4),
            Text(selected.label),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
