/* Original Moonveil atmospheric visual effects, browser-native, no external assets. */
(() => {
'use strict';
const style=document.createElement('style');
style.textContent=`
:root{--moonveil-light:rgba(185,204,255,.13)}
body{position:relative}
body::before{content:"";pointer-events:none;position:fixed;inset:0;z-index:0;background:radial-gradient(ellipse at 77% 14%,var(--moonveil-light),transparent 45%);animation:mvMoonPulse 14s ease-in-out infinite alternate}
body>*{position:relative}
.scene{position:relative;overflow:hidden;isolation:isolate;background-size:cover;background-position:center;transition:background-position 6s ease,filter 1s ease}
.scene::before{content:"";position:absolute;inset:-20%;pointer-events:none;z-index:0;background:radial-gradient(ellipse at 20% 85%,#dce6ff25,transparent 55%),radial-gradient(ellipse at 75% 60%,#dce6ff16,transparent 50%);animation:mvMist 20s ease-in-out infinite alternate}
.scene::after{content:"";position:absolute;inset:0;pointer-events:none;background:linear-gradient(120deg,transparent 20%,#fff1 48%,transparent 70%);animation:mvMoonSweep 17s linear infinite}
.scene .copy{position:relative;z-index:1}
.scene:hover{background-position:55% center}
#mv-cinematic-toggle{position:fixed;left:12px;bottom:12px;z-index:9999;background:#251a45ee;border:1px solid #8d77ba;border-radius:10px;color:#f4eaff;padding:10px 12px;cursor:pointer}
@keyframes mvMist{from{transform:translate(-8%,3%) scale(1.02);opacity:.4}to{transform:translate(8%,-4%) scale(1.12);opacity:.9}}
@keyframes mvMoonPulse{from{opacity:.45}to{opacity:1}}
@keyframes mvMoonSweep{from{transform:translateX(-140%)}to{transform:translateX(140%)}}
@media(prefers-reduced-motion:reduce){body::before,.scene::before,.scene::after{animation:none!important}.scene{transition:none!important}}
body.mv-cinematics-off::before,body.mv-cinematics-off .scene::before,body.mv-cinematics-off .scene::after{animation:none!important;opacity:0!important}
`;
document.head.append(style);
const button=document.createElement('button');
button.id='mv-cinematic-toggle';button.type='button';button.textContent='✦ Cinematics: On';button.setAttribute('aria-pressed','true');
button.onclick=()=>{const off=document.body.classList.toggle('mv-cinematics-off');button.textContent='✦ Cinematics: '+(off?'Off':'On');button.setAttribute('aria-pressed',String(!off))};
document.body.append(button);
})();
