/* Original Moonveil atmosphere generators. No third-party adventure content or item grants. */
(() => {
'use strict';
const tables={
  omen:[
    'Three silver moths circle a sealed doorway.',
    'A church bell rings once, although the tower is empty.',
    'A pale moon is reflected in a dry fountain.',
    'The mist briefly spells a forgotten scholar’s name.',
    'A raven delivers a ribbon tied around a brass key.',
    'Blue candlelight appears beneath a locked archive door.'
  ],
  encounter:[
    'A frightened courier asks for safe passage through the fog.',
    'A clockwork raven repeats an unfinished warning.',
    'Two lost scholars disagree about the safest route.',
    'A guardian statue requests proof of peaceful intentions.',
    'A silver lantern flickers near an abandoned campsite.',
    'An injured traveler offers a map fragment in exchange for help.'
  ],
  market:[
    'Moonwax candles — 3 gp — mundane, inventory not changed',
    'Ink and parchment kit — 5 gp — mundane, inventory not changed',
    'Wool traveling cloak — 2 gp — mundane, inventory not changed',
    'Brass compass — 8 gp — mundane, inventory not changed',
    'Silvered mirror — 10 gp — mundane, inventory not changed',
    'Raven-feather bookmark — 1 sp — mundane, inventory not changed'
  ]
};
const panel=document.createElement('section');
panel.id='mv-generators';
panel.style.cssText='margin:18px auto;padding:16px;max-width:960px;border:1px solid #8068b1;border-radius:14px;background:#171329;color:#f7edff;font:15px system-ui';
panel.innerHTML='<h2 style="margin:0 0 8px">🎲 Ravenloft Discovery Tables</h2><p>Original non-mechanical scene prompts. Rolls do not award items, spend gold, or alter combat or saves.</p><div style="display:flex;flex-wrap:wrap;gap:8px"><button data-mv-roll="omen">Moonlit omen</button><button data-mv-roll="encounter">Roleplay encounter</button><button data-mv-roll="market">Market stall</button></div><p id="mv-roll-result" aria-live="polite">Choose a table to roll a d6.</p>';
document.querySelector('main')?.append(panel) || document.body.append(panel);
panel.querySelectorAll('button').forEach(b=>{
  b.style.cssText='padding:10px;border:1px solid #9079c2;border-radius:9px;background:#45366e;color:white;cursor:pointer';
  b.onclick=()=>{
    const values=tables[b.dataset.mvRoll];
    const a=new Uint32Array(1);
    if(window.crypto?.getRandomValues)crypto.getRandomValues(a);
    else a[0]=Math.floor(Math.random()*4294967296);
    const roll=(a[0]%6)+1,output=values[roll-1];
    panel.querySelector('#mv-roll-result').textContent='d6 = '+roll+' · '+output;
    window.MoonveilAudioDirector?.effect?.();
    window.MoonveilAudioDirector?.speak?.(output);
  };
});
})();
