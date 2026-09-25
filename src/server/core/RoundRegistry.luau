-- RoundRegistry: round name resolution.
-- Minigame scaffolding deleted (Operator directive: free-roam lobby until maps
-- are rebuilt one by one). Registry is an empty no-op — no rounds/ folder exists.
-- When the Operator confirms rounds return, restore the FindFirstChild require path.
local RoundRegistry = {}

function RoundRegistry.getRound(_name: string)
	return nil
end

return RoundRegistry
