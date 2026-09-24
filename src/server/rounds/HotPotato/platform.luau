-- HotPotato platform subsystem: spawnable standing surface under the potato ring.
local Workspace = game:GetService("Workspace")

local config = require(script.Parent.config)

local platform = {
	part = nil,
}

function platform.create()
	platform.part = Instance.new("Part")
	platform.part.Size = config.platformSize
	platform.part.CFrame = CFrame.new(0, config.platformY, 0)
	platform.part.BrickColor = config.platformColor
	platform.part.Anchored = true
	platform.part.CanCollide = true
	platform.part.Name = "HotPotatoPlatform"
	platform.part.Parent = Workspace
end

function platform.destroy()
	if platform.part and platform.part.Parent then
		platform.part:Destroy()
	end
	platform.part = nil
end

return platform
