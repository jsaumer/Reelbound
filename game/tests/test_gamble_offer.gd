## The gamble-up offer gate itself (economy_config.gd:GAMBLE_OFFER_PROBABILITY)
## -- separate from test_gamble_up.gd, which tests the flip mechanic
## assuming the offer already appeared.
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


func test_offer_probability_zero_always_auto_banks():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(100.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 10.0}},
			setup.paylines, 3, 1000.0, 1000, rng, 0.5, 0.4, 0.0)

	play_phase.spin(1.0)

	assert_false(play_phase.awaiting_gamble_decision)
	assert_eq(pools.winnings, 10.0)


func test_offer_probability_one_always_offers():
	var setup = _single_symbol_machine("A", 5, 1)
	var pools := Pools.new(100.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var play_phase := PlayPhase.new(setup.machine, pools, {"A": {5: 10.0}},
			setup.paylines, 3, 1000.0, 1000, rng, 0.5, 0.4, 1.0)

	play_phase.spin(1.0)

	assert_true(play_phase.awaiting_gamble_decision)
	assert_eq(pools.winnings, 0.0)  # still pending, not banked yet
