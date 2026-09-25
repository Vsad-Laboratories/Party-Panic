-- Placements: server-side player placement for lobby states.
-- Distributes players round-robin across LobbyHub spawnPoints with honest
-- height-offset math so characters stand on (not fall through) the lobby disc.

local LobbyHubConfig = require(game.ServerScriptService.Server.maps.LobbyHub.config)

-- Defensive: spawnPoints nil OR empty → fall back to lobbySpawn.Position as
-- the single anchor (makes lobbySpawn a real reader). Prevents #nil throws in
-- _nextSlot/computeTargetPos and avoids _slot % 0 NaN on empty tables.
local spawnPoints = LobbyHubConfig.spawnPoints or {}
local lobbySpawn = LobbyHubConfig.lobbySpawn
local fallbackPoint
if #spawnPoints == 0 and lobbySpawn ~= nil then
	fallbackPoint = Vector3.new(lobbySpawn.Position.X, lobbySpawn.Position.Y, lobbySpawn.Position.Z)
end

local Placements = {}
Placements._slot = 0
Placements._characterAddedConn = {}

function Placements:_nextSlot()
	if #spawnPoints == 0 then
		return fallbackPoint
	end
	Placements._slot = (Placements._slot % #spawnPoints) + 1
	return spawnPoints[Placements._slot]
end

-- Height math: spawnPoints sit at y=1.5, disc top at y=1 (disc y=0, thickness 2).
-- HRP is ~half the character's vertical extent above feet. Without the offset,
-- placing HRP at spawnPoint.y=1.5 puts feet at ~-0.5 (below disc) → free-fall.
-- Fix: target HRP.y = spawnPoint.y + (charHeight / 2) so feet land at ~y=1.5
-- (0.5 studs above disc top — character rests on disc).
-- Guard: halfHeight covers GetExtentsSize anomalies (<0.5 or >10 → fallback 2.5)
local function computeTargetPos(spawnPoint, character)
	local charSize = character:GetExtentsSize()
	local halfHeight = charSize.Y / 2
	if halfHeight < 0.5 or halfHeight > 10 then
		halfHeight = 2.5
	end
	return Vector3.new(spawnPoint.X, spawnPoint.Y + halfHeight, spawnPoint.Z)
end

function Placements.placePlayer(player)
	if not player or player.Parent == nil then
		return
	end
	local character = player.Character
	if not character then
		if Placements._characterAddedConn[player] == nil then
			Placements._characterAddedConn[player] = player.CharacterAdded:Connect(function()
				Placements.placePlayer(player)
			end)
		end
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local spawnPoint = Placements:_nextSlot()
	local targetPos = computeTargetPos(spawnPoint, character)

	hrp.CFrame = CFrame.new(targetPos)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end

function Placements.placeLobby(players)
	for _, player in ipairs(players) do
		Placements.placePlayer(player)
	end
end

function Placements.unhook(player)
	if Placements._characterAddedConn[player] then
		Placements._characterAddedConn[player]:Disconnect()
		Placements._characterAddedConn[player] = nil
	end
end

return Placements
