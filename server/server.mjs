import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import * as E from '../dist/engine.js';
import {ensureEnhancedState} from '../dist/continuity.js';

const ROOT=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../dist');
const LIMIT=3_000_000;
const SECURITY_HEADERS={'Referrer-Policy':'no-referrer','X-Frame-Options':'DENY','X-Content-Type-Options':'nosniff','Permissions-Policy':'camera=(), microphone=(), geolocation=()'};
const ACTION_NAMES=['travel','explore','rest','talk','acceptQuest','completeQuest','usePotion','beginBattle','guard','endTurn','retreat','collectLoot'];
export function dmOpenApi(origin='https://YOUR-MOONVEIL-HOST') {
 const auth=[{dmBearer:[]}];
 const slot=[{name:'slot',in:'query',schema:{type:'string',default:'main'}}];
 return {
  openapi:'3.1.0',
  info:{title:'Moonveil Universe Dungeon Master API',version:'1.0.0',description:'Use private bearer authentication. Never expose a token in the public site.'},
  servers:[{url:origin}],
  components:{securitySchemes:{dmBearer:{type:'http',scheme:'bearer'}}},
  paths:{
   '/api/save':{get:{operationId:'readMoonveilSave',summary:'Read current save and revision',security:auth,parameters:slot,responses:{'200':{description:'Current campaign snapshot'},'401':{description:'Unauthorized'}}}},
   '/api/dm/action':{post:{operationId:'performMoonveilDMAction',summary:'Perform one authorized game action',security:auth,parameters:slot,
    requestBody:{required:true,content:{'application/json':{schema:{type:'object',required:['action','expectedRevision'],properties:{action:{type:'string',enum:ACTION_NAMES},expectedRevision:{type:'integer',minimum:0},destination:{type:'string'},questId:{type:'string'}},additionalProperties:false}}}},
    responses:{'200':{description:'Updated campaign'},'409':{description:'Revision conflict'},'422':{description:'Invalid action'}}}}
  }
 };
}
const validSlug=s=>typeof s==='string'&&/^[a-zA-Z0-9_-]{1,64}$/.test(s);
export const eqToken=(a,b)=>{if(!a||!b)return false;const x=crypto.createHash('sha256').update(a).digest();const y=crypto.createHash('sha256').update(b).digest();return crypto.timingSafeEqual(x,y);};
export function createHandler({playerToken,dmToken,storageDir,serveStatic=true}={}){
 if(!playerToken||playerToken.length<24||!dmToken||dmToken.length<24||playerToken===dmToken)throw Error('Configure two distinct random tokens (24+ chars): MOONVEIL_PLAYER_TOKEN and MOONVEIL_DM_TOKEN.');
 const dir=path.resolve(storageDir||path.join(process.cwd(),'private-saves'));
 const locks=new Map();
 const reply=(res,status,payload)=>{res.writeHead(status,{...SECURITY_HEADERS,'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'});res.end(JSON.stringify(payload));};
 async function body(req){let chunks=[],size=0;for await(const part of req){size+=part.length;if(size>LIMIT)throw Object.assign(new Error('Payload too large'),{status:413});chunks.push(part);}try{return JSON.parse(Buffer.concat(chunks).toString('utf8'));}catch{throw Object.assign(new Error('Invalid JSON'),{status:400});}}
 const filename=id=>path.join(dir,`${id}.json`);
 async function read(id){try{return JSON.parse(await fs.readFile(filename(id),'utf8'));}catch(e){if(e.code==='ENOENT')return null;throw e;}}
 async function write(id,record){await fs.mkdir(dir,{recursive:true,mode:0o700});const tmp=filename(id)+'.'+crypto.randomUUID()+'.tmp';await fs.writeFile(tmp,JSON.stringify(record),{mode:0o600});await fs.rename(tmp,filename(id));}
 async function locked(id,cb){const old=locks.get(id)||Promise.resolve();let release;const next=new Promise(resolve=>release=resolve);locks.set(id,next);await old;try{return await cb();}finally{release();if(locks.get(id)===next)locks.delete(id);}}
 const actions={travel:(s,a)=>E.travel(s,a.destination),explore:s=>E.explore(s),rest:s=>E.rest(s),talk:s=>E.talk(s),acceptQuest:(s,a)=>E.acceptQuest(s,a.questId),completeQuest:(s,a)=>E.completeQuest(s,a.questId),usePotion:s=>E.usePotion(s),beginBattle:s=>E.beginBattle(s),guard:s=>E.guard(s),endTurn:s=>E.endTurn(s),retreat:s=>E.retreat(s),collectLoot:s=>E.collectLoot(s)};
 return async function handler(req,res){
 try{
  const url=new URL(req.url,'http://moonveil.local');
  // Unauthenticated readiness probe contains no save or account information.
  if(url.pathname==='/healthz'&&req.method==='GET')return reply(res,200,{ok:true});
  if(url.pathname==='/openapi.json'&&req.method==='GET'){const base=process.env.MOONVEIL_PUBLIC_URL || (process.env.NODE_ENV==='production'?'':'http://127.0.0.1:4330'); if(!base)return reply(res,503,{error:'Public HTTPS connector URL not configured'}); if(process.env.NODE_ENV==='production'&&!/^https:\/\/[^\s/]+\/?$/.test(base))return reply(res,503,{error:'Public connector URL must be HTTPS'}); return reply(res,200,dmOpenApi(base.replace(/\/$/,'')));}
  if(url.pathname.startsWith('/api/')){
   const isPlayer=eqToken((req.headers.authorization||'').replace(/^Bearer /,''),playerToken);
   const isDM=eqToken((req.headers.authorization||'').replace(/^Bearer /,''),dmToken);
   if(!isPlayer&&!isDM)return reply(res,401,{error:'Unauthorized'});
   const id=url.searchParams.get('slot')||'main';
   if(!validSlug(id))return reply(res,400,{error:'Invalid slot'});
   if(url.pathname==='/api/health'&&req.method==='GET')return reply(res,200,{ok:true});
   if(url.pathname==='/api/save'&&req.method==='GET'){const current=await read(id);return current?reply(res,200,current):reply(res,404,{error:'Save not found'});}
   if(url.pathname==='/api/save'&&req.method==='PUT'){
    if(!isPlayer)return reply(res,403,{error:'Only the player can replace a save'});
    const payload=await body(req); try{E.validateGame(payload.game);}catch(e){return reply(res,400,{error:e.message});}
    return await locked(id,async()=>{const before=await read(id),revision=before?.revision??0;
     if(req.headers['if-match']!==String(revision))return reply(res,409,{error:'Save revision conflict',revision});
     const game=ensureEnhancedState(payload.game);game.revision=revision+1;
     const record={revision:revision+1,game,updatedAt:new Date().toISOString()};await write(id,record);return reply(res,200,record);
    });
   }
   if(url.pathname==='/api/dm/action'&&req.method==='POST'){
    if(!isDM)return reply(res,403,{error:'DM authorization required'});
    const input=await body(req);
    if(!input||typeof input!=='object'||!Object.hasOwn(actions,input.action))return reply(res,400,{error:'Action is not allowed'});
    return await locked(id,async()=>{const before=await read(id);if(!before)return reply(res,404,{error:'Save not found'});
     if(input.expectedRevision!==before.revision)return reply(res,409,{error:'Game changed; fetch the latest save',revision:before.revision});
     const game=E.clone(before.game);try{actions[input.action](game,input);E.validateGame(game);}catch(e){return reply(res,422,{error:e.message});}
     game.revision=before.revision+1;const record={revision:before.revision+1,game:ensureEnhancedState(game),updatedAt:new Date().toISOString(),lastAction:input.action};await write(id,record);return reply(res,200,record);
    });
   }
   return reply(res,404,{error:'Unknown endpoint'});
  }
  if(!serveStatic||!['GET','HEAD'].includes(req.method))return reply(res,404,{error:'Not found'});
  let p;try{p=decodeURIComponent(url.pathname);}catch{return reply(res,400,{error:'Invalid path'});}
  const target=path.resolve(ROOT,'.'+(p==='/'?'/index.html':p));if(!target.startsWith(ROOT+path.sep))return reply(res,403,{error:'Forbidden'});
  const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json','.webmanifest':'application/manifest+json','.png':'image/png','.jpg':'image/jpeg','.jpeg':'image/jpeg','.webp':'image/webp','.svg':'image/svg+xml','.woff2':'font/woff2'};
  try{const data=await fs.readFile(target);res.writeHead(200,{...SECURITY_HEADERS,'Content-Type':types[path.extname(target)]||'application/octet-stream','Cache-Control':/\.(?:html|webmanifest)$/.test(target)||target.endsWith('sw.js')?'no-cache':'public, max-age=3600'});res.end(req.method==='HEAD'?undefined:data);}catch(e){if(e.code==='ENOENT'||e.code==='EISDIR')return reply(res,404,{error:'Not found'});throw e;}
 }catch(e){reply(res,e.status||500,{error:e.status?e.message:'Internal server error'});}
 };
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const port=Number(process.env.PORT||4330);
 const handler=createHandler({playerToken:process.env.MOONVEIL_PLAYER_TOKEN,dmToken:process.env.MOONVEIL_DM_TOKEN,storageDir:process.env.MOONVEIL_DATA_DIR});
 http.createServer(handler).listen(port,process.env.HOST||'127.0.0.1',()=>console.log(`Moonveil secure server listening on port ${port}`));
}
