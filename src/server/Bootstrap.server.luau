-- Smoke bootstrap: proves rojo -> Studio sync end-to-end.
-- Wires up the lobby state machine frame (sprint 1).
print("[PartyPanic] server booted")

local LobbyMachine = require(game.ServerScriptService.Server.core.LobbyMachine)
local PlaytimeService = require(game.ServerScriptService.Server.core.PlaytimeService)
local MonetizationService = require(game.ServerScriptService.Server.MonetizationService)

local machine = LobbyMachine.new()
machine:start()

local LobbyHub = require(game.ServerScriptService.Server.maps.LobbyHub)
LobbyHub.init()

PlaytimeService.start()
MonetizationService.init()

-- Flush all player playtime + clean up lobby on server shutdown
game:BindToClose(function()
	machine:stop()
	LobbyHub.cleanup()
	PlaytimeService.shutdown()
	MonetizationService.shutdown()
end)
