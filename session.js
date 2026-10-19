import {effectivePlace} from './scene-director.js?v=20261018-dm2';
import * as E from './engine.js?v=20261018-dm2';
import {PLACES,QUESTS,ITEMS} from './world.js';
export const ACTIONS=['travel','explore','talk','dialogue_next','accept','complete','start_combat','move','select_enemy','attack','end_turn','guard','companion','loot','rest','retreat','view','buy','use_potion'];
export function performAction(s,input){
 if(!s||!ACTIONS.includes(input?.action))throw Error('Choose a supported game action.');
 switch(input.action){
 case 'travel':return E.travel(s,input.destination);
 case 'explore':return E.explore(s);
 case 'talk':return E.talk(s);
 case 'dialogue_next':if(!s.dialogue||s.dialogue.place!==s.location)throw Error('Start a conversation here first.');if(s.dialogue.step===0)s.dialogue.step=1;else s.dialogue=null;return;
 case 'accept':E.acceptQuest(s,input.questId);s.dialogue=null;return;
 case 'complete':E.completeQuest(s,input.questId);s.dialogue=null;return;
 case 'start_combat':return E.beginBattle(s);
 case 'move':if(!Number.isInteger(input.x)||!Number.isInteger(input.y))throw Error('Grid coordinates must be integers.');return E.moveHero(s,input.x,input.y);
 case 'select_enemy':{const b=s.battle;if(b?.status!=='active'||!b.units.some(u=>u.id===input.targetId&&u.side==='enemy'&&u.hp>0))throw Error('Choose a living enemy in the current encounter.');b.selected=input.targetId;return;}
 case 'attack':if(!['bolt','melee'].includes(input.kind))throw Error('Choose bolt or melee.');return E.attack(s,input.targetId,input.kind);
 case 'end_turn':return E.endTurn(s);
 case 'guard':return E.guard(s);
 case 'companion':return E.companionAct(s);
 case 'loot':return E.collectLoot(s);
 case 'rest':return E.rest(s);
 case 'retreat':return E.retreat(s);
 case 'buy':return E.buy(s,input.itemId);
 case 'use_potion':return E.usePotion(s);
 case 'view':if(!['journey','atlas','character','inventory','codex','guide','battle','life'].includes(input.view))throw Error('Unknown view.');if(input.sheet!==undefined){if(input.view!=='life'||!['quest-sheet','profession-sheet','devotion-sheet','spell-sheet','ritual-sheet'].includes(input.sheet))throw Error('Choose a known World sheet.');s.lifeSheet=input.sheet;}if(input.guideTab!==undefined){if(input.view!=='guide'||!['together','director','notebook','wayfinder'].includes(input.guideTab))throw Error('Choose a known Game Master section.');s.guideTab=input.guideTab;}s.view=input.view;return;
 }
}
export function addSessionNote(s,input){
 const text=typeof input?.text==='string'?input.text.trim():'';
 if(!text||text.length>1200)throw Error('Write a note between 1 and 1200 characters.');
 if(!['player','dm'].includes(input.author))throw Error('Choose player or dm as note author.');
 s.notes||=[];if(s.notes.length>=500)throw Error('The notebook is full. Export your save before beginning another volume.');
 const note={id:crypto.randomUUID(),author:input.author,text,location:s.location,tick:s.tick};s.notes.push(note);return note;
}
export function readSession(s){if(!s)return{character:null};const p=PLACES.find(p=>p.id===s.location);return{hero:s.hero,location:s.location,currentPlace:effectivePlace(s,p),sceneOverrides:s.sceneOverrides||{},sceneEditHistory:s.sceneEditHistory||[],places:PLACES.map(p=>effectivePlace(s,p)),quests:s.quests,questDefinitions:QUESTS,inventory:s.inventory,itemDefinitions:ITEMS,battle:s.battle,loot:s.loot,dialogue:s.dialogue,companion:s.companion,profession:s.profession||null,devotion:s.devotion||{},worldFlags:s.flags,notes:s.notes||[],recentEvents:s.events.slice(0,12),view:s.view,revision:s.revision};}
