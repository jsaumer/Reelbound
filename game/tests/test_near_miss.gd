extends GutTest


func test_no_match_returns_empty():
	var grid := [["A"], ["B"], ["C"]]
	var paylines := [[0, 0, 0]]
	var result = NearMiss.find_anticipation(grid, paylines, {"A": {2: 5.0, 3: 20.0}})
	assert_true(result.is_empty())


func test_developing_two_run_finds_the_deciding_reel():
	var grid := [["A"], ["A"], ["B"]]
	var paylines := [[0, 0, 0]]
	var paytable := {"A": {2: 5.0, 3: 20.0}}
	var result = NearMiss.find_anticipation(grid, paylines, paytable)

	assert_eq(result.reel_index, 2)
	assert_eq(result.symbol, "A")
	assert_eq(result.run_length, 2)
	assert_eq(result.potential_payout_multiplier, 20.0)


func test_full_match_has_nothing_left_to_decide():
	var grid := [["A"], ["A"], ["A"]]
	var paylines := [[0, 0, 0]]
	var result = NearMiss.find_anticipation(grid, paylines, {"A": {3: 20.0}})
	assert_true(result.is_empty())


func test_missing_next_length_in_paytable_is_not_developing():
	var grid := [["A"], ["A"], ["B"]]
	var paylines := [[0, 0, 0]]
	# Only a 2-match entry defined -- reaching reel 2 wouldn't change anything.
	var result = NearMiss.find_anticipation(grid, paylines, {"A": {2: 5.0}})
	assert_true(result.is_empty())


func test_symbol_not_in_paytable_is_ignored():
	var grid := [["A"], ["A"], ["B"]]
	var paylines := [[0, 0, 0]]
	var result = NearMiss.find_anticipation(grid, paylines, {"Z": {2: 5.0, 3: 20.0}})
	assert_true(result.is_empty())


func test_picks_the_line_with_the_highest_upside():
	# reel[r] = [row0_symbol, row1_symbol]
	var grid := [
		["A", "C"],
		["A", "C"],
		["B", "D"],
	]
	var paylines := [[0, 0, 0], [1, 1, 1]]
	var paytable := {
		"A": {2: 5.0, 3: 20.0},
		"C": {2: 1.0, 3: 50.0},
	}
	var result = NearMiss.find_anticipation(grid, paylines, paytable)

	assert_eq(result.symbol, "C")
	assert_eq(result.potential_payout_multiplier, 50.0)
	assert_eq(result.row_pattern, [1, 1, 1])
