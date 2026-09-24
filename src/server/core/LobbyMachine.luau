-- LobbyMachine: lobby -> countdown -> round dispatch -> results -> repeat.
-- One state = one function; transitions explicit. Ticks via Heartbeat (1s resolution).
-- Keeps the smoke boot working: boot never blocks, state sits in Waiting until players join.
-- Publishes lobby state to clients via RemoteEvent (LobbyState.luau payload type).
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(game.ReplicatedStorage.Shared.Constants)
local RoundRegistry = require(game.ServerScriptService.Server.core.RoundRegistry)
local Placements = require(game.ServerScriptService.Server.core.Placements)

local LobbyMachine = {}
LobbyMachine.__index = LobbyMachine

function LobbyMachine.new()
	local self = setmetatable({}, LobbyMachine)
	self.state = "Waiting"
	self.players = {}
	self.currentRoundName = Constants.RoundRotation[1]
	self.currentRound = nil
	self.currentContext = nil
	self.rotationIndex = 1
	self.countdown = 0
	self.tickAccumulator = 0
	self.lastResult = nil
	self.stateEvent = nil
	return self
end

function LobbyMachine:_wait()
	if #self.players >= Constants.MinPlayers then
		self.countdown = Constants.CountdownSeconds
		self.state = "Countdown"
		print("[PartyPanic] countdown started (" .. self.countdown .. "s)")
		self:_publishState()
	else
		Placements.placeLobby(self.players)
	end
end

function LobbyMachine:_countdown()
	if self.countdown > 0 then
		self.countdown -= 1
		print("[PartyPanic] starting in " .. self.countdown .. "s")
		self:_publishState()
	else
		self:_startRound()
	end
end

function LobbyMachine:_startRound()
	self.rotationIndex = (self.rotationIndex % #Constants.RoundRotation) + 1
	self.currentRoundName = Constants.RoundRotation[self.rotationIndex]
	local round = RoundRegistry.getRound(self.currentRoundName)
	if not round then
		print("[PartyPanic] round not found: " .. self.currentRoundName .. " — skipping to results")
		self.state = "Results"
		self:_publishState()
		return
	end
	self.state = "InRound"
	self.currentRound = round
	local context = {
		players = self.players,
		config = { duration = Constants.RoundDuration },
		onRoundComplete = function(result)
			self.lastResult = result
			if self.currentRound and self.currentContext then
				self.currentRound.cleanup(self.currentContext)
				self.currentRound = nil
				self.currentContext = nil
			end
			self.state = "Results"
			print("[PartyPanic] round complete")
			self:_publishState()
		end,
	}
	self.currentContext = context
	self:_publishState()
	round.setup(context)
	round.play(context)
end

function LobbyMachine:_results()
	local winner = self.lastResult and self.lastResult.winnerUserId
	print("[PartyPanic] results shown — winner: " .. tostring(winner))
	self.lastResult = nil
	self.state = "Waiting"
	Placements.placeLobby(self.players)
	print("[PartyPanic] back to lobby (waiting for players)")
	self:_publishState()
end

function LobbyMachine:_tick(dt)
	self.tickAccumulator += dt
	if self.tickAccumulator < 1 then
		return
	end
	self.tickAccumulator -= 1

	if self.state == "Waiting" then
		self:_wait()
	elseif self.state == "Countdown" then
		self:_countdown()
	elseif self.state == "Results" then
		self:_results()
	end
	-- InRound: round manages gameplay via its own Heartbeat; FSM idle until onRoundComplete.
end

function LobbyMachine:_bindPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(self.players, player)
	end
	Players.PlayerAdded:Connect(function(player)
		table.insert(self.players, player)
		print("[PartyPanic] player joined: " .. player.Name .. " (total: " .. #self.players .. ")")
		if self.state == "Waiting" or self.state == "Results" then
			Placements.placePlayer(player)
		end
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
		countdown = self.countdown,
		players = playerInfos,
		roundName = self.currentRoundName,
		lastResult = self.lastResult,
	})
end

function LobbyMachine:start()
	self:_bindPlayers()
	self:_createStateEvent()
	RunService.Heartbeat:Connect(function(dt)
		self:_tick(dt)
	end)
	Placements.placeLobby(self.players)
	self:_publishState()
	print("[PartyPanic] lobby machine started — state: Waiting")
end

return LobbyMachine
