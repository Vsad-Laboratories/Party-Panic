-- Smoke bootstrap: proves client-side rojo -> Studio sync.
-- Bootstraps lobby UI against mock local state (no server wiring yet).

local LobbyUI = require(script.LobbyUI)
local MockState = require(script.MockState)

local mockState = MockState.new()
mockState:startCountdown()

LobbyUI.new(mockState)
