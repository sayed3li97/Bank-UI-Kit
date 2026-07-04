// Builds an animated GIF walkthrough of the flagship Auto Finance apply
// journey by capturing each step of FlagshipApplyFlow from the screenshot
// harness and stitching the frames together.
//
//   cd example && flutter build web -t lib/screenshot_harness.dart --release \
//     --no-web-resources-cdn --no-tree-shake-icons
//   node tool/walkthrough.mjs
//
// Output: doc/screenshots/flagship-apply-walkthrough.gif
import { createServer } from 'node:http';
import { readFile, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, extname, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { PNG } from 'pngjs';
import gifenc from 'gifenc';
const { GIFEncoder, quantize, applyPalette } = gifenc;

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(__dirname, '..');
const webRoot = join(repoRoot, 'example', 'build', 'web');
const outPath = join(repoRoot, 'doc', 'screenshots', 'flagship-apply-walkthrough.gif');

const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'application/javascript',
  '.mjs': 'application/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.css': 'text/css', '.png': 'image/png',
  '.otf': 'font/otf', '.ttf': 'font/ttf', '.bin': 'application/octet-stream',
  '.symbols': 'application/octet-stream',
};

const server = createServer(async (req, res) => {
  try {
    const url = new URL(req.url, 'http://localhost');
    let p = decodeURIComponent(url.pathname);
    if (p === '/' || p === '') p = '/index.html';
    let filePath = join(webRoot, p);
    if (!existsSync(filePath)) {
      if (extname(p)) { res.writeHead(404); res.end('nf'); return; }
      filePath = join(webRoot, 'index.html');
    }
    const body = await readFile(filePath);
    res.writeHead(200, {
      'content-type': MIME[extname(filePath)] || 'application/octet-stream',
      'cross-origin-opener-policy': 'same-origin',
      'cross-origin-embedder-policy': 'require-corp',
    });
    res.end(body);
  } catch (e) { res.writeHead(500); res.end(String(e)); }
});

const PORT = 8096;
await new Promise((r) => server.listen(PORT, r));

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_PATH || '/opt/pw-browsers/chromium',
  args: ['--no-sandbox', '--force-color-profile=srgb'],
  proxy: process.env.HTTPS_PROXY
    ? { server: process.env.HTTPS_PROXY, bypass: 'localhost,127.0.0.1' }
    : undefined,
});

const W = 412, H = 892;
const SCALE = 0.85; // shrink to keep the GIF light
const page = await browser.newPage({
  viewport: { width: W, height: H },
  deviceScaleFactor: 1,
});

// One meaningful frame per step, with a per-frame dwell time (ms).
const frames = [
  { step: 0, delay: 2200 }, // eligibility
  { step: 1, delay: 2200 }, // customize
  { step: 2, delay: 2600 }, // offer
  { step: 3, delay: 2000 }, // documents
  { step: 4, delay: 2400 }, // disclosures
  { step: 5, delay: 2200 }, // sign
  { step: 6, delay: 3200 }, // decision
];

const gif = GIFEncoder();
const OW = Math.round(W * SCALE), OH = Math.round(H * SCALE);

for (const f of frames) {
  const url = `http://localhost:${PORT}/index.html?screen=flagship-apply` +
    `&preset=studio&dark=0&step=${f.step}`;
  await page.goto(url, { waitUntil: 'load', timeout: 60000 });
  await page.waitForSelector('flt-glass-pane, flutter-view', { timeout: 45000 }).catch(() => {});
  await page.waitForTimeout(2600);
  const buf = await page.screenshot({ clip: { x: 0, y: 0, width: W, height: H } });
  const png = PNG.sync.read(buf);

  // Nearest-neighbour downscale W×H -> OW×OH into an RGBA buffer.
  const out = new Uint8Array(OW * OH * 4);
  for (let y = 0; y < OH; y++) {
    const sy = Math.min(H - 1, Math.floor(y / SCALE));
    for (let x = 0; x < OW; x++) {
      const sx = Math.min(W - 1, Math.floor(x / SCALE));
      const si = (sy * png.width + sx) * 4;
      const di = (y * OW + x) * 4;
      out[di] = png.data[si];
      out[di + 1] = png.data[si + 1];
      out[di + 2] = png.data[si + 2];
      out[di + 3] = 255;
    }
  }
  const palette = quantize(out, 256);
  const index = applyPalette(out, palette);
  gif.writeFrame(index, OW, OH, { palette, delay: f.delay });
  console.log(`✓ step ${f.step} (${OW}x${OH})`);
}

gif.finish();
await writeFile(outPath, Buffer.from(gif.bytes()));
console.log(`\nWrote ${outPath}`);

await browser.close();
server.close();
