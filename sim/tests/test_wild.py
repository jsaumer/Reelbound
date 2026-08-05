import unittest

from sim.paytable import resolve_spin

PAYTABLE = {
    "A": {3: 1, 4: 5, 5: 20},
    "B": {3: 2, 4: 8, 5: 30},
    "WILD": {3: 10, 4: 50, 5: 200},
}
LINES = [
    [0, 0, 0, 0, 0],
]


def grid_from_row(row):
    return [[symbol] for symbol in row]


class TestWildSubstitution(unittest.TestCase):
    def test_no_wild_symbol_configured_is_unaffected(self):
        # wild_symbol defaults to None -- "WILD" is just an ordinary,
        # non-matching string in that case.
        grid = grid_from_row(["A", "A", "A", "WILD", "z"])
        self.assertEqual(resolve_spin(grid, LINES, PAYTABLE, 1.0), 1.0)

    def test_trailing_wild_extends_a_match(self):
        grid = grid_from_row(["A", "A", "WILD", "z", "z"])
        payout = resolve_spin(grid, LINES, PAYTABLE, 1.0, wild_symbol="WILD")
        self.assertEqual(payout, 1.0)  # A-A-WILD = 3x A

    def test_leading_wild_takes_the_identity_of_the_first_real_symbol(self):
        grid = grid_from_row(["WILD", "A", "A", "z", "z"])
        payout = resolve_spin(grid, LINES, PAYTABLE, 1.0, wild_symbol="WILD")
        self.assertEqual(payout, 1.0)  # WILD-A-A = 3x A

    def test_wild_break_by_a_different_symbol(self):
        grid = grid_from_row(["A", "WILD", "B", "A", "A"])
        payout = resolve_spin(grid, LINES, PAYTABLE, 1.0, wild_symbol="WILD")
        self.assertEqual(payout, 0.0)  # A-WILD counts as 2x A, then B breaks it (< min_match)

    def test_all_wild_line_pays_the_wild_symbols_own_entry(self):
        grid = grid_from_row(["WILD", "WILD", "WILD", "WILD", "WILD"])
        payout = resolve_spin(grid, LINES, PAYTABLE, 1.0, wild_symbol="WILD")
        self.assertEqual(payout, 200.0)

    def test_all_wild_line_with_no_wild_paytable_entry_pays_nothing(self):
        paytable = {"A": {3: 1, 4: 5, 5: 20}}  # no "WILD" entry
        grid = grid_from_row(["WILD", "WILD", "WILD", "WILD", "WILD"])
        payout = resolve_spin(grid, LINES, paytable, 1.0, wild_symbol="WILD")
        self.assertEqual(payout, 0.0)

    def test_bet_still_scales_a_wild_assisted_win(self):
        grid = grid_from_row(["A", "A", "WILD", "z", "z"])
        payout_1x = resolve_spin(grid, LINES, PAYTABLE, 1.0, wild_symbol="WILD")
        payout_3x = resolve_spin(grid, LINES, PAYTABLE, 3.0, wild_symbol="WILD")
        self.assertEqual(payout_3x, payout_1x * 3.0)


if __name__ == "__main__":
    unittest.main()
