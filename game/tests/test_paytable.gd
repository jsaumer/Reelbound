## GDScript port of sim/tests/test_paytable.py -- keeps the two payout
## resolvers verified in parallel so they can't silently drift apart.
extends GutTest

const PAYTABLE := {
	"A": {3: 1, 4: 5, 5: 20},
	"B": {3: 2, 4: 8, 5: 30},
}
const LINES := [
	[0, 0, 0, 0, 0],  # top row
	[1, 1, 1, 1, 1],  # middle row
]


func _grid_from_rows(rows: Array) -> Array:
	var num_reels: int = rows[0].size()
	var num_rows: int = rows.size()
	var grid := []
	for reel in range(num_reels):
		var column := []
		for row in range(num_rows):
			column.append(rows[row][reel])
		grid.append(column)
	return grid


func test_no_match_pays_nothing():
	var grid = _grid_from_rows([
		["A", "B", "A", "B", "A"],
		["x", "x", "x", "x", "x"],
	])
	assert_eq(Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0), 0.0)


func test_below_min_match_pays_nothing():
	var grid = _grid_from_rows([
		["A", "A", "x", "x", "x"],
		["y", "y", "y", "y", "y"],
	])
	assert_eq(Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0), 0.0)


func test_exact_three_match_pays_three_entry():
	var grid = _grid_from_rows([
		["A", "A", "A", "z", "z"],
		["q", "q", "q", "q", "q"],
	])
	assert_eq(Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0), 1.0)


func test_five_match_pays_five_entry():
	var grid = _grid_from_rows([
		["B", "B", "B", "B", "B"],
		["q", "q", "q", "q", "q"],
	])
	assert_eq(Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0), 30.0)


func test_match_must_be_left_anchored():
	var grid = _grid_from_rows([
		["z", "A", "A", "A", "A"],
		["q", "q", "q", "q", "q"],
	])
	assert_eq(Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0), 0.0)


func test_multiple_winning_lines_sum():
	var grid = _grid_from_rows([
		["A", "A", "A", "z", "z"],   # top: A x3 -> pays 1
		["B", "B", "B", "B", "z"],   # middle: B x4 -> pays 8
	])
	assert_eq(Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0), 9.0)


func test_bet_scales_payout_linearly():
	var grid = _grid_from_rows([
		["A", "A", "A", "z", "z"],
		["q", "q", "q", "q", "q"],
	])
	var payout_1x = Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0)
	var payout_3x = Paytable.resolve_spin(grid, LINES, PAYTABLE, 3.0)
	assert_eq(payout_3x, payout_1x * 3.0)


func test_symbol_not_in_paytable_pays_nothing():
	var grid = _grid_from_rows([
		["q", "q", "q", "q", "q"],
		["z", "z", "z", "z", "z"],
	])
	assert_eq(Paytable.resolve_spin(grid, LINES, PAYTABLE, 1.0), 0.0)
