## GDScript port of sim/tests/test_play_phase.py -- same dual-limiter
## fixtures (single-symbol machine removes RNG from the outcome), driven
## spin-by-spin the way the UI actually calls PlayPhase.spin().
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


func test_bust_when_bankroll_runs_out_before_quota():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(10.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.0}},
			setup.paylines, 3, 1000.0, 1000, rng)

	while not play_phase.is_over():
		play_phase.spin(2.0)

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
		play_phase.spin(1.0)

	assert_eq(play_phase.outcome, PlayPhase.Outcome.OUT_OF_SPINS)
	assert_eq(play_phase.spins_used, 3)
	assert_eq(pools.winnings, 1.5)  # 3 spins * 0.5
	assert_gt(pools.bankroll, 0.0)


func test_win_when_quota_cleared_before_either_limiter():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(50.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 100.0}},
			setup.paylines, 3, 50.0, 1000, rng)

	play_phase.spin(1.0)

	assert_eq(play_phase.outcome, PlayPhase.Outcome.WIN)
	assert_eq(play_phase.spins_used, 1)
	assert_eq(pools.winnings, 100.0)


func test_bankroll_never_increases_over_a_run():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(20.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.5}},
			setup.paylines, 3, 1000.0, 1000, rng)

	while not play_phase.is_over():
		play_phase.spin(3.0)

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
			EconomyConfig.QUOTA, EconomyConfig.SPIN_CAP, rng)
	var bet: float = (EconomyConfig.MIN_BET + EconomyConfig.MAX_BET) / 2.0

	while not play_phase.is_over():
		play_phase.spin(bet)

	return {
		"outcome": play_phase.outcome,
		"spins_used": play_phase.spins_used,
		"winnings": pools.winnings,
	}
