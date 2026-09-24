-- HotPotato potato subsystem: holder rotation, pass/explosion mechanic.
local Workspace = game:GetService("Workspace")

local config = require(script.Parent.config)

local potato = {
	part = nil,
	holderUserId = nil,
	touchConn = nil,
}

function potato.create()
	potato.part = Instance.new("Part")
	potato.part.Size = config.potatoSize
	potato.part.CFrame = CFrame.new(0, config.potatoStartY, 0)
	potato.part.BrickColor = config.potatoColor
	potato.part.Anchored = true
	potato.part.CanCollide = false
	potato.part.Name = "HotPotato"
	potato.part.Parent = Workspace

	potato.holderUserId = nil
end

function potato.onTouch(handler)
	if potato.part then
		potato.touchConn = potato.part.Touched:Connect(handler)
	end
end

function potato.pass()
	potato.holderUserId = nil
end

function potato.setHolder(player)
	potato.holderUserId = player.UserId
	print("[PartyPanic] HotPotato: " .. player.Name .. " holding potato")
end

function potato.destroy()
	if potato.touchConn then
		potato.touchConn:Disconnect()
		potato.touchConn = nil
	end
	if potato.part and potato.part.Parent then
		potato.part:Destroy()
	end
	potato.part = nil
	potato.holderUserId = nil
end

return potato
