--!strict
-- sounds.luau — central pop-sound helper for UI buttons (charter law: one module owns
-- all UI feedback sounds in SoundService). Every lobby button is wired through here
-- via the button factory, so no button can miss its feedback (Finding 5).
--   hover (PC MouseEnter) -> keyboard click,      127105730240202
--   press  (Activated, all devices) -> pop click, 138567614125924
-- Volume raised from a modest ~0.3 to ~0.45 so pop feedback is noticed during
-- live playtests (Operator: "hover and click pop sounds too quiet"), while keeping
-- the soft pop character and the registered asset IDs (docs/ASSETS.md) unchanged.

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local HOVER_ASSET = "rbxassetid://127105730240202"
local CLICK_ASSET = "rbxassetid://138567614125924"
local VOLUME = 0.45

local function play(asset: string, name: string): ()
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = asset
	sound.Volume = VOLUME
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 5)
end

local module = {
	playHover = function(): ()
		play(HOVER_ASSET, "UIHover")
	end,
	playClick = function(): ()
		play(CLICK_ASSET, "UIClick")
	end,
}

return module
