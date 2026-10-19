const CACHE='moonveil-dark-game-2026-10-18-v8';
const CORE=['./','index.html','style.css?v=20261018-dm2','app.js?v=20261018-dm2','engine.js?v=20261018-dm2','world.js','life-data.js','life-engine.js','life-view.js?v=20261018-cinema4','mythos.js','companion-ai.js','session.js?v=20261018-dm2','scene-art.js','scene-director.js?v=20261018-dm2','dm-view.js?v=20261018-dm2','audio.js?v=20261018-cinema4','dialogue.js?v=20261018-dm2','vendor/moonveil-rules.js','assets/library/library-manifest.json','assets/generated-manifest.json','assets/moonveil-realms.png','manifest.webmanifest','pwa.js?v=20261018-install1','assets/moonveil-icon-192.png','assets/moonveil-icon-512.png','assets/moonveil-icon.svg'];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(CORE)).then(()=>self.skipWaiting())));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('moonveil-dark-game-')&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{
 if(e.request.method!=='GET'||new URL(e.request.url).origin!==self.location.origin)return;
 e.respondWith(fetch(e.request).then(response=>{if(response.ok){const copy=response.clone();caches.open(CACHE).then(c=>c.put(e.request,copy)).catch(()=>{});}return response;}).catch(async()=>{const cached=await caches.match(e.request);if(cached)return cached;if(e.request.mode==='navigate')return caches.match('./');return Response.error();}));
});
