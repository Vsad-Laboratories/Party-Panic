-- MockState: mock local state for lobby UI playtesting — no server wiring.
-- Simulates countdown timer, player list, coins, and winner state.

local RunService = game:GetService("RunService")

local MockState = {}
MockState.__index = MockState

function MockState.new()
	local self = setmetatable({}, MockState)

	self.players = {
		{ name = "You", isWinner = true },
		{ name = "Alex_R", isWinner = false },
		{ name = "Sam_K", isWinner = false },
	}
	self.countdown = 10
	self.coins = 245
	self.onUpdate = Instance.new("BindableEvent")

	self._tickConn = nil
	self._running = false

	return self
end

function MockState:startCountdown()
	if self._running then
		return
	end
	self._running = true

	self._tickConn = RunService.Heartbeat:Connect(function(dt)
		self.countdown = self.countdown - dt
		if self.countdown <= 0 then
			self.countdown = 0
		end
		self.onUpdate:Fire()
	end)
end

function MockState:stopCountdown()
	if self._tickConn then
		self._tickConn:Disconnect()
		self._tickConn = nil
	end
	self._running = false
end

function MockState:addCoin(amount: number)
	self.coins = self.coins + amount
	self.onUpdate:Fire()
end

function MockState:destroy()
	self:stopCountdown()
	if self.onUpdate then
		self.onUpdate:Destroy()
	end
end

return MockState
