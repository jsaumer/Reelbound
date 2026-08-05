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


func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_generates_the_configured_number_of_offers():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	assert_eq(build.reel_offers().size(), BuildPhase.REEL_OFFER_COUNT)


func test_offers_only_draw_from_owned_symbols():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	for offer in build.reel_offers():
		assert_true(build.owned_symbols.has(offer.symbol))


func test_offer_reel_index_is_within_range():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	for offer in build.reel_offers():
		assert_gte(offer.reel_index, 0)
		assert_lt(offer.reel_index, build.reel_strips.size())


func test_offer_cost_matches_reel_edit_cost_for_its_symbol():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	for offer in build.reel_offers():
		assert_eq(offer.cost, build.reel_edit_cost(offer.symbol, offer.quantity))


func test_deterministic_for_a_fixed_seed():
	var build_a := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(42))
	var build_b := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(42))
	for i in range(BuildPhase.REEL_OFFER_COUNT):
		assert_eq(build_a.reel_offers()[i].reel_index, build_b.reel_offers()[i].reel_index)
		assert_eq(build_a.reel_offers()[i].symbol, build_b.reel_offers()[i].symbol)


func test_buying_an_offer_applies_the_edit_and_marks_it_bought():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	var offer = build.reel_offers()[0]
	var strip_before: Array = build.reel_strips[offer.reel_index].duplicate()
	var wallet_before: float = build.wallet

	var bought := build.buy_reel_offer(0)

	assert_true(bought)
	assert_true(offer.bought)
	assert_ne(build.reel_strips[offer.reel_index], strip_before)
	assert_eq(build.wallet, wallet_before - offer.cost)


func test_buying_an_already_bought_offer_is_a_noop():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	assert_true(build.buy_reel_offer(0))
	var wallet_after_first_buy: float = build.wallet
	assert_false(build.buy_reel_offer(0))
	assert_eq(build.wallet, wallet_after_first_buy)


func test_buying_an_unaffordable_offer_is_a_safe_noop():
	var build := BuildPhase.new(0.5, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	assert_false(build.buy_reel_offer(0))
	assert_eq(build.wallet, 0.5)


func test_invalid_offer_index_is_a_safe_noop():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	assert_false(build.buy_reel_offer(-1))
	assert_false(build.buy_reel_offer(BuildPhase.REEL_OFFER_COUNT))
	assert_eq(build.wallet, 100.0)


func test_buying_one_offer_leaves_the_others_untouched():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	build.buy_reel_offer(0)
	for i in range(1, build.reel_offers().size()):
		assert_false(build.reel_offers()[i].bought)


func test_reroll_cost_starts_at_the_base():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	assert_eq(build.reroll_cost(), BuildPhase.REEL_REROLL_BASE_COST)


func test_reroll_cost_climbs_each_time():
	var build := BuildPhase.new(1000.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	var first_cost := build.reroll_cost()
	build.reroll_reel_offers()
	var second_cost := build.reroll_cost()
	assert_eq(second_cost, first_cost + BuildPhase.REEL_REROLL_COST_INCREMENT)


func test_reroll_spends_wallet_and_replaces_offers():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	var offers_before := []
	for o in build.reel_offers():
		offers_before.append([o.reel_index, o.symbol])
	var wallet_before: float = build.wallet

	var rerolled := build.reroll_reel_offers()

	assert_true(rerolled)
	assert_eq(build.wallet, wallet_before - BuildPhase.REEL_REROLL_BASE_COST)
	var offers_after := []
	for o in build.reel_offers():
		offers_after.append([o.reel_index, o.symbol])
	assert_ne(offers_before, offers_after)


func test_reroll_also_resets_a_bought_offers_slot():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	build.buy_reel_offer(0)
	assert_true(build.reel_offers()[0].bought)

	build.reroll_reel_offers()

	assert_false(build.reel_offers()[0].bought)


func test_reroll_does_not_undo_a_previous_purchase():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	var offer = build.reel_offers()[0]
	build.buy_reel_offer(0)
	var strip_after_purchase: Array = build.reel_strips[offer.reel_index].duplicate()
	var ledger_after_purchase := build.reel_ledger()

	build.reroll_reel_offers()

	assert_eq(build.reel_strips[offer.reel_index], strip_after_purchase)
	assert_eq(build.reel_ledger(), ledger_after_purchase)


func test_can_buy_the_same_slot_again_after_a_reroll():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	build.buy_reel_offer(0)
	build.reroll_reel_offers()
	assert_true(build.buy_reel_offer(0))


func test_cannot_reroll_without_enough_wallet():
	var build := BuildPhase.new(1.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	assert_false(build.reroll_reel_offers())
	assert_eq(build.wallet, 1.0)
	assert_eq(build.reroll_count, 0)


func test_ledger_empty_before_any_purchase():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	assert_eq(build.reel_ledger(), {})


func test_ledger_records_a_purchase_via_offer():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	var offer = build.reel_offers()[0]
	build.buy_reel_offer(0)

	var ledger := build.reel_ledger()

	assert_eq(ledger[offer.reel_index][offer.symbol], offer.quantity)


func test_ledger_records_a_direct_edit_reel_call():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	build.edit_reel(2, "cherry", 3)
	assert_eq(build.reel_ledger(), {2: {"cherry": 3}})


func test_ledger_aggregates_repeated_purchases_of_the_same_symbol_on_the_same_reel():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	build.edit_reel(1, "cherry", 1)
	build.edit_reel(1, "cherry", 1)
	assert_eq(build.reel_ledger(), {1: {"cherry": 2}})


func test_ledger_keeps_different_reels_separate():
	var build := BuildPhase.new(100.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	build.edit_reel(0, "cherry", 1)
	build.edit_reel(1, "cherry", 1)
	var ledger := build.reel_ledger()
	assert_eq(ledger[0], {"cherry": 1})
	assert_eq(ledger[1], {"cherry": 1})


func test_ledger_a_failed_edit_is_not_logged():
	var build := BuildPhase.new(1.0, _reel_strips(), PAYTABLE.duplicate(true), 1.0, [], _seeded_rng(1))
	assert_false(build.edit_reel(0, "crown", 5))  # too expensive
	assert_eq(build.reel_ledger(), {})
