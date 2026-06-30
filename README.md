# Bank UI Kit

A production-grade Flutter UI component library for mobile banking and fintech apps.

> **License:** License TBD — not yet for production use.

---

## Why Bank UI Kit instead of a screen-template kit?

| | Bank UI Kit | Typical screen-template kits |
|---|---|---|
| **Integration model** | Compose into any existing app | Copy-paste full screens |
| **RTL support** | First-class, every widget | Mirror-on-demand or none |
| **Accessibility** | WCAG 2.1 AA, 44×44px targets | Not specified |
| **State management** | Agnostic (pure props + callbacks) | Tied to template's choice |
| **Customization** | `copyWith` + `itemBuilder` overrides everywhere | Fork the package |
| **License** | Commercial-friendly (TBD) | CodeCanyon one-time, non-redistributable |
| **Testing** | Golden + widget tests across presets × modes × directions | None |

---

## Installation

```yaml
dependencies:
  bank_ui_kit:
    git:
      url: https://github.com/sayed3li97/bank-ui-kit.git
```

Import only what your app uses:

```dart
import 'package:bank_ui_kit/core.dart';    // accounts, transactions, transfers, cards, security, states
import 'package:bank_ui_kit/saving.dart';  // pots, round-ups, income sorter
import 'package:bank_ui_kit/social.dart';  // peer-to-peer, splitting, joint accounts
import 'package:bank_ui_kit/investing.dart'; // multi-currency, holdings, buy/sell
import 'package:bank_ui_kit/credit.dart';  // installments, perks, subscriptions
```

---

## Quick start

Wrap your app with `BankUiScope` and choose a preset:

```dart
MaterialApp(
  theme: BankPreset.studio.apply(ThemeData.light()),
  darkTheme: BankPreset.studio.apply(ThemeData.dark()),
  home: BankUiScope(
    initialData: const BankUiScopeData(preset: BankPreset.studio),
    child: MyApp(),
  ),
);
```

---

## Custom themes

Beyond the three built-in presets you can build a fully custom `BankThemeData`
from any brand colour — only `primary` and `brightness` are required, every
other token has a sensible default:

```dart
final myTheme = BankThemeData.custom(
  primary: const Color(0xFF0052CC),
  brightness: Brightness.light,
  // optionally override any token
  cardRadius: const BorderRadius.all(Radius.circular(20)),
  useGlow: true,
  glowColor: const Color(0x440052CC),
  fontFamily: 'MyBrandFont',
  accentGradient: const LinearGradient(
    colors: [Color(0xFF0052CC), Color(0xFF00B8D9)],
  ),
);

MaterialApp(
  theme: ThemeData.light(useMaterial3: true).withBankTheme(myTheme),
  darkTheme: ThemeData.dark(useMaterial3: true).withBankTheme(
    BankThemeData.custom(
      primary: const Color(0xFF4D9DFF),
      brightness: Brightness.dark,
    ),
  ),
);
```

`withBankTheme()` is an extension on `ThemeData` — it registers the extension
**and** synchronises the Material `ColorScheme` to your palette so Material
widgets and Bank UI Kit widgets stay consistent.

You can also start from a preset and `copyWith` just the fields that differ:

```dart
final tweaked = BankPreset.bloom
    .apply(ThemeData.light(useMaterial3: true))
    .extension<BankThemeData>()!
    .copyWith(
      primary: const Color(0xFFE91E63),
      cardRadius: const BorderRadius.all(Radius.circular(24)),
    );

MaterialApp(
  theme: ThemeData.light(useMaterial3: true).withBankTheme(tweaked),
);
```

---

## Design presets

Three runtime-switchable `ThemeExtension` presets:

### Voltage (`BankVoltageTheme`)
Dark-first, high-energy. Violet→cyan gradient accent, pill-shaped buttons, glow-based depth, spring-overshoot motion.

### Studio (`BankStudioTheme`) — **default**
Quiet and minimal. Warm off-white canvas, petrol accent used sparingly, hairline borders for elevation, 12px consistent radius.

### Bloom (`BankBloomTheme`)
Warm and optimistic. Coral primary, rounded corners everywhere, bouncy spring motion, confetti on successful transfers.

All presets ship light and dark modes, WCAG 2.1 AA contrast-verified.

---

## Data model contracts

Components accept plain Dart data classes. Map your backend data to these at the boundary:

```dart
final account = BankAccount(
  id: 'acc_001',
  name: 'Main Account',
  maskedNumber: '•••• 4242',
  balance: Money.fromDouble(1_234.56, 'GBP'),
  status: BankAccountStatus.active,
  type: BankAccountType.current,
  currencyCode: 'GBP',
);

BankAccountCard(account: account, onTap: () { ... })
```

---

## Override pattern

Every list widget accepts an `itemBuilder` override; every themed surface accepts `copyWith` on the preset:

```dart
// Custom transaction tile
BankTransactionListTile(
  transaction: tx,
  itemBuilder: (context, transaction) => MyCustomTile(transaction),
)

// Custom accent gradient on Voltage
theme: BankVoltageTheme.light().copyWith(
  accentGradient: LinearGradient(colors: [myBrand, myBrandSecondary]),
)
```

---

## Localization

The package ships English strings. Override any or all via `BankUiStrings`:

```dart
BankUiScope(
  initialData: BankUiScopeData(
    strings: BankUiStrings(
      today: 'Heute',
      yesterday: 'Gestern',
    ),
  ),
  child: ...,
)
```

No dependency on `gen-l10n` — host apps bring their own l10n tooling.

---

## NumeralStyle

Independent of locale, suitable for GCC apps that want Western numerals alongside Arabic UI:

```dart
BankUiScope(
  initialData: BankUiScopeData(numeralStyle: NumeralStyle.easternArabicIndic),
  child: ...,
)
```

---

## Islamic finance mode

Swaps interest/APR labels for profit-rate equivalents wherever a component renders label text:

```dart
BankUiScope(
  initialData: BankUiScopeData(islamicFinanceMode: true),
  child: ...,
)
```

---

## Privacy toggle

`BankPrivacyToggle` controls `BankUiScope.privacyEnabled`. Every `BankBalanceText` in the tree automatically masks or unmasks:

```dart
BankPrivacyToggle()  // tap to toggle; state propagates via BankUiScope
BankBalanceText(money: account.balance)  // masks to '••••' when privacy is on
```

---

## Component gallery

| Module | Components |
|---|---|
| **States** | BankSkeletonLoader, BankEmptyStateView, BankErrorStateView, BankSuccessAnimation, BankToastBanner |
| **Accounts** | BankAccountCard, BankAccountSwitcher, BankBalanceText |
| **Transactions** | BankTransactionListTile, BankTransactionGroupHeader, BankTransactionFilterSheet, BankTransactionDetailSheet, BankReceiptView, BankTransactionCostSplitSheet, BankTransactionCategorySplitSheet |
| **Transfers** | BankAmountKeypad, BankBeneficiaryPicker, BankTransferReviewCard, BankTransactionPinSheet, BankTransferResultScreen, BankScheduledTransferToggle, BankContactPaymentSheet, BankPaymentRequestCard |
| **Cards** | BankVirtualCardWidget, BankCardControlsPanel, BankCardPinManager, BankPhysicalCardMaterialPicker |
| **Security** | BankBiometricPromptButton, BankPinKeypad, BankPinDots, BankPrivacyToggle, BankAppSwitcherPrivacyOverlay, BankSessionTimeoutDialog, BankDeviceTrustBanner |
| **KYC** | BankStepProgressIndicator, BankDocumentCaptureOverlay, BankLivenessCheckOverlay, BankAsyncVerificationState, BankConsentModal |
| **Saving** | BankSavingsPotCard, BankRoundUpSettingsSheet, BankPotContributionSheet, BankIncomeSorterSheet, BankSharedPotInvite |
| **Social** | BankJointTransactionListTile, BankAccountOwnershipBadge, BankSharedGoalProgressCard, BankContactPaymentSheet, BankPaymentRequestCard, BankTransactionCostSplitSheet, BankTransactionCategorySplitSheet |
| **Investing** | BankCurrencyWalletTabBar, BankLiveExchangeConverter, BankAssetPriceTicker, BankHoldingsListTile, BankBuySellSheet, BankPortfolioPerformanceChart, BankWatchlistCard |
| **Credit** | BankInstallmentPlanSelector, BankFlexEligibleBadge, BankCreditLimitGauge, BankRepaymentScheduleView |
| **Subscriptions** | BankPlanComparisonTable, BankPaywallSheet, BankPerksMarketplaceCard, BankReferralInviteCard |
| **Insights** | BankSpendingBreakdownChart, BankBudgetGaugeWidget, BankInsightCard |
| **Notifications** | BankInAppNotificationCenter, BankFraudAlertBanner |

---

## Headless flow controllers

Complex multi-step flows are backed by headless controllers that manage state and emit sealed-class statuses, so you can swap the visual layer without losing flow logic:

- `BankKycFlowController` — document capture, liveness, review
- `BankTransferFlowController` — amount, beneficiary, review, PIN, result
- `BankIncomeSorterController` — split incoming payment across pots
