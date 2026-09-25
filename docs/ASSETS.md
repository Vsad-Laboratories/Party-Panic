# Asset Registry — Party Panic

Operator-curated Creator Store inventory. **Control maintains this file; map/client agents consume it.**
Never hardcode asset IDs in code — maps reference entries from here via their `config.luau` (`meshId` / `textureId` / `soundId`).

## Ingest rules (binding)

1. **Visual/audio only — community scripts never run.** Models load via `InsertService:LoadAsset` while
   *unparented* → destroy every `Script` / `LocalScript` / `ModuleScript` descendant → only then parent.
   Several store models are marked "This model contains scripts" — the strip makes them safe; without the
   strip they are rejected.
2. Every ID gets verified in playtest (mesh renders, audio plays, no permissions error).
3. New batch flow: Operator collects → Control appends here → agents consume.
4. Skip any asset that needs a purchase — free inventory only.

## Batch 1 (2026-09-25)

### Audio

| Asset ID | Name | Intended use |
|---|---|---|
| 130456049552264 | Among-us-style kill effect | elimination SFX |
| 76586276648178 | Confetti pop | results / win burst |
| 73774648241042 | Excellent rating | round-win fanfare sting |
| 84784527213277 | Round start bell | round start (multi-use) |
| 155953872 | Ticking clock | final-seconds countdown |
| 9112819065 | Lobby looping sound | lobby ambient loop |
| 11202760067 | Winner podium | podium / crown fanfare |
| 13815846729 | Balloons | lobby decor ambience |
| 2068591214 | Confetti cannon | intermission burst |
| 138567614125924 | Button pop click | every button press/click (PC + mobile tap) |
| 127105730240202 | Keyboard click | every button hover (PC) |

### Models (geometry dressing)

| Asset ID | Name | Intended use | Flags |
|---|---|---|---|
| 4924776069 | Small obstacle map | Tag Blast arena reference / props | check scripts on ingest |
| 14075114183 | Moving platform on a ball | Phase B interactive (King of the Hill?) | check scripts |
| 7856302443 | Swinging hammer | Phase B interactive (Obstacle Sprint) | check scripts |
| 9521417156 | The Fall map | Floor Fall arena reference/kit | **contains scripts → strip** |
| 741384218 | Detailed bench | lobby decor | check scripts on ingest |
| 6121196773 | Conveyor belt | obstacle prop (Phase B) | contains scripts → strip |
| 16206527053 | Rectangle planter 1 | lobby decor | |
| 5463147966 | Round vase planter 2 | lobby decor | |
| 129972365670146 | Box vase planter 3 | lobby decor | |
| 5036801877 | Medieval lamp 1 | lobby decor (retheme via material/color) | |
| 12462175904 | Lamp post | lobby decor | |
### VFX / cosmetics (shop shell)

| Asset ID | Name | Intended use | Flags |
|---|---|---|---|
| 7564537285 | VFX pack | confetti/sparkle emitters | scripts → strip on ingest |
| 3222976721 | Player trail system | trails (shop tier) | scripts → strip; Phase B logic re-implemented by Client agent |
| 15374038687 | Normal aura pack | auras (common/rare shop tier) | scripts → strip |
| 106979401006635 | Premium aura pack | auras (legendary/elite tier, premium pricing) | scripts → strip |

### UI icons (2D)

| Asset ID | Name | Intended use |
|---|---|---|
| 115356376743509 | Coin icon | HUD / shop coin display |
| 8370512807 | Voting coin icon | vote UI |

## Open flags

- ~~Duplicate ID `6121196773`~~ **resolved 2026-09-25**: bench = `741384218`, conveyor = `6121196773`.
- Trail/aura packs contain gameplay scripts → Client agent re-implements effects cleanly in Phase B;
  pack scripts are stripped, only visuals/meshes referenced.
