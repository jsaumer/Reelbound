import unittest

from sim.paytable import resolve_spin


PAYTABLE = {
    "A": {3: 1, 4: 5, 5: 20},
    "B": {3: 2, 4: 8, 5: 30},
}
LINES = [
    (0, 0, 0, 0, 0),  # top row
    (1, 1, 1, 1, 1),  # middle row
]


def grid_from_rows(rows):
    """rows: list of per-reel symbol lists (row-major -> convert to
    grid[reel][row])."""
    num_reels = len(rows[0])
    num_rows = len(rows)
    return [[rows[row][reel] for row in range(num_rows)] for reel in range(num_reels)]


class TestResolveSpin(unittest.TestCase):
    def test_no_match_pays_nothing(self):
        grid = grid_from_rows([
            ["A", "B", "A", "B", "A"],
            ["x", "x", "x", "x", "x"],
        ])
        self.assertEqual(resolve_spin(grid, LINES, PAYTABLE, bet=1.0), 0.0)

    def test_below_min_match_pays_nothing(self):
        # top row: A A x x x -- only 2 in a row, below min_match=3
        grid = grid_from_rows([
            ["A", "A", "x", "x", "x"],
            ["y", "y", "y", "y", "y"],  # y isn't in paytable
        ])
        self.assertEqual(resolve_spin(grid, LINES, PAYTABLE, bet=1.0), 0.0)

    def test_exact_three_match_pays_three_entry(self):
        grid = grid_from_rows([
            ["A", "A", "A", "z", "z"],
            ["q", "q", "q", "q", "q"],  # not in paytable
        ])
        self.assertEqual(resolve_spin(grid, LINES, PAYTABLE, bet=1.0), 1.0)

    def test_five_match_pays_five_entry(self):
        grid = grid_from_rows([
            ["B", "B", "B", "B", "B"],
            ["q", "q", "q", "q", "q"],
        ])
        self.assertEqual(resolve_spin(grid, LINES, PAYTABLE, bet=1.0), 30.0)

    def test_match_must_be_left_anchored(self):
        # top row: z A A A A -- the run of A's doesn't start at reel 0
        grid = grid_from_rows([
            ["z", "A", "A", "A", "A"],
            ["q", "q", "q", "q", "q"],
        ])
        self.assertEqual(resolve_spin(grid, LINES, PAYTABLE, bet=1.0), 0.0)

    def test_multiple_winning_lines_sum(self):
        grid = grid_from_rows([
            ["A", "A", "A", "z", "z"],   # top: A x3 -> pays 1
            ["B", "B", "B", "B", "z"],   # middle: B x4 -> pays 8
        ])
        self.assertEqual(resolve_spin(grid, LINES, PAYTABLE, bet=1.0), 9.0)

    def test_bet_scales_payout_linearly(self):
        grid = grid_from_rows([
            ["A", "A", "A", "z", "z"],
            ["q", "q", "q", "q", "q"],
        ])
        payout_1x = resolve_spin(grid, LINES, PAYTABLE, bet=1.0)
        payout_3x = resolve_spin(grid, LINES, PAYTABLE, bet=3.0)
        self.assertEqual(payout_3x, payout_1x * 3.0)

    def test_symbol_not_in_paytable_pays_nothing(self):
        grid = grid_from_rows([
            ["q", "q", "q", "q", "q"],
            ["z", "z", "z", "z", "z"],
        ])
        self.assertEqual(resolve_spin(grid, LINES, PAYTABLE, bet=1.0), 0.0)


if __name__ == "__main__":
    unittest.main()
