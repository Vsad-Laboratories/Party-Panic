-- Smoke bootstrap: proves rojo -> Studio sync end-to-end.
-- Wires up the lobby state machine frame (sprint 1).
print("[PartyPanic] server booted")

local LobbyMachine = require(game.ServerScriptService.Server.core.LobbyMachine)
local PlaytimeService = require(game.ServerScriptService.Server.core.PlaytimeService)

local machine = LobbyMachine.new()
machine:start()

local LobbyHub = require(game.ServerScriptService.Server.maps.LobbyHub)
LobbyHub.init()

PlaytimeService.start()

-- Flush all player playtime on server shutdown (roblox-datastores: BindToClose)
game:BindToClose(function()
	PlaytimeService.shutdown()
end)
