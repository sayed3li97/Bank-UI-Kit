import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
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
      ),
      body: ListView.separated(
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
          return ListTile(
            leading: Icon(module.icon, color: theme.primary),
            title: Text(
              module.label,
              style: BankTokens.bodyLarge.copyWith(color: theme.onSurface),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.onSurfaceVariant,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => module.screen()),
            ),
          );
        },
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
