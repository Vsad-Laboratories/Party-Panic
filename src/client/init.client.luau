-- Smoke bootstrap: proves client-side rojo -> Studio sync.
-- Bootstraps lobby UI against mock local state (no server wiring yet).

local LobbyUI = require(script.LobbyUI)
local MockState = require(script.MockState)

local mockState = MockState.new()
mockState:startCountdown()

local lobbyUI = LobbyUI.new(mockState)

game:BindToClose(function()
	if lobbyUI then
		lobbyUI:destroy()
	end
	if mockState then
		mockState:destroy()
	end
end)
