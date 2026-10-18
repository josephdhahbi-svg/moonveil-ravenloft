/* Moonveil tactical encounter: isolated training simulation, no save mutation. */
(() => {
'use strict';
const section=document.createElement('section');
section.id='mv-combat';
section.style.cssText='margin:20px auto;max-width:960px;padding:18px;border:1px solid #8b74b4;border-radius:18px;background:#17152f;color:#f7efff';
section.innerHTML='<h2>⚔ Tactical Training — Moonlit Ruins</h2><p>Move through the 8 × 6 ruins and defeat the training sentinel. This encounter does not change your campaign save.</p><div id="mv-combat-status" role="status" aria-live="polite"></div><div id="mv-combat-grid" role="grid" aria-label="Tactical battle map"></div><div id="mv-combat-actions" style="display:flex;gap:8px;flex-wrap:wrap;margin-top:12px"><button data-mv-action="up">↑</button><button data-mv-action="left">←</button><button data-mv-action="down">↓</button><button data-mv-action="right">→</button><button data-mv-action="attack">✦ Eldritch Blast</button><button data-mv-action="reset">↻ Restart</button></div>';
const style=document.createElement('style');
style.textContent='#mv-combat-grid{display:grid;grid-template-columns:repeat(8,minmax(0,1fr));gap:3px;max-width:600px;margin:12px auto}#mv-combat-grid .mv-cell{aspect-ratio:1;min-height:30px;border-radius:5px;background:linear-gradient(145deg,#34344d,#202035);border:1px solid #51476b;display:grid;place-items:center;font-size:clamp(13px,3vw,27px)}#mv-combat-grid .mv-cell:nth-child(odd){background:linear-gradient(145deg,#343d51,#1b273b)}#mv-combat-grid .mv-wall{background:#45414e!important}#mv-combat-grid .mv-player{background:#483978!important;box-shadow:inset 0 0 16px #9a79e9}#mv-combat-grid .mv-enemy{background:#653a46!important;box-shadow:inset 0 0 14px #d35d70}#mv-combat-actions button{padding:9px 12px;background:#44336c;border:1px solid #9876c6;color:white;border-radius:9px;cursor:pointer}#mv-combat-actions button:focus-visible{outline:3px solid #fff}';
document.head.append(style);
const host=document.querySelector('#story')||document.querySelector('main')||document.body;
host.append(section);
let p,enemy,round,log;
const walls=new Set(['2,1','2,2','5,3','5,4','3,4']);
const pos=(x,y)=>x+','+y;
const dist=(a,b)=>Math.abs(a.x-b.x)+Math.abs(a.y-b.y);
const rnd=n=>{const a=new Uint32Array(1);if(window.crypto?.getRandomValues)window.crypto.getRandomValues(a);else a[0]=Math.floor(Math.random()*4294967295);return a[0]%n+1};
function reset(){p={x:1,y:4,hp:12};enemy={x:6,y:1,hp:10};round=1;log='The training sentinel stirs.';render()}
function render(){
  const grid=section.querySelector('#mv-combat-grid');grid.replaceChildren();
  for(let y=0;y<6;y++)for(let x=0;x<8;x++){
    const tile=document.createElement('div');tile.className='mv-cell';tile.setAttribute('role','gridcell');
    if(walls.has(pos(x,y))){tile.classList.add('mv-wall');tile.textContent='▩';tile.setAttribute('aria-label','Wall')}
    else if(p.x===x&&p.y===y){tile.classList.add('mv-player');tile.textContent='🌙';tile.setAttribute('aria-label','Vesper')}
    else if(enemy.hp>0&&enemy.x===x&&enemy.y===y){tile.classList.add('mv-enemy');tile.textContent='👁';tile.setAttribute('aria-label','Sentinel')}
    else {tile.textContent=(x+y)%3===0?'·':'';tile.setAttribute('aria-label','Open tile')}
    grid.append(tile);
  }
  section.querySelector('#mv-combat-status').textContent='Round '+round+' · Vesper '+p.hp+'/12 HP · Sentinel '+enemy.hp+'/10 HP · '+log;
}
function enemyTurn(){
  if(enemy.hp<=0||p.hp<=0)return;
  if(dist(enemy,p)<=1){const dmg=rnd(3);p.hp=Math.max(0,p.hp-dmg);log+=' Sentinel strikes for '+dmg+'.'}
  else{
    const dx=Math.sign(p.x-enemy.x),dy=Math.sign(p.y-enemy.y);
    const moves=Math.abs(p.x-enemy.x)>=Math.abs(p.y-enemy.y)?[[dx,0],[0,dy]]:[[0,dy],[dx,0]];
    for(const [mx,my] of moves){const nx=enemy.x+mx,ny=enemy.y+my;if(nx>=0&&nx<8&&ny>=0&&ny<6&&!walls.has(pos(nx,ny))&&pos(nx,ny)!==pos(p.x,p.y)){enemy.x=nx;enemy.y=ny;log+=' Sentinel advances.';break}}
  }
  if(p.hp===0)log+=' Training defeat — restart to try again.';
}
function act(a){
  if(a==='reset'){reset();window.MoonveilAudioDirector?.setScene?.('battle');return}
  if(p.hp<=0||enemy.hp<=0){log='Encounter finished. Restart for another battle.';render();return}
  if(a==='attack'){
    if(dist(p,enemy)>4){log='Eldritch Blast is out of training range (4 squares).';render();return}
    const roll=rnd(20)+4;
    if(roll>=12){const dmg=rnd(6)+2;enemy.hp=Math.max(0,enemy.hp-dmg);log='Eldritch Blast '+roll+' hits for '+dmg+' damage.';window.MoonveilAudioDirector?.effect?.()}
    else log='Eldritch Blast '+roll+' misses.';
    if(enemy.hp===0){log+=' Sentinel defeated!';window.MoonveilAudioDirector?.setScene?.('triumph');window.MoonveilAudioDirector?.speak?.('The guardian falls. The moonlit path is yours.')}
  }else{
    const d={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]}[a];if(!d)return;
    const x=p.x+d[0],y=p.y+d[1];
    if(x<0||x>=8||y<0||y>=6||walls.has(pos(x,y))||pos(x,y)===pos(enemy.x,enemy.y)){log='Movement blocked.';render();return}
    p.x=x;p.y=y;log='Vesper moves '+a+'.';
  }
  if(enemy.hp>0)enemyTurn();round++;render();
}
section.querySelector('#mv-combat-actions').addEventListener('click',e=>{const button=e.target.closest('[data-mv-action]');if(button)act(button.dataset.mvAction)});
section.addEventListener('keydown',e=>{const key={ArrowUp:'up',ArrowDown:'down',ArrowLeft:'left',ArrowRight:'right'}[e.key];if(!key||['INPUT','SELECT','TEXTAREA'].includes(e.target.tagName))return;e.preventDefault();act(key)});
section.tabIndex=0;
section.setAttribute('aria-label','Tactical encounter: focus and use arrow keys to move');
reset();
section.addEventListener('focusin',()=>window.MoonveilAudioDirector?.setScene?.('battle'),{once:true});
})();
