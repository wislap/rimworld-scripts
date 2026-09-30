# RimWorld workspace scripts

Small development scripts used by the N.E.K.O RimWorld workspace.

## Contents

- `Build-RimWorldMod.ps1`, `build-rimworld-mod.sh`: build the C# Mod.
- `Link-RimWorldDevMod.ps1`, `link-rimworld-dev-mod.sh`: link the development Mod into a local RimWorld installation.
- `Start-RimWorldDev.ps1`, `start-rimworld-dev.sh`: launch the development game setup.
- `start-dev.sh`, `start-neko.sh`: launch local development services.
- `Test-RimWorldBridge.ps1`, `test-rimworld-bridge.sh`: exercise the bridge.
- `Test-RimWorldDevEnv.ps1`, `verify-rimworld-dev-env.sh`: check the development environment.
- `archive-organize.sh`: organize local archive material; review its target paths before running.
- `workspace_checkpoint.py inventory|seal|verify`: offline recovery capsules for the five companion repositories and local experiment evidence. Uses the Python standard library and Git; no API calls, uploads or deletion. `seal --out <new-directory>` refuses overwrite and verifies every archived file. See Bench's `planning/RESEARCH-RETENTION.md` for scope and recovery limits.

These scripts are workspace tooling, not the production plugin, Mod, or benchmark runtime. They assume the directory layout of the companion `N.E.K.O_rimworld` workspace and may require local game paths or environment variables. No credentials or generated artifacts belong in this repository.

For recovery on Windows, use `git -c core.longpaths=true clone <bundle> <new-directory>` when historical archive paths exceed the default Git path limit. This is a per-command setting; no global configuration change is needed. ZIP verification itself uses streamed hashes and does not require checkout. The successful recovery capsule for this checkpoint is `workspace-backups/20260930-research-checkpoint-v2`; the earlier directory is an incomplete attempt, not a verified backup.
