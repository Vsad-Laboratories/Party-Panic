-- RoundRegistry: resolves round names to ModuleScripts in the rounds folder.
-- Adding a round = drop a ModuleScript in src/server/rounds/. No FSM or registry edit.
local RoundsFolder = game.ServerScriptService.Server:WaitForChild("rounds")

local RoundRegistry = {}

function RoundRegistry.getRound(name: string)
	local module = RoundsFolder:FindFirstChild(name)
	if not module then
		warn("[PartyPanic] round module not found: " .. name)
		return nil
	end
	return require(module)
end

return RoundRegistry
