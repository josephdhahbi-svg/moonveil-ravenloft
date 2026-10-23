# Moonveil Character Sheet, Improved UI, and Inventory Expansion Review

Reviewed 2026-10-17. Research integration only; **no third-party mod files copied, no inventory grants, and no save/database modifications**.

## 1. Character Craft 5.5e
- Source: https://github.com/renanmgs/CharacterCraft_5.5e_Public
- Uploaded archive inspected: `CharacterCraft_5.5e_Public-main.zip` (15 ZIP entries).
- README says multiplatform character sheets, multiple characters, stats, inventory, spells, dice and offline access.
- `assets/Character_Craft_Default_DB.json` is a large reference-data file; `assets/characters/` has example character JSON and a list.
- The README simultaneously describes 2024 Free Rules and credits *SRD 5.1 OGL*: license/edition classification requires record-level verification.
- Adapt **schema concepts** into Flutter/SQLite without assuming the sample stats, class progressions or character data are 5.5e authoritative.

## 2. BG3 ImprovedUI
- Source: https://github.com/TheRealDjmr/BG3ImprovedUI
- Uploaded archive inspected: `BG3ImprovedUI-main.zip` (39 ZIP entries).
- Source includes character creation, level up, respec and appearance XAML pages, plus separate keyboard/controller state machines.
- README explicitly says there are no plans to actively maintain the project and discusses patch 8 support.
- Adapt UX patterns: responsive panes, controller/keyboard focus, separate selection and confirmation; **do not paste BG3 XAML/assets into Flutter**.

## 3. BG3 Inventory Expanded
- Source: https://github.com/VelvetSociety/BG3-InventoryExpanded
- README calls it a **beta** BG3 mod, offering shared party/camp inventory and slot-based armory.
- Its client/server separation (Lua data collection + messaging; client state and XAML presentation) maps usefully to Moonveil's asset service, immutable catalog, local character-save adapter, and Flutter widgets.
- Suggested features: gallery + list toggle, search, rarity/type/attunement filters, item comparison, equipment-slot views, item source provenance.
- **Save isolation:** Vesper's and Alice's SQLite databases must remain distinct. An item in the global catalog is not an acquired item.

## Recommended implementation order
1. Create schema adapters for official SRD metadata, Moonveil's `MOI` item registry, and character sheet fields.
2. Build read-only global item library with 25-item pagination and validated `MOI` IDs.
3. Implement separate per-character owned-inventory service with explicit equip/unequip and attunement guards.
4. Create responsive Flutter library and equipment UI; wire original numbered PNG artwork only after asset checksums pass.
5. Test duplicate IDs, missing images, source attribution, edition uncertainty, attunement limits, and save separation.

## Rights and trust
Use published metadata only where lawful; license-check third-party code and art separately. Cite source repositories for design inspiration, and never identify BG3 mods or unverified data as official D&D rules.
