import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,rm,readFile,access} from 'node:fs/promises';
import os from 'node:os';import path from 'node:path';import http from 'node:http';
import {createHandler,dmOpenApi} from '../server/server.mjs';
const ROOT=new URL('../dist/',import.meta.url);
test('full site retains original art and PWA app shell',async()=>{
 for(const name of ['index.html','app.js','style.css','manifest.webmanifest','pwa.js','sw.js','continuity.js'])await access(new URL(name,ROOT));
 const html=await readFile(new URL('index.html',ROOT),'utf8');
 assert.match(html,/Moonveil Universe/);assert.match(html,/manifest.webmanifest/);
 const css=await readFile(new URL('style.css',ROOT),'utf8');assert.ok(css.length>1000);
 const files=(await import('node:fs')).readdirSync(new URL('assets/',ROOT));assert.ok(files.length>0);
});
test('OpenAPI connector schema restricts commands and protects secrets',()=>{
 const spec=dmOpenApi();assert.equal(spec.openapi,'3.1.0');
 const action=spec.paths['/api/dm/action'].post;
 const schema=action.requestBody.content['application/json'].schema;
 assert.ok(schema.properties.action.enum.includes('explore'));
 assert.ok(!schema.properties.action.enum.includes('runCode'));
 assert.ok(action.security[0].dmBearer);assert.doesNotMatch(JSON.stringify(spec),/player-secret|dm-secret/);
});
test('HTTP server serves actual game and connector schema with safety headers',async()=>{
 const tmp=await mkdtemp(path.join(os.tmpdir(),'moonveil-deploy-'));
 const server=http.createServer(createHandler({playerToken:'player-abcdefghijklmnopqrstvwxxyz',dmToken:'master-abcdefghijklmnopqrstvwxxyz',storageDir:tmp}));
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const base=`http://127.0.0.1:${server.address().port}`;
 try{let response=await fetch(base+'/');assert.equal(response.status,200);assert.match(await response.text(),/Moonveil Universe/);assert.equal(response.headers.get('x-frame-options'),'DENY');
 response=await fetch(base+'/manifest.webmanifest');assert.equal(response.status,200);
 response=await fetch(base+'/openapi.json');assert.equal(response.status,200);assert.equal((await response.json()).openapi,'3.1.0');
 response=await fetch(base+'/healthz');assert.deepEqual(await response.json(),{ok:true});}
 finally{await new Promise(r=>server.close(r));await rm(tmp,{recursive:true,force:true});}
});
