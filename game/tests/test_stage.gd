## GDScript port of sim/tests/test_stage.py. Stage is UI-driven (like
## play_phase.gd, unlike sim/stage.py's batch loop) -- tests drive it one
## node at a time via _advance(), matching test_play_phase.gd's
## _spin_bank_and_keep_playing() pattern.
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


## Resolves whatever node is current (free node or a spin at `bet`), then
## always banks (never gambles) and always keeps playing past a cleared
## quota -- the naive baseline, matching test_play_phase.gd's helper.
func _advance(stage: Stage, bet: float) -> void:
	if stage.is_free_node():
		stage.resolve_free_node()
	else:
		stage.spin(bet)
	if stage.play_phase.awaiting_gamble_decision:
		stage.bank_pending()
	if stage.play_phase.awaiting_continuation_decision:
		stage.keep_playing()


func test_treasure_adds_winnings_without_consuming_a_spin():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(10.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.0}},
			setup.paylines, 3, 1000.0, 2, rng)
	var stage := Stage.new(play_phase, [Stage.NodeType.TREASURE, Stage.NodeType.MINOR])

	while not stage.is_over():
		_advance(stage, 1.0)

	assert_eq(play_phase.spins_used, 2)  # only MINOR nodes consumed the cap
	assert_eq(pools.winnings, 2 * Stage.TREASURE_WINNINGS_BONUS)
	assert_eq(_count(stage.nodes_visited, Stage.NodeType.TREASURE), 2)


func test_elite_forces_a_bigger_bet_than_the_strategy_chose():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(100.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.0}},
			setup.paylines, 3, 1000.0, 1, rng)
	var stage := Stage.new(play_phase, [Stage.NodeType.ELITE])

	_advance(stage, 2.0)

	assert_almost_eq(pools.bankroll, 100.0 - 2.0 * Stage.ELITE_BET_MULTIPLIER, 0.001)


func test_elite_bet_is_clamped_to_available_bankroll():
	# min_bet=2.0 * ELITE_BET_MULTIPLIER (1.25) = 2.5, more than the 2.0
	# bankroll actually holds -- must clamp, not overdraw.
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(2.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.0}},
			setup.paylines, 3, 1000.0, 1, rng)
	var stage := Stage.new(play_phase, [Stage.NodeType.ELITE])

	_advance(stage, 2.0)

	assert_eq(pools.bankroll, 0.0)


func test_event_and_rest_nodes_are_a_no_op_turn():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(10.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.0}},
			setup.paylines, 3, 1000.0, 1, rng)
	var stage := Stage.new(play_phase, [Stage.NodeType.EVENT, Stage.NodeType.REST, Stage.NodeType.MINOR])

	while not stage.is_over():
		_advance(stage, 1.0)

	assert_eq(play_phase.spins_used, 1)
	assert_eq(pools.bankroll, 9.0)
	assert_true(stage.nodes_visited.has(Stage.NodeType.EVENT))
	assert_true(stage.nodes_visited.has(Stage.NodeType.REST))


func test_bust_when_bankroll_runs_out_before_quota():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(10.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.0}},
			setup.paylines, 3, 1000.0, 1000, rng)
	var stage := Stage.new(play_phase, [Stage.NodeType.MINOR])

	while not stage.is_over():
		_advance(stage, 2.0)

	assert_eq(play_phase.outcome, PlayPhase.Outcome.BUST)
	assert_eq(pools.bankroll, 0.0)


func test_out_of_spins_when_cap_hits_before_quota():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(1000.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.5}},
			setup.paylines, 3, 1000.0, 3, rng)
	var stage := Stage.new(play_phase, [Stage.NodeType.MINOR])

	while not stage.is_over():
		_advance(stage, 1.0)

	assert_eq(play_phase.outcome, PlayPhase.Outcome.OUT_OF_SPINS)
	assert_eq(play_phase.spins_used, 3)


func test_win_when_quota_is_cleared():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 100.0}},
			setup.paylines, 3, 50.0, 1000, rng)
	var stage := Stage.new(play_phase, [Stage.NodeType.MINOR])

	while not stage.is_over():
		_advance(stage, 1.0)

	assert_eq(play_phase.outcome, PlayPhase.Outcome.WIN)
	assert_gte(pools.winnings, 50.0)


func test_node_sequence_cycles_and_never_runs_out():
	# A short sequence over a long spin cap must keep cycling -- the stage
	# can only end via the dual limiter, never "out of nodes".
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(1000.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 0.1}},
			setup.paylines, 3, 1000.0, 20, rng)
	var stage := Stage.new(play_phase, [Stage.NodeType.MINOR, Stage.NodeType.TREASURE])

	while not stage.is_over():
		_advance(stage, 1.0)

	assert_eq(play_phase.outcome, PlayPhase.Outcome.OUT_OF_SPINS)
	assert_eq(play_phase.spins_used, 20)
	# 20 MINOR (hits the cap) + 19 TREASURE (the limiter check inside
	# PlayPhase fires before the 20th TREASURE's turn would be reached).
	assert_eq(stage.nodes_visited.size(), 39)


func test_deterministic_for_a_fixed_seed():
	var result_a := _run_default_seeded(42)
	var result_b := _run_default_seeded(42)

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
	var stage := Stage.new(play_phase, Stage.default_node_sequence())
	var bet: float = (EconomyConfig.MIN_BET + EconomyConfig.MAX_BET) / 2.0

	while not stage.is_over():
		_advance(stage, bet)

	return {"outcome": play_phase.outcome, "spins_used": play_phase.spins_used, "winnings": pools.winnings}


## D12's exit criterion, re-verified for the stage path (docs/05_ROADMAP.md's
## Phase 4 balance note): ELITE and TREASURE add pacing variety without
## breaking the tension band the flat economy was tuned to hit.
func test_default_node_sequence_stays_in_the_40_60_band():
	var runs := 1500
	var wins := 0
	for i in range(runs):
		var result := _run_default_seeded(1000 + i)
		if result.outcome == PlayPhase.Outcome.WIN:
			wins += 1
	var win_rate := float(wins) / float(runs)

	assert_gte(win_rate, 0.40)
	assert_lte(win_rate, 0.60)


func _count(arr: Array, value) -> int:
	var n := 0
	for v in arr:
		if v == value:
			n += 1
	return n
