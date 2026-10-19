// Soft synthesized sound cues; no external music/voice recordings claimed.
export function cueFor(before,after){
 if(before.battle?.status==='active'&&after.battle?.status==='won')return 'victory';
 if(Object.keys(after.quests).some(id=>after.quests[id].phase==='complete'&&before.quests[id]?.phase!=='complete'))return 'quest';
 if(before.location!==after.location)return 'travel';
 if(after.hero.hp<before.hero.hp)return 'hurt';if(after.hero.hp>before.hero.hp)return 'heal';
 if(!before.battle&&after.battle?.status==='active')return 'encounter';
 if(after.battle?.actionSpent&&!before.battle?.actionSpent){if(after.hero.slots<before.hero.slots)return 'spell';return 'strike';}
 if(before.loot&&!after.loot)return 'loot';
 if(after.hero.gold<before.hero.gold)return 'trade';return null;
}
const CUES={travel:[[220,440,.3]],spell:[[740,220,.22],[1100,550,.18]],strike:[[140,60,.12]],hurt:[[100,50,.16]],heal:[[392,523,.28],[523,784,.3]],victory:[[392,392,.18],[494,494,.18],[587,784,.4]],quest:[[523,659,.22],[659,784,.32]],encounter:[[110,73,.4]],loot:[[880,1175,.15],[1175,1568,.15]],trade:[[1046,784,.12]]};
export function playCue(context,name){if(!context||context.state!=='running'||!CUES[name])return false;let delay=0;for(const [from,to,duration]of CUES[name]){const oscillator=context.createOscillator(),gain=context.createGain(),at=context.currentTime+delay;oscillator.type=name==='strike'||name==='hurt'?'triangle':'sine';oscillator.frequency.setValueAtTime(from,at);oscillator.frequency.exponentialRampToValueAtTime(to,at+duration);gain.gain.setValueAtTime(.0001,at);gain.gain.exponentialRampToValueAtTime(.035,at+.015);gain.gain.exponentialRampToValueAtTime(.0001,at+duration);oscillator.connect(gain).connect(context.destination);oscillator.start(at);oscillator.stop(at+duration+.02);oscillator.onended=()=>{oscillator.disconnect();gain.disconnect();};delay+=duration*.7;}return true;}
