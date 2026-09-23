# Party Panic

Round-based party royale for Roblox. Audience: kids 9–13.

Concept, locked decisions, and roadmap live in [docs/GDD.md](docs/GDD.md).

## Toolchain

Managed by [rokit](https://github.com/rojo-rbx/rokit): [Rojo](https://rojo.space), [selene](https://github.com/Kampfkarren/selene), [Stylua](https://github.com/JohnnyMorganz/Stylua).

```sh
rokit install        # install pinned tools (rokit.toml)
stylua src           # format
stylua --check src   # verify formatting
selene src           # lint (run `selene generate-roblox-std` once per clone)
rojo build -o build/PartyPanic.rbxlx   # compile the place
```

## Workflow

Git-push-driven — there is no local Roblox Studio (Vinegar/HD 4000 ruled out; see Vision.md).

Every push to `main` runs CI: format check → lint → `rojo build` → uploads **`PartyPanic.rbxlx`** as a workflow artifact → **publishes the place to Roblox via Open Cloud**, then playtest in **Sober**.

Publish stays *skipped* until configured once: repo secret `ROBLOX_API_KEY` (Creator Dashboard → credentials, universe-places **Write**) and repo variables `ROBLOX_UNIVERSE_ID` + `ROBLOX_PLACE_ID`. Until then, the artifact alone is downloadable from the Actions run.

## Layout

```
default.project.json   Rojo place definition
rokit.toml             pinned tool versions
src/server/            server logic (round state machine, lobby)
src/client/            client logic (UI, spectate)
docs/GDD.md            game design + decision log
.github/workflows/     CI: lint, build, place artifact
```
