<div align="center">

# Bank UI Kit

### The Flutter front-end for digital banking.

Every surface a retail, Islamic, or business bank ships: onboarding to
servicing: as composable, bank-grade Flutter widgets. One codebase,
four built-in themes, your backend.

[![CI](https://github.com/sayed3li97/bank-ui-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/sayed3li97/bank-ui-kit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-027DFD.svg)](https://flutter.dev)
[![style: flutter_lints](https://img.shields.io/badge/style-flutter__lints-40c4ff.svg)](https://pub.dev/packages/flutter_lints)

**140+ components** · **22 banking domains** · **4 built-in themes** · **built toward WCAG 2.1 AA** · **RTL + Arabic-Indic numerals**

<br />

<table>
  <tr>
    <td align="center"><b>Heritage</b></td>
    <td align="center"><b>Studio</b></td>
    <td align="center"><b>Voltage</b></td>
    <td align="center"><b>Bloom</b></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/heritage-heritage-light.png" width="185" alt="Heritage preset" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/home-studio-light.png" width="185" alt="Studio preset" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/home-voltage-dark.png" width="185" alt="Voltage preset" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/home-bloom-light.png" width="185" alt="Bloom preset" /></td>
  </tr>
</table>

*The same widgets, four built-in themes. Rebrand in minutes, not quarters.*

</div>

---

## Contents

- [Why Bank UI Kit](#why-bank-ui-kit)
- [Install](#install)
- [Quick start](#quick-start)
- [Design presets](#design-presets)
- [Custom themes](#custom-themes)
- [Journeys, not just widgets](#journeys-not-just-widgets)
- [Component catalogue](#component-catalogue)
- [Full API reference](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/component-reference.md)
- [Cross-cutting features](#cross-cutting-features)
- [Architecture & principles](#architecture--principles)
- [Running the example](#running-the-example)
- [Contributing](#contributing)
- [License](#license)

---

## Why Bank UI Kit

**Coverage that reads like a banking platform.** Accounts, payments,
cards, onboarding and KYC, PFM and insights, lending, rewards, Islamic
banking, business-banking approvals, disputes, secure messaging,
statements: 140+ components across 22 domains, benchmarked against 21
of the world's leading banking apps so every surface they ship, you
can too.

**Compliance-ready patterns.** PSD2-style dynamic-linking approval,
open-banking consent management, deposit-protection notices, IBAN and
PAN checksum validation, semantics on every control, 44 px touch
targets, and first-class RTL with Arabic-Indic numeral rendering. The
kit implements the UX pattern; your bank provides the regulated
controls behind it. The division of responsibility is written down in
[docs/enterprise/compliance-matrix.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/enterprise/compliance-matrix.md),
and the accessibility position (verified vs on the roadmap) in
[docs/enterprise/accessibility-conformance.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/enterprise/accessibility-conformance.md).

**Four built-in themes, one theming engine.** Every widget reads its
colour, shape, depth, and numeral typography from `BankThemeData`
tokens. Ship the included presets, or derive a complete brand theme
from a single primary colour.

**Backend-agnostic by design.** Pure props and callbacks; headless flow
controllers (`ChangeNotifier` state machines) that never touch the
network. Your core banking APIs stay yours. One caveat, stated plainly:
widgets that accept image URLs resolve them with Flutter's standard
network image provider; injectable image resolution is on the roadmap
so fully air-gapped builds need no source changes.

### How it compares

| | Bank UI Kit | Typical screen-template kits |
|---|---|---|
| **Integration model** | Compose into any existing app | Copy-paste whole screens |
| **Theming** | 4 presets + fully custom themes, runtime-switchable | Fork the package |
| **RTL support** | First-class, every widget | Mirror-on-demand or none |
| **Accessibility** | Built toward WCAG 2.1 AA: 44×44 targets, semantics, documented conformance | Not specified |
| **State management** | Agnostic (pure props + callbacks) | Tied to the template's choice |
| **Money** | Lossless `Decimal`-backed `Money` type | `double` |
| **Tests** | Unit + widget tests across presets | None |

### One token change rebrands every surface

<p align="center">
  <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/diagrams/architecture-flow.svg" width="880" alt="Design tokens flow into four presets, into 140+ components, into your app" />
</p>

Tokens set color, shape, depth, and numeral typography once. Presets are
just token sets: swap one and every component follows, light and dark,
LTR and RTL. Your rebrand is a constructor argument, not a quarter.

---

## Install

```yaml
dependencies:
  bank_ui_kit:
    git:
      url: https://github.com/sayed3li97/bank-ui-kit.git
```

Import only the modules you use:

```dart
import 'package:bank_ui_kit/core.dart';       // accounts, transactions, transfers, cards, auth, states, insights…
import 'package:bank_ui_kit/saving.dart';     // pots, round-ups, income sorter
import 'package:bank_ui_kit/social.dart';     // joint accounts, shared goals, peer payments
import 'package:bank_ui_kit/investing.dart';  // wallets, holdings, buy/sell, charts
import 'package:bank_ui_kit/credit.dart';     // installments, credit gauges, subscriptions, perks
```

---

## Quick start

Wrap your app in a `BankUiScope` and apply a preset to your `ThemeData`:

```dart
import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BankUiScope(
      initialData: const BankUiScopeData(preset: BankPreset.studio),
      child: MaterialApp(
        theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        darkTheme: BankPreset.studio.apply(ThemeData.dark(useMaterial3: true)),
        home: const Dashboard(),
      ),
    );
  }
}
```

Then compose with the widgets:

```dart
BankBalanceText(money: account.balance, size: BankBalanceSize.hero),
BankVirtualCardWidget(account: account, cardholderName: 'ALEX MORGAN'),
BankTransactionListTile(transaction: tx, onTap: () { /* open detail */ }),
```

---

## Design presets

Four first-class presets ship in the box. Each defines a complete `BankThemeData`
(colours, shape radii, elevation/glow, brand font, numeral typography) in light **and** dark.

| Preset | Personality | Signature |
|---|---|---|
| **Studio** | Restrained, editorial | Petrol-green, soft-shadow depth, Space Grotesk |
| **Voltage** | Electric, dark-native | Violet→cyan gradient, pill shapes, glow depth |
| **Bloom** | Warm, consumer-friendly | Coral primary, fully-rounded, Nunito |
| **Heritage** | Institutional, Islamic-banking ready | Deep forest green + muted gold, pairs with `BankShariahBadge` and profit-rate labels |

Switch presets at runtime by changing the `ThemeData` you pass to `MaterialApp` -
every widget re-themes itself because it reads tokens from `BankThemeData.of(context)`.

<table>
  <tr>
    <td align="center">Accounts · Studio</td>
    <td align="center">Accounts · Voltage</td>
    <td align="center">Accounts · Bloom</td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/accounts-studio-light.png" width="240" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/accounts-voltage-dark.png" width="240" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/accounts-bloom-light.png" width="240" /></td>
  </tr>
</table>

### Heritage: the Islamic-banking preset

A complete demo app (`HeritageDashboard` in the example) built on the Heritage
preset: SAR balances, profit-rate labels via `islamicFinanceMode`,
`BankShariahBadge` on eligible products, and gold-accent virtual cards.

<table>
  <tr>
    <td align="center">Heritage · light</td>
    <td align="center">Heritage · dark</td>
    <td align="center">Home · Heritage</td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/heritage-heritage-light.png" width="240" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/heritage-heritage-dark.png" width="240" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/home-heritage-light.png" width="240" /></td>
  </tr>
</table>

Every component is also captured under all four presets: see
`docs/screenshots/components/` (Studio at the top level, plus
`heritage/`, `voltage/`, and `bloom/` sub-folders for theme-specific decks).

---

## Custom themes

Not limited to the four presets: build a fully custom theme from your brand colour.
Only `primary` and `brightness` are required; every other token has a sensible default.

```dart
final myTheme = BankThemeData.custom(
  primary: const Color(0xFF0052CC),
  brightness: Brightness.light,
  // optionally override any token:
  cardRadius: const BorderRadius.all(Radius.circular(20)),
  useGlow: true,
  glowColor: const Color(0x440052CC),
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

`withBankTheme()` registers the theme extension **and** synchronises the Material
`ColorScheme`, so Material widgets and Bank UI Kit widgets stay consistent.

You can also start from a preset and override just the fields that differ:

```dart
final tweaked = BankPreset.bloom
    .apply(ThemeData.light(useMaterial3: true))
    .extension<BankThemeData>()!
    .copyWith(primary: const Color(0xFFE91E63));
```

---

## Journeys, not just widgets

Components are designed to chain into complete, compliant banking
journeys. Below, a payment travels through five kit widgets while one
headless controller owns the state machine:

<p align="center">
  <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/diagrams/payment-journey.svg" width="880" alt="A payment journey composed from kit components over one headless flow controller" />
</p>

The same composition pattern covers every core journey. The full
catalogue of 25 journey blueprints (triggers, steps, variants, error
states) lives in [docs/banking-journeys.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/banking-journeys.md).

| Journey | Chain of kit components |
|---|---|
| Onboard a customer | `BankOnboardingCarousel` → `BankStepProgressIndicator` → `BankDocumentCaptureOverlay` → `BankLivenessCheckOverlay` → `BankAsyncVerificationState` → `BankSuccessAnimation` |
| Pay a bill | `BankBillForecastList` → `BankBillPayTile` → `BankAmountInputField` → `BankTransferReviewCard` → `BankScaApprovalSheet` → `BankReceiptView` |
| Send money to a friend | `BankBeneficiaryPicker` → `BankAmountKeypad` → `BankTransferReviewCard` → `BankTransactionPinSheet` → `BankTransferResultScreen` |
| Recover a lost card | `BankPanicFreezeButton` → `BankCardControlsPanel` → `BankDisposableCardTile` → `BankPhysicalCardMaterialPicker` → `BankStatusTracker` |
| Grow savings | `BankFinancialHealthScore` → `BankSavingsPotCard` → `BankRoundUpSettingsSheet` → `BankSavingsChallengeCard` → `BankSharedPotInvite` |
| Dispute a charge | `BankTransactionDetailSheet` → `BankDisputeWizardSheet` → `BankSecureMessageThread` → `BankStatusTracker` → `BankInAppNotificationCenter` |

---

## Component catalogue

140+ widgets across 22 modules. Each screenshot below is a live render of that module's
showcase screen (Studio preset, light mode) from the example app.

For the full parameter-level API reference (every constructor argument, type, required/optional status, and default value) see **[docs/component-reference.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/component-reference.md)**.

### States & feedback
`BankSkeletonLoader` · `BankEmptyStateView` · `BankErrorStateView` · `BankSuccessAnimation` · `BankToastBanner` · `BankFraudAlertBanner` · `BankAppGateScreen` (11 gate reasons: maintenance, force update, root/VPN blocks, waiting room) · `BankConnectivityBanner` · `BankServiceStatusList` · `BankUpdatePromptSheet`

<img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/states-studio-light.png" width="260" align="right" />

### Accounts & balances
`BankAccountCard` · `BankAccountSwitcher` · `BankBalanceText` (privacy-aware) · `BankProductItemTile` · `BankAccountNumberText` · `BankPeekBalance` (pre-login peek) · `BankEarlyPaydayCard`

### Transactions
`BankTransactionListTile` · `BankTransactionGroupHeader` · `BankTransactionDetailSheet` · `BankTransactionFilterSheet` · `BankReceiptView` · `BankTransactionCostSplitSheet` · `BankTransactionCategorySplitSheet`

<br clear="right" />

| Transactions | Transfers | Cards |
|---|---|---|
| <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/transactions-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/transfers-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/cards-studio-light.png" width="230" /> |

**Transfers & payments**: `BankAmountKeypad` · `BankBeneficiaryPicker` · `BankTransferReviewCard` · `BankTransactionPinSheet` · `BankScheduledTransferToggle` · `BankPaymentRequestCard` · `BankTransferResultScreen` · `BankContactPaymentSheet`

**Cards**: `BankFlipCard` · `BankHorizontalAccountCard` · `BankVirtualCardWidget` (flat / gradient / mesh / metallic / image) · `BankCardControlsPanel` · `BankCardPinManager` · `BankPhysicalCardMaterialPicker` · `BankDisposableCardTile` (single-use) · `BankMerchantBlockList` (self-exclusion) · `BankFamilyCardTile` (teen cards)

### Flip cards

Smooth 3-D perspective flip animation revealing the account details on the back face.
Three trigger modes, two flip axes, three front-face layouts, and three background modes
ship in the box: all backward-compatible and opt-in.

<table>
  <tr>
    <td align="center">Cards · Studio</td>
    <td align="center">Cards · Voltage</td>
    <td align="center">Cards · Bloom</td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/cards-studio-light.png" width="230" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/cards-voltage-dark.png" width="230" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/cards-bloom-light.png" width="230" /></td>
  </tr>
</table>

#### `BankFlipCard`: generic flip container

Wraps any two widgets in a perspective flip. Use it for any two-sided surface.

```dart
BankFlipCard(
  trigger: BankFlipTrigger.tapToFlip,  // tapToFlip · builtInButton · external
  flipAxis: BankFlipAxis.horizontal,   // horizontal (Y-axis) · vertical (X-axis)
  flipDuration: const Duration(milliseconds: 400),
  flipCurve: Curves.easeInOutCubic,
  frontBuilder: (ctx, _) => MyFront(),
  backBuilder:  (ctx, _) => MyBack(),
)
```

#### `BankHorizontalAccountCard`: landscape account card with flip

A landscape-format bank card showing balance, masked number, and account-type icon on
the front. The back reveals the full IBAN / account number and sort code / BIC with
tap-to-copy actions.

```dart
BankHorizontalAccountCard(
  account: myAccount,
  cardholderName: 'Alice Johnson',
  // Front-face layout
  layout: BankHorizontalCardLayout.centred,        // balanceLeft · centred · balanceBottom
  // Background
  background: BankHorizontalCardBackground.image,  // themeGradient · solidColor · image
  backgroundImage: const AssetImage('assets/card_bg.jpg'),
  backgroundImageOverlay: Colors.black54,
  // Flip
  trigger: BankFlipTrigger.builtInButton,
  flipAxis: BankFlipAxis.horizontal,
)
```

External (host-controlled) flip: pair `isFlipped` with `onFlip`:

```dart
bool _flipped = false;

BankHorizontalAccountCard(
  account: myAccount,
  trigger: BankFlipTrigger.external,
  isFlipped: _flipped,
  onFlip: () => setState(() => _flipped = !_flipped),
)
```

#### Enhanced `BankVirtualCardWidget`

The existing virtual-card widget now accepts an image background and an explicit flip
trigger. All new parameters are optional: existing code compiles unchanged.

```dart
BankVirtualCardWidget(
  account: account,
  cardholderName: 'ALEX MORGAN',
  // new: image background
  backgroundImage: const NetworkImage('https://example.com/card.jpg'),
  // new: flip trigger (default: tapToFlip: same as before)
  flipTrigger: BankFlipTrigger.builtInButton,
  // new: optional custom flip button
  flipButtonBuilder: (ctx, flip) => IconButton(
    icon: const Icon(Icons.flip),
    onPressed: flip,
  ),
)
```

| Auth & security | Onboarding & KYC | Saving |
|---|---|---|
| <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/auth-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/onboarding-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/saving-studio-light.png" width="230" /> |

**Auth & security**: `BankPinKeypad` · `BankPinDots` · `BankBiometricPromptButton` · `BankPrivacyToggle` · `BankDeviceTrustBanner` · `BankSessionTimeoutDialog` · `BankAppSwitcherPrivacyOverlay` · `BankOtpInput` · `BankScaApprovalSheet` (PSD2 dynamic linking) · `BankDeviceSessionTile` · `BankCallVerificationScreen` (anti-vishing) · `BankEidLoginButton` (national eID) · `BankPanicFreezeButton`

**Onboarding & KYC**: `BankStepProgressIndicator` · `BankDocumentCaptureOverlay` · `BankLivenessCheckOverlay` · `BankAsyncVerificationState` · `BankConsentModal` · `BankConsentManagementList` (open-banking dashboard) · `BankOnboardingCarousel` · `BankAddressForm`

**Saving**: `BankSavingsPotCard` · `BankRoundUpSettingsSheet` · `BankPotContributionSheet` · `BankIncomeSorterSheet` · `BankSharedPotInvite` · `BankSavingsChallengeCard` (streaks + stamps) · `BankSavingsProjectionCard` (earnings calculator)

| Social | Investing | Credit |
|---|---|---|
| <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/social-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/investing-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/credit-studio-light.png" width="230" /> |

**Social**: `BankJointTransactionListTile` · `BankAccountOwnershipBadge` · `BankSharedGoalProgressCard` · `BankMoneyCircleCard` (Jamiyah saving circle)

**Investing**: `BankPortfolioPerformanceChart` · `BankHoldingsListTile` · `BankWatchlistCard` · `BankBuySellSheet` · `BankAssetPriceTicker` · `BankLiveExchangeConverter` · `BankCurrencyWalletTabBar`

**Credit**: `BankCreditLimitGauge` · `BankFlexEligibleBadge` · `BankInstallmentPlanSelector` · `BankRepaymentScheduleView` · `BankCreditScoreGauge` · `BankLoanCalculatorCard` · `BankCreditLimitAdjuster` (user-set limit) · `BankPreapprovedLoanCard` · `BankOverdraftCushionMeter`

| Subscriptions | Insights | Notifications |
|---|---|---|
| <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/subscriptions-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/insights-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/screenshots/notifications-studio-light.png" width="230" /> |

**Subscriptions**: `BankPlanComparisonTable` · `BankPaywallSheet` · `BankPerksMarketplaceCard` · `BankReferralInviteCard`

**Insights**: `BankSpendingBreakdownChart` (donut) · `BankBudgetGaugeWidget` · `BankInsightCard` · `BankCashflowChart` (history + forecast) · `BankRecurringMerchantTile` (subscription detection) · `BankFinancialHealthScore` · `BankFoundMoneyList`

**Notifications**: `BankInAppNotificationCenter` · `BankAlertPreferencesPanel`

### Forms & input
`BankTextField` · `BankAmountInputField` (currency-aware) · `BankMaskedInputField` (IBAN / PAN / sort code, mod-97 + Luhn) · `BankPhoneInputField` (E.164) · `BankCountryPicker` (236 countries) · `BankPeriodSelector`

### Payments & billing
`BankBillPayTile` + `BankBillCalendarStrip` · `BankStandingOrderTile` · `BankTransferLimitManager` (SCA-gated) · `BankQrScannerOverlay` + `BankMyQrCard` (local QR encoding) · `BankBillForecastList` (bill prediction) · `BankAtmLocatorTile` + `BankCardlessCashCode`

### Rewards & engagement
`BankPointsHubCard` (earn/burn) · `BankOffersRail` (card-linked offers) · `BankCashbackCategoryPicker` (quarterly picks) · `BankStoriesCarousel` (stories + full-screen viewer) · `BankPrizeDrawCard` (prize-linked savings)

### Islamic banking
`BankZakatCalculator` (nisab-aware) · `BankDonationHubCard` (verified charities) · `BankShariahBadge` · profit-rate labeling via `islamicFinanceMode` · Murabaha cost-plus math in `BankLoanCalculatorCard` · the Heritage preset

The Zakat calculator applies the widely used 2.5% rate on zakatable
wealth above a bank-supplied nisab threshold; the calculation method,
threshold, and the charity verification flag are inputs your Shariah
board controls, not rulings the kit makes.

### Business banking
`BankApprovalRequestTile` (maker-checker) · `BankBatchPaymentReviewSheet` · `BankValueDiffRow`

### Documents & deposits
`BankStatementListTile` · `BankChequeCaptureOverlay` + `BankChequeDepositSummary` (remote deposit capture)

### Support & servicing
`BankDisputeWizardSheet` (+ headless `BankDisputeFlowController`) · `BankSecureMessageThread` · `BankHelpFaqList` · `BankAssistantPanel` (named AI assistant entry)

### Scaffolding & display
`BankAppBar` · `BankBottomNavBar` · `BankEmblem` · `BankSummaryStack` · `BankStatusTracker` · `BankQuickActionsGrid` · `BankMoneyProtectionBanner` · `BankShariahBadge` · `BankWalletProvisioningButton` · `BankTravelNoticeForm`

---

## Cross-cutting features

### Privacy mode
`BankPrivacyToggle` flips `BankUiScope.privacyEnabled`; every `BankBalanceText` masks itself automatically.

```dart
BankBalanceText(money: account.balance) // shows '••••' when privacy is on
```

`BankAppSwitcherPrivacyOverlay` blurs the app-switcher snapshot at the
widget level. It is defense in depth, not capture protection: pair it
with platform `FLAG_SECURE` (Android) and screen-capture protection
(iOS) per the recipes in
[docs/enterprise/integration-playbook.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/enterprise/integration-playbook.md).

### Currency-correct money display
Every amount renders through a currency engine that knows each
currency's official symbol, minor units, and symbol placement: the
Saudi riyal symbol, three-decimal Gulf currencies (OMR, KWD, BHD),
zero-decimal JPY/KRW, and crypto precision all follow their own
guidelines. Register your own with `BankCurrencies.register`.

```dart
BankBalanceText(money: Money.fromDouble(1250.5, 'OMR')) // ر.ع. 1,250.500
```

### Numeral styles
Western or Eastern Arabic-Indic digits, independent of locale: ideal for GCC apps.

```dart
BankUiScope(
  initialData: BankUiScopeData(numeralStyle: NumeralStyle.easternArabicIndic),
  child: ...,
)
```

### Islamic finance mode
Swaps interest/APR labels for profit-rate equivalents wherever a widget renders label text.

```dart
BankUiScope(initialData: BankUiScopeData(islamicFinanceMode: true), child: ...)
```

### Localization
Ships English strings; override any subset via `BankUiStrings`: no `gen-l10n` dependency.

### RTL
Every widget is built RTL-first with directional geometry throughout;
widget-test coverage runs under `TextDirection.rtl` and automated RTL
golden screenshots are on the release roadmap
([docs/enterprise/versioning-and-releases.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/enterprise/versioning-and-releases.md)).

---

## Architecture & principles

- **Tokens, not magic numbers.** Widgets read colours, radii, spacing, elevation, and
  numeral typography from `BankThemeData` / `BankTokens`: never hard-coded.
- **State-management agnostic.** Pure widgets: data in via the constructor, events out
  via callbacks. No provider/bloc/riverpod coupling in `lib/`.
- **Lossless money.** The `Money` type wraps `Decimal`; no `double` ever touches an amount.
- **Headless flow controllers.** `BankKycFlowController`, `BankTransferFlowController`, and
  `BankIncomeSorterController` own multi-step flow state so you can swap the visual layer.
- **Bring your own imagery.** Widgets expose `Widget? illustration` slots; the kit bundles
  no raster/vector art.

```
lib/
  core.dart · saving.dart · social.dart · investing.dart · credit.dart   # barrels
  src/
    theme/      # BankTokens, BankThemeData, presets, custom theming
    scope/      # BankUiScope + BankUiStrings
    models/     # Money, Transaction, BankAccount, …  (==, hashCode, copyWith)
    <feature>/  # one folder per module
    controllers/# headless flow controllers
```

---

## Running the example

The example app ships two entry points:

| Entry point | Launch command | What it shows |
|---|---|---|
| **Component gallery** | `flutter run -t lib/gallery_main.dart` | 119 components with live parameter controls, preset/dark-mode switching, and search |
| **Demo dashboard** | `flutter run` | Revolut-style demo app under the Studio preset |

```bash
cd example
flutter pub get
flutter run -t lib/gallery_main.dart    # interactive gallery
flutter run                             # demo dashboard
```

### Regenerating the screenshots

Screenshots in this README are produced from the real widgets via Flutter web:

```bash
cd example
flutter build web -t lib/screenshot_harness.dart --release --no-web-resources-cdn --no-tree-shake-icons
cd ..
node tools/screenshots.mjs          # requires playwright + a Chromium
```

---

## See it, then ship it

**Ten minutes to conviction.** Run the gallery and switch presets live:

```bash
git clone https://github.com/sayed3li97/bank-ui-kit.git
cd bank-ui-kit/example && flutter run -t lib/gallery_main.dart
```

**Building a bank?** Start from the [journey blueprints](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/banking-journeys.md),
compose the widgets, wire your APIs to the callbacks, and read the
[integration playbook](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/docs/enterprise/integration-playbook.md). Your
core banking stays yours.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md).
In short: `flutter analyze` and `flutter test` must be green, and every change must work
across all four presets, both brightnesses, and RTL.

---

## License

[MIT](LICENSE) © 2026 Sayed Ali and Bank UI Kit contributors.

Fonts bundled with the kit: [Space Grotesk](https://github.com/floriankarsten/space-grotesk),
[Fredoka](https://github.com/hafontia/Fredoka), and [Nunito](https://github.com/googlefonts/nunito) -
are licensed under the SIL Open Font License.
