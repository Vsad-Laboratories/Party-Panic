-- LobbyMachine: free-roam lobby FSM.
-- State = always Waiting. No countdown, no round dispatch, no scheduled advance.
-- Players join → placed via Placements → state published to clients.
-- Countdown/InRound/Results states are unreachable until the Operator confirms
-- a manual round-start trigger (PR contract note).
-- Publishes lobby state to clients via RemoteEvent (LobbyState.luau payload type).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Placements = require(game.ServerScriptService.Server.core.Placements)

local LobbyMachine = {}
LobbyMachine.__index = LobbyMachine

function LobbyMachine.new()
	local self = setmetatable({}, LobbyMachine)
	self.state = "Waiting"
	self.players = {}
	self.currentRoundName = ""
	self.lastResult = nil
	self.stateEvent = nil
	return self
end

function LobbyMachine:_bindPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(self.players, player)
	end
	Players.PlayerAdded:Connect(function(player)
		table.insert(self.players, player)
		print("[PartyPanic] player joined: " .. player.Name .. " (total: " .. #self.players .. ")")
		Placements.placePlayer(player)
		self:_publishState()
	end)
	Players.PlayerRemoving:Connect(function(player)
		Placements.unhook(player)
		for i, p in ipairs(self.players) do
			if p == player then
				table.remove(self.players, i)
				break
			end
		end
		self:_publishState()
	end)
end

function LobbyMachine:_createStateEvent()
	self.stateEvent = ReplicatedStorage:FindFirstChild("LobbyStateEvent")
	if not self.stateEvent then
		self.stateEvent = Instance.new("RemoteEvent")
		self.stateEvent.Name = "LobbyStateEvent"
		self.stateEvent.Parent = ReplicatedStorage
	end
end

function LobbyMachine:_publishState()
	if not self.stateEvent then
		return
	end
	local playerInfos = {}
	for _, player in ipairs(self.players) do
		table.insert(playerInfos, {
			userId = player.UserId,
			name = player.Name,
		})
	end
	self.stateEvent:FireAllClients({
		state = self.state,
		countdown = 0,
		players = playerInfos,
		roundName = self.currentRoundName,
		lastResult = self.lastResult,
	})
end

function LobbyMachine:start()
	self:_bindPlayers()
	self:_createStateEvent()
	Placements.placeLobby(self.players)
	self:_publishState()
	print("[PartyPanic] lobby machine started — state: Waiting (free-roam)")
end

return LobbyMachine
