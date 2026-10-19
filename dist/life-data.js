// Moonveil campaign additions. These are homebrew, not official D&D lore/rules.
export const PATRONS = [
 {id:'veil-mother',name:'The Veil Mother',temple:'veil-chapel',theme:'Shelter, remembrance and safe passage',tenet:'Keep a light for those who cannot find their way.',keeper:'Sister Aven',art:'Moonlit Castle',line:'A candle cannot erase the dark. It can help someone take the next step.'},
 {id:'verdant-witness',name:'The Verdant Witness',temple:'root-shrine',theme:'Renewal, patience and living memory',tenet:'Return something to the world that sustains you.',keeper:'Tender Leth',art:'waterfall',line:'The forest remembers what we take. Let it remember what we give as well.'},
 {id:'starwright',name:'The Starwright',temple:'star-temple',theme:'Discovery, craft and faithful repair',tenet:'Mend what you can. Learn what you cannot yet mend.',keeper:'Custodian Eno',art:'Hall of Frozen',line:'An imperfect thing can still carry someone home. Orison understands this better than most.'}
];
export const PROFESSIONS = [
 {id:'alchemist',name:'Alchemist',hub:'lanternfall',mentor:'Apothecary Sella',material:'moonherb',product:'potion',cost:4,art:'Candlelit',order:'Medicine for the Night Watch',line:'Two sprigs, a clean vessel, and a steady hand. The watch needs medicine before nightfall.'},
 {id:'runesmith',name:'Runesmith',hub:'starharbor',mentor:'Forgekeeper Tal',material:'scrap-iron',product:'ward',cost:6,art:'Hall of Frozen',order:'A Ward for the Dockworkers',line:'The inscription matters. A ward should hold long enough for its bearer to get to safety.'},
 {id:'herbalist',name:'Herbalist',hub:'glasshaven',mentor:'Gardener Esra',material:'moonherb',product:'potion',cost:3,art:'Hidden Ridge',order:'The Garden Infirmary',line:'Take only mature leaves. Leave the root, and the next traveler will find medicine too.'},
 {id:'cartographer',name:'Cartographer',hub:'nexus',mentor:'Chartkeeper Oren',material:'star-dust',product:'atlas',cost:6,art:'Chapter11 Diderius',order:'An Atlas for the Gatekeepers',line:'A map is a promise. Mark the safe roads, and write down what you do not know.'}
];
export const LIFE_ITEMS = [
 {id:'moonherb',name:'Moonherb Sprigs',kind:'Material',icon:'leaf',description:'Two sprigs are used for a healing draught at a profession workshop.'},
 {id:'scrap-iron',name:'Salvaged Iron',kind:'Material',icon:'diamond',description:'Clean iron recovered for protective runework.'},
 {id:'star-dust',name:'Star Ink Pigment',kind:'Material',icon:'spark',description:'A luminous pigment used to copy maps of the interrealm gates.'},
 {id:'echo-seal',name:'The Quietus Seal',kind:'Quest item',icon:'diamond',description:'A sealed funerary focus from the lichbound archive. Return it to Archivist Nera.'}
];
export const TEMPLE_PLACES = [
 {id:'veil-chapel',name:'Chapel of the Last Lantern',realm:'veil',kind:'Temple',x:8,y:27,art:'mist',description:'Candles illuminate names carved into black stone. A bell rope hangs beside a door that is never locked.',speaker:'Sister Aven',line:PATRONS[0].line,neighbors:['lanternfall']},
 {id:'root-shrine',name:'Shrine of Returning Roots',realm:'verdant',kind:'Temple',x:48,y:10,art:'waterfall',description:'Offerings of seeds rest in shallow pools. An elderly keeper tends a tree growing through the roof.',speaker:'Tender Leth',line:PATRONS[1].line,neighbors:['glasshaven']},
 {id:'star-temple',name:'Sanctum of the Patient Forge',realm:'astral',kind:'Temple',x:90,y:9,art:'forge',description:'A brass orrery turns above an altar of repaired tools. Tiny blue lights mark each completed act of service.',speaker:'Custodian Eno',line:PATRONS[2].line,neighbors:['starharbor']}
];
export const CRYPT_PLACES = [
 {id:'archive',name:'The Vigil Archive',realm:'veil',kind:'Archive',x:40,y:59,art:'tomb',description:'Archivist Nera guards the ledger of a long-dead court. A voice has begun reading from the locked crypt below.',speaker:'Archivist Nera',line:'The lich is gone, but an echo of its will has awakened. Bring me the Quietus Seal. Read the archivist’s testament before opening the reliquary.',neighbors:['nexus','lich-crypt']},
 {id:'lich-crypt',name:'Crypt of the Unwritten King',realm:'veil',kind:'Encounter',x:50,y:78,art:'tomb',description:'Four chambers lie beneath the archive: a vestibule, an ossuary, a scriptorium, and the sealed reliquary. This is the lair of a weakened lichbound echo, not a full official lich encounter.',speaker:'The Lichbound Echo',line:'My court has forgotten my name. Will you write it again—or let the dead be still?',neighbors:['archive'],quest:'quietus-seal'}
];
export const CRYPT_QUEST = {id:'quietus-seal',name:'Let the Dead Be Still',giver:'archive',site:'lich-crypt',item:'echo-seal',reward:45,xp:55,summary:'Read the testament in the crypt scriptorium, open the reliquary, defeat the lichbound echo and return the Quietus Seal to Archivist Nera.'};
export const ROOMS = [
 {id:'vestibule',name:'The Mourning Vestibule',x:20,y:50,art:'Tomb of Diderius',neighbors:['ossuary','scriptorium'],text:'A stone threshold opens into two passages. Three empty candleholders face the sealed reliquary.',interaction:'Read the threshold inscription'},
 {id:'ossuary',name:'The Ossuary',x:48,y:22,art:'Crowned Mummy',neighbors:['vestibule','vault'],text:'Bone niches surround a dry fountain. A burial offering lies beneath a fallen lantern. The inner door is visible beyond the columns.',interaction:'Recover the burial offering'},
 {id:'scriptorium',name:'The Silent Scriptorium',x:48,y:78,art:'Ancient stone wizards',neighbors:['vestibule','vault'],text:'An unfinished testament rests beneath a glass weight. Its last line says: “Let my name end here. Let my servants rest.”',interaction:'Read the archivist’s testament'},
 {id:'vault',name:'The Quietus Reliquary',x:80,y:50,art:'Vaulted Mosaic',neighbors:['ossuary','scriptorium'],text:'A voice clings to the funerary focus. The echo and its skeletal bailiff stand between you and the Quietus Seal.',interaction:'Release the reliquary seal'}
];
export const SPELLS = [
 {id:'frost',name:'Frost Sigil',cost:1,text:'One action, 1 focus. A visible enemy within 6 squares takes 1d4 cold damage and gains a frost mark. No attack roll. Homebrew.'},
 {id:'storm',name:'Storm Arc',cost:1,text:'One action, 1 focus. A visible enemy within 6 squares takes 1d6 lightning damage. A frost mark adds 1d4 shatter damage and is consumed. Homebrew.'}
];
export const RITUAL={id:'waybound-ascension',name:'The Concordance of Three Lights',rank:'Waybound Ascendant',cost:15,scrollCost:8,sequence:['remembrance','witness','mercy','resolve','return'],nodes:[{id:'remembrance',name:'Remembrance',x:50,y:12},{id:'resolve',name:'Resolve',x:87,y:38},{id:'witness',name:'Witness',x:74,y:82},{id:'return',name:'Return',x:26,y:82},{id:'mercy',name:'Mercy',x:13,y:38}]};
LIFE_ITEMS.push({id:'concordance-scroll',name:'Scroll of Three Lights',kind:'Ritual scroll',icon:'book',description:'An inscribed diagram for the Concordance of Three Lights. Read the Rituals section of World & Sheets for the sequence and requirements. Consumed when the ritual succeeds.'});
