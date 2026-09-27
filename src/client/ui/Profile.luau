--!strict
-- Profile.luau — client-side snapshot of the player's monetization/profile state.
-- Populated from the SERVER LobbyStatePayload (owned passes + equipped cosmetics) and
-- read by the Shop/Locker screen and the lobby status row. The server is the source of
-- truth; this module only caches values for UI reads (no client-side ownership).
-- Skills: roblox-datastores (persisted profile shape), roblox-monetization.

local Profile: {
	ownedPasses: { number },
	equipped: {
		crown: string?,
		title: string?,
		trail: string?,
		auras: { string },
	},
} =
	{
		ownedPasses = {},
		equipped = {
			crown = nil,
			title = nil,
			trail = nil,
			auras = {},
		},
	}

function Profile.setOwnedPasses(passes: { number }): ()
	Profile.ownedPasses = passes
end

function Profile.isOwned(passId: number): boolean
	for _, id in Profile.ownedPasses do
		if id == passId then
			return true
		end
	end
	return false
end

function Profile.setEquipped(equipped: { crown: string?, title: string?, trail: string?, auras: { string } }): ()
	Profile.equipped = equipped
end

function Profile.getEquipped(): {
	crown: string?,
	title: string?,
	trail: string?,
	auras: { string },
}
	return Profile.equipped
end

-- Equipped list for the lobby status row / effect list (crown|title|trail|auras).
-- Returns { "Crown: <name>", "Title: <name>", "Trail: <name>", "Aura: <name>", ... }.
-- Empty when nothing is equipped (the list then stays hidden — never mocked).
function Profile.getEquippedTags(): { string }
	local equipped = Profile.equipped
	local tags: { string } = {}
	if equipped.crown then
		table.insert(tags, "Crown: " .. equipped.crown)
	end
	if equipped.title then
		table.insert(tags, "Title: " .. equipped.title)
	end
	if equipped.trail then
		table.insert(tags, "Trail: " .. equipped.trail)
	end
	if equipped.auras then
		for _, aura in equipped.auras do
			table.insert(tags, "Aura: " .. aura)
		end
	end
	return tags
end

return Profile
