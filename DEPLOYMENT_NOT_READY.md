# Moonveil Universe full PWA deployment branch

This branch is reserved for the EXISTING complete Moonveil PWA, not the small earlier Ravenloft game.

## Not live / incomplete
The full ~417 MB game asset tree is NOT uploaded to this branch yet. Do not connect Render or share a URL until `dist/`, `server/`, `tests/`, `package.json`, and `render.yaml` from the tested full release are pushed together.

On Render, create a Blueprint for this branch after full files are pushed. Set two distinct random 24+ character secret values for `MOONVEIL_PLAYER_TOKEN` and `MOONVEIL_DM_TOKEN`. The Starter plan and persistent disk have costs. Do not expose secret tokens in GitHub or browser JavaScript. Verify HTTPS `/healthz`, `/openapi.json`, homepage, art assets, and authenticated saves/actions. The ChatGPT connector must be separately authorized to access the DM API.
