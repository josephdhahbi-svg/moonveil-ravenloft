import * as E from './engine.js';
export const VESPER_CONTINUITY={
 codename:'The Moonveil Archivist',classTitle:'Undead Warlock',patron:'Vaelthara',faith:'Mystra',
 checkpoint:'Forgotten Netherese-Barovian Archive · Link 2 open · Choice F relic harmonization complete',
 locationTitle:'Forgotten Netherese-Barovian Archive',companions:['Orison','PariahT'],
 relics:['Sight of Vaelthara','Hand of the Weave','Silver Strand Codex'],
 questItem:'Vial of Pure Selûnite Starlight',
 libraryObjective:'Collect all grimoires throughout the multiverse.',
 futureArtifacts:['Book of Vile Darkness','Eye of Vecna','Hand of Vecna'],
 notes:['Vesper Vane: female Dhampir Undead Warlock. Current web ruleset represents her as Arcanist.','Level 1/30 · HP 10/10 · AC 13 · patron Vaelthara · Mystra.']
};
export const BUILD_LOG=['Original Moonveil game and artwork preserved','Secure online save and DM API added','PWA mobile and desktop foundations'];
export function ensureEnhancedState(state){
 if(!state||typeof state!=='object')return state;
 state.notes ||= []; state.storyFlags ||= {}; state.buildLog ||= BUILD_LOG.slice(); state.cinemaScene ??= 0;
 if(state.hero?.name==='Vesper Vane'){
  state.continuity ||= JSON.parse(JSON.stringify(VESPER_CONTINUITY));
  state.heroPortrait ||= 'assets/vesper/vesper-compendium.png';
  state.heroToken ||= 'assets/vesper/vesper-token-01.png';
 }
 return state;
}
export function createVesperCheckpoint(){
 const s=E.createGame({name:'Vesper Vane',className:'Arcanist',ancestry:'Dhampir',pronouns:'she/her'});
 Object.assign(s.hero,{level:1,hp:10,maxHp:10,ac:13,slots:1,maxSlots:1,gold:24});
 s.location='archive';s.visited=['nexus','lanternfall','bellcross','watchtower','glasshaven','rootway','starharbor','archive','lich-crypt'];s.chapter=2;s.view='journey';
 s.events=[{tick:0,text:'Choice F relic harmonization completed. Forgotten Netherese-Barovian Archive discovered.',kind:'quest'}];
 E.addItem(s,'ward');s.flags.relicHarmony='Choice F';s.flags.archiveOpen=true;s.flags.vesperContinuity=true;
 s.notes=['PariahT is your raven companion.','Attuned relics: Sight of Vaelthara, Hand of the Weave, Silver Strand Codex.'];
 return ensureEnhancedState(s);
}
