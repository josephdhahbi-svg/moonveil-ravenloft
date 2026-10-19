import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { createHandler, dmOpenApi } from '../server/server.mjs';
import { createGame } from '../dist/engine.js';
import { CLASSES } from '../dist/world.js';

const PLAYER = 'test-player-token-not-for-production-0001';
const DM = 'test-dm-token-not-for-production-0000002';

test('authenticated DM and cross-device saves enforce revision checks without discarding local progress', async t => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'moonveil-api-recovery-'));
  const server = http.createServer(createHandler({playerToken:PLAYER,dmToken:DM,storageDir:root,serveStatic:false}));
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => {
    await new Promise(resolve => server.close(resolve));
    await fs.rm(root, {recursive:true,force:true});
  });
  const base = 'http://127.0.0.1:' + server.address().port;
  const call = async (endpoint, token, opts={}) => {
    const res=await fetch(base+endpoint,{...opts,headers:{...(token?{Authorization:'Bearer '+token}:{}),...(opts.headers||{})}});
    return {status:res.status,body:await res.json()};
  };
  assert.equal((await call('/api/save',null)).status,401);
  assert.equal((await call('/api/save','invalid-token')).status,401);
  assert.equal((await call('/api/dm/action',PLAYER,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:'rest',expectedRevision:1})})).status,403);
  assert.equal((await call('/api/save',DM,{method:'PUT',headers:{'Content-Type':'application/json','If-Match':'0'},body:JSON.stringify({game:{}})})).status,403);
  const original=createGame({name:'Vesper Vane',className:Object.keys(CLASSES)[0]});
  const first=await call('/api/save',PLAYER,{method:'PUT',headers:{'Content-Type':'application/json','If-Match':'0'},body:JSON.stringify({game:original})});
  assert.equal(first.status,200);
  assert.equal(first.body.revision,1);
  assert.equal(first.body.game.hero.name,'Vesper Vane');
  const localOffline=structuredClone(first.body.game);
  localOffline.notes.push('Offline progress: never silently replace this copy');
  const postAction=await call('/api/dm/action',DM,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:'rest',expectedRevision:1})});
  assert.equal(postAction.status,200);
  assert.equal(postAction.body.revision,2);
  const stale=await call('/api/save',PLAYER,{method:'PUT',headers:{'Content-Type':'application/json','If-Match':'1'},body:JSON.stringify({game:localOffline})});
  assert.equal(stale.status,409);
  assert.equal(stale.body.revision,2);
  assert.ok(localOffline.notes.includes('Offline progress: never silently replace this copy'));
  const fresh=await call('/api/save',PLAYER);
  assert.equal(fresh.status,200);
  assert.equal(fresh.body.revision,2);
  assert.equal(fresh.body.game.hero.name,'Vesper Vane');
  const staleDM=await call('/api/dm/action',DM,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:'rest',expectedRevision:1})});
  assert.equal(staleDM.status,409);
  const [a,b]=await Promise.all([1,2].map(()=>call('/api/save',PLAYER,{method:'PUT',headers:{'Content-Type':'application/json','If-Match':'2'},body:JSON.stringify({game:fresh.body.game})})));
  assert.deepEqual([a.status,b.status].sort((x,y)=>x-y),[200,409]);
  assert.equal((await call('/api/save',PLAYER)).body.revision,3);
  assert.equal((await call('/api/save?slot=..%2Fother',PLAYER)).status,400);
});
test('DM connector specification requires bearer authentication', () => {
  const doc=dmOpenApi('https://example.test');
  assert.equal(doc.components.securitySchemes.dmBearer.scheme,'bearer');
  assert.deepEqual(doc.paths['/api/dm/action'].post.security,[{dmBearer:[]}]);
  assert.ok(doc.paths['/api/dm/action'].post.requestBody.content['application/json'].schema.required.includes('expectedRevision'));
});
