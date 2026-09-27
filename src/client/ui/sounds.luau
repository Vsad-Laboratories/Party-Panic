--!strict
-- sounds.luau — central pop-sound helper for UI buttons (charter law: one module owns
-- all UI feedback sounds in SoundService). Every lobby button is wired through here
-- via the button factory, so no button can miss its feedback (Finding 5).
--   hover (PC MouseEnter) -> keyboard click,      127105730240202
--   press  (Activated, all devices) -> pop click, 138567614125924
-- Volume is a modest ~0.3 so clicks never startle the 9-13 audience. These IDs are
-- registered in docs/ASSETS.md (audio table) — this file only wires them, ASSETS.md
-- is not edited here.

local SoundService = game:GetService("SoundService")

local HOVER_ASSET = "rbxassetid://127105730240202"
local CLICK_ASSET = "rbxassetid://138567614125924"
local VOLUME = 0.3

local function newSound(name: string, asset: string): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = asset
	sound.Volume = VOLUME
	sound.Parent = SoundService
	return sound
end

local hover = newSound("UIHover", HOVER_ASSET)
local click = newSound("UIClick", CLICK_ASSET)

local function play(sound: Sound): ()
	sound.TimePosition = 0
	sound:Play()
end

local module = {
	playHover = function(): ()
		play(hover)
	end,
	playClick = function(): ()
		play(click)
	end,
}

return module
