## GDScript port of sim/tests/test_cash_out.py -- D23's post-quota
## keep-playing-vs-cash-out choice.
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


func test_no_runway_left_ends_as_win_without_a_choice():
	# spin_cap reached in the same spin that clears quota -- nothing left
	# to decide, no bonus offered.
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(100.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 100.0}},
			setup.paylines, 3, 50.0, 1, rng)

	play_phase.spin(1.0)
	play_phase.bank_pending()

	assert_eq(play_phase.outcome, PlayPhase.Outcome.WIN)
	assert_eq(play_phase.spins_used, 1)
	assert_false(play_phase.awaiting_continuation_decision)
	assert_eq(play_phase.cash_out_offer, 0.0)
	assert_eq(pools.winnings, 100.0)  # no bonus applied


func test_bankroll_hitting_zero_after_quota_clear_is_still_a_win():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(5.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 10.0}},
			setup.paylines, 3, 5.0, 1000, rng)

	while not play_phase.is_over():
		play_phase.spin(1.0)
		if play_phase.awaiting_gamble_decision:
			play_phase.bank_pending()
		if play_phase.awaiting_continuation_decision:
			play_phase.keep_playing()

	assert_eq(play_phase.outcome, PlayPhase.Outcome.WIN)
	assert_eq(pools.bankroll, 0.0)
