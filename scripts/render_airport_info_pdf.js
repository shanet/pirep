#!/usr/bin/env node

const fs = require('node:fs');
const puppeteer = require('puppeteer-core');

(async () => {
  try {
    const browser = await puppeteer.launch({
      executablePath: '/usr/bin/chromium',
      args: ['--headless', '--enable-gpu', '--no-sandbox']
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
    console.log(`Rendering ${pdf['url']} to ${pdf['output']}`);

    try {
      const page = await browser.newPage();
      await page.goto(pdf['url'], {waitUntil: 'networkidle2'});

      await page.pdf({
        path: pdf['output'],
        format: 'A4',
        printBackground: true,
      });
    } catch(error) {
      console.error(`Failed to render PDF for ${pdf['url']}`);
      console.error(error);
      process.exit(1);
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
