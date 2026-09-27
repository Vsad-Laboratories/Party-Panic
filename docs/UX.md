# UX Guidelines: Party Panic Lobby HUD

**Audience:** Kids 9–13. **Target hardware:** Low-end mobile, 30 fps. **Scope:** Lobby-screen UI only (menus, player list, ready button, lobby chat).

> **Skills consulted per project rule:**
> - `~/.config/kilo/skills/roblox-ui-design/SKILL.md` — visual composition, hierarchy, anti-patterns
> - `~/.config/kilo/skills/roblox-gui/SKILL.md` — ScreenGui lifecycle, UDim2, `TextScaled`, `ResetOnSpawn`

---

## 1. Fonts

1. **Display heading font:** `Builder Sans ExtraBold` (`rbxasset://fonts/families/BuilderSans.json` + `Enum.FontWeight.ExtraBold`). Builder Sans is Roblox's official platform font (launched 2024, fully replaced Gotham). `Gotham`/`GothamBold`/`GothamMedium` are deprecated — they silently map to Montserrat and should not be used.
   - Source: https://create.roblox.com/docs/reference/engine/enums/Font
   - Source: https://github.com/Roblox/creator-docs/blob/main/content/en-us/resources/builder-font-license.md

2. **Body / label font + FontFace:** `Builder Sans Regular` (`rbxasset://fonts/families/BuilderSans.json` + `Enum.FontWeight.Regular`) for all body/label text. Set `FontFace` (not the legacy `Font` enum) when you need weight granularity — `Font.fromName("BuilderSans", Enum.FontWeight.Regular)` resolves to the correct `rbxasset://` asset. No decorative fonts in HUD text — kids scan quickly and thin/decorative fonts become illegible on a 30 fps, low-end phone.
   - Source: https://create.roblox.com/docs/reference/engine/datatypes/Font
   - Source: https://create.roblox.com/docs/production/publishing/accessibility#text-size

---

## 2. Text sizing (responsive)

4. **Never hardcode `TextSize` without `UITextSizeConstraint`.** Enable `TextScaled = true` on every `TextLabel`/`TextButton` and parent a `UITextSizeConstraint` with `MinTextSize = 14`, `MaxTextSize = 32`. This bounds scaling across devices.
   - Source: https://create.roblox.com/docs/reference/engine/classes/UITextSizeConstraint
   - Source: https://create.roblox.com/docs/reference/engine/classes/TextLabel/TextScaled

5. **Minimum readable body text inside the constraint: 14 px.** Roblox's own docs warn that `MinTextSize` values below 9 are unreadable; 14 is the comfortable floor for a 9-year-old on a budget phone.
   - Source: https://create.roblox.com/docs/reference/engine/classes/UITextSizeConstraint (docstring: "It's recommended that no values lower than 9 be used")

6. **Heading text:** 24–28 px base, capped at 40 px max. Body: 14–18 px base. Caption/label: 12–14 px base.
   - Source: https://create.roblox.com/docs/production/publishing/accessibility#text-size (illustrates low-vision blur on small text)

7. **Respect `GuiService.PreferredTextSize`.** If you use `AutomaticSize = Enum.AutomaticSize.XY` on text containers (rather than `TextScaled`), the engine honors the player's Settings→Text Size preference automatically. `TextScaled`-constrained text does **not** honor that setting — document this tradeoff when choosing the pattern.
   - Source: https://create.roblox.com/docs/production/publishing/accessibility#preferred-text-size

---

## 3. Touch targets

8. **Minimum touch target: 44×44 px; hit area extends beyond visual glyph.** iOS Human Interface and Axe DevTools Mobile both set 44 px as the floor for active controls. If an icon is 24×24 px, place it in a 44×44 px `TextButton`/`ImageButton` with `BackgroundTransparency = 1`. Never ship a 24×24 tappable icon. Roblox does not override this — treat 44 px as your hard minimum for any tappable element.
    - Source: https://developer.apple.com/design/human-interface-guidelines/buttons (44×44 pt minimum)
    - Source: https://docs.deque.com/devtools-mobile/2024.9.18/en/ios-touch-target-size ("All active controls should have a minimum of 44pt by 44pt")
    - Source: https://developer.apple.com/design/human-interface-guidelines/tappable-areas (touch targets should include invisible padding beyond visual bounds)

9. **Thumb-zone safe area on mobile:** keep the primary CTA (Ready / Start) within 70% of the bottom half of the screen. The bottom corners are where the virtual home/nav bar lives (per Roblox mobile orientation docs), so inset 12–16 px from the absolute edges.
    - Source: https://create.roblox.com/docs/reference/engine/classes/ScreenGui (reserved zones)
    - Source: https://create.roblox.com/docs/input/mobile (thumb zones / bottom-bar conflict)

---

## 4. Contrast & color

11. **Text ≥ 4.5:1 against its background** (WCAG AA). For large text (≥ 18 pt / 24 px regular, or ≥ 14 pt / 18.66 px bold) the floor drops to 3:1. Use a checker before shipping.
    - Source: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html (SC 1.4.3)
    - Source: https://www.w3.org/WAI/WCAG20/Understanding/contrast-minimum.html (3:1 for large text)

12. **Non-text UI controls ≥ 3:1** against adjacent surface (WCAG SC 1.4.11). Buttons, sliders, and borders that convey meaning must hit 3:1 — this covers outlines and icon strokes, not just fills.
    - Source: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html (non-text contrast 1.4.11)

13. **Default lobby palette recommendation (Builder Sans era):** computed with the WCAG sRGB relative-luminance formula against `#1E1E1E` (L = 0.0130):
    - Surface: `#1E1E1E` (deep gray, 0.35 alpha over world)
    - Text: `#FFFFFF` — **16.7:1** (exceeds 4.5:1 ✓)
    - Muted text: `#B3B3B3` — **7.95:1** (exceeds 4.5:1 ✓)
    - Accent (CTA / ready): `#00D1FF` — **9.18:1** (exceeds 4.5:1 ✓)
    - Danger (leave): `#FF4D4D` — **5.10:1** (exceeds 4.5:1 ✓)
    - Border: `#5C5C5C` — **3.1:1** (meets non-text 3:1 ✓; `#3A3A3A` yields only 1.47:1 and FAILS rule 12)
    - Source: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html (SC 1.4.3, SC 1.4.11)

14. **Multiply `BackgroundTransparency` by `GuiService.PreferredTransparency`.** Players who set "Background Transparency" to 0 want opaque UI for readability — honor it. Tag all background-bearing `GuiObject`s with a CollectionService tag and apply `defaultTransparency * GuiService.PreferredTransparency` on init and on `PropertyChangedSignal`.
    - Source: https://create.roblox.com/docs/production/publishing/accessibility#preferred-transparency

15. **Do not rely on color alone for state.** Color-blindness affects ~5% of males. A locked player slot must show a lock icon **and** grayed text, not just a gray color.
    - Source: https://create.roblox.com/docs/production/publishing/accessibility#color-non-reliance

---

## 5. Layout & responsiveness

16. **Use `UDim2.fromScale` for panel size/position, not fixed Offset.** A 75% width panel via `UDim2.fromScale(0.75, 0)` works on a 1920 px monitor and a 375 px phone; `UDim2.new(0, 700, 0, 50)` breaks on mobile.
    - Source: https://create.roblox.com/docs/ui/position-and-size
    - Source: https://roblox-gui-maker.online/blog/roblox-scale-vs-offset-guide

17. **AnchorPoint before Position.** To center a panel: `AnchorPoint = Vector2.new(0.5, 0.5)` then `Position = UDim2.fromScale(0.5, 0.5)`. Forgetting the AnchorPoint is the #1 alignment bug.
    - Source: https://create.roblox.com/docs/ui/position-and-size
    - Source: https://roblox-gui-maker.online/blog/roblox-scale-vs-offset-guide

18. **Use `UIListLayout` for vertical stacks** (player list, menu buttons). Set `FillDirection = Vertical`, `HorizontalAlignment = Center`, `SortOrder = Name`. Avoid manual Y-offset math — it drifts on different aspect ratios.
    - Source: ~/.config/kilo/skills/roblox-ui-design/SKILL.md (principle 3: "Flow")

19. **Constrain max panel width on large screens.** A 600 px-wide lobby panel reads fine on a phone; on a 4K TV it becomes a postage stamp. Wrap panels in `UISizeConstraint` with `MaxSize = UDim2.new(0, 800, 0, 0)` so the panel never exceeds 800 px.
    - Source: https://create.roblox.com/docs/projects/cross-platform (75% on 4K = too big)

20. **Keep 3D world visible.** The lobby is a social space — don't hide it behind an opaque `#000000` fullscreen frame. Use a semi-transparent surface (`BackgroundTransparency = 0.3–0.5`) or a 9-slice border so character models and the LobbyHub map peek through.
    - Source: `~/.config/kilo/skills/roblox-ui-design/references/full.md:232` ("3D world: visible around modal, not fully blocked")

---

## 6. Animation & motion

21. **Tween duration: 0.2 s for hover/focus, 0.3 s for entrance.** Anything longer feels laggy at 30 fps. Use `Enum.EasingStyle.Quad` / `Enum.EasingDirection.Out`.
    - Source: ~/.config/kilo/skills/roblox-gui/SKILL.md (TweenService examples use 0.3 s Quad Out)

22. **Respect `GuiService.ReducedMotionEnabled`.** When true, set `TweenInfo.Time = 0` (snap) or swap positional tweens for fade-only. Kids with motion sensitivity are disproportionately affected.
    - Source: https://create.roblox.com/docs/production/publishing/accessibility#reduced-motion

---

## 7. Tooltips & hover UX (desktop)

23. **Hover-tooltip delay: 150–200 ms; fade-in 0.1 s, fade-out 0.1 s.** Shorter feels twitchy (kids move the mouse a lot); longer feels broken. 150 ms is the sweet spot for 9–13 yo — they perceive it as "instant." No slide/scale — at 30 fps a position tween makes text jitter; opacity-only.
    - Source: https://www.nngroup.com/articles/timing-100-ms/ (100 ms = feels instant; 150 ms is the practical floor for hover-triggered)

24. **Tooltip `ZIndex` = 100 (above all HUD elements). Maximum width: 200 px; wrap with `TextWrapped = true`.** Tooltip text font: `Builder Sans Regular` at `MinTextSize = 12` via `UITextSizeConstraint` (Roblox warns values below 9 are unreadable).
    - Source: https://create.roblox.com/docs/reference/engine/classes/UITextSizeConstraint (MinTextSize ≥ 9)
    - Source: https://create.roblox.com/docs/reference/engine/classes/GuiObject (ZIndex controls render order; higher renders on top)

25. **Touch equivalent:** long-press for ≥ 500 ms triggers the tooltip (or a context menu). Never show a hover-tooltip on touch — touch has no hover state.
    - Source: https://create.roblox.com/docs/reference/engine/classes/TextLabel (TouchLongPress event)

---

## 8. Input affordances (mouse / touch / gamepad)

26. **Hover state (mouse):** lighten background by 10% (`BackgroundColor3` tint) + 0.1 s scale-up to 1.05× via `UIScale` or `Size` tween. No click-through to 3D world.
    - Source: ~/.config/kilo/skills/roblox-ui-design/SKILL.md (principle: "State: active, available, locked, completed, selected, and disabled states need more than color")

27. **Touch state:** use `AutoButtonColor = true` on `TextButton` (gives a press tint). Disable it and manually tween if you need a scale-down effect. Never rely on right-click context menus — they don't exist on touch.
    - Source: https://create.roblox.com/docs/reference/engine/classes/GuiButton (AutoButtonColor)

28. **Gamepad focus:** every button must have `SelectionImageObject` set (the default Roblox selection box) and `NextSelectionUp/Down/Left/Right` wired so the focus ring can navigate by D-pad. Visible focus ring is mandatory — no focus = gamepad users are stuck.
    - Source: https://create.roblox.com/docs/input/gamepad (directional navigation, SelectionImageObject)

29. **Child-friendly clarity:** every interactive element must have a visible text label. Icon-only buttons fail for 9–13 yo literacy levels. If you must use an icon, label it on hover/long-press.
    - Source: https://create.roblox.com/docs/production/game-design/ui-ux-design (demographics: younger players favor mobile UX, label clarity)

---

## 9. ScreenGui lifecycle (from roblox-gui SKILL)

30. **`ResetOnSpawn = false`** on the lobby `ScreenGui` — the lobby survives respawns while the player re-orients. Only re-create the GUI for hard transitions (main menu → lobby).
    - Source: ~/.config/kilo/skills/roblox-gui/SKILL.md (line 25, 157: "ResetOnSpawn = false")

31. **`ZIndexBehavior = Enum.ZIndexBehavior.Sibling`** — lets sibling UI elements layer predictably without fighting the engine's global Z-index bucket.
    - Source: ~/.config/kilo/skills/roblox-gui/SKILL.md (line 26)

32. **Read `AbsoluteSize` inside `task.defer` or `RenderStepped:Wait()`,** never on first frame — it's zero at creation and causes a one-frame layout pop on low-end devices.
    - Source: ~/.config/kilo/skills/roblox-gui/SKILL.md (line 188: "AbsoluteSize is zero on first frame")

---

## Anti-patterns (known offenders to reject)

| # | Anti-pattern | Rule violated | Correct approach |
|---|---|---|---|
| 1 | **Full-width text buttons** (`Size = UDim2.new(1, 0, 0, 50)`, no max-width constraint) | #16, #19 | Use `fromScale` + `UISizeConstraint.MaxSize` |
| 2 | **Opaque fullscreen background hiding the 3D world** (`BackgroundTransparency = 0` on a `UDim2.fromScale(1,1)` frame, hiding all world content) | #20, design principle | Use `BackgroundTransparency = 0.3–0.5` or a 9-slice border; let LobbyHub show through |
| 3 | **Mock data chips** (fake player count / "24 online" hardcoded in the HUD) | honesty | Bind labels to live `ReplicatedStorage` state; if data isn't ready, show skeleton loaders, not fake numbers |
| 4 | **Missing labels** (icon-only Ready button, unlabeled settings gear) | #29 | Every icon has visible text; on touch, long-press reveals a tooltip with the label |
| 5 | **`Font = Enum.Font.Gotham` / `GothamBold`** | #1 | `FontFace = Font.fromName("BuilderSans", Enum.FontWeight.ExtraBold)` |
| 6 | **Fixed `TextSize = 10` with no constraint** | #4, #5 | `TextScaled = true` + `UITextSizeConstraint(MinTextSize = 14, MaxTextSize = 32)` |
| 7 | **Touch targets < 44 px** (icon-only chat button at 32×32) | #8 | Place 24×24 icon inside a 44×44 tappable container |
| 8 | **No gamepad `SelectionImageObject`** | #28 | Set `SelectionImageObject` + `NextSelectionUp/Down/Left/Right` on every button |
| 9 | **Tooltip delay ≤ 50 ms** (flickers on accidental hover) | #23 | 150 ms minimum; 200 ms is safe for kids |
| 10 | **Color-only state** (red button = disabled, no icon change) | #15 | Add a lock icon / grayed label alongside the color |
| 11 | **Manual Position/Size math in a `UIListLayout` parent** | #18, design "Flow" | Let `UIListLayout` own the Y-axis; use it or don't use it |
| 12 | **`ResetOnSpawn = true` on lobby HUD** | #30 | `ResetOnSpawn = false` — lobby must survive respawn |

---

## 10. One-pager for the UI agent (copy-paste checklist)

Before merging any lobby HUD change, verify:

1. [ ] `FontFace` uses `BuilderSans` (not `Gotham`)
2. [ ] Every `TextLabel`/`TextButton` has `TextScaled = true` + `UITextSizeConstraint` (min 14, max 32)
3. [ ] Every tappable element is ≥ 44×44 px
4. [ ] Text/background contrast ≥ 4.5:1 (check with a contrast tool)
5. [ ] Panel uses `UDim2.fromScale`, not fixed `Offset`
6. [ ] Panel has `UISizeConstraint.MaxSize` so it doesn't shrink on 4K
7. [ ] `ScreenGui.ResetOnSpawn = false`, `ZIndexBehavior = Sibling`
8. [ ] No opaque fullscreen overlay hiding the 3D lobby
9. [ ] Every icon has a text label (or long-press tooltip on touch)
10. [ ] Gamepad: `SelectionImageObject` + directional nav wired
11. [ ] Hover tooltip: 150 ms delay, 0.1 s fade
12. [ ] `PreferredTransparency` and `ReducedMotionEnabled` respected via `GuiService` signals
