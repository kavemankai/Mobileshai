import assert from 'node:assert/strict';

const saveKey = 'last-check-in-save-v2';

// Runs against the built PWA on loopback. Each viewport has fresh browser storage.
export default async function ({ page, context, mobile, capture }) {
  const play = locator => mobile ? locator.tap() : locator.click();
  const location = new URL(page.url());
  const readSave = () => page.evaluate(key => localStorage.getItem(key), saveKey);
  async function frame(name) {
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 1), false,
      name + ' has horizontal overflow');
    const badImages = await page.locator('img').evaluateAll(async images => {
      await Promise.allSettled(images.map(image => image.decode()));
      return images.filter(image => !image.naturalWidth).map(image => image.getAttribute('src'));
    });
    assert.deepEqual(badImages, [], name + ' image decode failures');
    await capture(name);
  }

  assert.equal(await page.evaluate(() => typeof window.__lci), 'undefined');
  await frame('title');
  await play(page.getByRole('button', { name: 'Settings', exact: true }));
  const settings = page.getByRole('dialog', { name: 'Settings' });
  await settings.waitFor();
  await frame('settings');
  await play(settings.getByRole('button', { name: 'Close' }));
  await play(page.getByRole('button', { name: /Begin your shift/ }));
  await page.locator('.name-input').fill('Toolkit QA');
  await play(page.getByRole('button', { name: 'Start the shift' }));
  await play(page.locator('.chapter'));
  await play(page.locator('.dialogue'));
  await frame('narrative');
  const saved = await readSave();
  assert.equal(JSON.parse(saved).line, 1);
  await page.reload();
  await play(page.getByRole('button', { name: /Continue · Chapter 1/ }));
  assert.equal(await readSave(), saved);

  const debug = new URL(location);
  debug.searchParams.set('debug', '1');
  await page.goto(debug.href);
  await page.evaluate(() => window.__lci.jump(4));
  await frame('puzzle');
  await page.evaluate(() => window.__lci.jump(27));
  await play(page.getByRole('button', { name: 'DEV skip' }));
  await play(page.getByRole('button', { name: 'Continue', exact: true }));
  await page.evaluate(() => window.__lci.finishScene());
  assert.equal(await page.evaluate(() => window.__lci.state().phase), 'end');
  assert.equal(await readSave(), saved, 'debug sandbox must preserve the real save');
  await frame('ending');

  await page.goto(location.href);
  await page.waitForFunction(() => Boolean(navigator.serviceWorker.controller));
  await context.setOffline(true);
  await page.reload();
  await page.getByRole('button', { name: /Continue · Chapter 1/ }).waitFor();
  assert.equal(await readSave(), saved);
  assert.equal(await page.evaluate(() => typeof window.__lci), 'undefined');
}
