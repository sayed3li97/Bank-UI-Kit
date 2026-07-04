# Enterprise Integration Playbook

This document specifies how a bank composes `bank_ui_kit` 0.1.0 into a
production app: where the kit's responsibility ends, where the host shell
begins, and the seams (scope, callbacks, controllers) that join them. Every
statement traces to source under `lib/` or a sibling document in
`doc/enterprise/`. Where the kit does not yet do something, this file
says so and names the committed direction.

## Reference architecture

The kit is a display and interaction layer: a pure Dart package with five
runtime dependencies (`decimal`, `intl`, `fl_chart`, `collection`, `qr`)
and zero platform channels (`pubspec.yaml`). It never opens a socket,
reads storage, or touches the platform window. The layering:

| Layer | Owner | Kit seam |
|---|---|---|
| Network, tokens, session lifetime | Host | Typed callbacks (`Future<bool>`-returning where a verdict is needed) |
| State management and routing | Host | `ChangeNotifier` flow controllers in `lib/src/controllers/` |
| Runtime configuration | Shared | `BankUiScope` at the root (`lib/src/scope/bank_ui_scope.dart`) |
| Theming and copy | Shared | `BankThemeData`, `BankTokens`, `BankUiStrings` overrides |
| Rendering, a11y, RTL, numerals | Kit | 141 exported widgets across six entry points |

Root composition: platform hardening (FLAG_SECURE section below), then
`BankUiScope` carrying `BankUiScopeData` (preset, strings, `numeralStyle`,
`privacyEnabled`, `islamicFinanceMode`), then `BankAppSwitcherPrivacyOverlay`
around routed content. Descendants read via `BankUiScope.of(context)` and
mutate via `BankUiScope.controllerOf(context)`; only scope dependents rebuild.

## Auth and session management

The kit ships the display side of the session lifecycle; authority for every
decision stays server-side, per `doc/enterprise/compliance-matrix.md`.

- `BankSessionTimeoutDialog` (`lib/src/auth/bank_session_timeout_dialog.dart`)
  counts down from `remainingTime` and fires `onLogout` at zero; the host
  resets its own timer in `onExtend`. Token expiry is enforced server-side.
- `BankScaApprovalSheet` (`lib/src/auth/bank_sca_approval_sheet.dart`) pins
  amount and payee on a non-dismissible sheet, offers biometric, PIN, and
  push-confirm methods behind
  `BankScaApproveCallback = Future<bool> Function(BankScaMethod, String? pin)`,
  and auto-resolves `false` when `expiresAt` passes. The countdown is
  cosmetic; SCA expiry is server-authoritative.
- `BankDeviceSessionTile`, `BankDeviceTrustBanner`,
  `BankBiometricPromptButton`, `BankEidLoginButton`, and
  `BankPanicFreezeButton` (1,500 ms press-and-hold default) render
  host-supplied state and report intent; none inspects the device.

## Per-widget entitlements gating

Current position, stated plainly: the kit contains no entitlement registry
and no permission-aware widget; each of the 141 widgets renders whatever
the host constructs it with. Gating is therefore a composition rule, at the
correct layer: the host resolves entitlements server-side and does not
build the widgets a customer may not use. Every widget is independently
instantiable through the six entry points (`bank_ui_kit.dart`, `core.dart`,
`saving.dart`, `social.dart`, `investing.dart`, `credit.dart`), so
tree-shaking removes what a deployment never composes. Committed direction:
journey controllers gain step-skip configuration as the top-10 controller
set lands through v0.5.0 per `doc/enterprise/versioning-and-releases.md`;
that is where entitlement-driven flow variation belongs. A client-side
"hide if not entitled" flag will not be added; concealment without server
enforcement is not access control.

## Feature flags

The kit ships no flag system and depends on none. The integration pattern:
the host's flag provider resolves values, then maps them to constructor
parameters and `BankUiScopeData` fields. `BankUiScopeData` is an immutable
snapshot with `copyWith`, so a flag flip is one `controllerOf(context)`
mutation or one rebuild of the scope's `initialData`; the scope's equality
check keeps no-op flips from rebuilding the tree. Flags that alter journeys
(for example enabling scheduled transfers) gate whole steps at the host
router, not inside kit widgets.

## Analytics event hooks

Every user action a bank would instrument already exits the kit through a
named, typed callback: `onStoryViewed` on `BankStoriesCarousel`,
`onNotificationTap` on `BankInAppNotificationCenter`, `onFeedback` on
`BankHelpFaqList`, `onCompleted` on `BankOtpInput`, and the sealed status
hierarchies of the flow controllers (`BankTransferStepChanged`,
`BankTransferSuccess`, `BankKycSubmitted`, and peers), which give funnel
analytics exact step-transition events. Current position: there is no
central analytics observer; instrumentation is wired callback by callback.
Committed direction: an optional scope-level event sink is a post-1.0
candidate, additive if it ships. Hard rule regardless of transport: PIN and
OTP callback payloads are never loggable events (rules below).

## Offline behavior

The kit performs no I/O, so it cannot detect connectivity; it renders the
offline states the host detects. `BankConnectivityBanner`
(`lib/src/states/bank_connectivity_banner.dart`) distinguishes
device-offline from service-degraded; neither variant auto-dismisses or
offers a close affordance. `BankAppGateScreen.offline` is the full-screen
gate with a retry action. `BankSkeletonLoader` (self-contained shimmer, no
third-party package), `BankEmptyStateView`, `BankErrorStateView`, and
`BankServiceStatusList` cover load, empty, failure, and status surfaces.
Persisted drafts are a host duty; `doc/banking-journeys.md` states the
resume-from-step pattern the controllers' input setters support.

## Deep linking and navigation conventions

Flow controllers are navigation-agnostic by design: `ChangeNotifier`s with
a step enum and a sealed status hierarchy, no `Navigator` calls anywhere in
`lib/src/controllers/`. The convention: one host route per step enum value
(`BankTransferStep.amount` through `.result`, `BankKycStep.welcome` through
`.complete`); the router listens to the controller, the controller never
imports the router. Deep-link entry constructs a controller, replays known
inputs through its setters (`setAmount`, `setBeneficiary`), and advances to
the target step.
`BankNotification.deepLinkPath` (`lib/src/models/bank_notification.dart`)
carries an opaque path string; the kit never parses or routes it, the
host's `onNotificationTap` handler does. Mid-flow re-auth: pause at the
current step, present the auth surface, resume; controller state survives
because the host owns its lifetime.

## Image loading and pinned CDN clients

Current position, stated plainly, because it is a supply-chain question:
`BankVirtualCardWidget.backgroundImage` and
`BankHorizontalAccountCard.backgroundImage` accept any host-supplied
`ImageProvider`, but most avatar and logo surfaces (`BankEmblem.imageUrl`,
`BankTransactionListTile`, `BankHoldingsListTile`, `BankWatchlistCard`,
`BankPhysicalCardMaterialPicker`) take a URL string and construct
`NetworkImage` internally; there is no scope-level image resolver yet. The
certificate-pinning enforcement point today is `HttpOverrides.global`,
which Flutter's `NetworkImage` honors, so one pinned `HttpClient` covers
every kit-initiated fetch. `BankEmblem` degrades to initials or an icon on
failure, never a broken-image glyph. Committed direction: an injectable
resolver on `BankUiScopeData` (URL string in, `ImageProvider` out) so hosts
route through their pinned CDN client and cache, additive, targeted at
v0.3.0 (2026-10-31).

## FLAG_SECURE and iOS screen capture

`BankAppSwitcherPrivacyOverlay`
(`lib/src/auth/bank_app_switcher_privacy_overlay.dart`) is cosmetic only: a
Dart-side lifecycle observer that covers content with a sigma-12 blur and
scrim (or a full placeholder) on `AppLifecycleState.inactive` or `.paused`.
It does not block screenshots, recording, or the OS snapshot. The kit sets
no window flags and ships no platform channels; none are planned
(`doc/enterprise/compliance-matrix.md`). The host applies the controls:

Android, in `MainActivity.onCreate`:

```kotlin
window.setFlags(LayoutParams.FLAG_SECURE, LayoutParams.FLAG_SECURE)
```

iOS has no screenshot-blocking API. The recipe: present an opaque cover
view in `sceneWillResignActive`, and observe
`UIScreen.capturedDidChangeNotification` to gate sensitive screens while
`UIScreen.main.isCaptured` is true. The kit overlay then covers the
app-switcher card on both platforms: defense in depth, not the control.

## PIN and OTP handling rules

Binding rules for integrators, each grounded in shipped behavior:

1. Never log callback payloads. `BankOtpInput.onCompleted`,
   `BankPinKeypad.onDigit`, and the `pin` argument of
   `BankScaApproveCallback` carry live credentials; they must never reach
   analytics, crash reporters, or debug logs.
2. The client never validates. `BankTransferFlowController.submitPin`
   deliberately ignores its `pin` parameter; verification happens in the
   host backend via `markSuccess` or `markFailure`.
3. Clear on failure and dispose. `BankScaApprovalSheet` clears its PIN
   buffer when `onApprove` returns `false`; `BankOtpInputController.clear()`
   resets the code, and `BankOtpInput` disposes its text controller. Hosts
   holding PIN state for `BankPinKeypad` clear it in their own `dispose`.
4. Display is masked by default: `BankPinDots` renders obscured dots only;
   `BankOtpInput.obscure` masks digits where policy requires.
5. Attempt counting, lockout, and SCA expiry are server-authoritative; the
   widgets render the outcome and count nothing.

## Performance budgets and benchmarks

Budgets the project builds against: 16 ms per frame at 60 Hz (8 ms at
120 Hz) for scrolling `BankTransactionListTile` lists and chart surfaces,
no dropped frames during `BankFlipCard` and `BankSuccessAnimation` runs,
and reduced-motion compliance via `MediaQuery.disableAnimationsOf`, which
`BankOtpInput`'s shake and `BankEmblem`'s fade already honor. Current
position, stated plainly: at 0.1.0 there is no `integration_test/`
directory and no device benchmark results have been published; the shipped
evidence is the six suites under `test/` that CI runs on Flutter 3.27.1
per `.github/workflows/ci.yml`. Committed methodology: an
`integration_test` harness driving the example gallery
(`example/lib/gallery_main.dart`) with `IntegrationTestWidgetsFlutterBinding`
frame-timing summaries, reporting average and worst-case build and raster
times per screen. The low-end reference device is an Android Go class
handset (2 GB RAM, Cortex-A53); GCC and South Asian deployments profiled
in `doc/research/top-20-banking-apps.md` skew toward that tier. Harness
and first numbers ride the v0.3.0 milestone (2026-10-31) with the
golden-test baseline; until they exist, this document publishes none.

This document is versioned with the repository; changes land through the
same pull-request review and CI gates as code.
