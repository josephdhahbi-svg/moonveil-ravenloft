# Moonveil: 17 additional GitHub references (October 2026)

Source evaluation is based on accessible repository READMEs and GitHub metadata. The repositories were **not installed or executed**. This review does not claim test or licensing clearance.

| Source | Main purpose | Disposition | Caveat |
|---|---|---|---|
| [Orcpub/orcpub](https://github.com/Orcpub/orcpub) | Character sheet generator | adapt | Legacy 5e; verify rules and licensing |
| [Durtur/Dungeoneer](https://github.com/Durtur/Dungeoneer) | Multiplayer VTT, encounters, initiative and stat tracking | adapt | Strong VTT reference, not proof of 2024 compatibility |
| [opendnd/opendnd](https://github.com/opendnd/opendnd) | Names, NPCs, settlements and dynasty generators | adapt | Keep procedural content separate from official canon |
| [elymsyr/dungeon-master-tool](https://github.com/elymsyr/dungeon-master-tool) | Offline-first Flutter DM tool, maps, combat and dice | study | CC BY-NC 4.0; no commercial/code reuse without review |
| [oakbrad/dungeonchurch](https://github.com/oakbrad/dungeonchurch) | Campaign hosting and group infrastructure | defer | Operational stack; avoid automatic imports or unlicensed media |
| [Traneptora/grimoire](https://github.com/Traneptora/grimoire) | Mobile 2016-era spellbook | adapt | Historical 5e and prior DMCA context; don't reproduce restricted spells |
| [thomascgray/fantasy-content-generator](https://github.com/thomascgray/fantasy-content-generator) | Seeded fantasy narrative and item generators | adapt | Generated results are homebrew unless verified |
| [jsnee/vscode-dmbinder](https://github.com/jsnee/vscode-dmbinder) | Campaign document management and PDF templates | adapt | Use as inspiration for archive/document workflows |
| [alessio29/savagebot](https://github.com/alessio29/savagebot) | Discord RPG dice and initiative bot | defer | Primarily Savage Worlds; external bot is not needed in Flutter core |
| [Qubus0/diceRoller](https://github.com/Qubus0/diceRoller) | Physics-based dice visualization | adapt | Review platform and dependencies before animation integration |
| [BrianWendt/dnd5e_json_schema](https://github.com/BrianWendt/dnd5e_json_schema) | 5e JSON schema definitions | adapt | Schema reference only; verify 2024 rule fields |
| [bencodrington/phanary](https://github.com/bencodrington/phanary) | Atmospheric browser RPG audio | defer | README explicitly says obsolete and replaced by TurboBard |
| [andyaiken/masterplan](https://github.com/andyaiken/masterplan) | D&D 4e encounter and campaign planning | adapt | Edition mismatch; conceptual planning only |
| [swichers/dndbeyond-screen](https://github.com/swichers/dndbeyond-screen) | Consolidated DM party dashboard | adapt | README warns of unofficial and rate-limited D&D Beyond endpoints |
| [benwebber/tiddlywiki-dnd](https://github.com/benwebber/tiddlywiki-dnd) | Wiki campaign database and stat-sheet cards | adapt | Good journal and codex patterns, MIT per README |
| [wanderers-guide/wanderers-guide](https://github.com/wanderers-guide/wanderers-guide) | Pathfinder/Starfinder character builder | defer | Wrong rules family; only optional UI reference |
| [GooseWillis/SoundBoard](https://github.com/GooseWillis/SoundBoard) | PowerShell tabletop soundboard | defer | Manual audio playlist CSVs; no platform portability assumed |

## Recommended implementation sequence

1. Use Dungeoneer and dungeon-master-tool as reference designs for combat, encounter tracking, DM screens and mobile VTT; the latter is CC BY-NC 4.0, so do not copy code/assets without rights review.
2. Use OrcPub, TiddlyWiki D&D, and the JSON-schema reference to shape modular, source-provenance-aware character sheets and lore/archive tools. Keep old-5e fields explicitly distinct from 2024/SRD 5.2.1.
3. Use seedable generator concepts from opendnd and fantasy-content-generator to create original NPCs, towns and dungeons; label these as generated homebrew, not canon.
4. Consider 3D dice/physics and soundscape components, using independent original or suitably licensed assets. No automatic copying of third-party audio.
5. Build AI/robot adapters with validation, deterministic IDs, import staging, citation/rights review, and checksums. Preserve Vesper and Alice save isolation and global collection versus owned items.
6. Exclude unsupported scraping of D&D Beyond endpoints and wholesale 4e/Pathfinder conversions. Maintain development solely on `integration/copy-first-audit`.

## Implementation status

Research archive committed only. **No integration, testing, artwork installation, gameplay change, save mutation or deployment** occurred in this review.
