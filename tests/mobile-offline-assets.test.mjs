import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'../dist');

test('mobile app includes offline worker, cinematic CSS and protected cloud controls',async()=>{
 const [html,pwa,cloud,style]=await Promise.all(['index.html','pwa.js','cloud-sync.js','style.css'].map(f=>fs.readFile(path.join(root,f),'utf8')));
 assert.match(html,/name="viewport"/);
 assert.match(html,/cloud-sync\.js/);
 assert.match(html,/pwa\.js/);
 assert.match(pwa,/serviceWorker/);
 assert.match(cloud,/moonveil-cloud-export-local/);
 assert.match(cloud,/URL\.createObjectURL/);
 assert.match(cloud,/moonveil-universe-play-v1/);
 assert.match(cloud,/If-Match/);
 assert.match(cloud,/backup-/);
 assert.match(style,/(background-image|url\(|image-rendering)/);
});
test('assets referenced by relative CSS urls resolve, excluding inline and remote art',async()=>{
 const css=await fs.readFile(path.join(root,'style.css'),'utf8');
 const refs=[...css.matchAll(/url\(\s*['"]?([^'")]+)['"]?\s*\)/g)].map(m=>m[1]).filter(u=>!(/^(https?:|data:|#)/i.test(u)));
 const missing=[];
 for(const ref of refs){
  const clean=decodeURIComponent(ref.split(/[?#]/)[0]);
  if(!clean)continue;
  try{await fs.access(path.resolve(root,clean));}catch{missing.push(clean);}
 }
 assert.deepEqual(missing,[],'Cinematic image or UI assets missing from dist');
});
