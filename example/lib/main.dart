import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'demo/flagship/flagship_apply.dart';
import 'demo/flagship/flagship_catalog.dart';
import 'demo/flagship/flagship_home.dart';
import 'demo/flagship/flagship_my_products.dart';
import 'demo/flagship/flagship_product_detail.dart';
import 'demo/heritage_dashboard.dart';
import 'demo/home_dashboard.dart';
import 'screens/accounts_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/credit_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/investing_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/saving_screen.dart';
import 'screens/social_screen.dart';
import 'screens/states_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/transfers_screen.dart';

void main() {
  runApp(const BankUiKitExampleApp());
}

class BankUiKitExampleApp extends StatefulWidget {
  const BankUiKitExampleApp({super.key});

  @override
  State<BankUiKitExampleApp> createState() => _BankUiKitExampleAppState();
}

class _BankUiKitExampleAppState extends State<BankUiKitExampleApp> {
  BankPreset _preset = BankPreset.studio;
  bool _darkMode = false;
  TextDirection _direction = TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    final base = _darkMode ? ThemeData.dark() : ThemeData.light();
    final theme = _preset.apply(base);

    return BankUiScope(
      initialData: BankUiScopeData(preset: _preset),
      child: MaterialApp(
        title: 'Bank UI Kit: Component Gallery',
        theme: theme,
        debugShowCheckedModeBanner: false,
        home: Directionality(
          textDirection: _direction,
          child: _ExampleShell(
            preset: _preset,
            darkMode: _darkMode,
            direction: _direction,
            onPresetChanged: (p) => setState(() => _preset = p),
            onDarkModeChanged: (d) => setState(() => _darkMode = d),
            onDirectionChanged: (d) => setState(() => _direction = d),
          ),
        ),
      ),
    );
  }
}

class _ExampleShell extends StatefulWidget {
  final BankPreset preset;
  final bool darkMode;
  final TextDirection direction;
  final ValueChanged<BankPreset> onPresetChanged;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<TextDirection> onDirectionChanged;

  const _ExampleShell({
    required this.preset,
    required this.darkMode,
    required this.direction,
    required this.onPresetChanged,
    required this.onDarkModeChanged,
    required this.onDirectionChanged,
  });

  @override
  State<_ExampleShell> createState() => _ExampleShellState();
}

class _ExampleShellState extends State<_ExampleShell> {
  static const _modules =
      <({String label, IconData icon, Widget Function() screen})>[
    (
      label: 'Meridian: Home',
      icon: Icons.star_outline,
      screen: FlagshipHome.new,
    ),
    (
      label: 'Meridian: Explore products',
      icon: Icons.inventory_2_outlined,
      screen: FlagshipCatalog.new,
    ),
    (
      label: 'Meridian: Product detail',
      icon: Icons.directions_car_outlined,
      screen: FlagshipProductDetail.new,
    ),
    (
      label: 'Meridian: Apply (Auto Finance)',
      icon: Icons.assignment_turned_in_outlined,
      screen: FlagshipApplyFlow.new,
    ),
    (
      label: 'Meridian: My products',
      icon: Icons.account_balance_outlined,
      screen: FlagshipMyProducts.new,
    ),
    (
      label: 'Home (full-app demo)',
      icon: Icons.home_outlined,
      screen: HomeDashboard.new,
    ),
    (
      label: 'Heritage demo (green+gold)',
      icon: Icons.account_balance_outlined,
      screen: HeritageDashboard.new,
    ),
    (
      label: 'States',
      icon: Icons.widgets_outlined,
      screen: StatesScreen.new,
    ),
    (
      label: 'Accounts',
      icon: Icons.account_balance_wallet_outlined,
      screen: AccountsScreen.new,
    ),
    (
      label: 'Transactions',
      icon: Icons.receipt_outlined,
      screen: TransactionsScreen.new,
    ),
    (
      label: 'Transfers',
      icon: Icons.swap_horiz,
      screen: TransfersScreen.new,
    ),
    (
      label: 'Cards',
      icon: Icons.credit_card_outlined,
      screen: CardsScreen.new,
    ),
    (
      label: 'Auth',
      icon: Icons.lock_outline,
      screen: AuthScreen.new,
    ),
    (
      label: 'Onboarding',
      icon: Icons.verified_outlined,
      screen: OnboardingScreen.new,
    ),
    (
      label: 'Saving',
      icon: Icons.savings_outlined,
      screen: SavingScreen.new,
    ),
    (
      label: 'Social',
      icon: Icons.group_outlined,
      screen: SocialScreen.new,
    ),
    (
      label: 'Investing',
      icon: Icons.show_chart,
      screen: InvestingScreen.new,
    ),
    (
      label: 'Credit',
      icon: Icons.credit_score_outlined,
      screen: CreditScreen.new,
    ),
    (
      label: 'Subscriptions',
      icon: Icons.workspace_premium_outlined,
      screen: SubscriptionsScreen.new,
    ),
    (
      label: 'Insights',
      icon: Icons.lightbulb_outline,
      screen: InsightsScreen.new,
    ),
    (
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      screen: NotificationsScreen.new,
    ),
  ];

  // The module shown in the detail pane on wide (tablet / laptop) layouts.
  int _selected = 0;

  // Below this width we use a single-column, push-navigation layout (phones);
  // at or above it we use a two-pane list + device-frame layout (tablets,
  // laptops, desktops), so the mobile-first banking screens render at their
  // natural phone width instead of stretching across the viewport.
  static const double _twoPaneBreakpoint = 760;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final wide = MediaQuery.sizeOf(context).width >= _twoPaneBreakpoint;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: _buildAppBar(theme),
      body: wide ? _buildTwoPane(theme) : _buildList(theme, selectable: false),
    );
  }

  PreferredSizeWidget _buildAppBar(BankThemeData theme) {
    return AppBar(
      backgroundColor: theme.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Bank UI Kit',
        style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
      ),
      actions: [
        _PresetsMenu(
          preset: widget.preset,
          onChanged: widget.onPresetChanged,
        ),
        IconButton(
          icon: Icon(
            widget.darkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            color: theme.onSurface,
          ),
          onPressed: () => widget.onDarkModeChanged(!widget.darkMode),
          tooltip: widget.darkMode ? 'Light mode' : 'Dark mode',
        ),
        IconButton(
          icon: Icon(
            widget.direction == TextDirection.ltr
                ? Icons.format_textdirection_r_to_l
                : Icons.format_textdirection_l_to_r,
            color: theme.onSurface,
          ),
          onPressed: () => widget.onDirectionChanged(
            widget.direction == TextDirection.ltr
                ? TextDirection.rtl
                : TextDirection.ltr,
          ),
          tooltip: widget.direction == TextDirection.ltr
              ? 'Switch to RTL'
              : 'Switch to LTR',
        ),
        const BankPrivacyToggle(),
        const SizedBox(width: 8),
      ],
    );
  }

  // Two-pane tablet / laptop layout: a navigation rail of modules on the
  // leading side and the selected screen in a centered device frame.
  Widget _buildTwoPane(BankThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: _buildList(theme, selectable: true),
        ),
        VerticalDivider(width: 1, color: theme.outline),
        Expanded(
          child: ColoredBox(
            color: theme.background,
            child: _DeviceFrame(
              // Rebuild the framed screen when the module changes.
              key: ValueKey<int>(_selected),
              child: _modules[_selected].screen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(BankThemeData theme, {required bool selectable}) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: BankTokens.space4),
      itemCount: _modules.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: theme.outline,
        indent: BankTokens.space4,
        endIndent: BankTokens.space4,
      ),
      itemBuilder: (context, index) {
        final module = _modules[index];
        final isSelected = selectable && index == _selected;
        return ListTile(
          selected: isSelected,
          selectedTileColor: theme.primary.withValues(alpha: 0.10),
          leading: Icon(module.icon, color: theme.primary),
          title: Text(
            module.label,
            style: BankTokens.bodyLarge.copyWith(
              color: isSelected ? theme.primary : theme.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing: selectable
              ? null
              : Icon(Icons.chevron_right, color: theme.onSurfaceVariant),
          onTap: () {
            if (selectable) {
              setState(() => _selected = index);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _ScreenHost(child: module.screen()),
                ),
              );
            }
          },
        );
      },
    );
  }
}

/// Hosts a pushed screen on single-column layouts. On phones the screen is
/// shown full-bleed; on wider viewports (large phones, tablets in portrait)
/// it is centred in a device frame so it keeps its intended proportions.
class _ScreenHost extends StatelessWidget {
  const _ScreenHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 480) return child;
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      body: _DeviceFrame(child: child),
    );
  }
}

/// Renders [child] as a phone-sized preview: a rounded, shadowed device frame
/// with the embedded screen's [MediaQuery] overridden to the frame's size, so
/// mobile-first screens lay out exactly as they would on a handset.
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({required this.child, super.key});

  final Widget child;

  static const double _frameWidth = 400;
  static const double _cornerRadius = 30;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth.clamp(0.0, _frameWidth).toDouble();
            final height =
                constraints.maxHeight.isFinite ? constraints.maxHeight : 820.0;
            final size = Size(width, height);
            final radius = BorderRadius.circular(_cornerRadius);
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: theme.outline, width: 1),
                boxShadow: BankTokens.shadowHero,
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: SizedBox.fromSize(
                  size: size,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: size,
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                      viewInsets: EdgeInsets.zero,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PresetsMenu extends StatelessWidget {
  final BankPreset preset;
  final ValueChanged<BankPreset> onChanged;

  const _PresetsMenu({required this.preset, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return PopupMenuButton<BankPreset>(
      initialValue: preset,
      onSelected: onChanged,
      icon: Icon(Icons.palette_outlined, color: theme.onSurface),
      tooltip: 'Switch preset',
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: BankPreset.studio,
          child: Text('Studio (default)'),
        ),
        const PopupMenuItem(
          value: BankPreset.voltage,
          child: Text('Voltage'),
        ),
        const PopupMenuItem(
          value: BankPreset.bloom,
          child: Text('Bloom'),
        ),
      ],
    );
  }
}
