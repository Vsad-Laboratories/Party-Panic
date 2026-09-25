# assets/ — Operator-generated art

Source art for the game. PNGs are **not** synced into the place by Rojo — they are
uploaded through Roblox Studio and referenced by `rbxassetid://` in code.

## Format & naming

- 512×512 PNG, transparent background, **no baked text**
- Astro-Arcade Punk palette (see `docs/DESIGN.md`)
- PascalCase filenames matching ui button names (`Back.png` → button "Back")

## Icons (`assets/Icons/`) — 19 of 24 present

| Tier | Present | Pending |
|---|---|---|
| 1 — nav | Inventory, Shop, Settings, PartyPass, Packs, MiniGames, WorldMap, Stats | — |
| 2 — HUD | Coin, Perk, Players | **Level** |
| 3 — controls | Close, Back, Confirm, Claim, Lock, VoteMap, Play | — |
| 4 — round 2 | Buy | **Sell, Equip, Unequip, Gift** |

`WorldMap` = the "Maps" nav button.

## Upload → IDs workflow

1. Operator bulk-uploads in Studio: **View → Asset Manager → Bulk Import**, select PNGs.
2. IDs are dropped here (`assets/IDs.txt`) or pasted in chat.
3. Code side: `src/client/ui/icons.luau` holds the `name → rbxassetid://` table;
   filling the table is the only change needed.

Hover/pressed visual states are tinted in code (`ImageColor3`) — no duplicate
uploads needed.

## Sounds

Registered in `docs/ASSETS.md` (Audio table):

- Press/click (all devices): `138567614125924`
- Hover (PC only): `127105730240202`

## Reference

- `assets/Reference/Lobby.jpg` — lobby ground truth (moved from repo root;
  the old `LobbyMap Reference.jpg` was replaced by this file).
