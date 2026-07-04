// Runnable flagship product-suite demo: a fictional premium retail bank
// ("Meridian") showcasing the full product catalogue and apply journeys,
// composed entirely from Bank UI Kit widgets.
//
//   flutter run -t lib/flagship_main.dart
//
// Switch the preset below to see the same app in another design language.
import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'demo/flagship/flagship_catalog.dart';
import 'demo/flagship/flagship_home.dart';
import 'demo/flagship/flagship_my_products.dart';

void main() => runApp(const FlagshipApp());

/// The flagship demo application shell with bottom navigation.
class FlagshipApp extends StatelessWidget {
  const FlagshipApp({super.key});

  static const BankPreset preset = BankPreset.studio;

  @override
  Widget build(BuildContext context) {
    return BankUiScope(
      initialData: const BankUiScopeData(preset: preset),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Meridian',
        theme: preset.apply(ThemeData.light(useMaterial3: true)),
        darkTheme: preset.apply(ThemeData.dark(useMaterial3: true)),
        home: const _FlagshipShell(),
      ),
    );
  }
}

class _FlagshipShell extends StatefulWidget {
  const _FlagshipShell();

  @override
  State<_FlagshipShell> createState() => _FlagshipShellState();
}

class _FlagshipShellState extends State<_FlagshipShell> {
  int _tab = 0;

  static const List<Widget> _tabs = [
    FlagshipHome(),
    FlagshipCatalog(),
    FlagshipMyProducts(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        indicatorColor: theme.primary.withValues(alpha: 0.14),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance_rounded),
            label: 'Products',
          ),
        ],
      ),
    );
  }
}
