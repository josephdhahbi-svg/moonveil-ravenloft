// Deterministic local tactical assistant. No external AI service or credentials.
import * as E from './engine.js';
export function playAssistedAction(s){
 const b=s.battle;if(!b||b.status!=='active'||b.actionSpent)throw Error('Orison needs an active encounter and an unused action.');
 if(!s.companion.enabled)throw Error('Enable Orison in Settings first.');
 if(s.hero.hp<=s.hero.maxHp/2&&E.quantity(s,'potion')>0){E.usePotion(s);E.log(s,'Orison’s tactical assist: used a healing draught.','companion');return;}
 const hero=b.units.find(u=>u.id==='hero'),distance=u=>Math.max(Math.abs(hero.x-u.x),Math.abs(hero.y-u.y));
 const targets=b.units.filter(u=>u.side==='enemy'&&u.hp>0).sort((a,z)=>Number(Boolean(z.frostMarked))-Number(Boolean(a.frostMarked))||distance(a)-distance(z));
 for(const target of targets){let position=null;for(let x=0;x<8;x++)for(let y=0;y<8;y++){const path=E.gridPath(b,hero,x,y);if(!path||path.length-1>b.movement||!E.lineOfSight(b,{x,y},target))continue;const d=Math.max(Math.abs(x-target.x),Math.abs(y-target.y));if(d>6)continue;const score=path.length+(d<=1?0:2);if(!position||score<position.score)position={x,y,score};}
 if(!position)continue;if(position.x!==hero.x||position.y!==hero.y)E.moveHero(s,position.x,position.y);b.selected=target.id;
 if(target.frostMarked&&s.hero.slots>0)E.castSpell(s,target.id,'storm');else if(s.hero.slots>=2&&target.hp>=8)E.castSpell(s,target.id,'frost');else E.attack(s,target.id,distance(target)<=1?'melee':'bolt');
 E.log(s,'Orison’s tactical assist: chose a visible target and used one validated action. End the turn when ready.','companion');return;
 }
 E.guard(s);E.log(s,'Orison’s tactical assist: no clear firing position; braced for the enemy turn.','companion');
}
