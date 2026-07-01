import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart' hide BankCardMaterial;
import 'package:bank_ui_kit/investing.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:bank_ui_kit/social.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

enum GalleryCategory {
  accounts('Accounts & Balances', Icons.account_balance_wallet),
  cards('Cards', Icons.credit_card),
  transactions('Transactions', Icons.receipt_long),
  transfers('Transfers & Payments', Icons.send),
  auth('Auth & Security', Icons.lock),
  states('States & Feedback', Icons.info_outline),
  insights('Insights', Icons.bar_chart),
  onboarding('Onboarding & KYC', Icons.how_to_reg),
  saving('Saving', Icons.savings),
  social('Social', Icons.people),
  investing('Investing', Icons.trending_up),
  credit('Credit', Icons.credit_score),
  notifications('Notifications', Icons.notifications);

  const GalleryCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ---------------------------------------------------------------------------
// Param control model
// ---------------------------------------------------------------------------

enum ParamType {
  boolType,
  stringType,
  doubleType,
  intType,
  enumType,
  colorType,
}

class GalleryParam {
  const GalleryParam({
    required this.name,
    required this.label,
    required this.type,
    required this.defaultValue,
    this.enumValues,
    this.min,
    this.max,
    this.isRequired = false,
    this.description,
  });

  final String name;
  final String label;
  final ParamType type;
  final dynamic defaultValue;
  final List<String>? enumValues;
  final double? min;
  final double? max;
  final bool isRequired;
  final String? description;
}

// ---------------------------------------------------------------------------
// Gallery entry
// ---------------------------------------------------------------------------

class GalleryEntry {
  const GalleryEntry({
    required this.name,
    required this.description,
    required this.category,
    required this.params,
    required this.builder,
    this.codeExample,
    this.isFullScreen = false,
  });

  final String name;
  final String description;
  final GalleryCategory category;
  final List<GalleryParam> params;
  final Widget Function(BuildContext context, Map<String, dynamic> params)
      builder;
  final String? codeExample;

  /// When true the widget fills the container width (list tiles, banners…).
  final bool isFullScreen;
}

// ---------------------------------------------------------------------------
// Sample data helpers
// ---------------------------------------------------------------------------

BankAccount _account({
  BankAccountType type = BankAccountType.current,
  BankAccountStatus status = BankAccountStatus.active,
  double balance = 2480.50,
}) =>
    BankAccount(
      id: 'gal-1',
      name: 'Main Account',
      maskedNumber: '•••• 4242',
      balance: Money.fromDouble(balance, 'GBP'),
      status: status,
      type: type,
      currencyCode: 'GBP',
      ibanOrAccountNumber: 'GB29 NWBK 6016 1331 9268 19',
      sortCodeOrBic: '60-16-13',
    );

BankAccount _savingsAccount() => BankAccount(
      id: 'gal-2',
      name: 'Savings',
      maskedNumber: '•••• 5678',
      balance: Money.fromDouble(5200.0, 'GBP'),
      status: BankAccountStatus.active,
      type: BankAccountType.savings,
      currencyCode: 'GBP',
    );

Transaction _tx({
  TransactionCategory category = TransactionCategory.dining,
  TransactionStatus status = TransactionStatus.cleared,
  bool isCredit = false,
}) =>
    Transaction(
      id: 'gal-tx-1',
      amount: Money.fromDouble(isCredit ? 45.00 : -12.80, 'GBP'),
      settledAt: DateTime(2026, 6, 28),
      status: status,
      merchantName: isCredit ? 'Bank Transfer' : 'Café Nero',
      category: category,
      isFlexEligible: category == TransactionCategory.shopping,
    );

BankBeneficiary _beneficiary() => const BankBeneficiary(
      id: 'ben-1',
      name: 'Alice Johnson',
      maskedAccount: '•••• 5678',
      type: BeneficiaryType.bankTransfer,
      isVerified: true,
    );

SavingsPot _pot({double progress = 0.62}) => SavingsPot(
      id: 'pot-1',
      name: 'Holiday Fund',
      target: Money.fromDouble(3000, 'GBP'),
      current: Money.fromDouble(3000 * progress, 'GBP'),
      hasOwnAccountNumber: false,
      memberIds: const [],
      isRoundUpDestination: false,
      interestRate: 3.5,
    );

BankBudget _budget({double fraction = 0.65}) => BankBudget(
      id: 'bud-1',
      name: 'Groceries',
      limit: Money.fromDouble(400, 'GBP'),
      spent: Money.fromDouble(400 * fraction, 'GBP'),
      periodStart: DateTime(2026, 6, 1),
      periodEnd: DateTime(2026, 6, 30),
      category: TransactionCategory.groceries,
    );

BankInsight _insight({InsightConfidence confidence = InsightConfidence.high}) =>
    BankInsight(
      id: 'ins-1',
      title: 'Spending up 18% on dining',
      body: 'You spent £142 on restaurants this month — 18% more than average.',
      confidence: confidence,
      generatedAt: DateTime(2026, 6, 28),
      isDismissed: false,
      relatedCategory: TransactionCategory.dining,
    );

Holding _holding({double gainPercent = 12.4}) => Holding(
      assetId: 'aapl',
      symbol: 'AAPL',
      name: 'Apple Inc.',
      assetClass: AssetClass.equity,
      quantity: Decimal.parse('10'),
      currentValue: Money.fromDouble(1823.40, 'USD'),
      gainLoss: Money.fromDouble(gainPercent > 0 ? 180.0 : -80.0, 'USD'),
      gainLossPercent: gainPercent,
    );

// ---------------------------------------------------------------------------
// Enum parse helpers
// ---------------------------------------------------------------------------

String _enumLabel<T extends Enum>(T v) => v.name;

BankAccountType _accountType(String s) =>
    BankAccountType.values.firstWhere((e) => e.name == s);
BankAccountStatus _accountStatus(String s) =>
    BankAccountStatus.values.firstWhere((e) => e.name == s);
TransactionCategory _txCat(String s) =>
    TransactionCategory.values.firstWhere((e) => e.name == s);
TransactionStatus _txStatus(String s) =>
    TransactionStatus.values.firstWhere((e) => e.name == s);
BankBalanceSize _balanceSize(String s) =>
    BankBalanceSize.values.firstWhere((e) => e.name == s);
BankSkeletonVariant _skelVariant(String s) =>
    BankSkeletonVariant.values.firstWhere((e) => e.name == s);
BankToastVariant _toastVariant(String s) =>
    BankToastVariant.values.firstWhere((e) => e.name == s);
BankFlipTrigger _flipTrigger(String s) =>
    BankFlipTrigger.values.firstWhere((e) => e.name == s);
BankFlipAxis _flipAxis(String s) =>
    BankFlipAxis.values.firstWhere((e) => e.name == s);
BankHorizontalCardLayout _hLayout(String s) =>
    BankHorizontalCardLayout.values.firstWhere((e) => e.name == s);
BankHorizontalCardBackground _hBg(String s) =>
    BankHorizontalCardBackground.values.firstWhere((e) => e.name == s);
InsightConfidence _confidence(String s) =>
    InsightConfidence.values.firstWhere((e) => e.name == s);
BankDeviceTrustState _trustState(String s) =>
    BankDeviceTrustState.values.firstWhere((e) => e.name == s);
BankCardSurface _cardSurface(String s) =>
    BankCardSurface.values.firstWhere((e) => e.name == s);

// ---------------------------------------------------------------------------
// Registry
// ---------------------------------------------------------------------------

final List<GalleryEntry> kGalleryEntries = [
  // ── ACCOUNTS ──────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankBalanceText',
    description: 'Currency-formatted balance with automatic privacy masking.',
    category: GalleryCategory.accounts,
    codeExample: '''BankBalanceText(
  money: Money.fromDouble(2480.50, 'GBP'),
  size: BankBalanceSize.hero,
  showSign: false,
  compact: false,
)''',
    params: [
      const GalleryParam(
        name: 'amount',
        label: 'Amount (GBP)',
        type: ParamType.doubleType,
        defaultValue: 2480.50,
        min: -5000,
        max: 10000,
      ),
      GalleryParam(
        name: 'size',
        label: 'Size',
        type: ParamType.enumType,
        defaultValue: 'large',
        enumValues: BankBalanceSize.values.map(_enumLabel).toList(),
      ),
      const GalleryParam(
        name: 'showSign',
        label: 'Show sign (+)',
        type: ParamType.boolType,
        defaultValue: false,
      ),
      const GalleryParam(
        name: 'compact',
        label: 'Compact notation (£1.2K)',
        type: ParamType.boolType,
        defaultValue: false,
      ),
    ],
    builder: (ctx, p) => BankBalanceText(
      money: Money.fromDouble(p['amount'] as double, 'GBP'),
      size: _balanceSize(p['size'] as String),
      showSign: p['showSign'] as bool,
      compact: p['compact'] as bool,
    ),
  ),

  GalleryEntry(
    name: 'BankAccountCard',
    description: 'Swipeable card showing balance, account type, and masked number.',
    category: GalleryCategory.accounts,
    isFullScreen: true,
    codeExample: '''BankAccountCard(
  account: myAccount,
  showFullBalance: true,
  onTap: () => openDetail(),
)''',
    params: [
      GalleryParam(
        name: 'type',
        label: 'Account type',
        type: ParamType.enumType,
        defaultValue: 'current',
        enumValues: BankAccountType.values.map(_enumLabel).toList(),
      ),
      GalleryParam(
        name: 'status',
        label: 'Account status',
        type: ParamType.enumType,
        defaultValue: 'active',
        enumValues: BankAccountStatus.values.map(_enumLabel).toList(),
      ),
      const GalleryParam(
        name: 'balance',
        label: 'Balance (GBP)',
        type: ParamType.doubleType,
        defaultValue: 2480.50,
        min: -1000,
        max: 50000,
      ),
      const GalleryParam(
        name: 'showFullBalance',
        label: 'Hero balance size',
        type: ParamType.boolType,
        defaultValue: true,
      ),
    ],
    builder: (ctx, p) => BankAccountCard(
      account: _account(
        type: _accountType(p['type'] as String),
        status: _accountStatus(p['status'] as String),
        balance: p['balance'] as double,
      ),
      showFullBalance: p['showFullBalance'] as bool,
    ),
  ),

  GalleryEntry(
    name: 'BankAccountSwitcher',
    description: 'Compact list for switching between accounts.',
    category: GalleryCategory.accounts,
    isFullScreen: true,
    codeExample: '''BankAccountSwitcher(
  accounts: myAccounts,
  selectedAccountId: activeId,
  onSelected: (a) => setState(() => activeId = a.id),
)''',
    params: [
      const GalleryParam(
        name: 'selectedIdx',
        label: 'Selected account index',
        type: ParamType.intType,
        defaultValue: 0,
        min: 0,
        max: 2,
      ),
    ],
    builder: (ctx, p) {
      final accounts = [_account(), _savingsAccount()];
      final idx = (p['selectedIdx'] as int).clamp(0, accounts.length - 1);
      return BankAccountSwitcher(
        accounts: accounts,
        selectedAccountId: accounts[idx].id,
        onSelected: (_) {},
      );
    },
  ),

  // ── CARDS ──────────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankVirtualCardWidget',
    description: 'Credit/debit card with 3-D flip and multiple surface styles.',
    category: GalleryCategory.cards,
    codeExample: '''BankVirtualCardWidget(
  account: myAccount,
  cardholderName: 'ALEX MORGAN',
  surface: BankCardSurface.gradient,
  flipTrigger: BankFlipTrigger.tapToFlip,
)''',
    params: [
      GalleryParam(
        name: 'surface',
        label: 'Surface',
        type: ParamType.enumType,
        defaultValue: 'gradient',
        enumValues: BankCardSurface.values.map(_enumLabel).toList(),
      ),
      GalleryParam(
        name: 'flipTrigger',
        label: 'Flip trigger',
        type: ParamType.enumType,
        defaultValue: 'tapToFlip',
        enumValues: BankFlipTrigger.values.map(_enumLabel).toList(),
      ),
      GalleryParam(
        name: 'accountType',
        label: 'Account type',
        type: ParamType.enumType,
        defaultValue: 'current',
        enumValues: BankAccountType.values.map(_enumLabel).toList(),
      ),
    ],
    builder: (ctx, p) => BankVirtualCardWidget(
      account: _account(type: _accountType(p['accountType'] as String)),
      cardholderName: 'ALEX MORGAN',
      surface: _cardSurface(p['surface'] as String),
      flipTrigger: _flipTrigger(p['flipTrigger'] as String),
    ),
  ),

  GalleryEntry(
    name: 'BankHorizontalAccountCard',
    description: 'Landscape bank card with flip, showing IBAN on the back.',
    category: GalleryCategory.cards,
    codeExample: '''BankHorizontalAccountCard(
  account: myAccount,
  cardholderName: 'Alice Johnson',
  layout: BankHorizontalCardLayout.centred,
  background: BankHorizontalCardBackground.themeGradient,
  trigger: BankFlipTrigger.tapToFlip,
)''',
    params: [
      GalleryParam(
        name: 'layout',
        label: 'Layout',
        type: ParamType.enumType,
        defaultValue: 'balanceLeft',
        enumValues: BankHorizontalCardLayout.values.map(_enumLabel).toList(),
      ),
      GalleryParam(
        name: 'background',
        label: 'Background',
        type: ParamType.enumType,
        defaultValue: 'themeGradient',
        enumValues:
            BankHorizontalCardBackground.values.map(_enumLabel).toList(),
      ),
      GalleryParam(
        name: 'trigger',
        label: 'Flip trigger',
        type: ParamType.enumType,
        defaultValue: 'tapToFlip',
        enumValues: BankFlipTrigger.values.map(_enumLabel).toList(),
      ),
      GalleryParam(
        name: 'flipAxis',
        label: 'Flip axis',
        type: ParamType.enumType,
        defaultValue: 'horizontal',
        enumValues: BankFlipAxis.values.map(_enumLabel).toList(),
      ),
    ],
    builder: (ctx, p) => BankHorizontalAccountCard(
      account: _account(),
      cardholderName: 'Alice Johnson',
      layout: _hLayout(p['layout'] as String),
      background: _hBg(p['background'] as String),
      trigger: _flipTrigger(p['trigger'] as String),
      flipAxis: _flipAxis(p['flipAxis'] as String),
    ),
  ),

  GalleryEntry(
    name: 'BankFlipCard',
    description: 'Generic 3-D flip container — wrap any two widgets.',
    category: GalleryCategory.cards,
    codeExample: '''BankFlipCard(
  trigger: BankFlipTrigger.tapToFlip,
  flipAxis: BankFlipAxis.horizontal,
  frontBuilder: (ctx, _) => MyFront(),
  backBuilder: (ctx, _) => MyBack(),
)''',
    params: [
      GalleryParam(
        name: 'trigger',
        label: 'Flip trigger',
        type: ParamType.enumType,
        defaultValue: 'tapToFlip',
        enumValues: BankFlipTrigger.values.map(_enumLabel).toList(),
      ),
      GalleryParam(
        name: 'flipAxis',
        label: 'Flip axis',
        type: ParamType.enumType,
        defaultValue: 'horizontal',
        enumValues: BankFlipAxis.values.map(_enumLabel).toList(),
      ),
      const GalleryParam(
        name: 'durationMs',
        label: 'Duration (ms)',
        type: ParamType.intType,
        defaultValue: 500,
        min: 100,
        max: 1500,
      ),
    ],
    builder: (ctx, p) => BankFlipCard(
      trigger: _flipTrigger(p['trigger'] as String),
      flipAxis: _flipAxis(p['flipAxis'] as String),
      flipDuration: Duration(milliseconds: p['durationMs'] as int),
      frontBuilder: (_, __) => Container(
        width: 300,
        height: 160,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.credit_card, color: Colors.white, size: 32),
              SizedBox(height: 8),
              Text(
                'FRONT — tap to flip',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      backBuilder: (_, __) => Container(
        width: 300,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 32),
              SizedBox(height: 8),
              Text(
                'BACK — tap to flip',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    ),
  ),

  GalleryEntry(
    name: 'BankCardControlsPanel',
    description: 'Toggle panel for freeze, online, contactless, and ATM controls.',
    category: GalleryCategory.cards,
    isFullScreen: true,
    codeExample: '''BankCardControlsPanel(
  isFrozen: false,
  onFreezeToggle: (v) => setState(() => isFrozen = v),
)''',
    params: [
      const GalleryParam(
        name: 'isFrozen',
        label: 'Card frozen',
        type: ParamType.boolType,
        defaultValue: false,
      ),
      const GalleryParam(
        name: 'onlinePayments',
        label: 'Online payments enabled',
        type: ParamType.boolType,
        defaultValue: true,
      ),
      const GalleryParam(
        name: 'contactless',
        label: 'Contactless enabled',
        type: ParamType.boolType,
        defaultValue: true,
      ),
      const GalleryParam(
        name: 'atmWithdrawals',
        label: 'ATM withdrawals enabled',
        type: ParamType.boolType,
        defaultValue: true,
      ),
    ],
    builder: (ctx, p) => BankCardControlsPanel(
      isFrozen: p['isFrozen'] as bool,
      isOnlinePaymentsEnabled: p['onlinePayments'] as bool,
      isContactlessEnabled: p['contactless'] as bool,
      isInternationalEnabled: true,
      onFreezeChanged: (_) {},
      onOnlinePaymentsChanged: (_) {},
      onContactlessChanged: (_) {},
      onInternationalChanged: (_) {},
    ),
  ),

  GalleryEntry(
    name: 'BankPhysicalCardMaterialPicker',
    description: 'Swatch picker for selecting a physical card material.',
    category: GalleryCategory.cards,
    isFullScreen: true,
    codeExample: '''BankPhysicalCardMaterialPicker(
  options: designOptions,
  selectedId: selected?.id,
  onSelected: (opt) => setState(() => selected = opt),
)''',
    params: [],
    builder: (ctx, p) {
      final options = [
        const BankCardDesignOption(
          id: 'matte-black',
          label: 'Matte Black',
          material: BankCardMaterial.metal,
          primaryColor: Color(0xFF1A1A1A),
        ),
        const BankCardDesignOption(
          id: 'ocean-blue',
          label: 'Ocean Blue',
          material: BankCardMaterial.plastic,
          primaryColor: Color(0xFF1565C0),
        ),
      ];
      return _StatefulWrapper<BankCardDesignOption?>(
        initial: options.first,
        builder: (val, set) => BankPhysicalCardMaterialPicker(
          options: options,
          selectedId: val?.id,
          onSelected: set,
        ),
      );
    },
  ),

  GalleryEntry(
    name: 'BankCardPinManager',
    description: 'Multi-step PIN change flow: current → new → confirm.',
    category: GalleryCategory.cards,
    codeExample: '''BankCardPinManager(
  pinLength: 4,
  onSubmit: (current, next) async => verifyAndChange(current, next),
  onSuccess: () => showSuccess(),
)''',
    params: [
      const GalleryParam(
        name: 'pinLength',
        label: 'PIN length',
        type: ParamType.intType,
        defaultValue: 4,
        min: 4,
        max: 6,
      ),
    ],
    builder: (ctx, p) => BankCardPinManager(
      pinLength: p['pinLength'] as int,
      onSubmit: (_, __) async => true,
      onSuccess: () {},
    ),
  ),

  // ── TRANSACTIONS ──────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankTransactionListTile',
    description: 'Single transaction row with category icon, amount, and status.',
    category: GalleryCategory.transactions,
    isFullScreen: true,
    codeExample: '''BankTransactionListTile(
  transaction: myTx,
  onTap: () => openDetail(myTx),
)''',
    params: [
      GalleryParam(
        name: 'category',
        label: 'Category',
        type: ParamType.enumType,
        defaultValue: 'dining',
        enumValues: TransactionCategory.values.map(_enumLabel).toList(),
      ),
      GalleryParam(
        name: 'status',
        label: 'Status',
        type: ParamType.enumType,
        defaultValue: 'cleared',
        enumValues: TransactionStatus.values.map(_enumLabel).toList(),
      ),
      const GalleryParam(
        name: 'isCredit',
        label: 'Incoming (credit)',
        type: ParamType.boolType,
        defaultValue: false,
      ),
    ],
    builder: (ctx, p) => BankTransactionListTile(
      transaction: _tx(
        category: _txCat(p['category'] as String),
        status: _txStatus(p['status'] as String),
        isCredit: p['isCredit'] as bool,
      ),
    ),
  ),

  GalleryEntry(
    name: 'BankTransactionGroupHeader',
    description: 'Date separator row with day total for grouped lists.',
    category: GalleryCategory.transactions,
    isFullScreen: true,
    codeExample: '''BankTransactionGroupHeader(
  date: DateTime(2026, 6, 28),
  totalAmount: Money.fromDouble(-86.40, 'GBP'),
)''',
    params: [
      const GalleryParam(
        name: 'total',
        label: 'Day total (GBP)',
        type: ParamType.doubleType,
        defaultValue: -86.40,
        min: -500,
        max: 500,
      ),
    ],
    builder: (ctx, p) => BankTransactionGroupHeader(
      date: DateTime(2026, 6, 28),
    ),
  ),

  GalleryEntry(
    name: 'BankTransactionDetailSheet',
    description: 'Full transaction detail bottom sheet with actions.',
    category: GalleryCategory.transactions,
    codeExample: '''BankTransactionDetailSheet.show(
  context,
  transaction: myTx,
  accountName: 'Main Account',
)''',
    params: [
      GalleryParam(
        name: 'category',
        label: 'Category',
        type: ParamType.enumType,
        defaultValue: 'dining',
        enumValues: TransactionCategory.values.map(_enumLabel).toList(),
      ),
      const GalleryParam(
        name: 'isFlexEligible',
        label: 'BNPL eligible',
        type: ParamType.boolType,
        defaultValue: false,
      ),
    ],
    builder: (ctx, p) => _SheetOpener(
      label: 'Open Transaction Detail',
      onOpen: (c) => BankTransactionDetailSheet.show(
        c,
        transaction: Transaction(
          id: 'gal-tx',
          amount: Money.fromDouble(-38.50, 'GBP'),
          settledAt: DateTime(2026, 6, 28),
          status: TransactionStatus.cleared,
          merchantName: 'Café Nero',
          category: _txCat(p['category'] as String),
          isFlexEligible: p['isFlexEligible'] as bool,
        ),
      ),
    ),
  ),

  GalleryEntry(
    name: 'BankTransactionFilterSheet',
    description: 'Filter sheet for date range and category selection.',
    category: GalleryCategory.transactions,
    codeExample: '''BankTransactionFilterSheet.show(
  context,
  onApply: (filter) => setState(() => _filter = filter),
)''',
    params: [],
    builder: (ctx, p) => _SheetOpener(
      label: 'Open Filter Sheet',
      onOpen: (c) => BankTransactionFilterSheet.show(c),
    ),
  ),

  GalleryEntry(
    name: 'BankReceiptView',
    description: 'Receipt-style summary for a completed transaction.',
    category: GalleryCategory.transactions,
    codeExample: '''BankReceiptView(
  transaction: myTx,
  accountName: 'Main Account',
)''',
    params: [
      GalleryParam(
        name: 'category',
        label: 'Category',
        type: ParamType.enumType,
        defaultValue: 'dining',
        enumValues: TransactionCategory.values.map(_enumLabel).toList(),
      ),
    ],
    builder: (ctx, p) => BankReceiptView(
      transaction: Transaction(
        id: 'gal-rx',
        amount: Money.fromDouble(-38.50, 'GBP'),
        settledAt: DateTime(2026, 6, 28),
        status: TransactionStatus.cleared,
        merchantName: 'Café Nero',
        category: _txCat(p['category'] as String),
      ),
      fromAccountName: 'Main Account',
    ),
  ),

  // ── TRANSFERS ─────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankTransferReviewCard',
    description: 'Confirm-before-send card showing amount, fee, and ETA.',
    category: GalleryCategory.transfers,
    codeExample: '''BankTransferReviewCard(
  amount: Money.fromDouble(500, 'GBP'),
  beneficiary: myBeneficiary,
  estimatedArrival: 'Within 2 hours',
)''',
    params: [
      const GalleryParam(
        name: 'amount',
        label: 'Amount (GBP)',
        type: ParamType.doubleType,
        defaultValue: 500.0,
        min: 1,
        max: 5000,
      ),
      const GalleryParam(
        name: 'fee',
        label: 'Fee (GBP)',
        type: ParamType.doubleType,
        defaultValue: 0.0,
        min: 0,
        max: 20,
      ),
      const GalleryParam(
        name: 'isScheduled',
        label: 'Scheduled transfer',
        type: ParamType.boolType,
        defaultValue: false,
      ),
    ],
    builder: (ctx, p) => BankTransferReviewCard(
      amount: Money.fromDouble(p['amount'] as double, 'GBP'),
      beneficiary: _beneficiary(),
      fee: Money.fromDouble(p['fee'] as double, 'GBP'),
      estimatedArrival: (p['isScheduled'] as bool) ? null : 'Within 2 hours',
      isScheduled: p['isScheduled'] as bool,
      scheduledDate:
          (p['isScheduled'] as bool) ? DateTime(2026, 7, 5) : null,
    ),
  ),

  GalleryEntry(
    name: 'BankPaymentRequestCard',
    description: 'Incoming money-request card with accept and decline actions.',
    category: GalleryCategory.transfers,
    codeExample: '''BankPaymentRequestCard(
  requesterName: 'Alice Johnson',
  amount: Money.fromDouble(25, 'GBP'),
  requestedAt: DateTime.now(),
  onAccept: () {},
  onDecline: () {},
)''',
    params: [
      const GalleryParam(
        name: 'amount',
        label: 'Requested amount (GBP)',
        type: ParamType.doubleType,
        defaultValue: 25.0,
        min: 1,
        max: 500,
      ),
      const GalleryParam(
        name: 'note',
        label: 'Note',
        type: ParamType.stringType,
        defaultValue: 'Dinner last Friday 🍕',
      ),
    ],
    builder: (ctx, p) => BankPaymentRequestCard(
      requesterId: 'u-1',
      requesterName: 'Alice Johnson',
      amount: Money.fromDouble(p['amount'] as double, 'GBP'),
      note: (p['note'] as String).isEmpty ? null : p['note'] as String,
      requestedAt: DateTime(2026, 6, 27),
      onAccept: () {},
      onDecline: () {},
    ),
  ),

  GalleryEntry(
    name: 'BankScheduledTransferToggle',
    description: 'Segmented control for instant / later / recurring timing.',
    category: GalleryCategory.transfers,
    isFullScreen: true,
    codeExample: '''BankScheduledTransferToggle(
  selected: BankTransferTiming.instant,
  onChanged: (t) => setState(() => timing = t),
)''',
    params: [],
    builder: (ctx, p) => _StatefulWrapper<BankTransferTiming>(
      initial: BankTransferTiming.instant,
      builder: (val, set) => BankScheduledTransferToggle(
        selected: val,
        onChanged: set,
      ),
    ),
  ),

  GalleryEntry(
    name: 'BankAmountKeypad',
    description: 'Numeric keypad for entering transfer amounts.',
    category: GalleryCategory.transfers,
    isFullScreen: true,
    codeExample: '''BankAmountKeypad(
  currencyCode: 'GBP',
  onChanged: (v) => setState(() => amount = v),
)''',
    params: [
      const GalleryParam(
        name: 'currencyCode',
        label: 'Currency',
        type: ParamType.enumType,
        defaultValue: 'GBP',
        enumValues: ['GBP', 'USD', 'EUR', 'AED'],
      ),
    ],
    builder: (ctx, p) => _StatefulWrapper<String>(
      initial: '0',
      builder: (amtText, setAmt) => BankAmountKeypad(
        amountText: amtText,
        currencyCode: p['currencyCode'] as String,
        onDigit: (d) => setAmt(amtText == '0' ? d : amtText + d),
        onDelete: () =>
            setAmt(amtText.length <= 1 ? '0' : amtText.substring(0, amtText.length - 1)),
      ),
    ),
  ),

  GalleryEntry(
    name: 'BankBeneficiaryPicker',
    description: 'Searchable list of saved payment beneficiaries.',
    category: GalleryCategory.transfers,
    isFullScreen: true,
    codeExample: '''BankBeneficiaryPicker(
  beneficiaries: myBeneficiaries,
  onSelected: (b) => proceed(b),
)''',
    params: [],
    builder: (ctx, p) => BankBeneficiaryPicker(
      beneficiaries: [
        _beneficiary(),
        const BankBeneficiary(
          id: 'ben-2',
          name: 'Bob Smith',
          maskedAccount: '•••• 9012',
          type: BeneficiaryType.bankTransfer,
          isVerified: false,
        ),
      ],
      onSelected: (_) {},
    ),
  ),

  GalleryEntry(
    name: 'BankTransferResultScreen',
    description: 'Full-screen success / failure screen after a transfer.',
    category: GalleryCategory.transfers,
    codeExample: '''BankTransferResultScreen(
  amount: Money.fromDouble(500, 'GBP'),
  beneficiaryName: 'Alice Johnson',
  isSuccess: true,
  onDone: () => navigator.popUntil(isHome),
)''',
    params: [
      const GalleryParam(
        name: 'isSuccess',
        label: 'Transfer succeeded',
        type: ParamType.boolType,
        defaultValue: true,
      ),
      const GalleryParam(
        name: 'amount',
        label: 'Amount (GBP)',
        type: ParamType.doubleType,
        defaultValue: 500.0,
        min: 1,
        max: 5000,
      ),
    ],
    builder: (ctx, p) => BankTransferResultScreen(
      amount: Money.fromDouble(p['amount'] as double, 'GBP'),
      beneficiaryName: 'Alice Johnson',
      isSuccess: p['isSuccess'] as bool,
      onDone: () {},
    ),
  ),

  // ── AUTH ──────────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankPinKeypad',
    description: 'Telephone-layout numeric keypad for PIN entry.',
    category: GalleryCategory.auth,
    codeExample: '''BankPinKeypad(
  onDigit: (d) => setState(() => pin += d),
  onDelete: () => setState(() {
    if (pin.isNotEmpty) pin = pin.substring(0, pin.length - 1);
  }),
  onBiometric: _launchBiometric,
)''',
    params: [
      const GalleryParam(
        name: 'enabled',
        label: 'Enabled',
        type: ParamType.boolType,
        defaultValue: true,
      ),
      const GalleryParam(
        name: 'showBiometric',
        label: 'Show biometric button',
        type: ParamType.boolType,
        defaultValue: true,
      ),
    ],
    builder: (ctx, p) => BankPinKeypad(
      onDigit: (_) {},
      onDelete: () {},
      enabled: p['enabled'] as bool,
      onBiometric: (p['showBiometric'] as bool) ? () {} : null,
    ),
  ),

  GalleryEntry(
    name: 'BankPinDots',
    description: 'Row of obscured dots indicating entered PIN digits.',
    category: GalleryCategory.auth,
    codeExample: '''BankPinDots(
  length: 6,
  filled: _pin.length,
  error: _wrongPin,
)''',
    params: [
      const GalleryParam(
        name: 'length',
        label: 'PIN length',
        type: ParamType.intType,
        defaultValue: 6,
        min: 4,
        max: 8,
      ),
      const GalleryParam(
        name: 'filled',
        label: 'Digits entered',
        type: ParamType.intType,
        defaultValue: 3,
        min: 0,
        max: 8,
      ),
      const GalleryParam(
        name: 'error',
        label: 'Error (shake)',
        type: ParamType.boolType,
        defaultValue: false,
      ),
    ],
    builder: (ctx, p) {
      final length = (p['length'] as int).clamp(4, 8);
      final filled = (p['filled'] as int).clamp(0, length);
      return BankPinDots(
        length: length,
        filled: filled,
        error: p['error'] as bool,
      );
    },
  ),

  GalleryEntry(
    name: 'BankPrivacyToggle',
    description: 'Icon button toggling balance masking via BankUiScope.',
    category: GalleryCategory.auth,
    codeExample: 'BankPrivacyToggle()',
    params: [],
    builder: (ctx, p) => const BankPrivacyToggle(),
  ),

  GalleryEntry(
    name: 'BankDeviceTrustBanner',
    description: 'Security banner for new-device or compromised-device alerts.',
    category: GalleryCategory.auth,
    isFullScreen: true,
    codeExample: '''BankDeviceTrustBanner(
  state: BankDeviceTrustState.newDevice,
  onDismiss: () {},
)''',
    params: [
      GalleryParam(
        name: 'state',
        label: 'Trust state',
        type: ParamType.enumType,
        defaultValue: 'newDevice',
        enumValues: BankDeviceTrustState.values.map(_enumLabel).toList(),
      ),
    ],
    builder: (ctx, p) => BankDeviceTrustBanner(
      state: _trustState(p['state'] as String),
      onDismiss: () {},
      onLearnMore: () {},
    ),
  ),

  GalleryEntry(
    name: 'BankBiometricPromptButton',
    description: 'Fingerprint / Face ID authentication button.',
    category: GalleryCategory.auth,
    codeExample: '''BankBiometricPromptButton(
  onAuthenticated: () => proceed(),
)''',
    params: [],
    builder: (ctx, p) => BankBiometricPromptButton(onAuthenticate: () async => true),
  ),

  GalleryEntry(
    name: 'BankSessionTimeoutDialog',
    description: 'Countdown dialog warning the user of imminent session expiry.',
    category: GalleryCategory.auth,
    codeExample: '''BankSessionTimeoutDialog.show(
  context,
  onExtend: () {},
  onLogout: () => logOut(),
)''',
    params: [],
    builder: (ctx, p) => _SheetOpener(
      label: 'Open Session Timeout Dialog',
      onOpen: (c) => showDialog<void>(
        context: c,
        builder: (_) => BankSessionTimeoutDialog(
          remainingTime: const Duration(minutes: 2),
          onExtend: () => Navigator.of(c).pop(),
          onLogout: () => Navigator.of(c).pop(),
        ),
      ),
    ),
  ),

  // ── STATES ────────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankSkeletonLoader',
    description: 'Shimmer placeholder matching common Bank UI Kit card shapes.',
    category: GalleryCategory.states,
    isFullScreen: true,
    codeExample: '''BankSkeletonLoader(
  variant: BankSkeletonVariant.transactionTile,
  count: 4,
)''',
    params: [
      GalleryParam(
        name: 'variant',
        label: 'Variant',
        type: ParamType.enumType,
        defaultValue: 'transactionTile',
        enumValues: BankSkeletonVariant.values.map(_enumLabel).toList(),
      ),
      const GalleryParam(
        name: 'count',
        label: 'Count',
        type: ParamType.intType,
        defaultValue: 3,
        min: 1,
        max: 6,
      ),
    ],
    builder: (ctx, p) => BankSkeletonLoader(
      variant: _skelVariant(p['variant'] as String),
      count: p['count'] as int,
    ),
  ),

  GalleryEntry(
    name: 'BankEmptyStateView',
    description: 'Centred empty-state with title, subtitle, and optional CTA.',
    category: GalleryCategory.states,
    codeExample: '''BankEmptyStateView(
  title: 'No transactions yet',
  subtitle: 'Your payments will appear here.',
  actionLabel: 'Make a Payment',
  onAction: () {},
)''',
    params: [
      const GalleryParam(
        name: 'title',
        label: 'Title',
        type: ParamType.stringType,
        defaultValue: 'No transactions yet',
      ),
      const GalleryParam(
        name: 'subtitle',
        label: 'Subtitle',
        type: ParamType.stringType,
        defaultValue: 'Your payments will appear here.',
      ),
      const GalleryParam(
        name: 'showAction',
        label: 'Show action button',
        type: ParamType.boolType,
        defaultValue: true,
      ),
    ],
    builder: (ctx, p) => BankEmptyStateView(
      title: p['title'] as String,
      subtitle: (p['subtitle'] as String).isEmpty
          ? null
          : p['subtitle'] as String,
      actionLabel: (p['showAction'] as bool) ? 'Make a Payment' : null,
      onAction: (p['showAction'] as bool) ? () {} : null,
    ),
  ),

  GalleryEntry(
    name: 'BankErrorStateView',
    description: 'Error state with retry and optional contact-support action.',
    category: GalleryCategory.states,
    codeExample: '''BankErrorStateView(
  title: 'Something went wrong',
  message: 'Please check your connection and retry.',
  retryLabel: 'Retry',
  onRetry: () => reload(),
)''',
    params: [
      const GalleryParam(
        name: 'title',
        label: 'Title',
        type: ParamType.stringType,
        defaultValue: 'Something went wrong',
      ),
      const GalleryParam(
        name: 'message',
        label: 'Message',
        type: ParamType.stringType,
        defaultValue: 'Please check your connection and retry.',
      ),
      const GalleryParam(
        name: 'showSupport',
        label: 'Show support button',
        type: ParamType.boolType,
        defaultValue: true,
      ),
    ],
    builder: (ctx, p) => BankErrorStateView(
      title: p['title'] as String,
      message: p['message'] as String,
      retryLabel: 'Retry',
      onRetry: () {},
      supportLabel: (p['showSupport'] as bool) ? 'Contact Support' : null,
      onContactSupport: (p['showSupport'] as bool) ? () {} : null,
    ),
  ),

  GalleryEntry(
    name: 'BankSuccessAnimation',
    description: 'Animated checkmark circle with optional confetti burst.',
    category: GalleryCategory.states,
    codeExample: '''BankSuccessAnimation(
  size: 80,
  showConfetti: true,
  label: Text('Payment sent!'),
)''',
    params: [
      const GalleryParam(
        name: 'size',
        label: 'Size (px)',
        type: ParamType.doubleType,
        defaultValue: 80.0,
        min: 40,
        max: 160,
      ),
      const GalleryParam(
        name: 'showConfetti',
        label: 'Show confetti',
        type: ParamType.boolType,
        defaultValue: true,
      ),
    ],
    builder: (ctx, p) => BankSuccessAnimation(
      size: p['size'] as double,
      showConfetti: p['showConfetti'] as bool,
      label: const Text('Payment sent!'),
    ),
  ),

  GalleryEntry(
    name: 'BankToastBanner',
    description: 'Slide-in toast banner with auto-dismiss.',
    category: GalleryCategory.states,
    isFullScreen: true,
    codeExample: '''BankToastBanner(
  variant: BankToastVariant.success,
  message: 'Payment sent successfully.',
  isVisible: _show,
  onDismiss: () => setState(() => _show = false),
)''',
    params: [
      GalleryParam(
        name: 'variant',
        label: 'Variant',
        type: ParamType.enumType,
        defaultValue: 'success',
        enumValues: BankToastVariant.values.map(_enumLabel).toList(),
      ),
      const GalleryParam(
        name: 'message',
        label: 'Message',
        type: ParamType.stringType,
        defaultValue: 'Payment sent successfully.',
      ),
    ],
    builder: (ctx, p) => _StatefulWrapper<bool>(
      initial: true,
      builder: (visible, set) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BankToastBanner(
            variant: _toastVariant(p['variant'] as String),
            message: p['message'] as String,
            isVisible: visible,
            onDismiss: () => set(false),
          ),
          if (!visible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => set(true),
                child: const Text('Show toast again'),
              ),
            ),
        ],
      ),
    ),
  ),

  GalleryEntry(
    name: 'BankFraudAlertBanner',
    description: 'High-urgency fraud alert banner with primary and dismiss.',
    category: GalleryCategory.states,
    isFullScreen: true,
    codeExample: '''BankFraudAlertBanner(
  title: 'Suspicious activity detected',
  body: 'An unusual payment was attempted.',
  primaryActionLabel: 'Secure My Account',
  dismissLabel: 'Dismiss',
  onPrimaryAction: () {},
  onDismiss: () {},
)''',
    params: [
      const GalleryParam(
        name: 'title',
        label: 'Title',
        type: ParamType.stringType,
        defaultValue: 'Suspicious activity detected',
      ),
    ],
    builder: (ctx, p) => BankFraudAlertBanner(
      title: p['title'] as String,
      body: 'An unusual payment of £850 was attempted on your account.',
      primaryActionLabel: 'Secure My Account',
      dismissLabel: 'Dismiss',
      onPrimaryAction: () {},
      onDismiss: () {},
    ),
  ),

  // ── INSIGHTS ──────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankSpendingBreakdownChart',
    description: 'Interactive donut chart showing spending by category.',
    category: GalleryCategory.insights,
    codeExample: '''BankSpendingBreakdownChart(
  categories: [
    BankSpendingCategory(
      category: TransactionCategory.dining,
      amount: Money.fromDouble(142, 'GBP'),
    ),
    ...
  ],
)''',
    params: [],
    builder: (ctx, p) => SizedBox(
      height: 300,
      child: BankSpendingBreakdownChart(
        categories: [
          BankSpendingCategory(
            category: TransactionCategory.dining,
            amount: Money.fromDouble(142, 'GBP'),
          ),
          BankSpendingCategory(
            category: TransactionCategory.groceries,
            amount: Money.fromDouble(220, 'GBP'),
          ),
          BankSpendingCategory(
            category: TransactionCategory.transport,
            amount: Money.fromDouble(85, 'GBP'),
          ),
          BankSpendingCategory(
            category: TransactionCategory.shopping,
            amount: Money.fromDouble(310, 'GBP'),
          ),
          BankSpendingCategory(
            category: TransactionCategory.entertainment,
            amount: Money.fromDouble(65, 'GBP'),
          ),
        ],
      ),
    ),
  ),

  GalleryEntry(
    name: 'BankBudgetGaugeWidget',
    description: 'Animated bar showing budget spent vs. limit.',
    category: GalleryCategory.insights,
    isFullScreen: true,
    codeExample: '''BankBudgetGaugeWidget(
  budget: BankBudget(name: 'Groceries', limit: ..., spent: ..., ...),
)''',
    params: [
      const GalleryParam(
        name: 'fraction',
        label: 'Spent fraction (0–1.2)',
        type: ParamType.doubleType,
        defaultValue: 0.65,
        min: 0,
        max: 1.2,
      ),
    ],
    builder: (ctx, p) => BankBudgetGaugeWidget(
      budget: _budget(fraction: p['fraction'] as double),
    ),
  ),

  GalleryEntry(
    name: 'BankInsightCard',
    description: 'AI-generated insight card with confidence indicator.',
    category: GalleryCategory.insights,
    isFullScreen: true,
    codeExample: '''BankInsightCard(
  insight: BankInsight(
    title: 'Spending up 18% on dining',
    body: 'You spent £142 on restaurants this month.',
    confidence: InsightConfidence.high,
    ...
  ),
  onDismiss: () {},
)''',
    params: [
      GalleryParam(
        name: 'confidence',
        label: 'Confidence',
        type: ParamType.enumType,
        defaultValue: 'high',
        enumValues: InsightConfidence.values.map(_enumLabel).toList(),
      ),
    ],
    builder: (ctx, p) => BankInsightCard(
      insight: _insight(confidence: _confidence(p['confidence'] as String)),
      onDismiss: () {},
      actionLabel: 'View details',
      onAction: () {},
    ),
  ),

  // ── ONBOARDING ────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankStepProgressIndicator',
    description: 'Step indicator for multi-step onboarding flows.',
    category: GalleryCategory.onboarding,
    isFullScreen: true,
    codeExample: '''BankStepProgressIndicator(
  totalSteps: 5,
  currentStep: 2,
  showLabels: true,
)''',
    params: [
      const GalleryParam(
        name: 'totalSteps',
        label: 'Total steps',
        type: ParamType.intType,
        defaultValue: 5,
        min: 2,
        max: 8,
      ),
      const GalleryParam(
        name: 'currentStep',
        label: 'Current step',
        type: ParamType.intType,
        defaultValue: 2,
        min: 1,
        max: 8,
      ),
      const GalleryParam(
        name: 'showLabels',
        label: 'Show labels',
        type: ParamType.boolType,
        defaultValue: true,
      ),
    ],
    builder: (ctx, p) {
      final total = (p['totalSteps'] as int).clamp(2, 8);
      final current = (p['currentStep'] as int).clamp(1, total);
      return BankStepProgressIndicator(
        totalSteps: total,
        currentStep: current,
        showLabels: p['showLabels'] as bool,
        labels: const ['ID', 'Selfie', 'Address', 'Review', 'Phone',
            'Terms', 'Code', 'Done']
            .take(total)
            .toList(),
      );
    },
  ),

  GalleryEntry(
    name: 'BankAsyncVerificationState',
    description: '"Under review" widget for async KYC processing states.',
    category: GalleryCategory.onboarding,
    codeExample: '''BankAsyncVerificationState(
  title: 'Verification Under Review',
  message: 'We are checking your documents…',
  estimatedTime: '1–2 business days',
  onCheckStatus: () => refreshStatus(),
)''',
    params: [
      const GalleryParam(
        name: 'title',
        label: 'Title',
        type: ParamType.stringType,
        defaultValue: 'Verification Under Review',
      ),
      const GalleryParam(
        name: 'estimatedTime',
        label: 'Estimated time',
        type: ParamType.stringType,
        defaultValue: '1–2 business days',
      ),
    ],
    builder: (ctx, p) => BankAsyncVerificationState(
      title: p['title'] as String,
      estimatedTime: p['estimatedTime'] as String,
      onCheckStatus: () {},
      onContactSupport: () {},
    ),
  ),

  GalleryEntry(
    name: 'BankConsentModal',
    description: 'Scrollable consent sheet with terms and accept button.',
    category: GalleryCategory.onboarding,
    codeExample: '''BankConsentModal.show(
  context,
  title: 'Terms & Conditions',
  body: termsText,
  onAccept: () => proceed(),
)''',
    params: [],
    builder: (ctx, p) => _SheetOpener(
      label: 'Open Consent Modal',
      onOpen: (c) => BankConsentModal.show(
        c,
        title: 'Terms & Conditions',
        termsContent: 'By continuing you agree to our Terms of Service and Privacy '
            'Policy. We will process your personal data in accordance with '
            'applicable data protection laws including GDPR. '
            'You may withdraw consent at any time by contacting support.',
        onAccept: () => Navigator.of(c).pop(),
        onDecline: () => Navigator.of(c).pop(),
      ),
    ),
  ),

  // ── SAVING ────────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankSavingsPotCard',
    description: 'Pot card with circular progress ring and interest badge.',
    category: GalleryCategory.saving,
    codeExample: '''BankSavingsPotCard(
  pot: SavingsPot(
    name: 'Holiday Fund',
    target: Money.fromDouble(3000, 'GBP'),
    current: Money.fromDouble(1860, 'GBP'),
    ...
  ),
  onTap: () => openPotDetail(),
)''',
    params: [
      const GalleryParam(
        name: 'progress',
        label: 'Progress (0–1)',
        type: ParamType.doubleType,
        defaultValue: 0.62,
        min: 0,
        max: 1,
      ),
    ],
    builder: (ctx, p) => BankSavingsPotCard(
      pot: _pot(progress: p['progress'] as double),
      onTap: () {},
    ),
  ),

  GalleryEntry(
    name: 'BankPotContributionSheet',
    description: 'Bottom sheet for adding or withdrawing pot funds.',
    category: GalleryCategory.saving,
    codeExample: '''BankPotContributionSheet.show(
  context,
  pot: myPot,
  onContribute: (amount) {},
  onWithdraw: (amount) {},
)''',
    params: [],
    builder: (ctx, p) => _SheetOpener(
      label: 'Open Contribution Sheet',
      onOpen: (c) => BankPotContributionSheet.show(
        c,
        pot: _pot(),
        onConfirm: (_) async => Navigator.of(c).pop(),
      ),
    ),
  ),

  // ── SOCIAL ────────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankJointTransactionListTile',
    description: 'Transaction tile showing spender avatar for joint accounts.',
    category: GalleryCategory.social,
    isFullScreen: true,
    codeExample: '''BankJointTransactionListTile(
  transaction: jointTx,
  onTap: () => openDetail(),
)''',
    params: [
      const GalleryParam(
        name: 'isCredit',
        label: 'Incoming (credit)',
        type: ParamType.boolType,
        defaultValue: false,
      ),
    ],
    builder: (ctx, p) => BankJointTransactionListTile(
      transaction: Transaction(
        id: 'j-tx-1',
        amount: Money.fromDouble(
          (p['isCredit'] as bool) ? 45.0 : -22.50,
          'GBP',
        ),
        settledAt: DateTime(2026, 6, 28),
        status: TransactionStatus.cleared,
        merchantName: 'Tesco',
        category: TransactionCategory.groceries,
        spenderId: 'u-2',
        spenderName: 'Alice',
      ),
    ),
  ),

  GalleryEntry(
    name: 'BankAccountOwnershipBadge',
    description: 'Compact badge showing joint-account co-owner names.',
    category: GalleryCategory.social,
    codeExample: '''BankAccountOwnershipBadge(
  ownerNames: ['You', 'Alice Johnson'],
)''',
    params: [],
    builder: (ctx, p) => const BankAccountOwnershipBadge(
      role: BankOwnershipRole.joint,
    ),
  ),

  GalleryEntry(
    name: 'BankSharedGoalProgressCard',
    description: 'Shared savings goal card with multi-member contributor list.',
    category: GalleryCategory.social,
    codeExample: '''BankSharedGoalProgressCard(
  goalName: 'Family Holiday',
  targetAmount: Money.fromDouble(5000, 'GBP'),
  savedAmount: Money.fromDouble(3200, 'GBP'),
)''',
    params: [
      const GalleryParam(
        name: 'progress',
        label: 'Progress (0–1)',
        type: ParamType.doubleType,
        defaultValue: 0.64,
        min: 0,
        max: 1,
      ),
    ],
    builder: (ctx, p) {
      const target = 5000.0;
      return BankSharedGoalProgressCard(
        goalName: 'Family Holiday',
        targetAmount: Money.fromDouble(target, 'GBP'),
        savedAmount: Money.fromDouble(
          target * (p['progress'] as double),
          'GBP',
        ),
      );
    },
  ),

  // ── INVESTING ─────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankPortfolioPerformanceChart',
    description: 'Line chart of portfolio value over time with range selector.',
    category: GalleryCategory.investing,
    codeExample: '''BankPortfolioPerformanceChart(
  dataPoints: [BankChartDataPoint(timestamp: t, value: v), ...],
  showGrid: true,
)''',
    params: [
      const GalleryParam(
        name: 'showGrid',
        label: 'Show grid',
        type: ParamType.boolType,
        defaultValue: true,
      ),
    ],
    builder: (ctx, p) => SizedBox(
      height: 240,
      child: BankPortfolioPerformanceChart(
        showGrid: p['showGrid'] as bool,
        dataPoints: _sampleChartData(),
      ),
    ),
  ),

  GalleryEntry(
    name: 'BankHoldingsListTile',
    description: 'Holding row showing symbol, value, and gain/loss.',
    category: GalleryCategory.investing,
    isFullScreen: true,
    codeExample: '''BankHoldingsListTile(
  holding: Holding(symbol: 'AAPL', ...),
  onTap: () => openAsset(),
)''',
    params: [
      const GalleryParam(
        name: 'gainPercent',
        label: 'Gain/loss %',
        type: ParamType.doubleType,
        defaultValue: 12.4,
        min: -30,
        max: 60,
      ),
    ],
    builder: (ctx, p) => BankHoldingsListTile(
      holding: _holding(gainPercent: p['gainPercent'] as double),
    ),
  ),

  GalleryEntry(
    name: 'BankAssetPriceTicker',
    description: 'Animated price ticker showing live asset price change.',
    category: GalleryCategory.investing,
    isFullScreen: true,
    codeExample: '''BankAssetPriceTicker(
  symbol: 'AAPL',
  price: Money.fromDouble(182.34, 'USD'),
  changePercent: 1.23,
)''',
    params: [
      const GalleryParam(
        name: 'symbol',
        label: 'Symbol',
        type: ParamType.stringType,
        defaultValue: 'AAPL',
      ),
      const GalleryParam(
        name: 'price',
        label: 'Price (USD)',
        type: ParamType.doubleType,
        defaultValue: 182.34,
        min: 1,
        max: 500,
      ),
      const GalleryParam(
        name: 'changePercent',
        label: 'Change %',
        type: ParamType.doubleType,
        defaultValue: 1.23,
        min: -10,
        max: 10,
      ),
    ],
    builder: (ctx, p) => BankAssetPriceTicker(
      quote: AssetQuote(
        symbol: p['symbol'] as String,
        name: 'Apple Inc.',
        price: Money.fromDouble(p['price'] as double, 'USD'),
        changePercent: p['changePercent'] as double,
      ),
    ),
  ),

  GalleryEntry(
    name: 'BankWatchlistCard',
    description: 'Compact card for a single watchlist asset.',
    category: GalleryCategory.investing,
    codeExample: '''BankWatchlistCard(
  quote: AssetQuote(symbol: 'TSLA', price: ..., changePercent: -0.8, ...),
  onTap: () => openAssetDetail(),
)''',
    params: [
      const GalleryParam(
        name: 'changePercent',
        label: 'Change %',
        type: ParamType.doubleType,
        defaultValue: 1.2,
        min: -10,
        max: 10,
      ),
    ],
    builder: (ctx, p) => BankWatchlistCard(
      quote: AssetQuote(
        symbol: 'TSLA',
        name: 'Tesla Inc.',
        price: Money.fromDouble(248.50, 'USD'),
        changePercent: p['changePercent'] as double,
      ),
      onTap: () {},
    ),
  ),

  // ── CREDIT ────────────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankCreditLimitGauge',
    description: 'Arc gauge showing used vs. total credit limit.',
    category: GalleryCategory.credit,
    codeExample: '''BankCreditLimitGauge(
  used: Money.fromDouble(800, 'GBP'),
  limit: Money.fromDouble(3000, 'GBP'),
)''',
    params: [
      const GalleryParam(
        name: 'used',
        label: 'Used (GBP)',
        type: ParamType.doubleType,
        defaultValue: 800.0,
        min: 0,
        max: 3000,
      ),
      const GalleryParam(
        name: 'limit',
        label: 'Limit (GBP)',
        type: ParamType.doubleType,
        defaultValue: 3000.0,
        min: 500,
        max: 10000,
      ),
    ],
    builder: (ctx, p) => BankCreditLimitGauge(
      usedAmount: Money.fromDouble(p['used'] as double, 'GBP'),
      creditLimit: Money.fromDouble(p['limit'] as double, 'GBP'),
    ),
  ),

  GalleryEntry(
    name: 'BankFlexEligibleBadge',
    description: 'Badge indicating a transaction is BNPL-splittable.',
    category: GalleryCategory.credit,
    codeExample: 'BankFlexEligibleBadge()',
    params: [],
    builder: (ctx, p) => const BankFlexEligibleBadge(),
  ),

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────

  GalleryEntry(
    name: 'BankInAppNotificationCenter',
    description: 'Swipeable notification feed with read/unread state.',
    category: GalleryCategory.notifications,
    isFullScreen: true,
    codeExample: '''BankInAppNotificationCenter(
  notifications: myNotifications,
  onDismiss: (n) => markDismissed(n),
  onMarkAllRead: () => markAllRead(),
)''',
    params: [
      const GalleryParam(
        name: 'count',
        label: 'Notification count',
        type: ParamType.intType,
        defaultValue: 5,
        min: 0,
        max: 10,
      ),
    ],
    builder: (ctx, p) {
      final count = p['count'] as int;
      final types = BankNotificationType.values;
      return BankInAppNotificationCenter(
        notifications: List.generate(
          count,
          (i) => BankNotification(
            id: 'n-$i',
            type: types[i % types.length],
            title: _notifTitle(types[i % types.length]),
            body: 'Notification body for item $i.',
            receivedAt:
                DateTime(2026, 6, 28).subtract(Duration(hours: i * 3)),
            isRead: i % 3 == 0,
          ),
        ),
        onDismiss: (_) {},
        onNotificationTap: (_) {},
        onMarkAllRead: () {},
      );
    },
  ),
];

String _notifTitle(BankNotificationType type) => switch (type) {
      BankNotificationType.payment => 'Payment received',
      BankNotificationType.transfer => 'Transfer completed',
      BankNotificationType.security => 'Security alert',
      BankNotificationType.fraud => 'Suspicious activity',
      BankNotificationType.marketing => 'New offer available',
      BankNotificationType.system => 'System update',
      BankNotificationType.savingsGoal => 'Goal milestone reached',
      BankNotificationType.cardActivity => 'Card used',
      BankNotificationType.kycUpdate => 'Verification updated',
      BankNotificationType.priceAlert => 'Price alert triggered',
    };

List<BankChartDataPoint> _sampleChartData() {
  const baseValue = 12500.0;
  const values = [
    12000.0, 12200.0, 11800.0, 12400.0, 12800.0, 12600.0,
    13000.0, 13200.0, 12900.0, 13400.0, 13600.0, 13800.0,
    14000.0, 13700.0, 14200.0, 14500.0, 14300.0, 14800.0,
    15000.0, 14700.0, 15200.0, 15500.0, 15300.0, 15800.0,
    baseValue,
  ];
  return List.generate(
    values.length,
    (i) => BankChartDataPoint(
      timestamp: DateTime(2026, 6, 1).add(Duration(days: i)),
      value: values[i],
    ),
  );
}

// ---------------------------------------------------------------------------
// Utility widgets
// ---------------------------------------------------------------------------

class _StatefulWrapper<T> extends StatefulWidget {
  const _StatefulWrapper({
    required this.initial,
    required this.builder,
  });

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_StatefulWrapper<T>> createState() => _StatefulWrapperState<T>();
}

class _StatefulWrapperState<T> extends State<_StatefulWrapper<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

class _SheetOpener extends StatelessWidget {
  const _SheetOpener({required this.label, required this.onOpen});

  final String label;
  final Future<dynamic> Function(BuildContext ctx) onOpen;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(label),
        onPressed: () => onOpen(context),
      );
}
