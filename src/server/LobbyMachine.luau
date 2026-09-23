-- LobbyMachine: lobby -> countdown -> round dispatch -> results -> repeat.
-- One state = one function; transitions explicit. Ticks via Heartbeat (1s resolution).
-- Keeps the smoke boot working: boot never blocks, state sits in Waiting until players join.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Constants = require(game.ReplicatedStorage.Shared.Constants)
local RoundRegistry = require(game.ServerScriptService.Server.RoundRegistry)

local LobbyMachine = {}
LobbyMachine.__index = LobbyMachine

function LobbyMachine.new()
	local self = setmetatable({}, LobbyMachine)
	self.state = "Waiting"
	self.players = {}
	self.countdown = 0
	self.tickAccumulator = 0
	self.lastResult = nil
	self.currentRoundName = Constants.DefaultRound
	return self
end

function LobbyMachine:_wait()
	if #self.players >= Constants.MinPlayers then
		self.countdown = Constants.CountdownSeconds
		self.state = "Countdown"
		print("[PartyPanic] countdown started (" .. self.countdown .. "s)")
	end
end

function LobbyMachine:_countdown()
	if self.countdown > 0 then
		self.countdown -= 1
		print("[PartyPanic] starting in " .. self.countdown .. "s")
	else
		self:_startRound()
	end
end

function LobbyMachine:_startRound()
	local round = RoundRegistry.getRound(self.currentRoundName)
	if not round then
		print("[PartyPanic] round not found: " .. self.currentRoundName .. " — skipping to results")
		self.state = "Results"
		return
	end
	self.state = "InRound"
	-- Placeholder resolves synchronously; real rounds keep this state until completion (sprint 3+).
	local context = {
		players = self.players,
		config = { duration = Constants.RoundDuration },
	}
	round.setup(context)
	self.lastResult = round.play(context)
	round.cleanup(context)
	self.state = "Results"
	print("[PartyPanic] round complete")
end

function LobbyMachine:_results()
	local winner = self.lastResult and self.lastResult.winnerUserId
	print("[PartyPanic] results shown — winner: " .. tostring(winner))
	self.lastResult = nil
	self.state = "Waiting"
	print("[PartyPanic] back to lobby (waiting for players)")
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
end

function LobbyMachine:_bindPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(self.players, player)
	end
	Players.PlayerAdded:Connect(function(player)
		table.insert(self.players, player)
		print("[PartyPanic] player joined: " .. player.Name .. " (total: " .. #self.players .. ")")
	end)
	Players.PlayerRemoving:Connect(function(player)
		for i, p in ipairs(self.players) do
			if p == player then
				table.remove(self.players, i)
				break
			end
		end
	end)
end

function LobbyMachine:start()
	self:_bindPlayers()
	RunService.Heartbeat:Connect(function(dt)
		self:_tick(dt)
	end)
	print("[PartyPanic] lobby machine started — state: Waiting")
end

return LobbyMachine
