import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  BankCardState _cardState = BankCardState.active;
  BankCardSurface _surface = BankCardSurface.gradient;
  bool _showBack = false;
  bool _freeze = false;
  bool _online = true;
  bool _contactless = true;
  double _spendLimit = 500;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Cards'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Virtual Card', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankVirtualCardWidget(
            cardholderName: 'Alex Carter',
            maskedPan: '•••• •••• •••• 4321',
            expiry: '12/27',
            surface: _surface,
            cardState: _cardState,
            showBack: _showBack,
            onFlip: () => setState(() => _showBack = !_showBack),
          ),
          const SizedBox(height: BankTokens.space3),
          SegmentedButton<BankCardSurface>(
            segments: const [
              ButtonSegment(value: BankCardSurface.flatColor, label: Text('Flat')),
              ButtonSegment(value: BankCardSurface.gradient, label: Text('Gradient')),
              ButtonSegment(value: BankCardSurface.metallicSweep, label: Text('Metal')),
            ],
            selected: {_surface},
            onSelectionChanged: (s) => setState(() => _surface = s.first),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Card Controls', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankCardControlsPanel(
            isFrozen: _freeze,
            isOnlineEnabled: _online,
            isContactlessEnabled: _contactless,
            spendLimit: _spendLimit,
            onFreezeToggle: (v) => setState(() {
              _freeze = v;
              _cardState = v ? BankCardState.frozen : BankCardState.active;
            }),
            onOnlineToggle: (v) => setState(() => _online = v),
            onContactlessToggle: (v) => setState(() => _contactless = v),
            onSpendLimitChanged: (v) => setState(() => _spendLimit = v),
          ),
          const SizedBox(height: BankTokens.space4),
          FilledButton(
            onPressed: () => BankCardPinManager.show(
              context,
              onPinChangeRequested: (current, next) async {},
            ),
            child: const Text('Change PIN'),
          ),
          const SizedBox(height: BankTokens.space3),
          Text('Material Picker', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankPhysicalCardMaterialPicker(
            options: [
              BankCardDesignOption(id: '1', name: 'Classic Black', color: const Color(0xFF1A1A1A)),
              BankCardDesignOption(id: '2', name: 'Ocean Blue', color: const Color(0xFF1E40AF)),
              BankCardDesignOption(id: '3', name: 'Rose Gold', color: const Color(0xFFB76E79), isMetal: true),
            ],
            onDesignSelected: (_) {},
          ),
        ],
      ),
    );
  }
}
