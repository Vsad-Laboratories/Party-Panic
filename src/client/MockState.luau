-- MockState: mock local state for lobby UI playtesting — no server wiring.
-- Simulates countdown timer, player list, and coins.

local RunService = game:GetService("RunService")

local MockState = {}
MockState.__index = MockState

function MockState.new()
	local self = setmetatable({}, MockState)

	self.players = {
		{ name = "You" },
		{ name = "Alex_R" },
		{ name = "Sam_K" },
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
		local previousCountdown = self.countdown
		self.countdown = math.max(0, self.countdown - dt)

		if self.countdown ~= previousCountdown then
			self.onUpdate:Fire()
		end

		if self.countdown == 0 then
			self._tickConn:Disconnect()
			self._tickConn = nil
			self._running = false
		end
	end)
end

return MockState
