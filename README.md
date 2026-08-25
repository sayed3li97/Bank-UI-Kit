<div align="center">

# Bank UI Kit

### The Flutter front-end for digital banking.

Every surface a retail, Islamic, or business bank ships, from onboarding to
servicing, as composable Flutter widgets. One codebase,
four built-in themes, your backend.

[![CI](https://github.com/sayed3li97/bank-ui-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/sayed3li97/bank-ui-kit/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/sayed3li97/bank-ui-kit/badge)](https://scorecard.dev/viewer/?uri=github.com/sayed3li97/bank-ui-kit)
[![pub package](https://img.shields.io/pub/v/bank_ui_kit.svg)](https://pub.dev/packages/bank_ui_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.44%2B-027DFD.svg)](https://flutter.dev)
[![style: flutter_lints](https://img.shields.io/badge/style-flutter__lints-40c4ff.svg)](https://pub.dev/packages/flutter_lints)

**173 components** · **23 modules** · **4 built-in themes** · **WCAG 2.1 AA gates enforced in CI** · **RTL + Arabic-Indic numerals**

### [▶ Try the live demo](https://sayed3li97.github.io/Bank-UI-Kit/)

Browse every component and the full Meridian flagship app in your browser: switch themes, dark mode, and RTL live.

<br />

<table>
  <tr>
    <td align="center"><b>Heritage</b></td>
    <td align="center"><b>Studio</b></td>
    <td align="center"><b>Voltage</b></td>
    <td align="center"><b>Bloom</b></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/heritage-heritage-light.png" width="185" alt="Heritage preset" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/home-studio-light.png" width="185" alt="Studio preset" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/home-voltage-dark.png" width="185" alt="Voltage preset" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/home-bloom-light.png" width="185" alt="Bloom preset" /></td>
  </tr>
</table>

*The same widgets in four built-in themes, so rebranding takes minutes.*

</div>

---

## Contents

**Evaluating it**

- [What it is](#what-it-is)
- [Enterprise readiness](#enterprise-readiness)
- [How it compares](#how-it-compares)
- [Design tokens: one source, every consumer](#design-tokens-one-source-every-consumer)
- [Accessibility, enforced in CI](#accessibility-enforced-in-ci)
- [Supply chain and provenance](#supply-chain-and-provenance)
- [Stability: what can change under you](#stability-what-can-change-under-you)

**Building with it**

- [Install](#install)
- [Quick start](#quick-start)
- [Design presets](#design-presets)
- [Custom themes](#custom-themes)
- [The flagship app: a complete product suite](#the-flagship-app-a-complete-product-suite)
- [Journeys, not just widgets](#journeys-not-just-widgets)
- [Component catalogue](#component-catalogue)
- [Full API reference](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/component-reference.md)
- [Cross-cutting features](#cross-cutting-features)
- [Architecture and principles](#architecture-and-principles)
- [Running the example](#running-the-example)
- [Contributing](#contributing)
- [License](#license)

---

## What it is

A component library, not a screen template. You compose the widgets into an
app you already own rather than copying whole screens out of a starter
project. The kit covers accounts, payments, cards, onboarding and KYC, PFM
and insights, lending, rewards, Islamic banking, business-banking approvals,
disputes, secure messaging, and statements: 173 components across 23
modules, benchmarked against 21 of the world's leading banking apps.

It is backend-agnostic by construction. Data goes in through constructors,
events come out through callbacks, and nothing in `lib/` opens a network
connection, writes to disk, or depends on a state-management package. The
headless flow controllers are `ChangeNotifier` state machines that own step
state and nothing else. Your core banking APIs stay yours.

Everything visible is a token. Colour, shape, depth, motion, and numeral
typography come from `BankThemeData` and `BankTokens`, which are generated
from a platform-neutral token file and serialise back to JSON. That is what
makes a rebrand a constructor argument instead of a fork.

---

## Enterprise readiness

The questions below are the ones that come up at bank and agency intake, in
roughly the order they get asked. Each answer links to the document or the
workflow file that carries the evidence, so you can check the claim rather
than take it.

| Question at intake | Where this project stands | Evidence |
|---|---|---|
| Is there an accessibility conformance report? | Yes. WCAG 2.1 A and AA plus EN 301 549 V3.2.1, per component, with the gaps named rather than smoothed over. Self-assessed, not third-party audited, and it says so on its first page | [ACR](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/acr/ACR.md) · [`openacr.yaml`](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/acr/openacr.yaml) |
| Is accessibility tested, or only asserted? | Enforced in CI. A contrast gate across every preset in light and dark, a 44 px tap-target gate, an accessible-label gate, and golden regression across preset, brightness, and direction. A failure breaks the build | [`ci.yml`](.github/workflows/ci.yml) · `test/accessibility_*_test.dart` |
| Who carries the regulatory obligation? | The bank does. The kit implements the UX pattern; the regulated control behind it stays yours. The split is written down line by line | [compliance matrix](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/compliance-matrix.md) |
| Can you produce an SBOM? | On every commit and every release, in SPDX 2.3 and CycloneDX 1.6 from one resolution, scanned against OSV, and byte-reproducible from the commit plus the lockfile shipped with it | [supply chain](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/supply-chain.md) · [`sbom.yml`](.github/workflows/sbom.yml) |
| Is the release chain attested? | Publishing runs over OIDC with no stored credential, bound to a tag ref. Release artifacts carry a Sigstore-backed SLSA build provenance attestation. Every GitHub Action is pinned by commit SHA | [`release.yml`](.github/workflows/release.yml) · [`publish.yml`](.github/workflows/publish.yml) |
| Is there a published OpenSSF Scorecard? | Yes, refreshed weekly and on branch-protection changes, with the SARIF kept as a build artifact | [Scorecard viewer](https://scorecard.dev/viewer/?uri=github.com/sayed3li97/bank-ui-kit) · [`scorecard.yml`](.github/workflows/scorecard.yml) |
| What can change under us, and with how much warning? | A written dependency contract: what counts as breaking for a UI kit including default visual values, the deprecation window, pinning guidance, and the 1.0 gate with the status of each criterion | [stability and support](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/stability-and-support.md) |
| What happens if the project stops? | One maintainer today, stated plainly. MIT, no private infrastructure, vendorable as a path dependency, and the design tokens are portable JSON that outlive the Dart code | [stability and support](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/stability-and-support.md), continuity section · [GOVERNANCE.md](GOVERNANCE.md) |
| How do we report a vulnerability? | Private GitHub advisory or email, with severity clocks adjusted for a UI library, where on-screen leakage of financial data is treated one band higher than raw CVSS | [SECURITY.md](SECURITY.md) |
| Does it work in our markets? | RTL-first on every widget, four numeral scripts, locale-aware money for every currency the kit knows, and Hijri calendar support | [localization and RTL](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/localization-and-rtl.md) |

### Where this project is honest about its gaps

It is version 0.3.0, which means pre-1.0 minors are permitted to break you,
so pin exactly. It has one maintainer, so the bus factor is one. The
accessibility report is a self-assessment and no independent firm has
audited it. Those facts are why the documents above exist, and each document
names the mitigation available to an adopter rather than an aspiration.

### The enterprise documentation set

[stability and support](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/stability-and-support.md) ·
[versioning and releases](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/versioning-and-releases.md) ·
[supply chain](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/supply-chain.md) ·
[compliance matrix](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/compliance-matrix.md) ·
[accessibility conformance](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/accessibility-conformance.md) ·
[ACR](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/acr/ACR.md) ·
[design tokens](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/design-tokens.md) ·
[integration playbook](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/integration-playbook.md) ·
[white-label guide](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/white-label-guide.md) ·
[localization and RTL](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/localization-and-rtl.md)

### How it compares

| | Bank UI Kit | Typical screen-template kits |
|---|---|---|
| **Integration model** | Compose into any existing app | Copy-paste whole screens |
| **Design tokens** | Platform-neutral **W3C DTCG `tokens.json`** generates the Dart tokens (CI-enforced) + `toJson`/`fromJson` for Figma and remote branding | Hard-coded values |
| **Theming** | 4 presets + fully custom themes, runtime-switchable | Fork the package |
| **RTL support** | First-class, every widget | Mirror-on-demand or none |
| **Localization** | Locale-aware money (German `1.234,56`, French `1 234,56`, Indian lakh) + 4 numeral scripts + Hijri calendar | English only |
| **Accessibility** | WCAG 2.1 AA **enforced in CI**: contrast gate across every preset, tap-target and label gates, semantics | Not specified |
| **Conformance evidence** | Published ACR (WCAG 2.1 AA, EN 301 549) + machine-readable OpenACR | None |
| **Supply chain** | SBOM on every commit, OSV scan, SLSA provenance, published Scorecard | None |
| **Visual regression** | Golden tests pin every preset × light/dark | None |
| **State management** | Agnostic (pure props + callbacks) | Tied to the template's choice |
| **Money** | Lossless `Decimal`-backed `Money` type | `double` |
| **Tests** | 487 unit, widget, golden, and accessibility test cases | None |

---

## Design tokens: one source, every consumer

The tokens are **not** Dart constants that only Flutter can read. The source
of truth is a platform-neutral [W3C DTCG](https://tr.designtokens.org/format/)
file, [`tokens/design-tokens.json`](tokens/design-tokens.json), that **generates**
the Dart tokens, and CI fails if the two drift:

```jsonc
// tokens/design-tokens.json  →  generates lib/src/theme/tokens.dart
"color":  { "positiveBalance": { "$type": "color", "$value": "#047857" } },
"space":  { "4": { "$type": "dimension", "$value": "16px" } },
"radius": { "full": { "$type": "dimension", "$value": "999px" } }
```

```bash
dart run tool/generate_tokens.dart          # regenerate tokens.dart from JSON
dart run tool/generate_tokens.dart --check   # CI drift guard
```

And any **brand** round-trips to and from JSON. These are the same tokens a Figma
library or an iOS/Android app would consume, or that a server could deliver for
remote re-branding:

```dart
final json = BankPreset.heritage.apply(base).extension<BankThemeData>()!.toJson();
// → { "colors": { "primary": "#006341FF", ... }, "radius": {...}, ... }
final brand = BankThemeData.fromJson(json);   // lossless round-trip
```

All four presets are exported to [`tokens/themes/`](tokens/themes/) as
Figma-Variables-ready token sets. The same source feeds Flutter, Figma, and
native apps, which is what makes this a design system rather than only a widget
library. It is also the reason your design decisions survive independently of
this package: those files carry no dependency on Flutter, on Dart, or on the
kit. Full pipeline in
[doc/enterprise/design-tokens.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/design-tokens.md).

### One token change rebrands every surface

<p align="center">
  <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/diagrams/architecture-flow.svg" width="880" alt="Design tokens flow into four presets, into 173 components, into your app" />
</p>

Tokens set colour, shape, depth, and numeral typography once. Presets are
just token sets: swap one and every component follows, light and dark,
LTR and RTL. Your rebrand is a single constructor argument rather than a
multi-quarter project.

---

## Accessibility, enforced in CI

Accessibility here is a build gate, not a section in a sales deck. Every
push runs:

- a **WCAG contrast** test (92 cases) covering every text pair and
  financial colour across all four presets in light and dark;
- **tap-target** (44 px) and **accessible-label** guideline checks on
  interactive widgets;
- **golden** visual-regression across preset × brightness × direction.

The conformance position, including what is verified, what is the host app's
responsibility, and what is still a gap with a remediation date, is written
down in
[doc/enterprise/accessibility-conformance.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/accessibility-conformance.md).
The formal report a procurement team files is the
[ACR](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/acr/ACR.md),
with a machine-readable
[OpenACR](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/acr/openacr.yaml)
source of truth beside it.

Both are self-assessments. No independent accessibility firm has assessed
this package, and neither document pretends otherwise.

Regenerate goldens with `flutter test --update-goldens`.

---

## Supply chain and provenance

Every commit and every release produces a Software Bill of Materials in both
SPDX 2.3 and CycloneDX 1.6, generated from one dependency resolution so the
two formats cannot disagree. The generator derives its timestamps from the
commit rather than the clock, and ships the resolved `pubspec.lock` inside
the artifact, so re-running it on the same commit gives byte-identical
documents. The same document is scanned against OSV, and a known advisory
affecting a runtime dependency fails the build.

Releases publish to pub.dev over OIDC through Dart's trusted-publishing
workflow, with no credential stored in the repository or in Actions secrets,
and the artifacts attached to each GitHub Release carry a Sigstore-backed
SLSA build provenance attestation. Every third-party GitHub Action is pinned
by commit SHA rather than by tag.

Details, and how to verify any of it yourself, are in
[doc/enterprise/supply-chain.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/supply-chain.md).

---

## Stability: what can change under you

The package is at 0.3.0. Under SemVer a 0.x minor may break you, so **pin
exactly** until 1.0:

```yaml
dependencies:
  bank_ui_kit: 0.3.0   # exact, no caret, while the package is pre-1.0
```

For a UI kit the interesting breakage is not a deleted method. It is a
default colour, size, elevation, font, or motion value moving, which changes
what ships to customers without a single analyzer warning and fails your own
golden tests. This project treats those as breaking changes and says so. The
[stability and support](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/stability-and-support.md)
policy lists them item by item, and names the three releases that have already
changed visual defaults.

The rest of the dependency contract, including the deprecation window, the
procedure for retiring a visual default, the supported-version policy, the
1.0 criteria with the current status of each, and the continuity story for a
single-maintainer project, is in
[doc/enterprise/stability-and-support.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/stability-and-support.md).
Release mechanics and the roadmap are in
[doc/enterprise/versioning-and-releases.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/versioning-and-releases.md).

---

## Install

```yaml
dependencies:
  bank_ui_kit: 0.3.0   # exact, no caret, while the package is pre-1.0
```

Or take it straight from git, which is also the vendoring path if you mirror
the repository into internal hosting:

```yaml
dependencies:
  bank_ui_kit:
    git:
      url: https://github.com/sayed3li97/bank-ui-kit.git
      ref: v0.3.0
```

Pin exactly either way until 1.0, and read
[what can change under you](#stability-what-can-change-under-you) before you
take the upgrade.

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

Switch presets at runtime by changing the `ThemeData` you pass to `MaterialApp`.
Every widget re-themes itself because it reads tokens from `BankThemeData.of(context)`.

<table>
  <tr>
    <td align="center">Accounts · Studio</td>
    <td align="center">Accounts · Voltage</td>
    <td align="center">Accounts · Bloom</td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/accounts-studio-light.png" width="240" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/accounts-voltage-dark.png" width="240" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/accounts-bloom-light.png" width="240" /></td>
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
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/heritage-heritage-light.png" width="240" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/heritage-heritage-dark.png" width="240" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/home-heritage-light.png" width="240" /></td>
  </tr>
</table>

Every component is also captured under all four presets: see
`doc/screenshots/components/` (Studio at the top level, plus
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

## The flagship app: a complete product suite

The kit ships with **Meridian**, a full reference banking app built entirely
from Bank UI Kit widgets: a real product catalogue (accounts, cards, loans,
mortgages, investments, protection), product detail pages with a
conventional/Shariah toggle, an end-to-end lending application, and a
servicing view with a live application tracker. It is the app a bank CEO
reviews before signing off a launch: every rate, disclosure, and
representative example is presented the way a regulator expects.

Run it in any of the four presets:

```bash
cd example
flutter run -t lib/flagship_main.dart      # switch BankPreset in flagship_main.dart
```

### The Auto Finance application, end to end

One `BankApplicationController` drives seven steps; each step is a real kit
widget. This is the actual journey, captured stage by stage from the running
app:

<p align="center">
  <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/flagship-apply-walkthrough.gif" width="300" alt="The Auto Finance apply journey: eligibility, customise, offer, documents, disclosures, e-signature, approval" />
</p>

*Eligibility (soft search, no credit impact) → customise amount and term →
firm personalised offer with the representative example → document capture →
pre-contract disclosures and consents → e-signature → approval with a
reference and funding timeline.*

### The product suite

<table>
  <tr>
    <td align="center"><b>Home</b></td>
    <td align="center"><b>Explore catalogue</b></td>
    <td align="center"><b>Product detail</b></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/flagship-home-studio-light.png" width="240" alt="Meridian home with total position, accounts, and a pre-qualified offer" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/flagship-catalog-studio-light.png" width="240" alt="Product catalogue with category grid, featured Auto Finance, and the loans line-up" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/flagship-product-studio-light.png" width="240" alt="Auto Finance product detail with a conventional and Shariah toggle" /></td>
  </tr>
  <tr>
    <td align="center"><b>Apply: your offer</b></td>
    <td align="center"><b>My products</b></td>
    <td align="center"><b>Shariah variant (Heritage)</b></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/flagship-apply-studio-light.png" width="240" alt="A firm, personalised credit offer with the full cost breakdown" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/flagship-my-products-studio-light.png" width="240" alt="Servicing view: holdings, a live application tracker, and relationship summary" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/flagship-product-heritage-light.png" width="240" alt="The same product detail in the Heritage Islamic-banking preset" /></td>
  </tr>
</table>

Every product line in the app maps to a documented, regulator-aware pattern.
The complete banking-products reference (lending, deposits, cards, wealth,
insurance, and their Islamic variants, with the metrics, journeys, and
servicing views each one needs) lives in
[doc/research/banking-products.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/research/banking-products.md).

---

## Journeys, not just widgets

Components are designed to chain into complete, compliant banking
journeys. Below, a payment travels through five kit widgets while one
headless controller owns the state machine:

<p align="center">
  <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/diagrams/payment-journey.svg" width="880" alt="A payment journey composed from kit components over one headless flow controller" />
</p>

The same composition pattern covers every core journey. The full
catalogue of 25 journey blueprints (triggers, steps, variants, error
states) lives in [doc/banking-journeys.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/banking-journeys.md).

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

173 widgets across 23 modules. Each screenshot below is a live render of that module's
showcase screen (Studio preset, light mode) from the example app.

For the full parameter-level API reference (every constructor argument, type, required/optional status, and default value) see **[doc/component-reference.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/component-reference.md)**.

### States & feedback
`BankSkeletonLoader` · `BankEmptyStateView` · `BankErrorStateView` · `BankSuccessAnimation` · `BankToastBanner` · `BankFraudAlertBanner` · `BankAppGateScreen` (11 gate reasons: maintenance, force update, root/VPN blocks, waiting room) · `BankConnectivityBanner` · `BankServiceStatusList` · `BankUpdatePromptSheet`

<img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/states-studio-light.png" width="260" align="right" />

### Accounts & balances
`BankAccountCard` · `BankAccountSwitcher` · `BankBalanceText` (privacy-aware) · `BankProductItemTile` · `BankAccountNumberText` · `BankPeekBalance` (pre-login peek) · `BankEarlyPaydayCard`

### Transactions
`BankTransactionListTile` · `BankTransactionGroupHeader` · `BankTransactionDetailSheet` · `BankTransactionFilterSheet` · `BankReceiptView` · `BankTransactionCostSplitSheet` · `BankTransactionCategorySplitSheet`

<br clear="right" />

| Transactions | Transfers | Cards |
|---|---|---|
| <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/transactions-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/transfers-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/cards-studio-light.png" width="230" /> |

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
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/cards-studio-light.png" width="230" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/cards-voltage-dark.png" width="230" /></td>
    <td><img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/cards-bloom-light.png" width="230" /></td>
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
| <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/auth-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/onboarding-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/saving-studio-light.png" width="230" /> |

**Auth & security**: `BankPinKeypad` · `BankPinDots` · `BankBiometricPromptButton` · `BankPrivacyToggle` · `BankDeviceTrustBanner` · `BankSessionTimeoutDialog` · `BankAppSwitcherPrivacyOverlay` · `BankOtpInput` · `BankScaApprovalSheet` (PSD2 dynamic linking) · `BankDeviceSessionTile` · `BankCallVerificationScreen` (anti-vishing) · `BankEidLoginButton` (national eID) · `BankPanicFreezeButton`

**Onboarding & KYC**: `BankStepProgressIndicator` · `BankDocumentCaptureOverlay` · `BankLivenessCheckOverlay` · `BankAsyncVerificationState` · `BankConsentModal` · `BankConsentManagementList` (open-banking dashboard) · `BankOnboardingCarousel` · `BankAddressForm`

**Saving**: `BankSavingsPotCard` · `BankRoundUpSettingsSheet` · `BankPotContributionSheet` · `BankIncomeSorterSheet` · `BankSharedPotInvite` · `BankSavingsChallengeCard` (streaks + stamps) · `BankSavingsProjectionCard` (earnings calculator)

| Social | Investing | Credit |
|---|---|---|
| <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/social-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/investing-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/credit-studio-light.png" width="230" /> |

**Social**: `BankJointTransactionListTile` · `BankAccountOwnershipBadge` · `BankSharedGoalProgressCard` · `BankMoneyCircleCard` (Jamiyah saving circle)

**Investing**: `BankPortfolioPerformanceChart` · `BankHoldingsListTile` · `BankWatchlistCard` · `BankBuySellSheet` · `BankAssetPriceTicker` · `BankLiveExchangeConverter` · `BankCurrencyWalletTabBar`

**Credit**: `BankCreditLimitGauge` · `BankFlexEligibleBadge` · `BankInstallmentPlanSelector` · `BankRepaymentScheduleView` · `BankCreditScoreGauge` · `BankLoanCalculatorCard` · `BankCreditLimitAdjuster` (user-set limit) · `BankPreapprovedLoanCard` · `BankOverdraftCushionMeter`

| Subscriptions | Insights | Notifications |
|---|---|---|
| <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/subscriptions-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/insights-studio-light.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/notifications-studio-light.png" width="230" /> |

**Subscriptions**: `BankPlanComparisonTable` · `BankPaywallSheet` · `BankPerksMarketplaceCard` · `BankReferralInviteCard`

**Insights**: `BankSpendingBreakdownChart` (donut) · `BankBudgetGaugeWidget` · `BankInsightCard` · `BankCashflowChart` (history + forecast) · `BankRecurringMerchantTile` (subscription detection) · `BankFinancialHealthScore` · `BankFoundMoneyList`

**Notifications**: `BankInAppNotificationCenter` · `BankAlertPreferencesPanel`

### Forms & input
`BankTextField` · `BankAmountInputField` (currency-aware) · `BankMaskedInputField` (IBAN / PAN / sort code, mod-97 + Luhn) · `BankPhoneInputField` (E.164) · `BankCountryPicker` (236 countries) · `BankPeriodSelector`

### Payments & billing
`BankBillPayTile` + `BankBillCalendarStrip` · `BankStandingOrderTile` · `BankTransferLimitManager` (SCA-gated) · `BankQrScannerOverlay` + `BankMyQrCard` (local QR encoding) · `BankBillForecastList` (bill prediction) · `BankAtmLocatorTile` + `BankCardlessCashCode`

### Products & applications
The origination surface behind the [flagship app](#the-flagship-app-a-complete-product-suite): market a product, check eligibility, present an offer, and take an application to signature.

| Product card | Personalised offer | Eligibility result |
|---|---|---|
| <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/components/BankProductCard.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/components/BankOfferSummaryCard.png" width="230" /> | <img src="https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/screenshots/components/BankEligibilityResultCard.png" width="230" /> |

`BankProductCard` (rate hero, features, badges, dual CTA) · `BankProductCategoryTile` (catalogue grid) · `BankEligibilityResultCard` (soft-search outcome, no credit impact) · `BankOfferSummaryCard` (firm/indicative offer with the representative example) · `BankRatioGauge` (LTV / DTI / LTI affordability bands) · `BankDisclosureConsentSheet` (pre-contract disclosures + no-dark-pattern consents) · `BankESignaturePad` (typed or drawn, timestamped) · headless `BankApplicationController` (the seven-step state machine)

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
[doc/enterprise/integration-playbook.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/integration-playbook.md).

### Currency-correct money display
Every amount renders through a currency engine that knows each
currency's official symbol, minor units, and symbol placement: the
Saudi riyal symbol, three-decimal Gulf currencies (OMR, KWD, BHD),
zero-decimal JPY/KRW, and crypto precision all follow their own
guidelines. Register your own with `BankCurrencies.register`.

```dart
BankBalanceText(money: Money.fromDouble(1250.5, 'OMR')) // ر.ع. 1,250.500
```

Grouping and separators are **locale-aware**: kit money widgets read the
ambient `Localizations` locale, so the same amount reads correctly in every
market. Calling the formatter yourself? Pass `context.bankLocale`.

```dart
BankMoneyFormatter.format(amount: a, currencyCode: 'EUR', locale: 'de'); // €1.234.567,89
BankMoneyFormatter.format(amount: a, currencyCode: 'EUR', locale: 'fr'); // €1 234 567,89
BankMoneyFormatter.format(amount: a, currencyCode: 'INR', locale: 'en_IN'); // ₹12,34,567.89
```

### Numeral styles
Four numeral scripts, independent of locale (grouping) and useful for GCC and
South-Asian apps: Western, Eastern Arabic-Indic (`٠١٢`), Persian (`۰۱۲`), and
Devanagari (`०१२`). The kit **bundles Noto fallback fonts** (`kBankFontFallback`)
so currency symbols (₹ ₩ ₫ ₿ Ξ), Arabic script, and these numerals render
everywhere: offline, on web without a CDN, and on devices lacking those
system fonts.

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
Locale-aware number formatting (above) plus injectable copy: ships English
strings and overrides any subset via `BankUiStrings`. The full position,
including what the kit does not translate for you, is in
[doc/enterprise/localization-and-rtl.md](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/localization-and-rtl.md).

### RTL
Every widget is built RTL-first with directional geometry throughout;
widget-test coverage runs under `TextDirection.rtl`, and an LTR/RTL **golden
test** pins the mirrored layout so it can't regress.

### Air-gapped and offline builds
Widgets that take an image URL resolve it through
`BankUiScopeData.imageResolver` when one is set, so a deployment with no
outbound network can supply its own `ImageProvider` (asset, cache, or
internal CDN) without touching kit source. Fonts are bundled, not fetched, so
the numeral scripts and currency glyphs render with no CDN.

### Accessibility
See [Accessibility, enforced in CI](#accessibility-enforced-in-ci) above for
the gates, and the
[ACR](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/acr/ACR.md)
for the per-component conformance position.

---

## Architecture and principles

- Widgets read colours, radii, spacing, elevation, and
  numeral typography from `BankThemeData` / `BankTokens`, never from hard-coded values. The scalar
  tokens are generated from a W3C DTCG `tokens.json` (CI-enforced), and any brand
  serialises to and from JSON. See [Design tokens: one source, every consumer](#design-tokens-one-source-every-consumer).
- Widgets are state-management agnostic: data comes in via the constructor and events go out
  via callbacks, with no provider/bloc/riverpod coupling in `lib/`.
- The `Money` type wraps `Decimal`, so no `double` ever touches an amount.
- The headless flow controllers `BankKycFlowController`, `BankTransferFlowController`,
  `BankIncomeSorterController`, `BankApplicationController`, and
  `BankDisputeFlowController` own multi-step flow state so you can swap the visual layer.
- Widgets expose `Widget? illustration` slots and the kit bundles
  no raster/vector art, so you bring your own imagery.

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
| **Component gallery** | `flutter run -t lib/gallery_main.dart` | Every component with live parameter controls, preset/dark-mode switching, and search |
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
node tool/screenshots.mjs          # requires playwright + a Chromium
node tool/walkthrough.mjs           # rebuilds the flagship apply-journey GIF
```

---

## Try it, then build with it

Run the gallery and switch presets live:

```bash
git clone https://github.com/sayed3li97/bank-ui-kit.git
cd bank-ui-kit/example && flutter run -t lib/gallery_main.dart
```

Building a bank? Start from the [journey blueprints](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/banking-journeys.md),
compose the widgets, wire your APIs to the callbacks, and read the
[integration playbook](https://raw.githubusercontent.com/sayed3li97/bank-ui-kit/main/doc/enterprise/integration-playbook.md). Your
core banking stays yours.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md).
In short: `flutter analyze` and `flutter test` must be green, and every change must work
across all four presets, both brightnesses, and RTL. How changes are reviewed
and who decides is in [GOVERNANCE.md](GOVERNANCE.md).

---

## License

[MIT](LICENSE) © 2026 Sayed Ali and Bank UI Kit contributors.

Fonts bundled with the kit: [Space Grotesk](https://github.com/floriankarsten/space-grotesk),
[Fredoka](https://github.com/hafontia/Fredoka), and [Nunito](https://github.com/googlefonts/nunito)
are licensed under the SIL Open Font License.
