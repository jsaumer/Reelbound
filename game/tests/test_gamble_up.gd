## GDScript port of sim/tests/test_gamble.py -- the bank-vs-gamble-up
## mechanic (docs/02_GAME_DESIGN.md #4).
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


func _new_play_phase(paytable: Dictionary, bankroll: float, quota: float,
		spin_cap: int, seed_value: int) -> PlayPhase:
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(bankroll)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# gamble_offer_probability=1.0: these tests exercise the gamble
	# mechanic itself, not the offer-gate (see test_gamble_offer.gd for
	# that), so the offer always appears here.
	return PlayPhase.new(setup.machine, pools, paytable, setup.paylines, 3,
			quota, spin_cap, rng, 0.5, 0.4, 1.0)


func test_bank_pending_commits_the_full_win():
	var play_phase := _new_play_phase({"A": {5: 10.0}}, 100.0, 1000.0, 1000, 1)

	play_phase.spin(1.0)
	assert_true(play_phase.awaiting_gamble_decision)
	play_phase.bank_pending()

	assert_false(play_phase.awaiting_gamble_decision)
	assert_eq(play_phase.pools.winnings, 10.0)


func test_gamble_pending_resolves_in_a_single_flip():
	# D25: not a ladder -- a win auto-banks, a loss forfeits, either way
	# awaiting_gamble_decision clears after exactly one flip.
	var play_phase := _new_play_phase({"A": {5: 10.0}}, 100.0, 1000.0, 1000, 1)

	play_phase.spin(1.0)
	var pending_before: float = play_phase.pools.pending
	var won: bool = play_phase.gamble_pending()

	assert_false(play_phase.awaiting_gamble_decision)
	assert_eq(play_phase.pools.pending, 0.0)
	if won:
		assert_almost_eq(play_phase.pools.winnings, pending_before * 2.0, 0.001)
	else:
		assert_eq(play_phase.pools.winnings, 0.0)  # forfeited, never banked


func test_gamble_pending_is_a_noop_once_already_resolved():
	var play_phase := _new_play_phase({"A": {5: 10.0}}, 100.0, 1000.0, 1000, 1)

	play_phase.spin(1.0)
	play_phase.gamble_pending()
	var winnings_after_first_flip: float = play_phase.pools.winnings

	var second_result: bool = play_phase.gamble_pending()

	assert_false(second_result)
	assert_eq(play_phase.pools.winnings, winnings_after_first_flip)


func test_gambling_never_touches_bankroll():
	var play_phase := _new_play_phase({"A": {5: 10.0}}, 100.0, 1000.0, 1000, 1)

	play_phase.spin(1.0)
	var bankroll_before: float = play_phase.pools.bankroll
	play_phase.gamble_pending()

	assert_eq(play_phase.pools.bankroll, bankroll_before)
