-- Placements: server-side player placement for lobby states.
-- [OPERATOR DIRECTIVE: spawn-stay] No player movement on join.
-- Spawning is handled solely by the SpawnLocation in LobbyHub.
-- This module is kept as a structural no-op — all repositioning removed.
-- Future placement logic may restore hook/unhook scaffolding here.

local Placements = {}
Placements._characterAddedConn = {}

function Placements.placePlayer(_player)
	return
end

function Placements.placeLobby(_players)
	return
end

function Placements.unhook(player)
	if Placements._characterAddedConn[player] then
		Placements._characterAddedConn[player]:Disconnect()
		Placements._characterAddedConn[player] = nil
	end
end

return Placements
