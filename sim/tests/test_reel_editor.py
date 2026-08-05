import unittest

from sim.reel_editor import apply_reel_edit, symbol_tier_value

PAYTABLE = {
    "cherry": {3: 2, 4: 5, 5: 10},
    "lemon": {3: 2, 4: 5, 5: 10},
    "bell": {3: 4, 4: 10, 5: 25},
    "crown": {3: 60, 4: 150, 5: 400},
}


class TestSymbolTierValue(unittest.TestCase):
    def test_ranks_by_richest_defined_payout(self):
        self.assertLess(symbol_tier_value("cherry", PAYTABLE),
                         symbol_tier_value("bell", PAYTABLE))
        self.assertLess(symbol_tier_value("bell", PAYTABLE),
                         symbol_tier_value("crown", PAYTABLE))

    def test_symbol_not_in_paytable_is_cheapest(self):
        self.assertEqual(symbol_tier_value("unknown", PAYTABLE), 0.0)


class TestApplyReelEdit(unittest.TestCase):
    def test_strip_length_is_conserved(self):
        strip = ["cherry"] * 8 + ["lemon"] * 8 + ["bell"] * 6 + ["crown"] * 1
        edited = apply_reel_edit(strip, "crown", 3, PAYTABLE)
        self.assertEqual(len(edited), len(strip))

    def test_converts_the_cheapest_tier_present_first(self):
        strip = ["cherry"] * 2 + ["bell"] * 2
        edited = apply_reel_edit(strip, "crown", 2, PAYTABLE)
        # Both cherries (cheaper than bell) become crown; bells untouched.
        self.assertEqual(edited.count("crown"), 2)
        self.assertEqual(edited.count("cherry"), 0)
        self.assertEqual(edited.count("bell"), 2)

    def test_cascades_to_next_tier_once_cheapest_is_exhausted(self):
        strip = ["cherry"] * 2 + ["bell"] * 2
        edited = apply_reel_edit(strip, "crown", 3, PAYTABLE)
        # Both cherries converted (2), then one bell converted (3rd).
        self.assertEqual(edited.count("crown"), 3)
        self.assertEqual(edited.count("cherry"), 0)
        self.assertEqual(edited.count("bell"), 1)

    def test_never_converts_the_target_symbol_into_itself(self):
        strip = ["crown"] * 2 + ["cherry"] * 2
        edited = apply_reel_edit(strip, "crown", 1, PAYTABLE)
        self.assertEqual(edited.count("crown"), 3)
        self.assertEqual(edited.count("cherry"), 1)

    def test_stops_early_if_nothing_left_to_convert(self):
        strip = ["crown"] * 4
        edited = apply_reel_edit(strip, "crown", 5, PAYTABLE)
        self.assertEqual(edited, strip)

    def test_zero_quantity_is_a_pure_copy(self):
        strip = ["cherry", "bell", "crown"]
        edited = apply_reel_edit(strip, "crown", 0, PAYTABLE)
        self.assertEqual(edited, strip)
        self.assertIsNot(edited, strip)

    def test_zero_purchases_baseline_is_unchanged(self):
        # The whole point of D29: applying no edits at all reproduces the
        # exact starting strip.
        strip = ["cherry"] * 8 + ["lemon"] * 8
        self.assertEqual(apply_reel_edit(strip, "bell", 0, PAYTABLE), strip)


if __name__ == "__main__":
    unittest.main()
