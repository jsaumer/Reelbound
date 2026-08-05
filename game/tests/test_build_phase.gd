## GDScript port of sim/tests/test_build_phase.py.
extends GutTest

const PAYTABLE := {
	"cherry": {3: 2, 4: 5, 5: 10},
	"lemon": {3: 2, 4: 5, 5: 10},
	"crown": {3: 60, 4: 150, 5: 400},
}


func _reel_strips() -> Array:
	var strips := []
	for i in range(5):
		strips.append(["cherry", "cherry", "lemon", "lemon", "crown"])
	return strips


func test_wild_is_offered_when_not_owned():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true))
	var ids := []
	for r in build.shelf():
		ids.append(r.id)
	assert_true(ids.has(BuildPhase.WILD_RELIC_ID))


func test_wild_disappears_from_the_shelf_once_bought():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true))
	build.buy_relic(BuildPhase.WILD_RELIC_ID)
	assert_eq(build.shelf(), [])


func test_buying_wild_adds_it_to_owned_symbols_and_paytable():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true))
	var bought := build.buy_relic(BuildPhase.WILD_RELIC_ID)
	assert_true(bought)
	assert_true(build.owned_symbols.has(BuildPhase.WILD_SYMBOL))
	assert_true(build.paytable.has(BuildPhase.WILD_SYMBOL))
	assert_eq(build.wallet, 100.0 - BuildPhase.WILD_RELIC_COST)


func test_cannot_afford_relic_is_a_safe_noop():
	var build := BuildPhase.new(5.0, _reel_strips(), PAYTABLE.duplicate(true))
	var bought := build.buy_relic(BuildPhase.WILD_RELIC_ID)
	assert_false(bought)
	assert_eq(build.wallet, 5.0)
	assert_false(build.owned_symbols.has(BuildPhase.WILD_SYMBOL))


func test_unknown_relic_id_is_a_safe_noop():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true))
	assert_false(build.buy_relic("not_a_real_relic"))
	assert_eq(build.wallet, 100.0)


func test_cannot_edit_with_an_unowned_symbol():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true))
	assert_false(build.edit_reel(0, BuildPhase.WILD_SYMBOL, 2))  # wild not bought yet
	assert_eq(build.wallet, 100.0)


func test_owned_symbol_edit_spends_wallet_and_changes_the_reel():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true))
	var wallet_before: float = build.wallet
	var strip_before: Array = build.reel_strips[0].duplicate()

	var edited := build.edit_reel(0, "cherry", 1)

	assert_true(edited)
	assert_lt(build.wallet, wallet_before)
	assert_ne(build.reel_strips[0], strip_before)
	assert_eq(build.reel_strips[0].size(), strip_before.size())  # D29: length conserved


func test_other_reels_are_untouched():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true))
	var other_before: Array = build.reel_strips[1].duplicate()
	assert_true(build.edit_reel(0, "cherry", 2))
	assert_eq(build.reel_strips[1], other_before)


func test_cannot_afford_edit_is_a_safe_noop():
	var build := BuildPhase.new(1.0, _reel_strips(), PAYTABLE.duplicate(true))
	var strip_before: Array = build.reel_strips[0].duplicate()
	assert_false(build.edit_reel(0, "crown", 5))  # crown is expensive
	assert_eq(build.wallet, 1.0)
	assert_eq(build.reel_strips[0], strip_before)


func test_spins_from_load_uses_min_bet():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 2.0)
	assert_eq(build.spins_from_load(20.0), 10.0)


func test_load_bankroll_moves_wallet_into_loaded_bankroll():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true))
	assert_true(build.load_bankroll(60.0))
	assert_eq(build.wallet, 40.0)
	assert_eq(build.loaded_bankroll, 60.0)


func test_cannot_load_more_than_the_wallet_holds():
	var build := BuildPhase.new(10.0, _reel_strips(), PAYTABLE.duplicate(true))
	assert_false(build.load_bankroll(20.0))
	assert_eq(build.wallet, 10.0)


func test_finalize_auto_converts_leftover_wallet_to_bankroll():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true))
	build.load_bankroll(60.0)  # explicit load

	var result := build.finalize()

	assert_eq(result.starting_bankroll, 100.0)  # 60 loaded + 40 leftover, no waste
	assert_eq(result.wild_symbol, "")


func test_finalize_reports_wild_symbol_when_bought():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true))
	build.buy_relic(BuildPhase.WILD_RELIC_ID)
	var result := build.finalize()
	assert_eq(result.wild_symbol, BuildPhase.WILD_SYMBOL)


func test_zero_purchases_baseline_is_the_unmodified_starting_machine():
	var strips := _reel_strips()
	var strips_copy := []
	for s in strips:
		strips_copy.append(s.duplicate())
	var build := BuildPhase.new(100.0, strips_copy, PAYTABLE.duplicate(true))
	var result := build.finalize()
	assert_eq(result.reel_strips, strips)
	assert_eq(result.starting_bankroll, 100.0)  # all wallet auto-converts
	assert_eq(result.wild_symbol, "")
