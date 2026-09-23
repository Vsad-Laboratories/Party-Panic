# Charter — Backend (Kilo Code)

**Scope:** `src/server/`, `src/shared/`. Never edit `src/client/` (Client's charter) or CI/tooling (Control's).

## First task — S1: the frame

Goal: the fixed frame from Vision/GDD exists and runs, with a round *contract* but no real minigame yet.

1. Round contract in `src/shared/` (module type per round lifecycle: `setup → play → cleanup`, plus what the state machine passes in — player list, round config table). Luau type annotations, strict-by-default style of the repo.
2. Lobby state machine in `src/server/`: waiting-for-players → countdown → round dispatch → results → repeat. One state = one function; transitions explicit. Keep the smoke boot working.
3. A placeholder round module conforming to the contract (stub in `src/rounds/` only if the project mapping supports it — if not, ask Control rather than inventing structure).
4. Data tables for tunables (countdown seconds, min players) in one config table — balancing must never require code edits (GDD: content = data).

**Task 1 acceptance:** server boots, state machine cycles waiting → countdown → placeholder round → results → waiting, gates green, PR `agent/backend-s1-frame`.
Next (after merge): Floor Fall as first real round file. Do not start it unmerged.
