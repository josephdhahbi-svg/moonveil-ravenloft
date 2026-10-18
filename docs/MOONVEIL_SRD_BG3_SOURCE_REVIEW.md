# 2024 SRD and Baldur's Gate 3 mod source review — October 2026

## Input files independently inspected
- `dnd-5e-srd-markdown-master.zip` — downfallx/dnd-5e-srd-markdown, SRD 5.2.1. The archive LICENSE states CC BY 4.0 and includes a Wizards of the Coast attribution.
- `bg3dnd-main.zip` — Yoonmoonsik/bg3dnd, Baldur's Gate 3 DnD 5.5e All-in-One BEYOND mod. README describes 41 backgrounds, updated combat/rules behaviors, and class/spell/item features. This is a **BG3 mod**, not a direct copy of official tabletop rules.
- `package.json` — separate local AI-DM Next.js app, version 0.1.0, using React, Prisma, Vitest and Ollama per its description. A manifest alone does not prove runtime behavior.

## Actual SRD archive structure
`magic-items.md` (243,847 characters) and `monsters-A-Z.md` (515,979 characters) contain Markdown entries. The section-heading extraction found **260 unique magic-item headings** and **235 monster entry headings**. These are *headings*, not a verified claim about every official 2024 sourcebook item, distinct monster or stat-block variant. Spell and monster counts in README are broader statements.

`scripts/import_srd_521.py` extracts names into a separate `MSRD-ITEM-00001`/`MSRD-MONSTER-00001` namespace. These IDs **do not alter Moonveil's MOI IDs**, saves, or prior artwork ZIPs.

## Integration safeguards
1. The SRD material is CC BY 4.0; preserve attribution, source links, and indicate modifications when redistributing licensed SRD text.
2. Treat BG3 mechanics, game art, custom class options, and mod assets as separate adaptations with license and version review.
3. Metadata index stores no copied rule text or images by default.
4. Do not treat a source heading as proof of precise rarity, attunement, monster CR, full stat block, or permission to reuse art.
5. Import into staging; merge only after ID reconciliation, duplicate review and tests.
6. Never overwrite campaign saves or push to `main`.
