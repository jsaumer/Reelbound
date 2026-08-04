## The play-phase controller (docs/02_GAME_DESIGN.md #4, D6 locked):
##     bankroll -> bet -> spin -> payout -> pending -> (bank or gamble) -> winnings
## under the dual limiter: play stops the instant bankroll hits zero OR the
## spin cap is reached, whichever comes first. Win iff winnings >= quota.
##
## Unlike sim/play_phase.py's batch while-loop (which runs a whole play
## phase to completion for simulation, with pluggable strategy callables),
## this is driven one decision at a time by the UI. A win only *may* pause
## on `awaiting_gamble_decision` -- gated by gamble_offer_probability (per
## playtest feedback, offering it on every win got old fast; the offer is
## meant to eventually be gated behind an obtainable item/boon, Phase 4/5,
## not built yet, so this probability is the buildable part of that today).
## When it does pause, resolve it via bank_pending()/gamble_pending(). Once
## quota clears, every subsequent spin pauses on
## `awaiting_continuation_decision` (D23) until the caller calls
## keep_playing()/cash_out(). Check those flags after every spin() and
## after every gamble_pending() call before doing anything else.
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
var starting_bankroll: float
var gamble_win_probability: float
var gamble_offer_probability: float
var cash_out_discount: float
var rng: RandomNumberGenerator

var spins_used: int = 0
var outcome: int = Outcome.PLAYING
var last_grid: Array = []
var last_payout: float = 0.0

var awaiting_gamble_decision: bool = false
var awaiting_continuation_decision: bool = false
var cash_out_offer: float = 0.0


func _init(p_machine: ReelMachine, p_pools: Pools, p_paytable: Dictionary,
		p_paylines: Array, p_min_match: int, p_quota: float, p_spin_cap: int,
		p_rng: RandomNumberGenerator, p_gamble_win_probability: float = 0.5,
		p_cash_out_discount: float = 0.4, p_gamble_offer_probability: float = 0.25) -> void:
	machine = p_machine
	pools = p_pools
	paytable = p_paytable
	paylines = p_paylines
	min_match = p_min_match
	quota = p_quota
	spin_cap = p_spin_cap
	starting_bankroll = p_pools.bankroll
	rng = p_rng
	gamble_win_probability = p_gamble_win_probability
	cash_out_discount = p_cash_out_discount
	gamble_offer_probability = p_gamble_offer_probability


func is_over() -> bool:
	return outcome != Outcome.PLAYING


func has_pending_decision() -> bool:
	return awaiting_gamble_decision or awaiting_continuation_decision


## Spend `bet` (clamped to the remaining bankroll) and resolve one spin.
## Returns the payout. No-ops (returns 0.0) if the play phase already ended
## or a prior decision hasn't been resolved yet.
func spin(bet: float) -> float:
	if is_over() or has_pending_decision():
		return 0.0

	var actual_bet: float = clamp(bet, 0.0, pools.bankroll)
	pools.spend_from_bankroll(actual_bet)
	spins_used += 1

	last_grid = machine.spin(rng)
	last_payout = Paytable.resolve_spin(last_grid, paylines, paytable,
			actual_bet, min_match)

	if last_payout > 0.0:
		pools.add_to_pending(last_payout)
		# The gamble-up choice is only offered some of the time (per
		# playtest feedback -- see economy_config.gd:GAMBLE_OFFER_PROBABILITY).
		# When it doesn't appear, the win just auto-banks.
		if rng.randf() < gamble_offer_probability:
			awaiting_gamble_decision = true
		else:
			pools.commit_pending_to_winnings()
			_after_pending_resolved()
	else:
		_after_pending_resolved()

	return last_payout


## Commits the current pending to winnings. Call only when
## awaiting_gamble_decision is true.
func bank_pending() -> void:
	if not awaiting_gamble_decision:
		return
	pools.commit_pending_to_winnings()
	awaiting_gamble_decision = false
	_after_pending_resolved()


## Flips the gamble-up coin. Returns true if it won (pending doubled, still
## awaiting a decision -- the ladder continues) or false if it lost
## (pending forfeited, decision resolved). Call only when
## awaiting_gamble_decision is true.
func gamble_pending() -> bool:
	if not awaiting_gamble_decision:
		return false
	var won := rng.randf() < gamble_win_probability
	if won:
		pools.double_pending()
	else:
		pools.forfeit_pending()
		awaiting_gamble_decision = false
		_after_pending_resolved()
	return won


## Keeps playing past a cleared quota. Call only when
## awaiting_continuation_decision is true.
func keep_playing() -> void:
	if not awaiting_continuation_decision:
		return
	awaiting_continuation_decision = false


## Takes the D23 cash-out offer: commits cash_out_offer on top of winnings
## and ends the play phase as a win. Call only when
## awaiting_continuation_decision is true.
func cash_out() -> void:
	if not awaiting_continuation_decision:
		return
	pools.add_to_pending(cash_out_offer)
	pools.commit_pending_to_winnings()
	awaiting_continuation_decision = false
	outcome = Outcome.WIN


func _after_pending_resolved() -> void:
	if pools.winnings >= quota:
		_offer_continuation_choice()
	else:
		_check_dual_limiter()


## D23: clearing quota doesn't end play -- it locks in a win (winnings
## never decreases, D3) and offers keep-playing-vs-cash-out. If there's no
## runway left to choose over (natural end reached exactly here), the win
## is finalized immediately with no offer.
func _offer_continuation_choice() -> void:
	var spins_remaining := _estimate_remaining_spins()
	if spins_remaining <= 0:
		outcome = Outcome.WIN
		return

	var avg_bet_so_far: float = (starting_bankroll - pools.bankroll) / spins_used
	var rtp := Odds.theoretical_rtp(machine.reel_strips, paylines, paytable)
	var avg_per_spin: float = rtp * avg_bet_so_far
	cash_out_offer = spins_remaining * avg_per_spin * cash_out_discount
	awaiting_continuation_decision = true


func _estimate_remaining_spins() -> int:
	var spin_cap_remaining: int = max(0, spin_cap - spins_used)
	if pools.bankroll <= 0 or spin_cap_remaining <= 0:
		return 0

	var avg_bet_so_far: float = (starting_bankroll - pools.bankroll) / spins_used
	if avg_bet_so_far <= 0.0:
		return spin_cap_remaining

	var bankroll_runway: int = int(pools.bankroll / avg_bet_so_far)
	return min(spin_cap_remaining, bankroll_runway)


func _check_dual_limiter() -> void:
	if pools.bankroll <= 0:
		outcome = Outcome.BUST
	elif spins_used >= spin_cap:
		outcome = Outcome.OUT_OF_SPINS
