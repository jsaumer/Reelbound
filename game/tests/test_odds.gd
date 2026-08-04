## GUT tests for Odds -- the live paytable/odds calculator behind the
## in-game info panel. Uses an asymmetric fixture (2/3 vs 1/3) so the
## exact-length vs full-reel-length cases can't coincidentally match.
extends GutTest

const REEL_STRIPS := [
	["A", "A", "B"],
	["A", "A", "B"],
	["A", "A", "B"],
]
const PAYTABLE := {
	"A": {2: 5.0, 3: 20.0},
}


func test_exact_length_probability_excludes_the_next_reel():
	var probs = Odds.symbol_match_probabilities(REEL_STRIPS, PAYTABLE)
	# P(A,A,not-A) = (2/3)^2 * (1/3) = 4/27
	assert_almost_eq(probs["A"][2], 4.0 / 27.0, 0.0001)


func test_full_reel_length_probability_has_no_exclusion():
	var probs = Odds.symbol_match_probabilities(REEL_STRIPS, PAYTABLE)
	# P(A,A,A) = (2/3)^3 = 8/27 -- no "next reel" to exclude, length == num_reels
	assert_almost_eq(probs["A"][3], 8.0 / 27.0, 0.0001)


func test_missing_symbol_on_a_reel_gives_zero_probability():
	var strips := [["B", "B"], ["B", "B"]]
	var paytable := {"A": {2: 10.0}}
	var probs = Odds.symbol_match_probabilities(strips, paytable)
	assert_eq(probs["A"][2], 0.0)


func test_rtp_scales_linearly_with_payline_count():
	var one_line := [[0, 0, 0]]
	var two_lines := [[0, 0, 0], [1, 1, 1]]

	var rtp_one = Odds.theoretical_rtp(REEL_STRIPS, one_line, PAYTABLE)
	var rtp_two = Odds.theoretical_rtp(REEL_STRIPS, two_lines, PAYTABLE)

	# (4/27)*5 + (8/27)*20 = 180/27
	assert_almost_eq(rtp_one, 180.0 / 27.0, 0.0001)
	assert_almost_eq(rtp_two, rtp_one * 2.0, 0.0001)


func test_odds_reflect_a_symbol_added_to_only_one_reel():
	# Simulates a purchased symbol landing on just one reel -- odds must
	# drop to zero for any match length, since it can never complete a
	# left-anchored run past that reel.
	var strips := [["C", "A"], ["B", "B"], ["B", "B"]]
	var paytable := {"C": {1: 1.0}, "A": {2: 5.0}}
	var probs = Odds.symbol_match_probabilities(strips, paytable)

	assert_almost_eq(probs["C"][1], 0.5, 0.0001)  # lands on reel 0 half the time
	assert_eq(probs["A"][2], 0.0)  # "A" never appears on reel 1, so 2-match is impossible
