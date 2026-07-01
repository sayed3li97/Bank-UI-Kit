// Screenshot harness for automated documentation captures.
//
// Renders a single screen with a chosen preset / brightness / direction,
// selected entirely from the URL query string so an external driver
// (Playwright) can capture the full matrix deterministically. Example:
//
//   index.html?screen=home&preset=voltage&dark=1&dir=ltr
//
// This is NOT the app users run — see main.dart for the interactive gallery.
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

final Map<String, Widget Function()> _screens = {
  'home': HomeDashboard.new,
  'heritage': HeritageDashboard.new,
  'states': StatesScreen.new,
  'accounts': AccountsScreen.new,
  'transactions': TransactionsScreen.new,
  'transfers': TransfersScreen.new,
  'cards': CardsScreen.new,
  'auth': AuthScreen.new,
  'onboarding': OnboardingScreen.new,
  'saving': SavingScreen.new,
  'social': SocialScreen.new,
  'investing': InvestingScreen.new,
  'credit': CreditScreen.new,
  'subscriptions': SubscriptionsScreen.new,
  'insights': InsightsScreen.new,
  'notifications': NotificationsScreen.new,
};

BankPreset _presetFromName(String? name) => switch (name) {
      'voltage' => BankPreset.voltage,
      'bloom' => BankPreset.bloom,
      'heritage' => BankPreset.heritage,
      _ => BankPreset.studio,
    };

void main() {
  final params = Uri.base.queryParameters;
  final screenKey = params['screen'] ?? 'home';
  final preset = _presetFromName(params['preset']);
  final dark = params['dark'] == '1';
  final rtl = params['dir'] == 'rtl';

  final base = dark ? ThemeData.dark() : ThemeData.light();
  final theme = preset.apply(base);
  final builder = _screens[screenKey] ?? _screens['home']!;

  runApp(
    BankUiScope(
      initialData: BankUiScopeData(preset: preset),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: builder(),
        ),
      ),
    ),
  );
}
