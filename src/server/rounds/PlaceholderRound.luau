--!strict
-- PlaceholderRound: stub round conforming to RoundContract (src/shared/RoundContract).
-- Resolves immediately via onRoundComplete. Replaced when Floor Fall lands.
local RoundContract = require(game.ReplicatedStorage.Shared.RoundContract)

local PlaceholderRound = {}

function PlaceholderRound.setup(context: RoundContract.RoundContext)
	print("[PartyPanic] placeholder setup — " .. #context.players .. " players")
end

function PlaceholderRound.play(context: RoundContract.RoundContext)
	local duration = context.config and context.config.duration or 0
	print("[PartyPanic] placeholder play — duration=" .. duration .. "s")
	context.onRoundComplete({
		winnerUserId = nil,
		scores = {},
	})
end

function PlaceholderRound.cleanup(context: RoundContract.RoundContext)
	print("[PartyPanic] placeholder cleanup — " .. #context.players .. " players")
end

return PlaceholderRound
