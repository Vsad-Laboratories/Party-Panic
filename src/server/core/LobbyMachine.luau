-- LobbyMachine: free-roam lobby FSM.
-- State = always Waiting. No countdown, no round dispatch, no scheduled advance.
-- Players join → placed via Placements → state published to clients.
-- Countdown/InRound/Results states are unreachable until the Operator confirms
-- a manual round-start trigger (PR contract note).
-- Publishes lobby state to clients via RemoteEvent (LobbyState.luau payload type).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Placements = require(game.ServerScriptService.Server.core.Placements)
local MonetizationService = require(game.ServerScriptService.Server.MonetizationService)

local LobbyMachine = {}
LobbyMachine.__index = LobbyMachine

function LobbyMachine.new()
	local self = setmetatable({}, LobbyMachine)
	self.state = "Waiting"
	self.players = {}
	self.currentRoundName = ""
	self.lastResult = nil
	self.stateEvent = nil
	self._connections = {}
	return self
end

function LobbyMachine:_bindPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(self.players, player)
		Placements.placePlayer(player)
	end
	table.insert(
		self._connections,
		Players.PlayerAdded:Connect(function(player)
			table.insert(self.players, player)
			print("[PartyPanic] player joined: " .. player.Name .. " (total: " .. #self.players .. ")")
			Placements.placePlayer(player)
			self:_publishState()
		end)
	)
	table.insert(
		self._connections,
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
	)
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
		-- Get coin count from session cache only (no DataStore calls in publish)
		local coinCount = MonetizationService.getCoins(player)

		table.insert(playerInfos, {
			userId = player.UserId,
			name = player.Name,
			coinCount = coinCount,
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
	if #self._connections > 0 then
		return
	end
	self:_createStateEvent()
	self:_bindPlayers()
	Placements.placeLobby(self.players)
	self:_publishState()
	print("[PartyPanic] lobby machine started — state: Waiting (free-roam)")
end

function LobbyMachine:stop()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}
	self.players = {}
	if self.stateEvent then
		self.stateEvent:Destroy()
		self.stateEvent = nil
	end
end

return LobbyMachine
