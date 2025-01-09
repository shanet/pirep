#!/usr/bin/env node

const fs = require('node:fs');
const puppeteer = require('puppeteer-core');

(async () => {
  const browser = await puppeteer.launch({
    executablePath: '/usr/bin/chromium',
    args: ['--headless', '--enable-gpu', '--no-sandbox']
  });

  const render_queue_path = process.argv[2];
  console.log(`Reading render queue from ${render_queue_path}`);
  const render_queue = JSON.parse(fs.readFileSync(render_queue_path, 'utf8'));

  for(const pdf of render_queue) {
    console.log(`Rendering ${pdf['url']} to ${pdf['output']}`);

    const page = await browser.newPage();
    await page.goto(pdf['url'], {waitUntil: 'networkidle2'});

    await page.pdf({
      path: pdf['output'],
      format: 'A4',
      printBackground: true,
    });
  }

  await browser.close();
})();
