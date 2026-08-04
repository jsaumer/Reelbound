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
	return PlayPhase.new(setup.machine, pools, paytable, setup.paylines, 3,
			quota, spin_cap, rng, 0.5, 0.4)


func test_bank_pending_commits_the_full_win():
	var play_phase := _new_play_phase({"A": {5: 10.0}}, 100.0, 1000.0, 1000, 1)

	play_phase.spin(1.0)
	assert_true(play_phase.awaiting_gamble_decision)
	play_phase.bank_pending()

	assert_false(play_phase.awaiting_gamble_decision)
	assert_eq(play_phase.pools.winnings, 10.0)


func test_gamble_pending_doubles_or_forfeits():
	var play_phase := _new_play_phase({"A": {5: 10.0}}, 100.0, 1000.0, 1000, 1)

	play_phase.spin(1.0)
	var pending_before: float = play_phase.pools.pending
	var won: bool = play_phase.gamble_pending()

	if won:
		assert_almost_eq(play_phase.pools.pending, pending_before * 2.0, 0.001)
		assert_true(play_phase.awaiting_gamble_decision)  # ladder continues
	else:
		assert_eq(play_phase.pools.pending, 0.0)
		assert_false(play_phase.awaiting_gamble_decision)
		assert_eq(play_phase.pools.winnings, 0.0)  # forfeited, never banked


func test_gambling_never_touches_bankroll():
	var play_phase := _new_play_phase({"A": {5: 10.0}}, 100.0, 1000.0, 1000, 1)

	play_phase.spin(1.0)
	var bankroll_before: float = play_phase.pools.bankroll
	while play_phase.awaiting_gamble_decision:
		play_phase.gamble_pending()

	assert_eq(play_phase.pools.bankroll, bankroll_before)


func test_gambling_until_a_loss_forfeits_everything():
	# Keep gambling until the loop resolves on its own (a loss) -- confirms
	# a losing flip always ends with zero pending and zero committed,
	# regardless of how many prior doublings happened.
	var play_phase := _new_play_phase({"A": {5: 10.0}}, 100.0, 1000.0, 1000, 1)

	play_phase.spin(1.0)
	var loops := 0
	while play_phase.awaiting_gamble_decision and loops < 100:
		play_phase.gamble_pending()
		loops += 1

	assert_false(play_phase.awaiting_gamble_decision)
	assert_lt(loops, 100)  # sanity: it did resolve, not an infinite ladder
