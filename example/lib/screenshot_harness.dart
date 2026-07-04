// Screenshot harness for automated documentation captures.
//
// Renders a single screen OR a single gallery component with a chosen preset /
// brightness, selected entirely from the URL query string so an external
// driver (Playwright) can capture the full matrix deterministically.
//
// Screen mode (existing):
//   index.html?screen=home&preset=voltage&dark=1
//
// Component mode (new: renders one gallery entry with default params):
//   index.html?component=BankBalanceText&preset=studio&dark=0
//
// This is NOT the app users run: see main.dart for the interactive gallery.
import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'demo/flagship/flagship_apply.dart';
import 'demo/flagship/flagship_catalog.dart';
import 'demo/flagship/flagship_home.dart';
import 'demo/flagship/flagship_my_products.dart';
import 'demo/flagship/flagship_product_detail.dart';
import 'demo/heritage_dashboard.dart';
import 'demo/home_dashboard.dart';
import 'gallery/component_registry.dart';
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
  'flagship-home': FlagshipHome.new,
  'flagship-catalog': FlagshipCatalog.new,
  'flagship-product': FlagshipProductDetail.new,
  'flagship-apply': () => const FlagshipApplyFlow(initialStep: 2),
  'flagship-my-products': FlagshipMyProducts.new,
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
  final preset = _presetFromName(params['preset']);
  final dark = params['dark'] == '1';
  final rtl = params['dir'] == 'rtl';

  final base = dark ? ThemeData.dark() : ThemeData.light();
  // Arabic glyph fallback: the capture browser cannot download the web
  // engine's remote Noto fonts, so the bundled subset steps in for
  // currency symbols and RTL sample text.
  final themed = preset.apply(base);
  final theme = themed.copyWith(
    textTheme: themed.textTheme.apply(
      fontFamilyFallback: const ['NotoSansArabic'],
    ),
  );

  // ── Component mode ─────────────────────────────────────────────────────────
  final componentName = params['component'];
  if (componentName != null) {
    final entry = kGalleryEntries.firstWhere(
      (e) => e.name == componentName,
      orElse: () => kGalleryEntries.first,
    );
    final defaultParams = {
      for (final p in entry.params) p.name: p.defaultValue
    };

    runApp(
      BankUiScope(
        initialData: BankUiScopeData(preset: preset),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: _ComponentShotPage(entry: entry, params: defaultParams),
        ),
      ),
    );
    return;
  }

  // ── Screen mode (existing) ─────────────────────────────────────────────────
  final screenKey = params['screen'] ?? 'home';
  // The apply flow can be pinned to a specific step via ?step=N so the
  // documentation walkthrough can capture every stage of the journey.
  Widget Function() builder;
  if (screenKey == 'flagship-apply') {
    final step = int.tryParse(params['step'] ?? '2') ?? 2;
    builder = () => FlagshipApplyFlow(initialStep: step);
  } else {
    builder = _screens[screenKey] ?? _screens['home']!;
  }

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

// ---------------------------------------------------------------------------
// Component shot page
// ---------------------------------------------------------------------------

class _ComponentShotPage extends StatelessWidget {
  const _ComponentShotPage({required this.entry, required this.params});

  final GalleryEntry entry;
  final Map<String, dynamic> params;

  @override
  Widget build(BuildContext context) {
    Widget child;
    try {
      child = entry.builder(context, params);
    } catch (e) {
      child = Center(
        child: Text(
          'Preview error: $e',
          style: const TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (entry.isFullScreen) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: child,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: child,
          ),
        ),
      ),
    );
  }
}
