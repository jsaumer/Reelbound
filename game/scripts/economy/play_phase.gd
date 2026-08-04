## The play-phase controller (docs/02_GAME_DESIGN.md #4, D6 locked):
##     bankroll -> bet -> spin -> payout -> winnings
## under the dual limiter: play stops the instant bankroll hits zero OR the
## spin cap is reached, whichever comes first. Win iff winnings >= quota.
##
## Unlike sim/play_phase.py's batch while-loop (which runs a whole play
## phase to completion for simulation), this is driven one spin at a time
## by the UI -- same rules, same outcome ordering (win checked before bust
## before out-of-spins), just paced by player input instead of a loop.
##
## Same Phase-1 simplification as the Python model: pending auto-commits to
## winnings every spin (bank-vs-press is a Phase 3 decision, not Phase 1).
class_name PlayPhase
extends RefCounted

enum Outcome { PLAYING, WIN, BUST, OUT_OF_SPINS }

var machine: ReelMachine
var pools: Pools
var paytable: Dictionary
var paylines: Array
var min_match: int
var quota: float
var spin_cap: int
var rng: RandomNumberGenerator

var spins_used: int = 0
var outcome: int = Outcome.PLAYING
var last_grid: Array = []
var last_payout: float = 0.0


func _init(p_machine: ReelMachine, p_pools: Pools, p_paytable: Dictionary,
		p_paylines: Array, p_min_match: int, p_quota: float, p_spin_cap: int,
		p_rng: RandomNumberGenerator) -> void:
	machine = p_machine
	pools = p_pools
	paytable = p_paytable
	paylines = p_paylines
	min_match = p_min_match
	quota = p_quota
	spin_cap = p_spin_cap
	rng = p_rng


func is_over() -> bool:
	return outcome != Outcome.PLAYING


## Spend `bet` (clamped to the remaining bankroll) and resolve one spin.
## Returns the payout. No-ops (returns 0.0) if the play phase already ended.
func spin(bet: float) -> float:
	if is_over():
		return 0.0

	var actual_bet: float = clamp(bet, 0.0, pools.bankroll)
	pools.spend_from_bankroll(actual_bet)
	spins_used += 1

	last_grid = machine.spin(rng)
	last_payout = Paytable.resolve_spin(last_grid, paylines, paytable,
			actual_bet, min_match)
	pools.add_to_pending(last_payout)
	pools.commit_pending_to_winnings()

	_update_outcome()
	return last_payout


func _update_outcome() -> void:
	if pools.winnings >= quota:
		outcome = Outcome.WIN
	elif pools.bankroll <= 0:
		outcome = Outcome.BUST
	elif spins_used >= spin_cap:
		outcome = Outcome.OUT_OF_SPINS
