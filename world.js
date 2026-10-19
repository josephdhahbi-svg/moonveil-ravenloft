import {MYTHOS_REALM,MYTHOS_PLACES,MYTHOS_QUEST,MYTHOS_ITEM} from './mythos.js';
import {TEMPLE_PLACES,CRYPT_PLACES,CRYPT_QUEST,LIFE_ITEMS} from './life-data.js';
export const REALMS=[
 {id:'veil',name:'The Veiled Marches',mood:'Gothic kingdoms · mist & moonlight',color:'#a2b9c7',position:'left',hub:'lanternfall'},
 {id:'verdant',name:'The Emerald Expanse',mood:'Ancient forests · living magic',color:'#97c7a9',position:'center',hub:'glasshaven'},
 {id:'astral',name:'The Astral Reach',mood:'Starbound ports · forgotten machines',color:'#c1adf3',position:'right',hub:'starharbor'}
];
export const PLACES=[
 {id:'nexus',name:'The Moonveil Nexus',realm:'veil',kind:'Sanctuary',x:49,y:45,art:'gateway',description:'Between worlds, a thousand roads meet beneath a broken moon. Silver gates wake at your approach. Somewhere beyond them, a bell rings without a hand to sound it.',speaker:'Keeper Ilyra',line:'Every gate is a beginning. Choose a road, traveler. The worlds will remember what you do.',neighbors:['lanternfall','glasshaven','starharbor']},
 {id:'lanternfall',name:'Lanternfall',realm:'veil',kind:'City & market',x:22,y:36,art:'workshop',description:'Lanterns burn against the rolling mist. Traders close their shutters as the watchtower bell sounds again—though the tower has stood empty for years.',speaker:'Warden Seren',line:'A lantern keeper vanished at the old watchtower. Bring back their silver lens. Without it, this city loses its last safe road.',neighbors:['nexus','bellcross']},
 {id:'bellcross',name:'The Mourning Road',realm:'veil',kind:'Wilderness',x:15,y:61,art:'mist',description:'Wheel ruts disappear beneath black water. Orison’s little brass eye catches a line of footprints turning toward the tower. The bell is louder here.',speaker:'Orison · construct companion',line:'Tracks detected. Two travelers outbound. One set returning. Shall we investigate?',neighbors:['lanternfall','watchtower']},
 {id:'watchtower',name:'The Hollow Watchtower',realm:'veil',kind:'Encounter',x:30,y:76,art:'tomb',description:'A cracked beacon hangs above an empty courtyard. Something moves between the stones. The missing lens glimmers in a cradle of silver wire.',speaker:'The Hollow Sentinel',line:'The road ends here. Leave the light, and you may leave alive.',neighbors:['bellcross'],quest:'lost-light'},
 {id:'glasshaven',name:'Glasshaven',realm:'verdant',kind:'City & market',x:55,y:22,art:'garden',description:'A city of glass and growing wood rests beneath an emerald canopy. In its gardens, every leaf trembles with the same uneasy pulse.',speaker:'Mira of the Green',line:'The waterfall shrine is failing. Find the heartseed beyond the roots, and our forest may breathe freely again.',neighbors:['nexus','rootway']},
 {id:'rootway',name:'The Silverroot Path',realm:'verdant',kind:'Wilderness',x:70,y:36,art:'forest',description:'Ancient roots rise like bridges above a luminous river. Far below, something sings in a language Orison cannot translate.',speaker:'Orison · construct companion',line:'Uncatalogued melody. Threat estimate: uncertain. Beauty estimate: considerable.',neighbors:['glasshaven','waterfall']},
 {id:'waterfall',name:'The Emerald Sanctuary',realm:'verdant',kind:'Encounter',x:76,y:55,art:'waterfall',description:'A curtain of water parts around an ancient shrine. Glassy roots twist around a seed that shines like a small, trapped sun.',speaker:'The Thornbound Warden',line:'Nothing leaves this garden. Nothing is ever lost again.',neighbors:['rootway'],quest:'heartseed'},
 {id:'starharbor',name:'Starfall Harbor',realm:'astral',kind:'City & market',x:78,y:18,art:'astral',description:'Ships drift between islands of stone in a violet sea of stars. A signal pulses from a derelict foundry beyond the docks.',speaker:'Engineer Ryn',line:'That foundry used to keep these islands aloft. Recover its starcoil before the next gravitational storm.',neighbors:['nexus','starbridge']},
 {id:'starbridge',name:'The Broken Orbit',realm:'astral',kind:'Wilderness',x:88,y:39,art:'astral',description:'Fragments of an old starbridge turn slowly in the dark. Your companion unfolds tiny stabilizers and steps into the impossible wind.',speaker:'Orison · construct companion',line:'Route calculated. Please disregard the absence of a floor.',neighbors:['starharbor','foundry']},
 {id:'foundry',name:'The Sleepless Foundry',realm:'astral',kind:'Encounter',x:88,y:73,art:'forge',description:'Blue fire burns in furnaces no living hand has tended for centuries. A damaged custodian guards the starcoil at their heart.',speaker:'Foundry Custodian',line:'Maintenance cycle incomplete. Living personnel are not authorized.',neighbors:['starbridge'],quest:'starcoil'}
];
export const QUESTS=[
 {id:'lost-light',name:'A Light for the Lost',giver:'lanternfall',site:'watchtower',item:'silver-lens',reward:30,xp:40,summary:'Recover the missing silver lens from the Hollow Watchtower and return to Warden Seren.'},
 {id:'heartseed',name:'The Forest Remembers',giver:'glasshaven',site:'waterfall',item:'heartseed',reward:35,xp:45,summary:'Recover the heartseed from the Emerald Sanctuary and return to Mira.'},
 {id:'starcoil',name:'A Signal Through Stars',giver:'starharbor',site:'foundry',item:'starcoil',reward:40,xp:50,summary:'Recover the foundry’s starcoil and return to Engineer Ryn.'}
];
export const ITEMS=[
 {id:'moonblade',name:'Moonsteel Blade',kind:'Weapon',icon:'sword',description:'A balanced traveler’s blade. Melee attack: +5 to hit, 1d8 + 3 damage.',price:35},
 {id:'focus',name:'Astral Focus',kind:'Focus',icon:'spark',description:'An engraved casting focus. Enables the Arcane Bolt action in this homebrew adventure.',price:30},
 {id:'potion',name:'Healing Draught',kind:'Consumable',icon:'flask',description:'Drink to recover 2d4 + 2 HP. Uses your action during combat.',price:8},
 {id:'ward',name:'Wardstone',kind:'Trinket',icon:'diamond',description:'A smooth rune-stone. Adds 2 AC for the next enemy turn when activated.',price:12},
 {id:'atlas',name:'Atlas of the Nine Skies',kind:'Book',icon:'book',description:'A field guide to the gates, the three explored realms, and the skies beyond. Open it in the Codex.',price:18},
 {id:'silver-lens',name:'Silver Beacon Lens',kind:'Quest item',icon:'diamond',description:'The lost lens of Lanternfall’s beacon. Warden Seren awaits its return.'},
 {id:'heartseed',name:'Emerald Heartseed',kind:'Quest item',icon:'leaf',description:'A living seed recovered from the ancient shrine. Mira knows how to plant it.'},
 {id:'starcoil',name:'Foundry Starcoil',kind:'Quest item',icon:'spark',description:'A humming arcane mechanism. Ryn needs it to stabilize the harbor.'}
];
export const CLASSES={Vanguard:{hp:16,ac:15,focus:'Steel & resolve',weapon:'moonblade'},Arcanist:{hp:12,ac:13,focus:'Magic & discovery',weapon:'focus'},Wayfarer:{hp:14,ac:14,focus:'Precision & exploration',weapon:'moonblade'}};
export const NPCS=[{id:'ilyra',name:'Keeper Ilyra',home:'nexus',role:'Gatekeeper'},{id:'seren',name:'Warden Seren',home:'lanternfall',role:'City watch'},{id:'mira',name:'Mira of the Green',home:'glasshaven',role:'Shrine keeper'},{id:'ryn',name:'Engineer Ryn',home:'starharbor',role:'Artificer'}];
export const BOOKS=[{id:'atlas',name:'Atlas of the Nine Skies',chapters:[['The roads between worlds','The Moonveil Nexus is a sanctuary between realms. Its gates currently connect the Veiled Marches, Emerald Expanse and Astral Reach. Return to the Nexus to change realms.'],['The little machines','Waybound constructs were made to carry messages across impossible distances. Orison is one of the few still walking. It learns routes, scouts danger and shields its traveling companion.'],['A light worth keeping','The worlds are linked by the people who tend them: a warden holding a road, a keeper planting a seed, an engineer keeping a harbor in the sky. Their stories are yours to change.']]}];

PLACES.push(...TEMPLE_PLACES,...CRYPT_PLACES);
for(const [hub,extra] of [['lanternfall','veil-chapel'],['glasshaven','root-shrine'],['starharbor','star-temple'],['nexus','archive']])PLACES.find(p=>p.id===hub).neighbors.push(extra);
QUESTS.push(CRYPT_QUEST); ITEMS.push(...LIFE_ITEMS);
NPCS.push(...TEMPLE_PLACES.map(p=>({id:p.id+'-keeper',name:p.speaker,home:p.id,role:'Temple keeper'})),{id:'nera',name:'Archivist Nera',home:'archive',role:'Archivist'});

REALMS.push(MYTHOS_REALM);PLACES.push(...MYTHOS_PLACES);QUESTS.push(MYTHOS_QUEST);ITEMS.push(MYTHOS_ITEM);PLACES.find(p=>p.id==='nexus').neighbors.push('nodens-shore');NPCS.push({id:'nodens',name:'Nodens',home:'nodens-shore',role:'Moonveil Mythos interpretation'});
