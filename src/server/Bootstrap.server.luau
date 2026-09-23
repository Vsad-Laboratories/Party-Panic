-- Smoke bootstrap: proves rojo -> Studio sync end-to-end.
-- Wires up the lobby state machine frame (sprint 1).
print("[PartyPanic] server booted")

local LobbyMachine = require(game.ServerScriptService.Server.LobbyMachine)

local machine = LobbyMachine.new()
machine:start()
