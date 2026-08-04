import unittest

from sim.odds import symbol_match_probabilities, theoretical_rtp

REEL_STRIPS = [
    ["A", "A", "B"],
    ["A", "A", "B"],
    ["A", "A", "B"],
]
PAYTABLE = {"A": {2: 5.0, 3: 20.0}}


class TestSymbolMatchProbabilities(unittest.TestCase):
    def test_exact_length_excludes_the_next_reel(self):
        probs = symbol_match_probabilities(REEL_STRIPS, PAYTABLE)
        # P(A,A,not-A) = (2/3)^2 * (1/3) = 4/27
        self.assertAlmostEqual(probs["A"][2], 4.0 / 27.0, places=6)

    def test_full_reel_length_has_no_exclusion(self):
        probs = symbol_match_probabilities(REEL_STRIPS, PAYTABLE)
        # P(A,A,A) = (2/3)^3 = 8/27 -- no next reel to exclude
        self.assertAlmostEqual(probs["A"][3], 8.0 / 27.0, places=6)

    def test_symbol_missing_from_a_reel_gives_zero(self):
        strips = [["C", "A"], ["B", "B"], ["B", "B"]]
        paytable = {"A": {2: 5.0}}
        probs = symbol_match_probabilities(strips, paytable)
        self.assertEqual(probs["A"][2], 0.0)


class TestTheoreticalRtp(unittest.TestCase):
    def test_scales_linearly_with_payline_count(self):
        one_line = [(0, 0, 0)]
        two_lines = [(0, 0, 0), (1, 1, 1)]

        rtp_one = theoretical_rtp(REEL_STRIPS, one_line, PAYTABLE)
        rtp_two = theoretical_rtp(REEL_STRIPS, two_lines, PAYTABLE)

        # (4/27)*5 + (8/27)*20 = 180/27
        self.assertAlmostEqual(rtp_one, 180.0 / 27.0, places=6)
        self.assertAlmostEqual(rtp_two, rtp_one * 2.0, places=6)


if __name__ == "__main__":
    unittest.main()
