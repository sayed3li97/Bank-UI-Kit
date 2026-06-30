// Documentation screenshot generator.
//
// Serves the built Flutter web harness (example/build/web) and drives a
// headless Chromium via Playwright to capture every screen across the three
// presets and light/dark, writing PNGs into docs/screenshots/.
//
// Usage:
//   cd example && flutter build web -t lib/screenshot_harness.dart --release
//   node tools/screenshots.mjs
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
const outDir = join(repoRoot, 'docs', 'screenshots');

if (!existsSync(webRoot)) {
  console.error(`Build not found at ${webRoot}. Run the flutter build first.`);
  process.exit(1);
}
mkdirSync(outDir, { recursive: true });

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
    if (!existsSync(filePath)) filePath = join(webRoot, 'index.html'); // SPA fallback
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

const presets = ['studio', 'voltage', 'bloom'];

// Component-showcase screens — long ListViews, captured tall to show more.
const galleryScreens = [
  'states', 'accounts', 'transactions', 'transfers', 'cards', 'auth',
  'onboarding', 'saving', 'social', 'investing', 'credit',
  'subscriptions', 'insights', 'notifications',
];

// Build the capture matrix.
const shots = [];
// Hero: full-app home in every preset, light + dark.
for (const preset of presets) {
  for (const dark of [false, true]) {
    shots.push({ screen: 'home', preset, dark, w: 412, h: 900 });
  }
}
// Every gallery screen once (studio light) for the component catalog.
for (const screen of galleryScreens) {
  shots.push({ screen, preset: 'studio', dark: false, w: 412, h: 1500 });
}
// Theme-variety: a few representative screens in voltage + bloom.
for (const screen of ['accounts', 'cards', 'investing']) {
  for (const preset of ['voltage', 'bloom']) {
    shots.push({ screen, preset, dark: preset === 'voltage', w: 412, h: 1500 });
  }
}

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_PATH || '/opt/pw-browsers/chromium',
  args: ['--no-sandbox', '--force-color-profile=srgb'],
});

let ok = 0;
for (const s of shots) {
  const page = await browser.newPage({
    viewport: { width: s.w, height: s.h },
    deviceScaleFactor: 2,
  });
  const url =
    `http://localhost:${PORT}/index.html?screen=${s.screen}` +
    `&preset=${s.preset}&dark=${s.dark ? 1 : 0}`;
  try {
    await page.goto(url, { waitUntil: 'load', timeout: 60000 });
    // Wait for Flutter to attach its render surface.
    await page
      .waitForSelector('flt-glass-pane, flt-scene-host, flutter-view', { timeout: 45000 })
      .catch(() => {});
    // Let entry animations / layout settle.
    await page.waitForTimeout(2800);
    const name = `${s.screen}-${s.preset}-${s.dark ? 'dark' : 'light'}.png`;
    await page.screenshot({ path: join(outDir, name) });
    ok++;
    console.log(`✓ ${name}`);
  } catch (e) {
    console.error(`✗ ${s.screen}-${s.preset}: ${e.message}`);
  } finally {
    await page.close();
  }
}

await browser.close();
server.close();
console.log(`\nDone: ${ok}/${shots.length} screenshots → ${outDir}`);
