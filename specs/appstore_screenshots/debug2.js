const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1320, height: 2868, deviceScaleFactor: 1 });
  const url = 'file://' + path.resolve(__dirname, 'screenshots.en.html.bak');
  console.log('Loading:', url);
  try {
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 15000 });
  } catch (e) {
    console.log('timeout (likely Google Fonts), continuing...');
  }
  const title = await page.title();
  console.log('Page title:', title);
  const el = await page.$('#frame-main');
  console.log('frame-main found:', el !== null);
  await browser.close();
})();
