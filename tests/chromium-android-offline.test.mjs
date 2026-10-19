import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { createHandler } from '../server/server.mjs';

test('mobile Chromium renders, caches the offline shell and retains local save', {timeout:120000}, async t => {
  const {chromium,devices}=await import('playwright-core');
  const server=http.createServer(createHandler({playerToken:'mobile-player-token-123456789012345',dmToken:'mobile-dm-token-1234567890123456789',serveStatic:true}));
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  let browser;
  try {
    browser=await chromium.launch({headless:true});
    const context=await browser.newContext({...devices['Pixel 7'],serviceWorkers:'allow'});
    const page=await context.newPage();
    const errors=[];
    page.on('pageerror',error=>errors.push(error.message));
    const origin='http://127.0.0.1:'+server.address().port;
    await page.goto(origin,{waitUntil:'domcontentloaded'});
    await page.locator('#app').waitFor();
    await page.waitForFunction(()=>navigator.serviceWorker?.controller!==null,{timeout:30000});
    const initial=await page.evaluate(()=>({width:document.documentElement.scrollWidth,viewport:innerWidth,local:localStorage.getItem('moonveil-universe-play-v1')}));
    assert.ok(initial.width<=initial.viewport+2,'Mobile viewport must not overflow horizontally');
    const art=await page.evaluate(()=>[...document.images].filter(img=>new URL(img.src).origin===location.origin).map(img=>({src:img.getAttribute('src'),ok:img.complete&&img.naturalWidth>0})));
    assert.ok(art.every(image=>image.ok),'Local cinematic image failed to load: '+JSON.stringify(art.filter(image=>!image.ok)));
    await context.setOffline(true);
    await page.reload({waitUntil:'domcontentloaded'});
    await page.locator('#app').waitFor();
    assert.equal(await page.evaluate(()=>localStorage.getItem('moonveil-universe-play-v1')),initial.local);
    assert.deepEqual(errors,[],'No uncaught browser errors');
    await context.close();
  } finally {
    await browser?.close();
    await new Promise(resolve=>server.close(resolve));
  }
});
