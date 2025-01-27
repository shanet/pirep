#!/usr/bin/env node

const fs = require('node:fs');
const puppeteer = require('puppeteer-core');

const TIMEOUT = 300000; // Give a long 5 minute timeout for slow software-based WebGL rendering
const RETRY_LIMIT = 3;

async function main() {
  let browser = await openBrowser();

  const render_queue_path = process.argv[2];
  console.log(`Reading render queue from ${render_queue_path}`);
  const render_queue = JSON.parse(fs.readFileSync(render_queue_path, 'utf8'));

  for(let i=0; i<render_queue.length; i++) {
    const pdf = render_queue[i];
    console.log(`(${i+1}/${render_queue.length}) Rendering ${pdf['url']} to ${pdf['output']}`);

    let retries = 0;

    while(retries < RETRY_LIMIT) {
      try {
        const page = await browser.newPage();

        await page.goto(pdf['url'], {waitUntil: 'networkidle0', timeout: TIMEOUT});

        // Wait for the map to fully load its tiles and annotations
        await page.waitForSelector('#airport-map[data-ready="true"]', {timeout: TIMEOUT});

        await page.pdf({
          format: 'A4',
          path: pdf['output'],
          preferCSSPageSize: true,
          printBackground: true,
        });

        break;
      } catch(error) {
        // Puppeteer seems to be kind of flaky with rendering pages as PDFs so try a few times with a browser restart for good measure before giving up
        if(error instanceof puppeteer.ProtocolError && retries <= RETRY_LIMIT) {
          console.error(`Failed to render PDF for ${pdf['url']}, retrying (attempt ${retries + 1})`);
          retries++;

          await closeBrowser(browser);
          browser = await openBrowser();

          continue;
        }

        console.error(`Failed to render PDF for ${pdf['url']}, giving up`);
        console.error(error);
        process.exit(1);
      }
    }
  }

  await closeBrowser(browser);
  console.log('Rendering complete')
}

async function openBrowser() {
  try {
    console.log('Launching browser');

    // In production, the local webserver serving the snapshot pages for the PDFs will be HTTP but assets from the CDN
    // are over HTTPS. To get Chrome to load these as mixed content we need to disable some security settings below.
    // It would be nice to start Puma with TLS, but Chrome still won't render assets for some reason? Hmm.
    return puppeteer.launch({
      args: [
        '--allow-running-insecure-content',
        '--disable-gpu',
        '--disable-web-security',
        '--enable-unsafe-swiftshader',
        '--no-sandbox',
      ],
      dumpio: true,
      executablePath: '/usr/bin/chromium',
      headless: true,
    });
  } catch(error) {
    console.error('Failed to launch browser');
    console.error(error);
    process.exit(1);
  }
}

async function closeBrowser(browser) {
  console.log('Closing browser');

  try {
    return browser.close();
  } catch(error) {
    console.error('Failed to close browser');
    console.error(error);
    process.exit(1);
  }
}

main();
