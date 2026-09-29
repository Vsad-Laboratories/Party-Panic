-- Smoke bootstrap: proves rojo -> Studio sync end-to-end.
-- Wires up the lobby state machine frame (sprint 1).
print("[PartyPanic] server booted")

-- DIAG: TEMPORARY boot diagnostics — revert after root cause. Every probe line is marker-commented "DIAG:".
-- DIAG: probe is built BEFORE any require, so even a require-time crash leaves it standing.
-- DIAG: player sees BootProbe -> replication is fine, failure sits in map init; player sees nothing
-- DIAG: -> the client received zero server parts.
local BootProbe = Instance.new("Part") -- DIAG:
BootProbe.Name = "BootProbe" -- DIAG:
BootProbe.Size = Vector3.new(10, 2, 10) -- DIAG:
BootProbe.CFrame = CFrame.new(0, 20, 0) -- DIAG:
BootProbe.Anchored = true -- DIAG:
BootProbe.CastShadow = true -- DIAG:
BootProbe.Material = Enum.Material.Neon -- DIAG:
BootProbe.Color = Color3.fromRGB(255, 0, 0) -- DIAG:
BootProbe.Parent = workspace -- DIAG:
-- DIAG: breadcrumb 1 + phase marker — probe replicated to Workspace
warn("[DIAG] phase: probe created (BootProbe @ 0,20,0)")
-- DIAG: phase marker — shown on the fallback error panel if init dies later
local diagPhase = "probe created" -- DIAG:

local LobbyMachine = require(game.ServerScriptService.Server.core.LobbyMachine)
local PlaytimeService = require(game.ServerScriptService.Server.core.PlaytimeService)
local MonetizationService = require(game.ServerScriptService.Server.MonetizationService)
-- DIAG: breadcrumb 2 + phase marker — all top-level requires done
warn("[DIAG] phase: requires done")
diagPhase = "requires done" -- DIAG:

local machine = LobbyMachine.new()
machine:start()
-- DIAG: breadcrumb 3 + phase marker — state machine started
warn("[DIAG] phase: machine:start done")
diagPhase = "machine:start done" -- DIAG:

-- DIAG: TEMPORARY fallback deck: player lands here and reads the exact init error instead of falling forever.
local function buildFallback(err, phase, trace) -- DIAG:
	-- DIAG: green landing platform (top y=2)
	local platform = Instance.new("Part") -- DIAG:
	platform.Name = "BootFallbackPlatform" -- DIAG:
	platform.Size = Vector3.new(40, 2, 40) -- DIAG:
	platform.CFrame = CFrame.new(0, 1, 0) -- DIAG:
	platform.Anchored = true -- DIAG:
	platform.CastShadow = true -- DIAG:
	platform.Material = Enum.Material.SmoothPlastic -- DIAG:
	platform.Color = Color3.fromRGB(0, 255, 0) -- DIAG:
	platform.Parent = workspace -- DIAG:

	-- DIAG: neutral spawn so the player lands on the deck, not in the void
	local fallbackSpawn = Instance.new("SpawnLocation") -- DIAG:
	fallbackSpawn.Name = "BootFallbackSpawn" -- DIAG:
	fallbackSpawn.Size = Vector3.new(8, 1, 8) -- DIAG:
	fallbackSpawn.CFrame = CFrame.new(0, 4, 0) -- DIAG:
	fallbackSpawn.Anchored = true -- DIAG:
	fallbackSpawn.CastShadow = true -- DIAG:
	fallbackSpawn.Neutral = true -- DIAG:
	fallbackSpawn.Material = Enum.Material.Neon -- DIAG:
	fallbackSpawn.Color = Color3.fromRGB(0, 255, 0) -- DIAG:
	fallbackSpawn.Parent = workspace -- DIAG:

	-- DIAG: error panel directly over the spawn; non-collidable so it never blocks the player
	local panel = Instance.new("Part") -- DIAG:
	panel.Name = "BootFallbackError" -- DIAG:
	panel.Size = Vector3.new(32, 12, 1) -- DIAG:
	panel.CFrame = CFrame.new(0, 8, 0) -- DIAG:
	panel.Anchored = true -- DIAG:
	panel.CastShadow = true -- DIAG:
	panel.CanCollide = false -- DIAG:
	panel.Material = Enum.Material.SmoothPlastic -- DIAG:
	panel.Color = Color3.fromRGB(255, 255, 255) -- DIAG:
	panel.Parent = workspace -- DIAG:

	-- DIAG: AlwaysOnTop so the text renders through geometry; Front faces the approach from -Z
	local gui = Instance.new("SurfaceGui") -- DIAG:
	gui.Name = "BootFallbackErrorGui" -- DIAG:
	gui.AlwaysOnTop = true -- DIAG:
	gui.Face = Enum.NormalId.Front -- DIAG:
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud -- DIAG:
	gui.PixelsPerStud = 40 -- DIAG:
	gui.Parent = panel -- DIAG:

	local label = Instance.new("TextLabel") -- DIAG:
	label.Name = "ErrorText" -- DIAG:
	label.Size = UDim2.fromScale(1, 1) -- DIAG:
	label.BackgroundTransparency = 1 -- DIAG:
	label.Font = Enum.Font.Code -- DIAG:
	label.TextColor3 = Color3.fromRGB(180, 0, 0) -- DIAG:
	label.TextScaled = true -- DIAG:
	label.TextWrapped = true -- DIAG:
	label.Text = "DIAG BOOT FAILED\nphase: " .. phase .. "\n" .. tostring(err) .. "\n\n" .. trace
	label.Parent = gui -- DIAG:
end -- DIAG:

-- DIAG: pcall trap around require(LobbyHub) + LobbyHub.init(): a hard error here would otherwise
-- DIAG: kill the script silently and leave players falling with no evidence.
local LobbyHub -- DIAG:
local initOk, initErr = pcall(function() -- DIAG:
	LobbyHub = require(game.ServerScriptService.Server.maps.LobbyHub) -- DIAG:
	-- DIAG: breadcrumb 4 — module required, init about to run
	warn("[DIAG] phase: LobbyHub required")
	diagPhase = "LobbyHub required" -- DIAG:
	LobbyHub.init() -- DIAG:
end) -- DIAG:

if initOk then -- DIAG:
	-- DIAG: breadcrumb 5 + success beacon: init ran but the map is still missing -> replication/visibility problem
	warn("[DIAG] phase: init finished")
	diagPhase = "init finished" -- DIAG:
	local BootOK = Instance.new("Part") -- DIAG:
	BootOK.Name = "BootOK" -- DIAG:
	BootOK.Size = Vector3.new(5, 1, 5) -- DIAG:
	BootOK.CFrame = CFrame.new(0, 25, 0) -- DIAG:
	BootOK.Anchored = true -- DIAG:
	BootOK.CastShadow = true -- DIAG:
	BootOK.Material = Enum.Material.Neon -- DIAG:
	BootOK.Color = Color3.fromRGB(0, 255, 0) -- DIAG:
	BootOK.Parent = workspace -- DIAG:
	-- DIAG: label on the underside — the face a player on the ground sees when looking up
	local okGui = Instance.new("SurfaceGui") -- DIAG:
	okGui.Name = "BootOKGui" -- DIAG:
	okGui.AlwaysOnTop = true -- DIAG:
	okGui.Face = Enum.NormalId.Bottom -- DIAG:
	okGui.Parent = BootOK -- DIAG:
	local okLabel = Instance.new("TextLabel") -- DIAG:
	okLabel.Name = "BootOKText" -- DIAG:
	okLabel.Size = UDim2.fromScale(1, 1) -- DIAG:
	okLabel.BackgroundTransparency = 1 -- DIAG:
	okLabel.TextColor3 = Color3.fromRGB(0, 0, 0) -- DIAG:
	okLabel.TextScaled = true -- DIAG:
	okLabel.Text = "BOOT OK - init completed" -- DIAG:
	okLabel.Parent = okGui -- DIAG:
else -- DIAG:
	-- DIAG: surface the failure to the player: short trace fits the 32x12 panel
	local diagTrace = string.sub(debug.traceback(), 1, 600) -- DIAG:
	warn("[DIAG] LobbyHub init FAILED at phase '" .. diagPhase .. "': " .. tostring(initErr))
	buildFallback(initErr, diagPhase, diagTrace) -- DIAG:
end -- DIAG:

PlaytimeService.start()
MonetizationService.init()

-- Flush all player playtime + clean up lobby on server shutdown
game:BindToClose(function()
	machine:stop()
	-- DIAG: guard — LobbyHub stays nil when the require trap fired, so cleanup is skipped
	if LobbyHub then -- DIAG:
		LobbyHub.cleanup()
	end -- DIAG:
	PlaytimeService.shutdown()
	MonetizationService.shutdown()
end)
