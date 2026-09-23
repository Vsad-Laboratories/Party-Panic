-- Round contract: the fixed lifecycle interface every round module implements.
-- The lobby state machine calls setup -> play -> cleanup in order.
-- Rounds never touch each other — this keeps AI-generated rounds safe to merge.
-- Future rounds require this module and annotate against its types.

export type RoundConfig = {
	duration: number?,
}

export type RoundContext = {
	players: { Player },
	config: RoundConfig,
}

export type RoundResult = {
	winnerUserId: number?,
	scores: { [number]: number }?,
}

export type RoundModule = {
	setup: (context: RoundContext) -> (),
	play: (context: RoundContext) -> RoundResult?,
	cleanup: (context: RoundContext) -> (),
}

return {}
