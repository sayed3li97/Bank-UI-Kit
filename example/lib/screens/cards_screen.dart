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

final _savingsAccount = BankAccount(
  id: 'acc-002',
  name: 'Holiday Fund',
  maskedNumber: '•••• 8881',
  balance: Money(amount: Decimal.parse('4200.00'), currencyCode: 'GBP'),
  status: BankAccountStatus.active,
  type: BankAccountType.savings,
  currencyCode: 'GBP',
  ibanOrAccountNumber: 'GB12 MONZ 2345 6789 0123 45',
  sortCodeOrBic: '04-00-04',
);

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  // Virtual card state
  BankCardState _cardState = BankCardState.normal;
  BankCardSurface _surface = BankCardSurface.gradient;
  bool _isFlipped = false;

  // Card controls
  bool _freeze = false;
  bool _online = true;
  bool _contactless = true;
  bool _international = false;
  double _spendLimit = 500;
  String? _selectedDesignId = '1';

  // Flip card demos
  bool _genericFlipped = false;
  bool _horizontalFlipped = false;
  bool _horizontalFlipped2 = false;
  BankHorizontalCardLayout _layout = BankHorizontalCardLayout.balanceLeft;
  BankHorizontalCardBackground _bg = BankHorizontalCardBackground.themeGradient;
  BankFlipTrigger _trigger = BankFlipTrigger.builtInButton;

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
          // ── Section: Virtual card ─────────────────────────────────────────
          _SectionHeader(
            label: 'Virtual Card — Enhanced',
            sublabel:
                'Tap card to flip • Built-in flip button • Image background',
            theme: theme,
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
              flipTrigger: BankFlipTrigger.builtInButton,
            ),
          ),
          const SizedBox(height: BankTokens.space3),
          SegmentedButton<BankCardSurface>(
            segments: const [
              ButtonSegment(
                value: BankCardSurface.flatColor,
                label: Text('Flat'),
              ),
              ButtonSegment(
                value: BankCardSurface.gradient,
                label: Text('Gradient'),
              ),
              ButtonSegment(
                value: BankCardSurface.metallicSweep,
                label: Text('Metal'),
              ),
              ButtonSegment(
                value: BankCardSurface.animatedMesh,
                label: Text('Mesh'),
              ),
            ],
            selected: {_surface},
            onSelectionChanged: (s) => setState(() => _surface = s.first),
          ),
          const SizedBox(height: BankTokens.space4),

          // ── Section: BankFlipCard generic ──────────────────────────────────
          _SectionHeader(
            label: 'BankFlipCard — Generic Container',
            sublabel:
                'Custom front & back builders • Any content • Tap to flip',
            theme: theme,
          ),
          const SizedBox(height: BankTokens.space3),
          Center(
            child: BankFlipCard(
              isFlipped: _genericFlipped,
              onFlip: () => setState(() => _genericFlipped = !_genericFlipped),
              trigger: BankFlipTrigger.tapToFlip,
              width: 340,
              height: 200,
              frontBuilder: (context, _) => _CustomFrontFace(
                account: _account,
                theme: theme,
              ),
              backBuilder: (context, _) => _CustomBackFace(
                account: _account,
                theme: theme,
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space2),
          Center(
            child: Text(
              'Tap the card to flip it',
              style: BankTokens.bodySmall.copyWith(
                color: theme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space4),

          // ── Section: Horizontal Account Card ──────────────────────────────
          _SectionHeader(
            label: 'Horizontal Account Card',
            sublabel: 'Back shows IBAN & sort code • Tap values to copy',
            theme: theme,
          ),
          const SizedBox(height: BankTokens.space3),

          // Layout picker
          _PickerRow(
            label: 'Layout',
            children: [
              for (final l in BankHorizontalCardLayout.values)
                _Chip(
                  label: l.name,
                  selected: _layout == l,
                  onTap: () => setState(() => _layout = l),
                  theme: theme,
                ),
            ],
          ),
          const SizedBox(height: BankTokens.space2),

          // Background picker
          _PickerRow(
            label: 'Background',
            children: [
              _Chip(
                label: 'Gradient',
                selected: _bg == BankHorizontalCardBackground.themeGradient,
                onTap: () => setState(
                  () => _bg = BankHorizontalCardBackground.themeGradient,
                ),
                theme: theme,
              ),
              _Chip(
                label: 'Solid',
                selected: _bg == BankHorizontalCardBackground.solidColor,
                onTap: () => setState(
                  () => _bg = BankHorizontalCardBackground.solidColor,
                ),
                theme: theme,
              ),
              _Chip(
                label: 'Network img',
                selected: _bg == BankHorizontalCardBackground.image,
                onTap: () => setState(
                  () => _bg = BankHorizontalCardBackground.image,
                ),
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: BankTokens.space2),

          // Trigger picker
          _PickerRow(
            label: 'Flip trigger',
            children: [
              _Chip(
                label: 'Tap card',
                selected: _trigger == BankFlipTrigger.tapToFlip,
                onTap: () =>
                    setState(() => _trigger = BankFlipTrigger.tapToFlip),
                theme: theme,
              ),
              _Chip(
                label: 'Button',
                selected: _trigger == BankFlipTrigger.builtInButton,
                onTap: () =>
                    setState(() => _trigger = BankFlipTrigger.builtInButton),
                theme: theme,
              ),
              _Chip(
                label: 'External',
                selected: _trigger == BankFlipTrigger.external,
                onTap: () =>
                    setState(() => _trigger = BankFlipTrigger.external),
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: BankTokens.space3),

          Center(
            child: BankHorizontalAccountCard(
              account: _account,
              cardholderName: 'Alice Johnson',
              layout: _layout,
              background: _bg,
              primaryColor: const Color(0xFF1A237E),
              secondaryColor: const Color(0xFF7B1FA2),
              backgroundImage: _bg == BankHorizontalCardBackground.image
                  ? const NetworkImage(
                      'https://images.unsplash.com/photo-1557683316-973673baf926?w=680',
                    )
                  : null,
              trigger: _trigger,
              isFlipped: _horizontalFlipped,
              onFlip: () =>
                  setState(() => _horizontalFlipped = !_horizontalFlipped),
            ),
          ),

          if (_trigger == BankFlipTrigger.external) ...[
            const SizedBox(height: BankTokens.space3),
            Center(
              child: FilledButton.icon(
                onPressed: () =>
                    setState(() => _horizontalFlipped = !_horizontalFlipped),
                icon: const Icon(Icons.flip_outlined, size: 18),
                label: Text(_horizontalFlipped ? 'Show front' : 'Show details'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: theme.buttonRadius,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: BankTokens.space4),

          // ── Section: savings card variant ──────────────────────────────────
          _SectionHeader(
            label: 'Savings Account Card',
            sublabel: 'centred layout • solid colour • tap to flip',
            theme: theme,
          ),
          const SizedBox(height: BankTokens.space3),
          Center(
            child: BankHorizontalAccountCard(
              account: _savingsAccount,
              cardholderName: 'Alice Johnson',
              layout: BankHorizontalCardLayout.centred,
              background: BankHorizontalCardBackground.solidColor,
              primaryColor: const Color(0xFF00695C),
              trigger: BankFlipTrigger.tapToFlip,
              isFlipped: _horizontalFlipped2,
              onFlip: () =>
                  setState(() => _horizontalFlipped2 = !_horizontalFlipped2),
            ),
          ),
          const SizedBox(height: BankTokens.space4),

          // ── Section: Card Controls ─────────────────────────────────────────
          _SectionHeader(
            label: 'Card Controls',
            sublabel: 'Freeze, limits, contactless, international',
            theme: theme,
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

          // ── Section: Material Picker ───────────────────────────────────────
          _SectionHeader(
            label: 'Physical Card Design',
            sublabel: 'Plastic & metal card options',
            theme: theme,
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
          const SizedBox(height: BankTokens.space8),
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

// ---------------------------------------------------------------------------
// Custom front/back builders for BankFlipCard demo
// ---------------------------------------------------------------------------

class _CustomFrontFace extends StatelessWidget {
  const _CustomFrontFace({required this.account, required this.theme});

  final BankAccount account;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 200,
      decoration: BoxDecoration(
        gradient: theme.accentGradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primary, theme.primaryVariant],
            ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(BankTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.name,
                style: BankTokens.labelLarge.copyWith(color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(BankTokens.radiusFull),
                ),
                child: Text(
                  account.type.name.toUpperCase(),
                  style: BankTokens.labelSmall
                      .copyWith(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${account.balance.currencyCode} '
            '${account.balance.amount.toStringAsFixed(2)}',
            style: theme.numeralLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: BankTokens.space1),
          Text(
            account.maskedNumber,
            style: BankTokens.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              letterSpacing: 2,
            ),
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}

class _CustomBackFace extends StatelessWidget {
  const _CustomBackFace({required this.account, required this.theme});

  final BankAccount account;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 200,
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outline.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(BankTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: theme.primary),
              const SizedBox(width: BankTokens.space1),
              Text(
                'Account Details',
                style: BankTokens.labelMedium.copyWith(color: theme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: BankTokens.space3),
          _Row(
            label: 'IBAN',
            value: account.ibanOrAccountNumber ?? '—',
            theme: theme,
          ),
          const SizedBox(height: BankTokens.space2),
          _Row(
            label: 'Sort Code',
            value: account.sortCodeOrBic ?? '—',
            theme: theme,
          ),
          const SizedBox(height: BankTokens.space2),
          _Row(
            label: 'Currency',
            value: account.currencyCode,
            theme: theme,
          ),
          const Spacer(),
          Text(
            'Tap to return to card front',
            style: BankTokens.bodySmall.copyWith(
              color: theme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.theme});

  final String label;
  final String value;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant),
        ),
        Text(
          value,
          style: BankTokens.bodySmall.copyWith(
            color: theme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// UI helpers
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.theme,
    this.sublabel,
  });

  final String label;
  final String? sublabel;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: BankTokens.space3),
        Text(
          label,
          style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
        ),
        if (sublabel != null) ...[
          const SizedBox(height: 2),
          Text(
            sublabel!,
            style: BankTokens.bodySmall.copyWith(
              color: theme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: BankTokens.bodySmall.copyWith(
              color: BankThemeData.of(context).onSurfaceVariant,
            ),
          ),
        ),
        Wrap(spacing: BankTokens.space2, children: children),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: BankTokens.durationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space3,
          vertical: BankTokens.space1,
        ),
        decoration: BoxDecoration(
          color: selected
              ? theme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          border: Border.all(
            color: selected ? theme.primary : theme.outline,
          ),
        ),
        child: Text(
          label,
          style: BankTokens.labelSmall.copyWith(
            color: selected ? theme.primary : theme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
