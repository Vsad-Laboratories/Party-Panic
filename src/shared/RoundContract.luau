-- Round contract: the fixed lifecycle interface every round module implements.
-- The lobby state machine calls setup -> play -> cleanup in order.
-- play() starts the round (may be async); completion is signaled via
-- context.onRoundComplete(result). Rounds never touch each other —
-- this keeps AI-generated rounds safe to merge.
-- Future rounds require this module and annotate against its types.

export type RoundConfig = {
	duration: number?,
}

export type RoundContext = {
	players: { Player },
	config: RoundConfig,
	onRoundComplete: (result: RoundResult) -> (),
}

export type RoundResult = {
	winnerUserId: number?,
	scores: { [number]: number }?,
}

export type RoundModule = {
	setup: (context: RoundContext) -> (),
	play: (context: RoundContext) -> (),
	cleanup: (context: RoundContext) -> (),
}

return {}
