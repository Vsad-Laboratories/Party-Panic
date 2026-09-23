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

Git-push-driven — there is no local Roblox Studio on the dev machine.

Every push to `main` runs CI: format check → lint → `rojo build` → uploads **`PartyPanic.rbxlx`** as a workflow artifact. Download it from the Actions run and open it in Roblox Studio to test.

## Layout

```
default.project.json   Rojo place definition
rokit.toml             pinned tool versions
src/server/            server logic (round state machine, lobby)
src/client/            client logic (UI, spectate)
docs/GDD.md            game design + decision log
.github/workflows/     CI: lint, build, place artifact
```
