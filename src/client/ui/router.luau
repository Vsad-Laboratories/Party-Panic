--!strict
-- router.luau — lobby button routing table.
-- Maps a lobby button name -> open-handler. Every entry is a no-op until its
-- matching screen is built in a follow-up task; buttons are still wired through
-- router.open (so they are not dead), and adding a screen is just filling the handler.
-- See docs/DESIGN.md "Lobby screen layout".

local router = {}

-- No-op handler used until the real screen exists; keeps every button resolvable.
local function noop(): () end

local routes: { [string]: () -> () } = {
	-- TODO(lobby-screens): build the Inventory screen
	Inventory = noop,
	-- TODO(lobby-screens): build the Shop screen
	Shop = noop,
	-- TODO(lobby-screens): build the Settings screen
	Settings = noop,
	-- TODO(lobby-screens): build the Party Pass screen
	PartyPass = noop,
	-- TODO(lobby-screens): build the Packs screen
	Packs = noop,
	-- TODO(lobby-screens): build the MiniGames screen
	MiniGames = noop,
	-- TODO(lobby-screens): build the Maps screen
	Maps = noop,
	-- TODO(lobby-screens): build the Stats screen
	Stats = noop,
}

-- Dispatch a lobby button press. No-ops silently until a real handler lands.
function router.open(name: string): ()
	local handler = routes[name]
	if handler then
		handler()
	end
end

return router
