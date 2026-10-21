let installEvent=null;
const installButton=document.createElement('button');
installButton.type='button';
installButton.id='moonveil-install';
installButton.textContent='Install Moonveil';
installButton.setAttribute('aria-label','Install Moonveil Universe app');
Object.assign(installButton.style,{position:'fixed',left:'12px',bottom:'12px',zIndex:'9998',background:'#172035',color:'#f0d9a1',border:'1px solid #a9956c',borderRadius:'10px',padding:'10px',font:'600 13px system-ui',display:'none'});
document.body.append(installButton);
addEventListener('beforeinstallprompt',event=>{event.preventDefault();installEvent=event;installButton.style.display='block'});
installButton.addEventListener('click',async()=>{if(!installEvent)return;const request=installEvent;installEvent=null;installButton.style.display='none';await request.prompt();await request.userChoice});
addEventListener('appinstalled',()=>{installEvent=null;installButton.style.display='none'});
if('serviceWorker' in navigator && (location.protocol==='https:'||location.hostname==='localhost'||location.hostname==='127.0.0.1')){
 addEventListener('load',()=>navigator.serviceWorker.register('/sw.js').catch(error=>console.warn('Moonveil offline shell unavailable',error)));
}
