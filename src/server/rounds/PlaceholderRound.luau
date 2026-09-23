-- PlaceholderRound: stub round conforming to RoundContract (src/shared/RoundContract).
-- Resolves immediately. Replaced when Floor Fall lands in sprint 3.
local PlaceholderRound = {}

function PlaceholderRound.setup(context)
	print("[PartyPanic] placeholder setup — " .. #context.players .. " players")
end

function PlaceholderRound.play(context)
	local duration = context.config and context.config.duration or 0
	print("[PartyPanic] placeholder play — duration=" .. duration .. "s")
	return {
		winnerUserId = nil,
		scores = {},
	}
end

function PlaceholderRound.cleanup(context)
	print("[PartyPanic] placeholder cleanup — " .. #context.players .. " players")
end

return PlaceholderRound
