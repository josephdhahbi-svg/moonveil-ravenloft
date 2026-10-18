# Moonveil animation and UI-control source audit

Reviewed 2026-10-17 against six GitHub repositories and the uploaded ZIPs
`dnd5e-animations-master.zip` (119 entries) and `builder-main.zip` (115 entries).

| Source | Observed purpose | Moonveil use | Rights/integration guard |
|---|---|---|---|
| https://github.com/MrVauxs/dnd5e-animations | Foundry VTT automated spell/item animation presets; README claims over 1,000 configurations and uses JB2A/PSFX media | Map spell, item, weapon and ability identifiers to proposed VTT visual-effect events | Repository GPL-3.0; third-party effect/video/audio assets have independent rights, some Patreon-gated; do not copy media or package module code blindly |
| https://github.com/vueform/builder | Vueform drag-and-drop JSON form builder | Admin-facing schema editor for item sheets, monsters, spells and character templates | Package is `@vueform/builder`, license says `SEE LICENSE IN LICENSE.txt`; separate license review required |
| https://github.com/vueform/toggle | Vue 3 toggle with labels/custom slots | On/off controls for animation, audio, automation and accessibility preferences | MIT; Vue code cannot run natively in Flutter |
| https://github.com/vueform/slider | Vue 3 multi-handle slider with formatting | Spell effect intensity, volume, zoom, HP thresholds | MIT; adapt UX using Flutter widgets |
| https://github.com/vueform/multiselect | Vue 3 tagging/single and multiple-select | Class, rarity, damage, faction and sourcebook filters | MIT; adapt UX using Flutter widgets |
| https://github.com/vueform/vueform | Vue form framework | Schema-driven form validation and DM/admin editing concepts | MIT; not a direct Flutter dependency |

## Implementation design

1. Keep game and save data in the existing Flutter/SQLite architecture. Source compatibility is **not** a license to overwrite either character's saved inventory.
2. Define an engine-neutral `animation_event` record: `event_id`, `entity_id`, `trigger`, `effect_key`, `duration_ms`, `intensity`, `asset_id`, `source`, `rights_status`.
3. Resolve by stable codex/spell/item IDs. Missing or unlicensed animation media means **no effect**, never break combat actions.
4. Expose animation enable, reduced motion, sound, volume and intensity as user controls; never autoplay Patreon media without a verified license.
5. Define schema-controlled admin forms, allowing source references, rarity, attunement, CR, spell levels and visual asset assignment; require provenance review.
6. Add UI tests for filtering, settings persistence, input bounds, accessibility, null/missing assets, and Vesper/Alice isolation.

## Status

This is a source and architecture review only. **No third-party code or art imported**, no media installed, no live GUI changes, and no save changes. Maintain all changes on `integration/copy-first-audit` until separately verified.
