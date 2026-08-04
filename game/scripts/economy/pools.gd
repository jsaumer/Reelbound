## The three-pool economy (docs/02_GAME_DESIGN.md #2). GDScript port of
## sim/pools.py -- kept structurally identical so the two stay in sync.
## D3 (locked): bankroll never receives a payout. There is no method here
## that adds to bankroll or subtracts from winnings, so the invariant can't
## be violated by a caller.
class_name Pools
extends RefCounted

var bankroll: float
var winnings: float = 0.0
var pending: float = 0.0


func _init(starting_bankroll: float) -> void:
	bankroll = starting_bankroll


func spend_from_bankroll(amount: float) -> void:
	assert(amount >= 0.0, "cannot spend a negative amount")
	assert(amount <= bankroll + 1e-9, "cannot spend more than the bankroll holds")
	bankroll -= amount


func add_to_pending(amount: float) -> void:
	assert(amount >= 0.0, "cannot add a negative payout to pending")
	pending += amount


func commit_pending_to_winnings() -> void:
	winnings += pending
	pending = 0.0


func double_pending() -> void:
	## The win leg of a gamble-up (docs/02_GAME_DESIGN.md #4). Stays
	## entirely within pending -- bankroll is untouched either way.
	pending *= 2.0


func forfeit_pending() -> void:
	## The loss leg of a gamble-up. Baseline gamble-up losses vanish
	## rather than draining bankroll (that's the "Hedged Gamble" boon,
	## not the baseline -- docs/03_IDEA_BACKLOG.md).
	pending = 0.0
