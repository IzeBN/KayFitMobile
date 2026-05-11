// Export each screenshot frame to a 1320 × 2868 PNG — Apple's primary
// App Store screenshot size for iPhone 6.9" Display (iPhone 16 Pro Max).
//
// Run:
//   cd specs/appstore_screenshots
//   npm install puppeteer
//   node export.js
//
// Output: appstore_<id>.png next to this script (6 PNGs, ~150 KB each).

const puppeteer = require('puppeteer');
const path = require('path');

const FRAMES = [
  { id: 'main',     title: '1 · Track every meal (visit card)' },
  { id: 'chat',     title: '2 · AI Nutritionist chat' },
  { id: 'voice',    title: '3 · Voice logging' },
  { id: 'photo',    title: '4 · Meal scan' },
  { id: 'barcode',  title: '5 · Barcode' },
  { id: 'plan',     title: '6 · Personal plan' },
];

const W = 1320;
const H = 2868;

// Use macOS-installed Chrome to avoid puppeteer's separate browser download.
// Override with PUPPETEER_EXECUTABLE_PATH env var if needed.
const CHROME_PATH = process.env.PUPPETEER_EXECUTABLE_PATH ||
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    executablePath: CHROME_PATH,
  });
  const page = await browser.newPage();
  await page.setViewport({ width: W, height: H, deviceScaleFactor: 1 });
  const url = 'file://' + path.resolve(__dirname, 'screenshots.html');
  await page.goto(url, { waitUntil: 'networkidle0' });

  for (const f of FRAMES) {
    const el = await page.$(`#frame-${f.id}`);
    if (!el) {
      console.warn(`skip: #frame-${f.id} not found`);
      continue;
    }
    const out = path.resolve(__dirname, `appstore_${f.id}.png`);
    await el.screenshot({ path: out, omitBackground: false });
    console.log(`✓ ${f.title} → ${out}`);
  }

  await browser.close();
  console.log('\nDone. 6 PNGs at 1320 × 2868. Upload to App Store Connect.');
})();
