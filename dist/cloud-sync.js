const KEY='moonveil-universe-play-v1';const REV='moonveil-cloud-revision';const TOKEN='moonveil-cloud-player-token';const api='/api/save?slot=main';const el=document.createElement('aside');el.id='moonveil-cloud-controls';Object.assign(el.style,{position:'fixed',right:'12px',bottom:'12px',background:'#101b2c',color:'#fff',border:'1px solid #ad915a',padding:'8px',borderRadius:'12px',zIndex:'9999',font:'13px system-ui',maxWidth:'245px'});el.innerHTML='<details><summary>☁ Cloud save</summary><label>Player token <input id="moonveil-cloud-token" type="password" autocomplete="off" placeholder="From your private server" style="width:100%"></label><button id="moonveil-cloud-upload">Upload save</button><button id="moonveil-cloud-download">Download save</button><p id="moonveil-cloud-status" role="status" aria-live="polite"></p></details>';document.body.append(el);const input=el.querySelector('#moonveil-cloud-token');input.value=sessionStorage.getItem(TOKEN)||'';input.addEventListener('change',()=>sessionStorage.setItem(TOKEN,input.value));const status=s=>el.querySelector('#moonveil-cloud-status').textContent=s;async function call(method,payload){const headers={Authorization:'Bearer '+input.value};if(method==='PUT'){headers['Content-Type']='application/json';headers['If-Match']=sessionStorage.getItem(REV)||'0';}const r=await fetch(api,{method,headers,body:payload?JSON.stringify(payload):undefined});const data=await r.json();if(!r.ok)throw Error((data.error||r.statusText)+(r.status===409?' (reload cloud version first)':''));sessionStorage.setItem(REV,String(data.revision));return data;}el.querySelector('#moonveil-cloud-upload').addEventListener('click',async()=>{try{const raw=localStorage.getItem(KEY);if(!raw)throw Error('No local game to upload');await call('PUT',{game:JSON.parse(raw)});status('Uploaded successfully');}catch(e){status(e.message)}});el.querySelector('#moonveil-cloud-download').addEventListener('click',async()=>{try{const previousRevision=sessionStorage.getItem(REV);const result=await call('GET');if(!confirm('Back up the local save, then replace it with the cloud save?')){if(previousRevision===null)sessionStorage.removeItem(REV);else sessionStorage.setItem(REV,previousRevision);status('Download cancelled; local save unchanged.');return;}const previous=localStorage.getItem(KEY);if(previous)localStorage.setItem(KEY+'-backup-'+Date.now(),previous);localStorage.setItem(KEY,JSON.stringify(result.game));status('Cloud save downloaded; reloading.');location.reload();}catch(e){status(e.message)}});
const moonveilCloudMobileStyle=document.createElement('style');moonveilCloudMobileStyle.textContent='@media (max-width: 800px) { #moonveil-cloud-controls { bottom: 94px !important; } }';document.head.append(moonveilCloudMobileStyle);

const cloudCheckButton=document.createElement('button');cloudCheckButton.id='moonveil-cloud-check';cloudCheckButton.type='button';cloudCheckButton.textContent='Check cloud updates';el.querySelector('details').insertBefore(cloudCheckButton,el.querySelector('#moonveil-cloud-status'));
cloudCheckButton.addEventListener('click',async()=>{const known=sessionStorage.getItem(REV);try{if(!input.value)throw Error('Enter a player token first');const response=await fetch(api,{headers:{Authorization:'Bearer '+input.value},cache:'no-store'});const record=await response.json();if(!response.ok)throw Error(record.error||'Cloud check failed');status(known===null?'Cloud revision '+record.revision+' available. Download to load it.':Number(record.revision)>Number(known)?'Cloud has newer changes (revision '+record.revision+'). Download to review and load.':'Cloud has no newer revision.');}catch(error){status(error.message)}});
let moonveilAutoCheckBusy=false;
async function moonveilSafeAutoCheck(){
 if(moonveilAutoCheckBusy||document.hidden||!navigator.onLine||!input.value)return;
 moonveilAutoCheckBusy=true;
 try{
  const response=await fetch(api,{headers:{Authorization:'Bearer '+input.value},cache:'no-store'});
  if(!response.ok)return;
  const record=await response.json();
  const known=sessionStorage.getItem(REV);
  if(known!==null&&Number(record.revision)>Number(known)){
   el.dataset.cloudUpdateAvailable='true';
   status('Cloud has newer changes (revision '+record.revision+'). Review and download when ready.');
  }else{delete el.dataset.cloudUpdateAvailable;}
 }catch(_error){}finally{moonveilAutoCheckBusy=false;}
}
window.setInterval(moonveilSafeAutoCheck,60000);
document.addEventListener('visibilitychange',()=>{if(!document.hidden)void moonveilSafeAutoCheck();});
window.addEventListener('online',()=>{void moonveilSafeAutoCheck();});
input.addEventListener('change',()=>{void moonveilSafeAutoCheck();}); 
const cloudPanelSafetyStyle=document.createElement('style');cloudPanelSafetyStyle.textContent='@media (max-width: 800px) { #moonveil-cloud-controls:has(details[open]) { top: 8px !important; bottom: auto !important; max-height: 42vh; overflow-y: auto; } }';document.head.append(cloudPanelSafetyStyle);
/* Recovery export: independent of server availability and cloud revision. */
const moonveilExportButton=document.createElement('button');
moonveilExportButton.id='moonveil-cloud-export-local';
moonveilExportButton.type='button';
moonveilExportButton.textContent='Export local backup';
el.querySelector('details').insertBefore(moonveilExportButton,el.querySelector('#moonveil-cloud-status'));
moonveilExportButton.addEventListener('click',()=>{
 try{
  const raw=localStorage.getItem(KEY);
  if(!raw)throw Error('No local game to export');
  const game=JSON.parse(raw);
  if(!game||typeof game!=='object'||!game.hero)throw Error('Local save is invalid');
  const blob=new Blob([JSON.stringify(game,null,2)],{type:'application/json'});
  const url=URL.createObjectURL(blob);
  const a=document.createElement('a');
  a.href=url;a.download='moonveil-local-recovery-'+new Date().toISOString().replace(/[:.]/g,'-')+'.json';
  document.body.append(a);a.click();a.remove();
  setTimeout(()=>URL.revokeObjectURL(url),1000);
  status('Local backup exported; cloud save unchanged.');
 }catch(error){status(error.message);}
});
