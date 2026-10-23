/* Moonveil Audio Director. Original browser-native synthesis; no third-party audio or keys. */
(() => {
  'use strict';
  let ctx, master, musicGain, ambienceGain, sfxGain, timer, speaking = false, scene = 'archive';
  let musicOn = false, ambienceOn = false, voiceOn = true, volume = .48;
  const scenes = {
    archive: {notes:[174.61,220,261.63,329.63],label:'Archive'},
    travel: {notes:[196,246.94,293.66,392],label:'Travel'},
    battle: {notes:[130.81,155.56,196,233.08],label:'Battle'},
    mystery: {notes:[146.83,185,220,277.18],label:'Mystery'},
    triumph: {notes:[261.63,329.63,392,523.25],label:'Triumph'}
  };
  const root=document.createElement('aside');
  root.id='moonveil-audio-director';
  root.setAttribute('aria-label','Moonveil audio controls');
  root.style.cssText='position:fixed;right:12px;bottom:12px;z-index:9999;width:min(350px,calc(100vw - 24px));background:#15112aee;color:#f4eaff;border:1px solid #8d77ba;border-radius:16px;padding:12px;font:14px system-ui;box-shadow:0 8px 30px #0008;backdrop-filter:blur(8px)';
  root.innerHTML='<details><summary style="cursor:pointer;font-weight:bold">♫ Moonveil Audio Studio <span id="mv-audio-status">· tap to enable</span></summary>'+
    '<div style="display:grid;gap:9px;margin-top:12px">'+
    '<button id="mv-enable" type="button">Enable sound</button>'+
    '<label>Soundtrack <select id="mv-scene"><option value="archive">Forgotten Archive</option><option value="travel">Travel</option><option value="battle">Battle</option><option value="mystery">Mystery</option><option value="triumph">Triumph</option></select></label>'+
    '<label><input type="checkbox" id="mv-music"> Music</label>'+
    '<label><input type="checkbox" id="mv-ambience"> Ambient atmosphere</label>'+
    '<label><input type="checkbox" id="mv-voice" checked> British narrator / scene reading</label>'+
    '<label>Voice <select id="mv-voices" style="max-width:100%;width:100%"></select></label>'+
    '<label>Master volume <input type="range" min="0" max="100" value="48" id="mv-volume"></label>'+
    '<div style="display:flex;gap:5px;flex-wrap:wrap"><button id="mv-test" type="button">Test narrator</button><button id="mv-sfx" type="button">Spell effect</button><button id="mv-stop" type="button">Stop all</button></div>'+
    '<small id="mv-info">Voice availability depends on this device. Music and effects are synthesized locally.</small></div></details>';
  document.body.append(root);
  root.querySelectorAll('button').forEach(b=>b.style.cssText='padding:7px 9px;background:#44356e;color:white;border:1px solid #8169b7;border-radius:8px;cursor:pointer');
  const $=id=>document.getElementById(id);
  function ensureAudio() {
    const C=window.AudioContext||window.webkitAudioContext;
    if(!C) { $('mv-info').textContent='Web Audio is unsupported in this browser.';return false; }
    if(!ctx){
      ctx=new C();master=ctx.createGain();master.gain.value=volume;
      musicGain=ctx.createGain();musicGain.gain.value=0;
      ambienceGain=ctx.createGain();ambienceGain.gain.value=0;
      sfxGain=ctx.createGain();sfxGain.gain.value=.35;
      musicGain.connect(master);ambienceGain.connect(master);sfxGain.connect(master);master.connect(ctx.destination);
      const noise=ctx.createBuffer(1,ctx.sampleRate*2,ctx.sampleRate);
      const data=noise.getChannelData(0);for(let i=0;i<data.length;i++)data[i]=(Math.random()*2-1)*.17;
      const src=ctx.createBufferSource();src.buffer=noise;src.loop=true;
      const filter=ctx.createBiquadFilter();filter.type='lowpass';filter.frequency.value=370;
      src.connect(filter);filter.connect(ambienceGain);src.start();
    }
    ctx.resume();
    $('mv-audio-status').textContent='· enabled';
    return true;
  }
  function tone(freq,duration,target,when=0,wave='sine') {
    if(!ctx)return;
    const now=ctx.currentTime+when,osc=ctx.createOscillator(),gain=ctx.createGain();
    osc.type=wave;osc.frequency.value=freq;
    gain.gain.setValueAtTime(.0001,now);
    gain.gain.exponentialRampToValueAtTime(.12,now+.035);
    gain.gain.exponentialRampToValueAtTime(.0001,now+duration);
    osc.connect(gain);gain.connect(target);osc.start(now);osc.stop(now+duration+.02);
  }
  function playPattern(){
    if(!musicOn||!ctx)return;
    const notes=scenes[scene].notes;
    notes.forEach((n,i)=>tone(n,1.1,musicGain,i*.33,scene==='battle'?'triangle':'sine'));
    timer=setTimeout(playPattern,2900);
  }
  function setMusic(on){
    musicOn=on;clearTimeout(timer);
    if(on&&ensureAudio()){musicGain.gain.setTargetAtTime(.24,ctx.currentTime,.3);playPattern();}
    else if(ctx)musicGain.gain.setTargetAtTime(0,ctx.currentTime,.2);
  }
  function setAmbience(on){
    ambienceOn=on;
    if(on)ensureAudio();
    if(ctx)ambienceGain.gain.setTargetAtTime(on?.16:0,ctx.currentTime,.25);
  }
  function effect(){
    if(!ensureAudio())return;
    [700,525,392,784].forEach((n,i)=>tone(n,.25,sfxGain,i*.11,'triangle'));
  }
  function voices(){return ('speechSynthesis'in window)?speechSynthesis.getVoices():[]}
  function chooseVoice(){
    const list=voices(),select=$('mv-voices');
    if(!list.length){select.innerHTML='<option value="">No voices available yet</option>';return;}
    const current=select.value;
    const ranked=list.map((v,i)=>({v,i,score:(/en-GB/i.test(v.lang)?100:0)+(/female|serena|sonia|libby|kate|hazel|susan|martha/i.test(v.name)?30:0)+(/en/i.test(v.lang)?10:0)})).sort((a,b)=>b.score-a.score);
    select.innerHTML='';
    ranked.forEach(({v,i})=>{const opt=document.createElement('option');opt.value=String(i);opt.textContent=v.name+' ('+v.lang+')';select.append(opt)});
    if([...select.options].some(o=>o.value===current))select.value=current;
  }
  function speak(message){
    if(!voiceOn||!('speechSynthesis'in window)||!message)return;
    speechSynthesis.cancel();
    const utter=new SpeechSynthesisUtterance(String(message).slice(0,750));
    utter.lang='en-GB';utter.rate=.88;utter.pitch=1.04;utter.volume=Math.min(1,volume*1.6);
    const choice=voices()[Number($('mv-voices').value)];if(choice)utter.voice=choice;
    utter.onstart=()=>{speaking=true;if(ctx)musicGain.gain.setTargetAtTime(musicOn?.075:0,ctx.currentTime,.12)};
    const end=()=>{speaking=false;if(ctx)musicGain.gain.setTargetAtTime(musicOn?.24:0,ctx.currentTime,.3)};
    utter.onend=end;utter.onerror=end;speechSynthesis.speak(utter);
  }
  function readScene(){
    const title=$('chapter')?.textContent||'Moonveil';
    const descriptions=[...document.querySelectorAll('#scenes .copy p')].map(e=>e.textContent);
    speak(title+'. '+descriptions.slice(0,2).join(' '));
  }
  $('mv-enable').onclick=()=>{if(ensureAudio())effect()};
  $('mv-scene').onchange=e=>{scene=e.target.value;if(musicOn)setMusic(true)};
  $('mv-music').onchange=e=>setMusic(e.target.checked);
  $('mv-ambience').onchange=e=>setAmbience(e.target.checked);
  $('mv-voice').onchange=e=>{voiceOn=e.target.checked;if(!voiceOn&&'speechSynthesis'in window)speechSynthesis.cancel()};
  $('mv-volume').oninput=e=>{volume=+e.target.value/100;if(ctx)master.gain.value=volume};
  $('mv-test').onclick=()=>{voiceOn=true;$('mv-voice').checked=true;speak('Welcome to Moonveil. Beyond the silver threshold, the forgotten archive is waking.')};
  $('mv-sfx').onclick=effect;
  $('mv-stop').onclick=()=>{setMusic(false);setAmbience(false);$('mv-music').checked=false;$('mv-ambience').checked=false;if('speechSynthesis'in window)speechSynthesis.cancel()};
  if('speechSynthesis'in window){chooseVoice();speechSynthesis.onvoiceschanged=chooseVoice}
  else $('mv-info').textContent='This browser has no speech synthesis. Music and effects remain available.';
  // Narrate actual story updates after user interactions; no automatic autoplay without gesture.
  let lastChapter=$('chapter')?.textContent||'';
  const chapter=$('chapter');
  if(chapter)new MutationObserver(()=>{
    const next=chapter.textContent;
    if(next!==lastChapter){lastChapter=next;readScene();}
  }).observe(chapter,{childList:true,characterData:true,subtree:true});
  window.MoonveilAudioDirector={setScene:name=>{if(scenes[name]){scene=name;$('mv-scene').value=name;if(musicOn)setMusic(true)}},speak,effect,stop:()=>$('mv-stop').click()};
})();