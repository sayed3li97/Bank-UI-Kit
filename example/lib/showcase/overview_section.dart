import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import '../demo/flagship/flagship_home.dart';
import 'device_frame.dart';
import 'showcase.dart';

/// The landing / overview: a restrained hero (headline, subhead, two CTAs, a
/// live device preview) followed by a feature grid and a live theming strip.
class OverviewSection extends StatelessWidget {
  const OverviewSection({
    required this.settings,
    required this.onExploreComponents,
    required this.onOpenFlagship,
    super.key,
  });

  final ShowcaseSettings settings;
  final VoidCallback onExploreComponents;
  final VoidCallback onOpenFlagship;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? BankTokens.space8 : BankTokens.space5,
                  vertical: wide ? BankTokens.space8 : BankTokens.space6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(
                      settings: settings,
                      wide: wide,
                      onExploreComponents: onExploreComponents,
                      onOpenFlagship: onOpenFlagship,
                    ),
                    SizedBox(
                        height: wide ? BankTokens.space10 : BankTokens.space8),
                    Text(
                      'Everything a bank ships',
                      style: BankTokens.headlineSmall
                          .copyWith(color: theme.onSurface),
                    ),
                    const SizedBox(height: BankTokens.space2),
                    Text(
                      'Built-in for retail, business, and Islamic banking.',
                      style: BankTokens.bodyLarge
                          .copyWith(color: theme.onSurfaceVariant),
                    ),
                    const SizedBox(height: BankTokens.space5),
                    _FeatureGrid(wide: wide),
                    SizedBox(
                        height: wide ? BankTokens.space10 : BankTokens.space8),
                    _ThemingStrip(settings: settings),
                    const SizedBox(height: BankTokens.space8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.settings,
    required this.wide,
    required this.onExploreComponents,
    required this.onOpenFlagship,
  });

  final ShowcaseSettings settings;
  final bool wide;
  final VoidCallback onExploreComponents;
  final VoidCallback onOpenFlagship;

  @override
  Widget build(BuildContext context) {
    final copy = _HeroCopy(
      onExploreComponents: onExploreComponents,
      onOpenFlagship: onOpenFlagship,
      wide: wide,
    );
    final device = SizedBox(
      height: wide ? 620 : 560,
      child: ThemedContent(
        settings: settings,
        child: const DeviceFrame(child: FlagshipHome()),
      ),
    );

    if (!wide) {
      return Column(
        children: [
          copy,
          const SizedBox(height: BankTokens.space6),
          device,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: copy),
        const SizedBox(width: BankTokens.space8),
        Expanded(flex: 5, child: device),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.onExploreComponents,
    required this.onOpenFlagship,
    required this.wide,
  });

  final VoidCallback onExploreComponents;
  final VoidCallback onOpenFlagship;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space3,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          ),
          child: Text(
            'Flutter UI for digital banking',
            style: BankTokens.labelMedium.copyWith(
              color: theme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: BankTokens.space4),
        Text(
          'Every screen a\nmodern bank ships.',
          style: (wide ? BankTokens.displayMedium : BankTokens.headlineLarge)
              .copyWith(
            color: theme.onSurface,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: BankTokens.space4),
        Text(
          'A production-grade component library: onboarding to servicing, '
          'lending to wealth. One codebase, four built-in themes, your brand. '
          'RTL, privacy, and Islamic finance are built in, not bolted on.',
          style: BankTokens.bodyLarge.copyWith(
            color: theme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: BankTokens.space5),
        Wrap(
          spacing: BankTokens.space3,
          runSpacing: BankTokens.space3,
          children: [
            FilledButton(
              onPressed: onExploreComponents,
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space6,
                  vertical: BankTokens.space4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
                ),
              ),
              child: Text(
                'Browse 147+ components',
                style: BankTokens.labelLarge.copyWith(color: theme.onPrimary),
              ),
            ),
            OutlinedButton(
              onPressed: onOpenFlagship,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.onSurface,
                side: BorderSide(color: theme.outline),
                padding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space6,
                  vertical: BankTokens.space4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
                ),
              ),
              child: Text(
                'Open the flagship app',
                style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
              ),
            ),
          ],
        ),
        const SizedBox(height: BankTokens.space6),
        Wrap(
          spacing: BankTokens.space5,
          runSpacing: BankTokens.space3,
          children: const [
            _Stat(value: '147+', label: 'components'),
            _Stat(value: '23', label: 'banking domains'),
            _Stat(value: '4', label: 'built-in themes'),
            _Stat(value: 'RTL', label: '+ Arabic numerals'),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: BankTokens.headlineSmall.copyWith(
            color: theme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: BankTokens.labelMedium.copyWith(color: theme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.wide});
  final bool wide;

  static const _features = <({IconData icon, String title, String body})>[
    (
      icon: Icons.palette_outlined,
      title: 'Themeable to any brand',
      body: 'Four presets plus a token API. Change one seed, rebrand every '
          'surface in minutes.',
    ),
    (
      icon: Icons.mosque_outlined,
      title: 'Islamic finance built in',
      body: 'Shariah-safe rate labels, Murabaha math, Zakat, and the Heritage '
          'preset out of the box.',
    ),
    (
      icon: Icons.visibility_off_outlined,
      title: 'Privacy by design',
      body: 'One flag masks every balance across the app, verified by a '
          'mask-proof test sweep.',
    ),
    (
      icon: Icons.translate_outlined,
      title: 'RTL & numerals',
      body: 'Directional layouts throughout, with Arabic-Indic numeral '
          'formatting in every input.',
    ),
    (
      icon: Icons.timeline_outlined,
      title: 'Journeys, not just widgets',
      body: 'Headless controllers chain widgets into complete, compliant '
          'banking flows.',
    ),
    (
      icon: Icons.accessibility_new_outlined,
      title: 'Built toward WCAG 2.1 AA',
      body: 'Semantic labels, 44px targets, and focus handling considered '
          'across the kit.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cols = wide ? 3 : 1;
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: BankTokens.space4,
      crossAxisSpacing: BankTokens.space4,
      childAspectRatio: wide ? 1.55 : 2.6,
      children: [
        for (final f in _features) _FeatureCard(feature: f),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});
  final ({IconData icon, String title, String body}) feature;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Container(
      padding: const EdgeInsets.all(BankTokens.space5),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(BankTokens.radiusLarge),
        border: Border.all(color: theme.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
            ),
            child: Icon(feature.icon, color: theme.primary, size: 22),
          ),
          const SizedBox(height: BankTokens.space4),
          Text(
            feature.title,
            style: BankTokens.bodyLarge.copyWith(
              color: theme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BankTokens.space2),
          Flexible(
            child: Text(
              feature.body,
              style: BankTokens.bodyMedium.copyWith(
                color: theme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemingStrip extends StatelessWidget {
  const _ThemingStrip({required this.settings});
  final ShowcaseSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Container(
      padding: const EdgeInsets.all(BankTokens.space6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary.withValues(alpha: 0.10),
            theme.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(BankTokens.radiusLarge),
        border: Border.all(color: theme.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'One kit, four design languages',
            style: BankTokens.headlineSmall.copyWith(
              color: theme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BankTokens.space2),
          Text(
            'Use the Appearance controls to re-skin the previews live — '
            'including dark mode, RTL, and privacy.',
            style:
                BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
          ),
          const SizedBox(height: BankTokens.space5),
          Wrap(
            spacing: BankTokens.space4,
            runSpacing: BankTokens.space4,
            children: [
              for (final p in kPresets)
                _PresetChip(
                  label: p.label,
                  blurb: p.blurb,
                  color: presetPrimary(p.preset),
                  selected: settings.preset == p.preset,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.blurb,
    required this.color,
    required this.selected,
  });

  final String label;
  final String blurb;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Container(
      width: 190,
      padding: const EdgeInsets.all(BankTokens.space4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
        border: Border.all(
          color: selected ? color : theme.outline.withValues(alpha: 0.6),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.65)],
              ),
              borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
            ),
          ),
          const SizedBox(width: BankTokens.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: BankTokens.labelLarge.copyWith(
                  color: theme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                blurb,
                style: BankTokens.labelSmall
                    .copyWith(color: theme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
