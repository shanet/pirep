#!/usr/bin/env node

const fs = require('node:fs');
const puppeteer = require('puppeteer-core');

const RETRY_LIMIT = 3;

(async () => {
  let browser;

  try {
    // In production, the local webserver serving the snapshot pages for the PDFs will be HTTP but assets from the CDN
    // are over HTTPS. To get Chrome to load these as mixed content we need to disable some security settings below.
    // It would be nice to start Puma with TLS, but Chrome still won't render assets for some reason? Hmm.
    browser = await puppeteer.launch({
      args: [
        '--allow-running-insecure-content',
        '--disable-gpu',
        '--disable-web-security',
        '--enable-unsafe-swiftshader',
        '--no-sandbox',
      ],
      // dumpio: true, // Uncomment for debugging
      executablePath: '/usr/bin/chromium',
      headless: true,
    });
  } catch(error) {
    console.log('Failed to launch Puppeteer');
    console.log(error);
    process.exit(1);
  }

  const render_queue_path = process.argv[2];
  console.log(`Reading render queue from ${render_queue_path}`);
  const render_queue = JSON.parse(fs.readFileSync(render_queue_path, 'utf8'));

  for(const pdf of render_queue) {
    // Uncomment for debugging
    // console.log(`Rendering ${pdf['url']} to ${pdf['output']}`);

    let retries = 0;

    while(retries < RETRY_LIMIT) {
      try {
        const page = await browser.newPage();
        await page.goto(pdf['url'], {waitUntil: 'networkidle0'});

        await page.pdf({
          format: 'A4',
          path: pdf['output'],
          preferCSSPageSize: true,
          printBackground: true,
        });

        break;
      } catch(error) {
        // Puppeteer seems to be kind of flaky with rendering pages as PDFs so try a few times before giving up
        if(error instanceof puppeteer.ProtocolError && retries <= RETRY_LIMIT) {
          console.error(`Failed to render PDF for ${pdf['url']}, retrying (attempt ${retries + 1})`);
          retries++;
          continue;
        }

        console.error(`Failed to render PDF for ${pdf['url']}, giving up`);
        console.error(error);
        process.exit(1);
      }
    }
  }

  try {
    await browser.close();
  } catch(error) {
    console.error('Failed to close browser');
    console.error(error);
    process.exit(1);
  }
})();
