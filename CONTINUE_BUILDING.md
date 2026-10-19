# CONTINUE BUILDING — Moonveil Universe

Baseline: ebbebf1f007ac6706977748337c5547a34b8b698
Active development branch: continue/ebbebf1-security-recovery-tests

## Non-destructive invariants
- Preserve all existing assets, original large game archives, artwork paths, interfaces, save files and prior character continuity. Never replace source artifacts with a newly generated demo.
- Vesper Vane and PariahT are established canon. Do not silently substitute demo default character/companion values.
- Do not activate paid Render hosting or publish secret tokens.
- Save conflicts must never silently overwrite an offline device's local progress. Keep revisions and an exportable local copy.

## This continuation
- Added tests/server-auth-conflicts.test.mjs for authenticated player/DM permissions, DM revision handling, stale writes, concurrent writes, and preservation of offline progress.
- Added .github/workflows/moonveil-recovery-ci.yml to run regression tests on ubuntu-latest with read-only GitHub token permissions.
- Commit ebbebf1 has a Windows-specific Chrome offline test that skips elsewhere; mobile Chromium browser verification remains OPEN.
- GitHub Actions workflow execution and test pass are NOT verified by the connector at the time of writing: associated workflow-runs endpoint returned an empty list and only exposes pull-request runs.
- 433 MB original archive presence, image hash integrity, and real Chrome Android rendering have NOT been reverified.

## Next implementation tasks
1. Obtain full asset archive and verify hashes and interface consistency without deleting/renaming files.
2. Run GitHub Actions, inspect actual job logs, and correct any failed assertions.
3. Add Playwright mobile Chromium tests with controlled offline service-worker lifecycle, cinematic image loading, and visual regression snapshots.
4. Improve device-local conflict recovery UX: explicit keep-local, download-remote, export-local, and manual merge; no implicit overwrite.
5. Validate authenticated DM endpoint over HTTPS in a non-paid environment; keep tokens outside the public client.
6. Validate the production app honors the authoritative Vesper Vane/PariahT checkpoint instead of demo defaults.

CONTINUE BUILDING
