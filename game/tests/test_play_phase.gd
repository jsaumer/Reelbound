## GDScript port of sim/tests/test_play_phase.py -- same dual-limiter
## fixtures (single-symbol machine removes RNG from the outcome). Unlike
## the Python model's pluggable strategy callables, this state machine is
## UI-driven: a winning spin leaves awaiting_gamble_decision true until
## bank_pending()/gamble_pending() is called, so tests must resolve that
## (and any D23 continuation offer) before spinning again.
extends GutTest


func _single_symbol_machine(symbol: String, num_reels: int, num_rows: int) -> Dictionary:
	var strips := []
	for i in range(num_reels):
		strips.append([symbol])
	var line := []
	for i in range(num_reels):
		line.append(0)
	return {
		"machine": ReelMachine.new(strips, num_rows),
		"paylines": [line],
	}


## Spins once, then always banks (never gambles) and always keeps playing
## past a cleared quota -- the "naive/never_gamble + always_keep_playing"
## baseline, matching sim's old auto-commit-every-spin behavior.
func _spin_bank_and_keep_playing(play_phase: PlayPhase, bet: float) -> float:
	var payout: float = play_phase.spin(bet)
	if play_phase.awaiting_gamble_decision:
		play_phase.bank_pending()
	if play_phase.awaiting_continuation_decision:
		play_phase.keep_playing()
	return payout


func test_bust_when_bankroll_runs_out_before_quota():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(10.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.0}},
			setup.paylines, 3, 1000.0, 1000, rng)

	while not play_phase.is_over():
		_spin_bank_and_keep_playing(play_phase, 2.0)

	assert_eq(play_phase.outcome, PlayPhase.Outcome.BUST)
	assert_eq(play_phase.spins_used, 5)  # 10 / 2
	assert_eq(pools.winnings, 0.0)
	assert_eq(pools.bankroll, 0.0)


func test_out_of_spins_when_cap_hits_before_quota():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(1000.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.5}},
			setup.paylines, 3, 1000.0, 3, rng)

	while not play_phase.is_over():
		_spin_bank_and_keep_playing(play_phase, 1.0)

	assert_eq(play_phase.outcome, PlayPhase.Outcome.OUT_OF_SPINS)
	assert_eq(play_phase.spins_used, 3)
	assert_eq(pools.winnings, 1.5)  # 3 spins * 0.5
	assert_gt(pools.bankroll, 0.0)


func test_win_locked_in_but_play_continues_to_natural_end_by_default():
	# D23: clearing quota no longer stops play. Every spin pays far more
	# than the bet, so quota clears on spin 1 (winnings=100 >= 50), but
	# always keeping-playing plays on until bankroll actually runs out.
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(50.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 100.0}},
			setup.paylines, 3, 50.0, 1000, rng)

	while not play_phase.is_over():
		_spin_bank_and_keep_playing(play_phase, 1.0)

	assert_eq(play_phase.outcome, PlayPhase.Outcome.WIN)
	assert_eq(play_phase.spins_used, 50)  # 50 bankroll / 1 bet
	assert_eq(pools.winnings, 5000.0)  # 100 * 50 spins
	assert_eq(pools.bankroll, 0.0)


func test_cash_out_stops_immediately_with_a_discounted_bonus():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(50.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 100.0}},
			setup.paylines, 3, 50.0, 1000, rng, 0.5, 0.4)

	play_phase.spin(1.0)
	play_phase.bank_pending()

	assert_true(play_phase.awaiting_continuation_decision)
	play_phase.cash_out()

	# After spin 1: winnings=100, bankroll=49, spins_remaining=49 (49
	# bankroll / 1 avg bet). Theoretical rtp for this guaranteed-match
	# fixture is 100.0 (matches sim's equivalent test exactly).
	# cash_out_offer = 49 * 100.0 * 0.4 = 1960.0
	assert_eq(play_phase.outcome, PlayPhase.Outcome.WIN)
	assert_almost_eq(play_phase.cash_out_offer, 1960.0, 0.01)
	assert_almost_eq(pools.winnings, 100.0 + 1960.0, 0.01)


func test_bankroll_never_increases_over_a_run():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(20.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.5}},
			setup.paylines, 3, 1000.0, 1000, rng)

	while not play_phase.is_over():
		_spin_bank_and_keep_playing(play_phase, 3.0)

	assert_eq(play_phase.outcome, PlayPhase.Outcome.BUST)
	assert_lt(pools.bankroll, 20.0)
	assert_gt(pools.winnings, 0.0)


func test_deterministic_for_a_fixed_seed():
	var result_a = _run_default_seeded(42)
	var result_b = _run_default_seeded(42)

	assert_eq(result_a.outcome, result_b.outcome)
	assert_eq(result_a.spins_used, result_b.spins_used)
	assert_eq(result_a.winnings, result_b.winnings)


func _run_default_seeded(seed_value: int) -> Dictionary:
	var machine := ReelMachine.new(
			EconomyConfig.build_default_reel_strips(), EconomyConfig.NUM_ROWS)
	var pools := Pools.new(EconomyConfig.STARTING_BANKROLL)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var play_phase := PlayPhase.new(machine, pools, EconomyConfig.DEFAULT_PAYTABLE,
			EconomyConfig.DEFAULT_PAYLINES, EconomyConfig.MIN_MATCH,
			EconomyConfig.QUOTA, EconomyConfig.SPIN_CAP, rng,
			EconomyConfig.GAMBLE_WIN_PROBABILITY, EconomyConfig.CASH_OUT_DISCOUNT)
	var bet: float = (EconomyConfig.MIN_BET + EconomyConfig.MAX_BET) / 2.0

	while not play_phase.is_over():
		_spin_bank_and_keep_playing(play_phase, bet)

	return {
		"outcome": play_phase.outcome,
		"spins_used": play_phase.spins_used,
		"winnings": pools.winnings,
	}
