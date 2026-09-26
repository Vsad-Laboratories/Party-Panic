# Party Panic — Project Agent Instructions

> Read together with `~/RULES.md` (hard rules) and your role charter in `docs/agents/`.
> Kilo discovers this file at session start; OpenCode reads it from the project cwd.

## Skills — mandatory

Skills are installed at `~/.agents/skills/<id>/SKILL.md` (universal dir) and mirrored to
`~/.config/kilo/skills/` for kilo discovery.

**Rule: before doing matching work, Read the SKILL.md and apply it. Name the skill(s) you
applied in your PR body. A PR that ignores an applicable skill is a review finding.**

| Work | Skill(s) |
|---|---|
| Any Luau | `roblox-luau` → `roblox-luau-core` |
| Modules, lifecycles, signals, cleanup | `roblox-luau-patterns` |
| Types, annotations, generics, narrowing | `roblox-luau-types` |
| Server logic, persistence, DataStores | `roblox-datastores` |
| Security, permissions, economy, reviews | `roblox-security`, `roblox-code-review` |
| Maps, lobby, zones, large environments | `building-maps`, `roblox-building` |
| Props, 3D objects, geometry | `roblox-building` |
| GUI, layout, visual systems | `roblox-gui`, `roblox-ui-design` |
| Animations | `roblox-animations` |
| Performance, mobile budget, profiling | `roblox-performance` |
| GamePasses, products, pass logic | `roblox-monetization` |
| Game structure, rounds, modes | `roblox-game-development` |
| Need a skill that does not exist | `find-skills` |

**Precedence:** skills advise *how* to build; `~/RULES.md`, `docs/DESIGN.md`, and your
charter decide *what* and *where*. On craft technique the skill beats generic docs (see the
AUTHORITY note in `building-maps`); palette/scope/law sections are never overridden.

**MCP note:** `building-maps` prefers `mcp__roblox__run_code` (live Studio). No MCP server is
configured yet — the default pipeline is config-driven Luau + Rojo + CI. Use the skills for
their craft knowledge; check `kilo mcp list` before assuming an MCP path exists.
