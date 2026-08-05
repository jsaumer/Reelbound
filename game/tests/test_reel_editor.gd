## GDScript port of sim/tests/test_reel_editor.py.
extends GutTest

const PAYTABLE := {
	"cherry": {3: 2, 4: 5, 5: 10},
	"lemon": {3: 2, 4: 5, 5: 10},
	"bell": {3: 4, 4: 10, 5: 25},
	"crown": {3: 60, 4: 150, 5: 400},
}


func test_ranks_by_richest_defined_payout():
	assert_lt(ReelEditor.symbol_tier_value("cherry", PAYTABLE),
			ReelEditor.symbol_tier_value("bell", PAYTABLE))
	assert_lt(ReelEditor.symbol_tier_value("bell", PAYTABLE),
			ReelEditor.symbol_tier_value("crown", PAYTABLE))


func test_symbol_not_in_paytable_is_cheapest():
	assert_eq(ReelEditor.symbol_tier_value("unknown", PAYTABLE), 0.0)


func test_strip_length_is_conserved():
	var strip := []
	for i in range(8): strip.append("cherry")
	for i in range(8): strip.append("lemon")
	for i in range(6): strip.append("bell")
	strip.append("crown")
	var edited := ReelEditor.apply_reel_edit(strip, "crown", 3, PAYTABLE)
	assert_eq(edited.size(), strip.size())


func test_converts_the_cheapest_tier_present_first():
	var strip := ["cherry", "cherry", "bell", "bell"]
	var edited := ReelEditor.apply_reel_edit(strip, "crown", 2, PAYTABLE)
	assert_eq(_count(edited, "crown"), 2)
	assert_eq(_count(edited, "cherry"), 0)
	assert_eq(_count(edited, "bell"), 2)


func test_cascades_to_next_tier_once_cheapest_is_exhausted():
	var strip := ["cherry", "cherry", "bell", "bell"]
	var edited := ReelEditor.apply_reel_edit(strip, "crown", 3, PAYTABLE)
	assert_eq(_count(edited, "crown"), 3)
	assert_eq(_count(edited, "cherry"), 0)
	assert_eq(_count(edited, "bell"), 1)


func test_never_converts_the_target_symbol_into_itself():
	var strip := ["crown", "crown", "cherry", "cherry"]
	var edited := ReelEditor.apply_reel_edit(strip, "crown", 1, PAYTABLE)
	assert_eq(_count(edited, "crown"), 3)
	assert_eq(_count(edited, "cherry"), 1)


func test_stops_early_if_nothing_left_to_convert():
	var strip := ["crown", "crown", "crown", "crown"]
	var edited := ReelEditor.apply_reel_edit(strip, "crown", 5, PAYTABLE)
	assert_eq(edited, strip)


func test_zero_quantity_is_a_pure_copy():
	var strip := ["cherry", "bell", "crown"]
	var edited := ReelEditor.apply_reel_edit(strip, "crown", 0, PAYTABLE)
	assert_eq(edited, strip)


func test_zero_purchases_baseline_is_unchanged():
	var strip := []
	for i in range(8): strip.append("cherry")
	for i in range(8): strip.append("lemon")
	assert_eq(ReelEditor.apply_reel_edit(strip, "bell", 0, PAYTABLE), strip)


func _count(arr: Array, value) -> int:
	var n := 0
	for v in arr:
		if v == value:
			n += 1
	return n
