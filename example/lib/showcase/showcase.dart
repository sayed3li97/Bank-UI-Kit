import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'components_section.dart';
import 'flagship_section.dart';
import 'overview_section.dart';

/// Live appearance state shared by the whole showcase. The chrome (sidebar,
/// top bar) stays a constant neutral studio-light theme; these controls drive
/// only the previewed app content, so switching them feels like re-skinning a
/// real bank in real time.
class ShowcaseSettings {
  const ShowcaseSettings({
    required this.preset,
    required this.dark,
    required this.rtl,
    required this.privacy,
  });

  final BankPreset preset;
  final bool dark;
  final bool rtl;
  final bool privacy;

  ShowcaseSettings copyWith({
    BankPreset? preset,
    bool? dark,
    bool? rtl,
    bool? privacy,
  }) =>
      ShowcaseSettings(
        preset: preset ?? this.preset,
        dark: dark ?? this.dark,
        rtl: rtl ?? this.rtl,
        privacy: privacy ?? this.privacy,
      );
}

const List<({BankPreset preset, String label, String blurb})> kPresets = [
  (preset: BankPreset.studio, label: 'Studio', blurb: 'Neutral & modern'),
  (preset: BankPreset.voltage, label: 'Voltage', blurb: 'Bold neobank'),
  (preset: BankPreset.bloom, label: 'Bloom', blurb: 'Warm & friendly'),
  (preset: BankPreset.heritage, label: 'Heritage', blurb: 'Islamic banking'),
];

Color presetPrimary(BankPreset preset) => preset
    .apply(ThemeData.light(useMaterial3: true))
    .extension<BankThemeData>()!
    .primary;

/// Wraps [child] in the currently selected preset, brightness, direction, and
/// privacy scope, so any previewed screen reflects the live controls.
class ThemedContent extends StatelessWidget {
  const ThemedContent({
    required this.settings,
    required this.child,
    super.key,
  });

  final ShowcaseSettings settings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = settings.dark ? ThemeData.dark() : ThemeData.light();
    final themed = settings.preset.apply(base);
    return Theme(
      data: themed,
      child: BankUiScope(
        initialData: BankUiScopeData(
          preset: settings.preset,
          privacyEnabled: settings.privacy,
        ),
        child: Directionality(
          textDirection: settings.rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Root
// ---------------------------------------------------------------------------

class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key});

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  ShowcaseSettings _settings = const ShowcaseSettings(
    preset: BankPreset.studio,
    dark: false,
    rtl: false,
    privacy: false,
  );
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    // The chrome is always a clean, neutral studio-light theme.
    final chrome = BankPreset.studio.apply(ThemeData.light(useMaterial3: true));
    return MaterialApp(
      title: 'Bank UI Kit',
      debugShowCheckedModeBanner: false,
      theme: chrome,
      home: _ShowcaseShell(
        settings: _settings,
        section: _section,
        onSettings: (s) => setState(() => _settings = s),
        onSection: (i) => setState(() => _section = i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation model
// ---------------------------------------------------------------------------

const _sections = <({String label, IconData icon, String caption})>[
  (
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    caption: 'The kit at a glance'
  ),
  (
    label: 'Flagship app',
    icon: Icons.phone_iphone_outlined,
    caption: 'Meridian, end to end'
  ),
  (
    label: 'Components',
    icon: Icons.widgets_outlined,
    caption: 'Live interactive gallery'
  ),
];

// ---------------------------------------------------------------------------
// Responsive shell
// ---------------------------------------------------------------------------

class _ShowcaseShell extends StatelessWidget {
  const _ShowcaseShell({
    required this.settings,
    required this.section,
    required this.onSettings,
    required this.onSection,
  });

  final ShowcaseSettings settings;
  final int section;
  final ValueChanged<ShowcaseSettings> onSettings;
  final ValueChanged<int> onSection;

  static const double _railBreakpoint = 1000;

  Widget _content() {
    switch (section) {
      case 1:
        return FlagshipSection(settings: settings);
      case 2:
        return ComponentsSection(settings: settings);
      default:
        return OverviewSection(
          settings: settings,
          onExploreComponents: () => onSection(2),
          onOpenFlagship: () => onSection(1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final wide = MediaQuery.sizeOf(context).width >= _railBreakpoint;

    if (wide) {
      return Scaffold(
        backgroundColor: theme.surface,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              settings: settings,
              section: section,
              onSettings: onSettings,
              onSection: onSection,
            ),
            Expanded(
              child: ColoredBox(
                color: theme.background,
                child: _content(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: BankTokens.space4,
        title: const _Wordmark(),
        actions: [
          IconButton(
            tooltip: 'Appearance',
            icon: Icon(Icons.tune_rounded, color: theme.onSurface),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: theme.surface,
              showDragHandle: true,
              builder: (_) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  BankTokens.space5,
                  0,
                  BankTokens.space5,
                  BankTokens.space6,
                ),
                child: _AppearanceControls(
                  settings: settings,
                  onSettings: onSettings,
                ),
              ),
            ),
          ),
          const SizedBox(width: BankTokens.space2),
        ],
      ),
      body: _content(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: section,
        onDestinationSelected: onSection,
        backgroundColor: theme.surface,
        indicatorColor: theme.primary.withValues(alpha: 0.14),
        destinations: [
          for (final s in _sections)
            NavigationDestination(
              icon: Icon(s.icon),
              label: s.label,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar (desktop / tablet)
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.settings,
    required this.section,
    required this.onSettings,
    required this.onSection,
  });

  final ShowcaseSettings settings;
  final int section;
  final ValueChanged<ShowcaseSettings> onSettings;
  final ValueChanged<int> onSection;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          right: BorderSide(color: theme.outline.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                BankTokens.space5,
                BankTokens.space6,
                BankTokens.space5,
                BankTokens.space5,
              ),
              child: _Wordmark(large: true),
            ),
            for (var i = 0; i < _sections.length; i++)
              _NavItem(
                section: _sections[i],
                selected: i == section,
                onTap: () => onSection(i),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BankTokens.space5,
                BankTokens.space4,
                BankTokens.space5,
                BankTokens.space5,
              ),
              child: _AppearanceControls(
                settings: settings,
                onSettings: onSettings,
              ),
            ),
            Divider(height: 1, color: theme.outline.withValues(alpha: 0.6)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space5,
                vertical: BankTokens.space4,
              ),
              child: Text(
                'Bank UI Kit v0.0.3  ·  MIT  ·  pub.dev',
                style: BankTokens.labelSmall.copyWith(
                  color: theme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final ({String label, IconData icon, String caption}) section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final fg = selected ? theme.primary : theme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space3,
        vertical: 2,
      ),
      child: Material(
        color: selected
            ? theme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
        child: InkWell(
          borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space3,
              vertical: BankTokens.space3,
            ),
            child: Row(
              children: [
                Icon(section.icon, size: 22, color: fg),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.label,
                        style: BankTokens.labelLarge.copyWith(
                          color: fg,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      Text(
                        section.caption,
                        style: BankTokens.labelSmall.copyWith(
                          color: theme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Brand wordmark
// ---------------------------------------------------------------------------

class _Wordmark extends StatelessWidget {
  const _Wordmark({this.large = false});
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: large ? 40 : 32,
          height: large ? 40 : 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primary, theme.primary.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(large ? 12 : 9),
          ),
          child: Icon(
            Icons.account_balance_rounded,
            color: theme.onPrimary,
            size: large ? 22 : 18,
          ),
        ),
        const SizedBox(width: BankTokens.space3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank UI Kit',
              style: (large ? BankTokens.headlineSmall : BankTokens.bodyLarge)
                  .copyWith(
                      color: theme.onSurface, fontWeight: FontWeight.w700),
            ),
            if (large)
              Text(
                'Flutter UI for digital banking',
                style: BankTokens.labelSmall.copyWith(
                  color: theme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance controls (shared by sidebar + mobile sheet)
// ---------------------------------------------------------------------------

class _AppearanceControls extends StatelessWidget {
  const _AppearanceControls({
    required this.settings,
    required this.onSettings,
  });

  final ShowcaseSettings settings;
  final ValueChanged<ShowcaseSettings> onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'APPEARANCE',
          style: BankTokens.labelSmall.copyWith(
            color: theme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: BankTokens.space3),
        // Preset swatches.
        Wrap(
          spacing: BankTokens.space2,
          runSpacing: BankTokens.space2,
          children: [
            for (final p in kPresets)
              _PresetSwatch(
                label: p.label,
                color: presetPrimary(p.preset),
                selected: settings.preset == p.preset,
                onTap: () => onSettings(settings.copyWith(preset: p.preset)),
              ),
          ],
        ),
        const SizedBox(height: BankTokens.space4),
        _SegRow(
          label: 'Mode',
          options: const ['Light', 'Dark'],
          index: settings.dark ? 1 : 0,
          onChanged: (i) => onSettings(settings.copyWith(dark: i == 1)),
        ),
        const SizedBox(height: BankTokens.space3),
        _SegRow(
          label: 'Direction',
          options: const ['LTR', 'RTL'],
          index: settings.rtl ? 1 : 0,
          onChanged: (i) => onSettings(settings.copyWith(rtl: i == 1)),
        ),
        const SizedBox(height: BankTokens.space3),
        Row(
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: 18,
              color: theme.onSurfaceVariant,
            ),
            const SizedBox(width: BankTokens.space2),
            Expanded(
              child: Text(
                'Privacy mode',
                style: BankTokens.bodyMedium.copyWith(color: theme.onSurface),
              ),
            ),
            Switch(
              value: settings.privacy,
              onChanged: (v) => onSettings(settings.copyWith(privacy: v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space3,
          vertical: BankTokens.space2,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : theme.background,
          borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
          border: Border.all(
            color: selected ? color : theme.outline.withValues(alpha: 0.7),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: BankTokens.space2),
            Text(
              label,
              style: BankTokens.labelMedium.copyWith(
                color: theme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegRow extends StatelessWidget {
  const _SegRow({
    required this.label,
    required this.options,
    required this.index,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: BankTokens.bodyMedium.copyWith(color: theme.onSurface),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
              border: Border.all(color: theme.outline.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < options.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              i == index ? theme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            BankTokens.radiusSmall,
                          ),
                        ),
                        child: Text(
                          options[i],
                          textAlign: TextAlign.center,
                          style: BankTokens.labelMedium.copyWith(
                            color: i == index
                                ? theme.onPrimary
                                : theme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
