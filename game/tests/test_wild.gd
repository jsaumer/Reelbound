## GDScript port of sim/tests/test_wild.py.
extends GutTest

const PAYTABLE := {
	"A": {3: 1, 4: 5, 5: 20},
	"B": {3: 2, 4: 8, 5: 30},
	"WILD": {3: 10, 4: 50, 5: 200},
}
const LINES := [[0, 0, 0, 0, 0]]


func _grid_from_row(row: Array) -> Array:
	var grid := []
	for symbol in row:
		grid.append([symbol])
	return grid


func test_no_wild_symbol_configured_is_unaffected():
	var grid := _grid_from_row(["A", "A", "A", "WILD", "z"])
	assert_eq(Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0), 1.0)


func test_trailing_wild_extends_a_match():
	var grid := _grid_from_row(["A", "A", "WILD", "z", "z"])
	var payout := Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0, 3, "WILD")
	assert_eq(payout, 1.0)  # A-A-WILD = 3x A


func test_leading_wild_takes_the_identity_of_the_first_real_symbol():
	var grid := _grid_from_row(["WILD", "A", "A", "z", "z"])
	var payout := Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0, 3, "WILD")
	assert_eq(payout, 1.0)  # WILD-A-A = 3x A


func test_wild_break_by_a_different_symbol():
	var grid := _grid_from_row(["A", "WILD", "B", "A", "A"])
	var payout := Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0, 3, "WILD")
	assert_eq(payout, 0.0)  # A-WILD counts as 2x A, then B breaks it (< min_match)


func test_all_wild_line_pays_the_wild_symbols_own_entry():
	var grid := _grid_from_row(["WILD", "WILD", "WILD", "WILD", "WILD"])
	var payout := Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0, 3, "WILD")
	assert_eq(payout, 200.0)


func test_all_wild_line_with_no_wild_paytable_entry_pays_nothing():
	var paytable := {"A": {3: 1, 4: 5, 5: 20}}  # no "WILD" entry
	var grid := _grid_from_row(["WILD", "WILD", "WILD", "WILD", "WILD"])
	var payout := Paytable.resolve_spin(grid, LINES, paytable, 1.0, 3, "WILD")
	assert_eq(payout, 0.0)


func test_bet_still_scales_a_wild_assisted_win():
	var grid := _grid_from_row(["A", "A", "WILD", "z", "z"])
	var payout_1x := Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0, 3, "WILD")
	var payout_3x := Paytable.resolve_spin(grid, LINES, PAYTABLE, 3.0, 3, "WILD")
	assert_eq(payout_3x, payout_1x * 3.0)
