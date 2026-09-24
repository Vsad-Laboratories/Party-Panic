# Party Panic — Manual Playtest Checklist

> For the Operator. Run against the **published** build (CI publishes every merge to main).
> Session-end rule: paste findings (pass/fail + repro) back to Control for fleet triage.

## Prereqs

- [ ] Latest main green: `gh run list --repo Vsad-Laboratories/Party-Panic --limit 1`
- [ ] Open **Sober** → search experience **Party Panic** (place id `118657294629389`)
- [ ] Optional (live dev instead of published): install Rojo plugin (library `96353449041057`) → `rojo serve`

## Session script (PRD §2 funnel gates)

- [ ] **First round starts ≤ 30 s** from joining an empty-ish lobby (countdown → Floor Fall)
- [ ] **Lobby is live**: player list and countdown tick driven by real server state (not mock)
- [ ] **Floor Fall plays**:
  - [ ] Characters land standing **on** the floor (no fall-through, no instant elimination)
  - [ ] Tiles warn then drop on schedule; falling below threshold eliminates you with feedback
  - [ ] Last player standing wins; results screen names the winner
  - [ ] 60–90 s cap works — round ends by timeout with best-Y award if nobody falls
  - [ ] **Solo check**: with one player the round plays to the timeout win (no instant win at t=0)
- [ ] **Rotation**: results → lobby → next round starts without a restart (repeat ≥ 3 rounds)
- [ ] **Session feel ≥ 8 min** without wanting to quit; no visible stutters (desktop smoke; mobile 30 fps check separately on a low-end device)
- [ ] **Crash-free**: close after a full session; no script errors visible in Sober console
- [ ] Published build matches main (`git log -1` sha vs. dashboard version note)

## Known gaps in this build (not failures)

| Surface | State |
|---|---|
| Vote buttons | Inert shell — vote protocol ships weeks 3–5 |
| Coin counter | Shell at 0 — economy/persistence weeks 6–7 |
| Rematch (FR11) / micro-awards (FR12) | Not yet built |
| Map voting, rounds 2–8 | Backlog (GDD round backlog) |
| Voice chat / 13+ flags | Operator dashboard step, see Vision manual steps |

## After the test

- Pass → Control notes the funnel-gate data point in Vision.
- Fail → file the repro to Control; fleet treats it as a review finding (blocking until fixed).
