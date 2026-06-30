import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

final _account = BankAccount(
  id: 'acc-001',
  name: 'Everyday Current',
  maskedNumber: '•••• 4321',
  balance: Money(amount: Decimal.parse('2480.55'), currencyCode: 'GBP'),
  status: BankAccountStatus.active,
  type: BankAccountType.current,
  currencyCode: 'GBP',
  ibanOrAccountNumber: 'GB29 NWBK 6016 1331 9268 19',
  sortCodeOrBic: '60-16-13',
);

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  BankCardState _cardState = BankCardState.normal;
  BankCardSurface _surface = BankCardSurface.gradient;
  bool _isFlipped = false;
  bool _freeze = false;
  bool _online = true;
  bool _contactless = true;
  bool _international = false;
  double _spendLimit = 500;
  String? _selectedDesignId = '1';

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
          Text(
            'Virtual Card',
            style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
          ),
          const SizedBox(height: BankTokens.space3),
          Center(
            child: BankVirtualCardWidget(
              account: _account,
              surface: _surface,
              cardState: _cardState,
              cardholderName: 'Alice Johnson',
              expiryDate: '12/27',
              isFlipped: _isFlipped,
              onFlip: () => setState(() => _isFlipped = !_isFlipped),
            ),
          ),
          const SizedBox(height: BankTokens.space3),
          SegmentedButton<BankCardSurface>(
            segments: const [
              ButtonSegment(
                  value: BankCardSurface.flatColor, label: Text('Flat')),
              ButtonSegment(
                  value: BankCardSurface.gradient, label: Text('Gradient')),
              ButtonSegment(
                value: BankCardSurface.metallicSweep,
                label: Text('Metal'),
              ),
            ],
            selected: {_surface},
            onSelectionChanged: (s) => setState(() => _surface = s.first),
          ),
          const SizedBox(height: BankTokens.space4),
          Text(
            'Card Controls',
            style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
          ),
          const SizedBox(height: BankTokens.space3),
          BankCardControlsPanel(
            isFrozen: _freeze,
            isOnlinePaymentsEnabled: _online,
            isContactlessEnabled: _contactless,
            isInternationalEnabled: _international,
            spendLimit: _spendLimit,
            onFreezeChanged: (v) => setState(() {
              _freeze = v;
              _cardState = v ? BankCardState.frozen : BankCardState.normal;
            }),
            onOnlinePaymentsChanged: (v) => setState(() => _online = v),
            onContactlessChanged: (v) => setState(() => _contactless = v),
            onInternationalChanged: (v) => setState(() => _international = v),
            onSpendLimitChanged: (v) => setState(() => _spendLimit = v),
            onChangePinTap: _showPinManager,
            onReportLostOrStolen: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          FilledButton(
            onPressed: _showPinManager,
            child: const Text('Change PIN'),
          ),
          const SizedBox(height: BankTokens.space4),
          Text(
            'Material Picker',
            style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
          ),
          const SizedBox(height: BankTokens.space3),
          BankPhysicalCardMaterialPicker(
            options: const [
              BankCardDesignOption(
                id: '1',
                label: 'Classic Black',
                material: BankCardMaterial.plastic,
                primaryColor: Color(0xFF1A1A1A),
              ),
              BankCardDesignOption(
                id: '2',
                label: 'Ocean Blue',
                material: BankCardMaterial.plastic,
                primaryColor: Color(0xFF1E40AF),
              ),
              BankCardDesignOption(
                id: '3',
                label: 'Rose Gold',
                material: BankCardMaterial.metal,
                primaryColor: Color(0xFFB76E79),
              ),
            ],
            selectedId: _selectedDesignId,
            onSelected: (option) =>
                setState(() => _selectedDesignId = option.id),
          ),
        ],
      ),
    );
  }

  void _showPinManager() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BankCardPinManager(
          onSubmit: (current, next) async => true,
          onCancel: () => Navigator.of(context).pop(),
          onSuccess: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
