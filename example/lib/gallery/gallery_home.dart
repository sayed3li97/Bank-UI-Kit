import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'component_detail.dart';
import 'component_registry.dart';

// ---------------------------------------------------------------------------
// Theme preset helpers
// ---------------------------------------------------------------------------

enum GalleryPreset { studio, voltage, bloom }

extension _GalleryPresetX on GalleryPreset {
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

// Per-category accent colours used for icon container tinting.
// These are theme-independent brand hues; they are blended with opacity so
// they harmonise with both light and dark surfaces.
const Map<GalleryCategory, Color> _kCategoryAccents = {
  GalleryCategory.accounts: Color(0xFF4A90D9),
  GalleryCategory.cards: Color(0xFF7C3AED),
  GalleryCategory.transactions: Color(0xFF0BB07B),
  GalleryCategory.transfers: Color(0xFF2563EB),
  GalleryCategory.auth: Color(0xFFE53935),
  GalleryCategory.states: Color(0xFFFF6D00),
  GalleryCategory.insights: Color(0xFF8E24AA),
  GalleryCategory.onboarding: Color(0xFF00897B),
  GalleryCategory.saving: Color(0xFF43A047),
  GalleryCategory.social: Color(0xFFE91E63),
  GalleryCategory.investing: Color(0xFF00ACC1),
  GalleryCategory.credit: Color(0xFFFF8F00),
  GalleryCategory.notifications: Color(0xFF5C6BC0),
};

// ---------------------------------------------------------------------------
// GalleryApp — root StatelessWidget wrapping state management
// ---------------------------------------------------------------------------

/// Root widget for the Bank UI Kit component gallery.
///
/// Mounts [BankUiScope] and [MaterialApp] with live theme switching, then
/// places [GalleryHome] as the home route.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  GalleryPreset _preset = GalleryPreset.studio;
  bool _isDark = false;

  void _handlePresetChanged(GalleryPreset preset) =>
      setState(() => _preset = preset);

  void _handleBrightnessChanged(bool isDark) =>
      setState(() => _isDark = isDark);

  @override
  Widget build(BuildContext context) {
    final bankPreset = _preset.bankPreset;
    return BankUiScope(
      initialData: BankUiScopeData(preset: bankPreset),
      child: MaterialApp(
        title: 'Bank UI Kit — Gallery',
        debugShowCheckedModeBanner: false,
        theme: bankPreset.apply(ThemeData.light(useMaterial3: true)),
        darkTheme: bankPreset.apply(ThemeData.dark(useMaterial3: true)),
        themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
        home: GalleryHome(
          preset: _preset,
          isDark: _isDark,
          onPresetChanged: _handlePresetChanged,
          onBrightnessChanged: _handleBrightnessChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GalleryHome — main scaffold
// ---------------------------------------------------------------------------

/// The interactive home screen of the Bank UI Kit component gallery.
///
/// Features:
/// - AppBar with theme-preset selector and brightness toggle.
/// - Animated search bar that filters components by name / description /
///   category label across all [kGalleryEntries].
/// - Two-column category grid when idle; flat filtered list when searching.
/// - Navigation to [ComponentDetailPage] on entry tap.
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  // ── computed properties ───────────────────────────────────────────────────

  bool get _isSearching => _query.isNotEmpty;

  List<GalleryEntry> get _searchResults {
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) return const [];
    return kGalleryEntries.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          e.category.label.toLowerCase().contains(q);
    }).toList();
  }

  Map<GalleryCategory, List<GalleryEntry>> get _entriesByCategory {
    final map = <GalleryCategory, List<GalleryEntry>>{};
    for (final entry in kGalleryEntries) {
      map.putIfAbsent(entry.category, () => []).add(entry);
    }
    return map;
  }

  // ── event handlers ────────────────────────────────────────────────────────

  void _onQueryChanged(String value) => setState(() => _query = value);

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    _searchFocus.unfocus();
  }

  void _navigateToDetail(BuildContext context, GalleryEntry entry) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ComponentDetailPage(entry: entry),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, GalleryCategory category) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _CategoryScreen(category: category),
      ),
    );
  }

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bankTheme = BankThemeData.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with gradient header ───────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 14),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Component Gallery',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${kGalleryEntries.length} components  •  '
                    '${_entriesByCategory.length} categories',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              background: _AppBarBackground(bankTheme: bankTheme),
            ),
            actions: [
              _PresetSelector(
                selected: widget.preset,
                onChanged: widget.onPresetChanged,
              ),
              IconButton(
                tooltip: widget.isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => RotationTransition(
                    turns:
                        Tween<double>(begin: 0.75, end: 1).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    widget.isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    key: ValueKey(widget.isDark),
                  ),
                ),
                onPressed: () => widget.onBrightnessChanged(!widget.isDark),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Sticky search bar ────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(
              query: _query,
              controller: _searchController,
              focusNode: _searchFocus,
              entryCount: kGalleryEntries.length,
              onChanged: _onQueryChanged,
              onClear: _clearSearch,
              colorScheme: colorScheme,
            ),
          ),

          // ── Body: grid (idle) or list (searching) ────────────────────────
          // Render the grid/list as sliver content so the SearchBar can
          // stick at the top while the rest scrolls underneath it.
          if (_isSearching)
            _SearchResultsSliver(
              key: const ValueKey('search'),
              results: _searchResults,
              query: _query,
              onTap: (e) => _navigateToDetail(context, e),
            )
          else
            _CategoryGridSliver(
              key: const ValueKey('grid'),
              byCategory: _entriesByCategory,
              onCategoryTap: (cat) => _navigateToCategory(context, cat),
            ),

          // Bottom padding so content clears the system navigation bar.
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar gradient background
// ---------------------------------------------------------------------------

class _AppBarBackground extends StatelessWidget {
  const _AppBarBackground({required this.bankTheme});

  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = bankTheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withAlpha(isDark ? 60 : 30),
            primary.withAlpha(isDark ? 20 : 8),
            Theme.of(context).colorScheme.surface,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky search bar (SliverPersistentHeaderDelegate)
// ---------------------------------------------------------------------------

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  _SearchBarDelegate({
    required this.query,
    required this.controller,
    required this.focusNode,
    required this.entryCount,
    required this.onChanged,
    required this.onClear,
    required this.colorScheme,
  });

  final String query;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int entryCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ColorScheme colorScheme;

  static const double _height = 64;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_SearchBarDelegate old) =>
      old.query != query || old.colorScheme != colorScheme;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SearchBar(
          controller: controller,
          focusNode: focusNode,
          hintText: 'Search $entryCount components…',
          leading: const Icon(Icons.search),
          trailing: [
            if (query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear search',
                onPressed: onClear,
              ),
          ],
          onChanged: onChanged,
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused) ? 4 : 1,
          ),
          backgroundColor: WidgetStatePropertyAll(
            colorScheme.surfaceContainerLow,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category grid sliver
// ---------------------------------------------------------------------------

class _CategoryGridSliver extends StatelessWidget {
  const _CategoryGridSliver({
    required this.byCategory,
    required this.onCategoryTap,
    super.key,
  });

  final Map<GalleryCategory, List<GalleryEntry>> byCategory;
  final ValueChanged<GalleryCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    // Preserve the canonical enum ordering.
    final categories =
        GalleryCategory.values.where((c) => byCategory.containsKey(c)).toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryCard(
            category: category,
            entryCount: byCategory[category]!.length,
            onTap: () => onCategoryTap(category),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category card
// ---------------------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.entryCount,
    required this.onTap,
  });

  final GalleryCategory category;
  final int entryCount;
  final VoidCallback onTap;

  Color _accentColor(BuildContext context) {
    // Prefer a static per-category accent; fall back to the theme primary.
    return _kCategoryAccents[category] ?? Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentColor(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(isDark ? 80 : 60),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withAlpha(30),
        highlightColor: accent.withAlpha(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withAlpha(isDark ? 45 : 30),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  category.icon,
                  color: accent,
                  size: 22,
                ),
              ),
              const Spacer(),
              // Category label
              Text(
                category.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Component count chip
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withAlpha(isDark ? 40 : 22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$entryCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    entryCount == 1 ? 'component' : 'components',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search results sliver
// ---------------------------------------------------------------------------

class _SearchResultsSliver extends StatelessWidget {
  const _SearchResultsSliver({
    required this.results,
    required this.query,
    required this.onTap,
    super.key,
  });

  final List<GalleryEntry> results;
  final String query;
  final ValueChanged<GalleryEntry> onTap;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptySearchPlaceholder(query: query),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      sliver: SliverList.separated(
        itemCount: results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _ComponentListTile(
          entry: results[index],
          onTap: () => onTap(results[index]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty search placeholder
// ---------------------------------------------------------------------------

class _EmptySearchPlaceholder extends StatelessWidget {
  const _EmptySearchPlaceholder({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: colorScheme.onSurfaceVariant.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching by component name, description, or category.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category screen (navigated to from home grid)
// ---------------------------------------------------------------------------

class _CategoryScreen extends StatelessWidget {
  const _CategoryScreen({required this.category});

  final GalleryCategory category;

  @override
  Widget build(BuildContext context) {
    final entries =
        kGalleryEntries.where((e) => e.category == category).toList();
    final accent =
        _kCategoryAccents[category] ?? Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.label),
        // Subtle tint strip to remind users which category they are in.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withAlpha(0)],
              ),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _ComponentListTile(
          entry: entries[index],
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ComponentDetailPage(entry: entries[index]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Component list tile (search results + category screen)
// ---------------------------------------------------------------------------

class _ComponentListTile extends StatelessWidget {
  const _ComponentListTile({
    required this.entry,
    required this.onTap,
  });

  final GalleryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _kCategoryAccents[entry.category] ?? colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(isDark ? 80 : 60),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withAlpha(25),
        highlightColor: accent.withAlpha(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withAlpha(isDark ? 45 : 28),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  entry.category.icon,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category badge
                    _CategoryBadge(
                      label: entry.category.label,
                      accent: accent,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category badge (used inside list tile)
// ---------------------------------------------------------------------------

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.label,
    required this.accent,
    required this.isDark,
  });

  final String label;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 40 : 22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preset selector (AppBar action)
// ---------------------------------------------------------------------------

class _PresetSelector extends StatelessWidget {
  const _PresetSelector({
    required this.selected,
    required this.onChanged,
  });

  final GalleryPreset selected;
  final ValueChanged<GalleryPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<GalleryPreset>(
      tooltip: 'Switch theme preset',
      initialValue: selected,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 48),
      itemBuilder: (_) => GalleryPreset.values.map((preset) {
        final isSelected = preset == selected;
        return PopupMenuItem<GalleryPreset>(
          value: preset,
          child: Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                preset.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.palette_outlined, size: 18),
            const SizedBox(width: 5),
            Text(
              selected.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
