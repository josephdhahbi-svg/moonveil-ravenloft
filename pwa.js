// Install and device help for the same Moonveil game. No embedded API key or automatic save sync.
let installPrompt=null;
window.addEventListener('beforeinstallprompt',event=>{event.preventDefault();installPrompt=event;});
window.addEventListener('appinstalled',()=>{installPrompt=null;});
if('serviceWorker' in navigator&&window.isSecureContext){window.addEventListener('load',()=>navigator.serviceWorker.register('./sw.js').catch(()=>{}));}
export function installStatus(){return {installed:matchMedia('(display-mode: standalone)').matches,canPrompt:Boolean(installPrompt),secure:window.isSecureContext};}
export async function installMoonveil(){if(!installPrompt)return false;const prompt=installPrompt;installPrompt=null;await prompt.prompt();const result=await prompt.userChoice;return result.outcome==='accepted';}
