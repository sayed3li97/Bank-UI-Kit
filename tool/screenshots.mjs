// Documentation screenshot generator.
//
// Serves the built Flutter web harness (example/build/web) and drives a
// headless Chromium via Playwright to capture every screen across the three
// presets and light/dark, writing PNGs into doc/screenshots/.
//
// Also captures a per-component screenshot for every gallery entry, writing to
// doc/screenshots/components/<ComponentName>.png.
//
// Usage:
//   cd example && flutter build web -t lib/screenshot_harness.dart --release \
//     --no-web-resources-cdn --no-tree-shake-icons
//   node tool/screenshots.mjs
//
// Pass --components-only to skip screen shots and only re-shoot components.
// Pass --screens-only  to skip component shots.
//
// Requires: playwright (npm) and a Chromium executable. In this repo's dev
// container Chromium lives at /opt/pw-browsers/chromium.
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { existsSync, mkdirSync } from 'node:fs';
import { join, extname, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(__dirname, '..');
const webRoot = join(repoRoot, 'example', 'build', 'web');
const outDir = join(repoRoot, 'doc', 'screenshots');
const compDir = join(outDir, 'components');

if (!existsSync(webRoot)) {
  console.error(`Build not found at ${webRoot}. Run the flutter build first.`);
  process.exit(1);
}
mkdirSync(outDir, { recursive: true });
mkdirSync(compDir, { recursive: true });

const args = process.argv.slice(2);
const screensOnly = args.includes('--screens-only');
const componentsOnly = args.includes('--components-only');

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.bin': 'application/octet-stream',
  '.symbols': 'application/octet-stream',
};

const server = createServer(async (req, res) => {
  try {
    const url = new URL(req.url, 'http://localhost');
    let p = decodeURIComponent(url.pathname);
    if (p === '/' || p === '') p = '/index.html';
    let filePath = join(webRoot, p);
    if (!existsSync(filePath)) {
      // A missing file with an extension is a real asset (e.g. Flutter 3.44
      // no longer emits FontManifest.json): 404 it so the engine handles the
      // absence gracefully. Only extensionless paths (navigation routes) fall
      // back to index.html. Returning index.html for a missing .json asset
      // makes the bootstrap parse "<!DOCTYPE" as JSON and the app never boots.
      if (extname(p)) {
        res.writeHead(404, { 'content-type': 'text/plain' });
        res.end('not found');
        return;
      }
      filePath = join(webRoot, 'index.html'); // SPA fallback
    }
    const body = await readFile(filePath);
    res.writeHead(200, {
      'content-type': MIME[extname(filePath)] || 'application/octet-stream',
      'cross-origin-opener-policy': 'same-origin',
      'cross-origin-embedder-policy': 'require-corp',
    });
    res.end(body);
  } catch (e) {
    res.writeHead(500);
    res.end(String(e));
  }
});

const PORT = 8099;
await new Promise((r) => server.listen(PORT, r));
console.log(`Serving ${webRoot} on http://localhost:${PORT}`);

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_PATH || '/opt/pw-browsers/chromium',
  args: ['--no-sandbox', '--force-color-profile=srgb'],
  // Route through the environment proxy (when present) so the Flutter web
  // engine can fetch Noto fallback fonts for Arabic and other scripts.
  proxy: process.env.HTTPS_PROXY
    ? { server: process.env.HTTPS_PROXY, bypass: 'localhost,127.0.0.1' }
    : undefined,
});

// ── Helper: navigate an existing page to a Flutter URL and wait for render ───
async function navigatePage(page, url) {
  await page.goto(url, { waitUntil: 'load', timeout: 60000 });
  await page
    .waitForSelector('flt-glass-pane, flt-scene-host, flutter-view', { timeout: 45000 })
    .catch(() => {});
  await page.waitForTimeout(2800);
}

let totalOk = 0;
let totalAttempts = 0;

// ── 1. SCREEN SHOTS ──────────────────────────────────────────────────────────
if (!componentsOnly) {
  const presets = ['studio', 'voltage', 'bloom', 'heritage'];
  const galleryScreens = [
    'states', 'accounts', 'transactions', 'transfers', 'cards', 'auth',
    'onboarding', 'saving', 'social', 'investing', 'credit',
    'subscriptions', 'insights', 'notifications',
  ];

  const shots = [];
  for (const preset of presets) {
    for (const dark of [false, true]) {
      shots.push({ screen: 'home', preset, dark, w: 412, h: 900 });
    }
  }
  for (const screen of galleryScreens) {
    shots.push({ screen, preset: 'studio', dark: false, w: 412, h: 1500 });
  }
  for (const screen of ['accounts', 'cards', 'investing']) {
    for (const preset of ['voltage', 'bloom']) {
      shots.push({ screen, preset, dark: preset === 'voltage', w: 412, h: 1500 });
    }
  }
  // Heritage demo dashboard under its own preset, light and dark.
  for (const dark of [false, true]) {
    shots.push({ screen: 'heritage', preset: 'heritage', dark, w: 412, h: 900 });
  }
  // Flagship product-suite demo (Meridian): capture the key journey
  // screens in Studio light, plus a couple of alternates for the README.
  const flagshipScreens = [
    'flagship-home', 'flagship-catalog', 'flagship-product',
    'flagship-apply', 'flagship-my-products', 'flagship-my-cards',
    'flagship-currencies',
  ];
  for (const screen of flagshipScreens) {
    shots.push({ screen, preset: 'studio', dark: false, w: 412, h: 1600 });
  }
  shots.push({ screen: 'flagship-home', preset: 'studio', dark: true, w: 412, h: 1600 });
  shots.push({ screen: 'flagship-product', preset: 'heritage', dark: false, w: 412, h: 1600 });
  shots.push({ screen: 'flagship-catalog', preset: 'voltage', dark: true, w: 412, h: 1600 });

  console.log(`\n── Screens (${shots.length}) ─────────────────────────────────────────────`);
  // Reuse a single page for all screen shots, resizing viewport as needed.
  const screenPage = await browser.newPage({
    viewport: { width: 412, height: 900 },
    deviceScaleFactor: 1,
  });
  for (const s of shots) {
    totalAttempts++;
    await screenPage.setViewportSize({ width: s.w, height: s.h });
    const url =
      `http://localhost:${PORT}/index.html?screen=${s.screen}` +
      `&preset=${s.preset}&dark=${s.dark ? 1 : 0}`;
    try {
      await navigatePage(screenPage, url);
      const name = `${s.screen}-${s.preset}-${s.dark ? 'dark' : 'light'}.png`;
      await screenPage.screenshot({ path: join(outDir, name) });
      totalOk++;
      console.log(`✓ ${name}`);
    } catch (e) {
      console.error(`✗ ${s.screen}-${s.preset}: ${e.message}`);
    }
  }
  await screenPage.close();
}

// ── 2. COMPONENT SHOTS ───────────────────────────────────────────────────────
if (!screensOnly) {
  // Full list of gallery entries from component_registry.dart.
  // isFullScreen entries get a taller viewport so the content is visible.
  const components = [
    // Accounts & Balances
    { name: 'BankBalanceText',            fullScreen: false },
    { name: 'BankAccountCard',            fullScreen: true  },
    { name: 'BankAccountSwitcher',        fullScreen: true  },
    // Cards
    { name: 'BankVirtualCardWidget',      fullScreen: false },
    { name: 'BankHorizontalAccountCard',  fullScreen: false },
    { name: 'BankFlipCard',              fullScreen: false },
    { name: 'BankCardControlsPanel',      fullScreen: true  },
    { name: 'BankPhysicalCardMaterialPicker', fullScreen: true },
    { name: 'BankCardPinManager',         fullScreen: false },
    // Transactions
    { name: 'BankTransactionListTile',    fullScreen: true  },
    { name: 'BankTransactionGroupHeader', fullScreen: true  },
    { name: 'BankTransactionDetailSheet', fullScreen: false },
    { name: 'BankTransactionFilterSheet', fullScreen: false },
    { name: 'BankReceiptView',            fullScreen: false },
    // Transfers & Payments
    { name: 'BankTransferReviewCard',     fullScreen: false },
    { name: 'BankPaymentRequestCard',     fullScreen: false },
    { name: 'BankScheduledTransferToggle', fullScreen: true },
    { name: 'BankAmountKeypad',           fullScreen: true  },
    { name: 'BankBeneficiaryPicker',      fullScreen: true  },
    { name: 'BankTransferResultScreen',   fullScreen: false },
    // Auth & Security
    { name: 'BankPinKeypad',              fullScreen: false },
    { name: 'BankPinDots',               fullScreen: false },
    { name: 'BankPrivacyToggle',          fullScreen: false },
    { name: 'BankDeviceTrustBanner',      fullScreen: true  },
    { name: 'BankBiometricPromptButton',  fullScreen: false },
    { name: 'BankSessionTimeoutDialog',   fullScreen: false },
    // States & Feedback
    { name: 'BankSkeletonLoader',         fullScreen: true  },
    { name: 'BankEmptyStateView',         fullScreen: false },
    { name: 'BankErrorStateView',         fullScreen: false },
    { name: 'BankSuccessAnimation',       fullScreen: false },
    { name: 'BankToastBanner',            fullScreen: true  },
    { name: 'BankFraudAlertBanner',       fullScreen: true  },
    // Insights
    { name: 'BankSpendingBreakdownChart', fullScreen: false },
    { name: 'BankBudgetGaugeWidget',      fullScreen: true  },
    { name: 'BankInsightCard',            fullScreen: true  },
    // Onboarding & KYC
    { name: 'BankStepProgressIndicator',  fullScreen: false },
    { name: 'BankAsyncVerificationState', fullScreen: false },
    { name: 'BankConsentModal',           fullScreen: false },
    // Saving
    { name: 'BankSavingsPotCard',         fullScreen: false },
    { name: 'BankPotContributionSheet',   fullScreen: false },
    // Social
    { name: 'BankJointTransactionListTile', fullScreen: true },
    { name: 'BankAccountOwnershipBadge',  fullScreen: false },
    { name: 'BankSharedGoalProgressCard', fullScreen: false },
    // Investing
    { name: 'BankPortfolioPerformanceChart', fullScreen: false },
    { name: 'BankHoldingsListTile',       fullScreen: true  },
    { name: 'BankAssetPriceTicker',       fullScreen: true  },
    { name: 'BankWatchlistCard',          fullScreen: false },
    // Credit
    { name: 'BankCreditLimitGauge',       fullScreen: false },
    { name: 'BankFlexEligibleBadge',      fullScreen: false },
    // Notifications
    { name: 'BankInAppNotificationCenter', fullScreen: true },
    // Parity release: common & forms
    { name: 'BankTextField',              fullScreen: true  },
    { name: 'BankAmountInputField',       fullScreen: true  },
    { name: 'BankMaskedInputField',       fullScreen: true  },
    { name: 'BankPhoneInputField',        fullScreen: true  },
    { name: 'BankCountryPicker',          fullScreen: true  },
    { name: 'BankPeriodSelector',         fullScreen: false },
    { name: 'BankEmblem',                 fullScreen: false },
    { name: 'BankSummaryStack',           fullScreen: true  },
    { name: 'BankStatusTracker',          fullScreen: false },
    { name: 'BankQuickActionsGrid',       fullScreen: true  },
    { name: 'BankMoneyProtectionBanner',  fullScreen: true  },
    { name: 'BankAppBar',                 fullScreen: true  },
    { name: 'BankBottomNavBar',           fullScreen: true  },
    // Parity release: accounts, auth, cards
    { name: 'BankProductItemTile',        fullScreen: true  },
    { name: 'BankAccountNumberText',      fullScreen: false },
    { name: 'BankOtpInput',               fullScreen: false },
    { name: 'BankScaApprovalSheet',       fullScreen: true  },
    { name: 'BankDeviceSessionTile',      fullScreen: true  },
    { name: 'BankWalletProvisioningButton', fullScreen: false },
    { name: 'BankTravelNoticeForm',       fullScreen: true  },
    { name: 'BankShariahBadge',           fullScreen: false },
    // Parity release: payments & billing
    { name: 'BankBillPayTile',            fullScreen: true  },
    { name: 'BankStandingOrderTile',      fullScreen: true  },
    { name: 'BankTransferLimitManager',   fullScreen: true  },
    { name: 'BankMyQrCard',               fullScreen: false },
    // Parity release: business banking
    { name: 'BankApprovalRequestTile',    fullScreen: true  },
    { name: 'BankValueDiffRow',           fullScreen: true  },
    // Parity release: documents, insights, credit
    { name: 'BankStatementListTile',      fullScreen: true  },
    { name: 'BankCashflowChart',          fullScreen: true  },
    { name: 'BankRecurringMerchantTile',  fullScreen: true  },
    { name: 'BankCreditScoreGauge',       fullScreen: false },
    { name: 'BankLoanCalculatorCard',     fullScreen: true  },
    // Parity release: notifications, onboarding, support
    { name: 'BankAlertPreferencesPanel',  fullScreen: true  },
    { name: 'BankConsentManagementList',  fullScreen: true  },
    { name: 'BankAddressForm',            fullScreen: true  },
    { name: 'BankOnboardingCarousel',     fullScreen: true  },
    { name: 'BankSecureMessageThread',    fullScreen: true  },
    { name: 'BankHelpFaqList',            fullScreen: true  },
    // Top-20 research release
    { name: 'BankStoriesCarousel',        fullScreen: true  },
    { name: 'BankPeekBalance',            fullScreen: false },
    { name: 'BankEarlyPaydayCard',        fullScreen: true  },
    { name: 'BankBillForecastList',       fullScreen: true  },
    { name: 'BankAtmLocatorTile',         fullScreen: true  },
    { name: 'BankCardlessCashCode',       fullScreen: false },
    { name: 'BankOffersRail',             fullScreen: true  },
    { name: 'BankCashbackCategoryPicker', fullScreen: true  },
    { name: 'BankPointsHubCard',          fullScreen: true  },
    { name: 'BankSavingsChallengeCard',   fullScreen: true  },
    { name: 'BankFinancialHealthScore',   fullScreen: true  },
    { name: 'BankFoundMoneyList',         fullScreen: true  },
    { name: 'BankCreditLimitAdjuster',    fullScreen: true  },
    { name: 'BankPreapprovedLoanCard',    fullScreen: true  },
    { name: 'BankOverdraftCushionMeter',  fullScreen: true  },
    { name: 'BankZakatCalculator',        fullScreen: true  },
    { name: 'BankDonationHubCard',        fullScreen: true  },
    { name: 'BankCallVerificationScreen', fullScreen: true  },
    { name: 'BankEidLoginButton',         fullScreen: true  },
    { name: 'BankPanicFreezeButton',      fullScreen: false },
    { name: 'BankMerchantBlockList',      fullScreen: true  },
    { name: 'BankFamilyCardTile',         fullScreen: true  },
    { name: 'BankDisposableCardTile',     fullScreen: true  },
    // Community savings & assistant
    { name: 'BankMoneyCircleCard',        fullScreen: true  },
    { name: 'BankPrizeDrawCard',          fullScreen: true  },
    { name: 'BankSavingsProjectionCard',  fullScreen: true  },
    { name: 'BankAssistantPanel',         fullScreen: true  },
    // App gates & degraded states
    { name: 'BankAppGateScreen',          fullScreen: true  },
    { name: 'BankConnectivityBanner',     fullScreen: true  },
    { name: 'BankServiceStatusList',      fullScreen: true  },
    { name: 'BankUpdatePromptSheet',      fullScreen: true  },
    // Cards expansion
    { name: 'BankPaymentCard',            fullScreen: true  },
    { name: 'BankCardCarousel',           fullScreen: true  },
    { name: 'BankBalanceTileRow',         fullScreen: true  },
    { name: 'BankNetworkBadge',           fullScreen: false },
    // Products & applications
    { name: 'BankProductCard',            fullScreen: true  },
    { name: 'BankProductCategoryTile',    fullScreen: true  },
    { name: 'BankEligibilityResultCard',  fullScreen: true  },
    { name: 'BankOfferSummaryCard',       fullScreen: true  },
    { name: 'BankRatioGauge',             fullScreen: true  },
    { name: 'BankDisclosureConsentSheet', fullScreen: true  },
    { name: 'BankESignaturePad',          fullScreen: true  },
  ];

  // --only=Name1,Name2 restricts the component sweep (incremental capture).
  const onlyArg = args.find((a) => a.startsWith('--only='));
  const filtered = onlyArg
    ? components.filter((c) =>
        onlyArg.slice('--only='.length).split(',').includes(c.name))
    : components;

  // Preset variants: studio-light is the canonical top-level shot; the
  // other presets land in components/<preset>/ for theme-specific decks.
  const variants = [
    { preset: 'studio',   dark: 0, dir: compDir },
    { preset: 'heritage', dark: 0, dir: join(compDir, 'heritage') },
    { preset: 'voltage',  dark: 1, dir: join(compDir, 'voltage') },
    { preset: 'bloom',    dark: 0, dir: join(compDir, 'bloom') },
  ];
  for (const v of variants) mkdirSync(v.dir, { recursive: true });

  console.log(
    `\n── Components (${filtered.length} × ${variants.length} presets) ──────────────`,
  );
  // Reuse a single page; resize viewport per component to save memory.
  const compPage = await browser.newPage({
    viewport: { width: 375, height: 600 },
    deviceScaleFactor: 1,
  });
  for (const v of variants) {
    for (const c of filtered) {
      totalAttempts++;
      const h = c.fullScreen ? 812 : 600;
      await compPage.setViewportSize({ width: 375, height: h });
      const url =
        `http://localhost:${PORT}/index.html?component=${encodeURIComponent(c.name)}` +
        `&preset=${v.preset}&dark=${v.dark}`;
      try {
        await navigatePage(compPage, url);
        const file = join(v.dir, `${c.name}.png`);
        await compPage.screenshot({ path: file });
        totalOk++;
        console.log(`✓ ${v.preset}/${c.name}.png`);
      } catch (e) {
        console.error(`✗ ${v.preset}/${c.name}: ${e.message}`);
      }
    }
  }
  await compPage.close();
}

await browser.close();
server.close();
console.log(`\nDone: ${totalOk}/${totalAttempts} screenshots`);
console.log(`  screens  → ${outDir}`);
console.log(`  components → ${compDir}`);
