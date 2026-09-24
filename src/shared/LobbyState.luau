--!strict
-- LobbyState: typed payload for lobby state sync via RemoteEvent.
-- Published by LobbyMachine on every state transition + 1s countdown ticks.
-- Client code codes against this type (LBY-1).

local RoundContract = require(game.ReplicatedStorage.Shared.RoundContract)

export type PlayerInfo = {
	userId: number,
	name: string,
}

export type LobbyStatePayload = {
	state: string,
	countdown: number,
	players: { PlayerInfo },
	roundName: string,
	lastResult: RoundContract.RoundResult?,
}

return {}
