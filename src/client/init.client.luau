-- Client bootstrap: builds the lobby UI and binds it to the session-scoped
-- LobbyStateEvent that LobbyMachine publishes (src/server/LobbyMachine.luau).
-- The event is created server-side at runtime; wait for it, then push every
-- payload to LobbyUI so it re-renders. Vote and coin surfaces stay shells.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyUI = require(script.ui.LobbyUI)

local lobbyUI = LobbyUI.new()

local lobbyStateEvent = ReplicatedStorage:WaitForChild("LobbyStateEvent")
lobbyStateEvent.OnClientEvent:Connect(function(payload)
	lobbyUI:update(payload)
end)
