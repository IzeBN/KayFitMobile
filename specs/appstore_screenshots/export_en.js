const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const FRAMES = [
  { id: 'main',    title: '1 · Track every meal' },
  { id: 'chat',    title: '2 · AI Nutritionist chat' },
  { id: 'voice',   title: '3 · Voice logging' },
  { id: 'photo',   title: '4 · Meal scan' },
  { id: 'barcode', title: '5 · Barcode' },
  { id: 'plan',    title: '6 · Personal plan' },
];

const W = 1320;
const H = 2868;
const OUT_DIR = path.resolve(__dirname, 'en');
const CHROME_PATH = process.env.PUPPETEER_EXECUTABLE_PATH ||
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

(async () => {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const browser = await puppeteer.launch({
    headless: 'new',
    executablePath: CHROME_PATH,
  });
  const page = await browser.newPage();
  await page.setViewport({ width: W, height: H, deviceScaleFactor: 1 });
  const url = 'file://' + path.resolve(__dirname, 'screenshots.en.html');
  await page.goto(url, { waitUntil: 'networkidle0' });

  for (const f of FRAMES) {
    const el = await page.$(`#frame-${f.id}`);
    if (!el) { console.warn(`skip: #frame-${f.id} not found`); continue; }
    const out = path.resolve(OUT_DIR, `appstore_${f.id}.png`);
    await el.screenshot({ path: out, omitBackground: false });
    console.log(`✓ ${f.title} → ${out}`);
  }

  await browser.close();
  console.log('\nDone. 6 EN PNGs at 1320 × 2868.');
})();
