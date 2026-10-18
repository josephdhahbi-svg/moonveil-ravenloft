# Moonveil AI Dungeon Master bridge

This is the **server-side** AI bridge for Moonveil Ravenloft. It is not deployed automatically by GitHub Pages. It keeps the API key off the public website.

Requires Node.js 20+. Set `OPENAI_API_KEY`, `ALLOWED_ORIGIN` (exact origin of your game, e.g. `https://josephdhahbi-svg.github.io`), optionally `OPENAI_MODEL`, and `PORT`. Run `npm start` from this directory.

`POST /api/turn` with JSON `{"action":"Examine the moonlit door","state":{"hero":"Vesper Vane","hp":10}}` returns `narrative`, `visualPrompt`, five `suggestedActions`, and **untrusted** `proposedChanges`. The frontend must validate proposed changes against the rules engine before committing them. Do not treat AI prose as authoritative save state.

`GET /health` reports whether the API key is configured. Deploy this server to a Node-compatible hosting provider with HTTPS and environment secrets; then connect the game UI to its URL. Browser speech input/output and artwork generation are separate integrations. The API is not authenticated for public multi-user use: add user authentication, per-user rate limits and durable server-side saves before public launch.

Do not embed an API key in HTML or commit it to GitHub.
