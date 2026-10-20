// Renders overlay.html frame by frame into transparent PNGs.
// usage: node render-overlay.mjs <assetsDir> <outDir> [--fps 30] [--duration 30] [--at 3.5,10,...]
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const [assetsDir, outDir, ...rest] = process.argv.slice(2);
const opt = (name, def) => { const i = rest.indexOf(`--${name}`); return i >= 0 ? rest[i + 1] : def; };
const fps = +opt('fps', 30);
const duration = +opt('duration', 30);
const at = opt('at', null);

fs.mkdirSync(outDir, { recursive: true });
const html = fs.readFileSync(path.join(here, 'overlay.html'), 'utf8')
  .replaceAll('ASSETS/', `file://${path.resolve(assetsDir)}/`);
const pagePath = path.join(path.resolve(outDir), '_overlay.html');
fs.writeFileSync(pagePath, html);

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
await page.goto(`file://${pagePath}`, { waitUntil: 'networkidle' });
await page.evaluate(() => document.fonts.ready);
fs.writeFileSync(path.join(outDir, 'sfx_cues.json'), JSON.stringify(await page.evaluate(() => window.SFX_CUES)));

const times = at ? at.split(',').map(Number) : Array.from({ length: Math.round(fps * duration) }, (_, i) => i / fps);
for (const [i, t] of times.entries()) {
  await page.evaluate(tt => window.setTime(tt), t);
  const name = at ? `at_${t.toFixed(2)}.png` : `${String(i).padStart(5, '0')}.png`;
  await page.screenshot({ path: path.join(outDir, name), omitBackground: true });
  if (!at && i % 150 === 0) console.log(`frame ${i}/${times.length}`);
}
await browser.close();
