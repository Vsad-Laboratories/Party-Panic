-- RoundRegistry: resolves round names to ModuleScripts in the rounds folder.
-- Adding a round = drop a ModuleScript (or directory with init.luau) in
-- src/server/rounds/. Rojo's init rule makes directories act as ModuleScripts,
-- so games are now expanded directory/module hierarchies (Operator rule).
-- No FSM or registry edit needed — just drop the folder/module.
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
