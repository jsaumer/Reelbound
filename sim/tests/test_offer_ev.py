import unittest

from sim.config import default_sim_config
from sim.odds import (theoretical_rtp, theoretical_rtp_exact, rtp_delta_for_edit,
                       offer_ev, expected_line_multiplier)
from sim.reel_editor import apply_reel_edit
from sim.build_phase import WILD_SYMBOL, WILD_PAYTABLE_ENTRY


def _default_machine():
    cfg = default_sim_config()
    return cfg.machine.reel_strips, cfg.machine.paylines, cfg.machine.paytable


class TestExactRtp(unittest.TestCase):
    def test_matches_the_analytic_rtp_on_a_wild_free_machine(self):
        strips, lines, paytable = _default_machine()
        self.assertAlmostEqual(theoretical_rtp_exact(strips, lines, paytable),
                                theoretical_rtp(strips, lines, paytable), places=9)

    def test_wild_substitution_raises_rtp_over_treating_wild_as_a_plain_symbol(self):
        strips, lines, paytable = _default_machine()
        paytable = dict(paytable)
        paytable[WILD_SYMBOL] = dict(WILD_PAYTABLE_ENTRY)
        strips = [list(s) for s in strips]
        strips[0] = apply_reel_edit(strips[0], WILD_SYMBOL, 1, paytable)

        as_plain = theoretical_rtp_exact(strips, lines, paytable, wild_symbol=None)
        as_wild = theoretical_rtp_exact(strips, lines, paytable, wild_symbol=WILD_SYMBOL)

        self.assertGreater(as_wild, as_plain)

    def test_deterministic_across_repeat_calls(self):
        strips, lines, paytable = _default_machine()
        self.assertEqual(theoretical_rtp_exact(strips, lines, paytable),
                          theoretical_rtp_exact(strips, lines, paytable))

    def test_line_multiplier_scales_linearly_with_payline_count(self):
        strips, lines, paytable = _default_machine()
        per_line = expected_line_multiplier(strips, paytable)
        self.assertAlmostEqual(theoretical_rtp_exact(strips, lines, paytable),
                                per_line * len(lines), places=12)


class TestRtpDeltaForEdit(unittest.TestCase):
    def test_left_anchoring_makes_reel_position_matter(self):
        # A wild added to reel 0 helps every developing line; on the last
        # reel it only ever matters to full-length matches. Same purchase
        # price today (D34) -- very different value.
        strips, lines, paytable = _default_machine()
        paytable = dict(paytable)
        paytable[WILD_SYMBOL] = dict(WILD_PAYTABLE_ENTRY)

        delta_first = rtp_delta_for_edit(strips, lines, paytable, 0, WILD_SYMBOL, 1,
                                          wild_symbol=WILD_SYMBOL)
        delta_last = rtp_delta_for_edit(strips, lines, paytable, 4, WILD_SYMBOL, 1,
                                         wild_symbol=WILD_SYMBOL)

        self.assertGreater(delta_first, delta_last)

    def test_a_single_crown_copy_is_rtp_negative(self):
        # Pins the 2026-08-05 Phase-4.5 finding: the fixed-slot swap
        # removes a frequent cheap symbol (breaking its common lines) to
        # add one copy of a symbol too rare on the other reels to form
        # lines -- net NEGATIVE RTP before cost even enters. The value of
        # top-tier purchases lives in cross-reel accumulation, not single
        # copies; if a paytable/pricing rework ever makes single copies
        # positive, this test should be revisited deliberately.
        strips, lines, paytable = _default_machine()
        delta = rtp_delta_for_edit(strips, lines, paytable, 0, "crown", 1)
        self.assertLess(delta, 0.0)

    def test_wild_beats_crown_on_the_same_reel(self):
        strips, lines, paytable = _default_machine()
        paytable = dict(paytable)
        paytable[WILD_SYMBOL] = dict(WILD_PAYTABLE_ENTRY)

        delta_wild = rtp_delta_for_edit(strips, lines, paytable, 0, WILD_SYMBOL, 1,
                                         wild_symbol=WILD_SYMBOL)
        delta_crown = rtp_delta_for_edit(strips, lines, paytable, 0, "crown", 1,
                                          wild_symbol=WILD_SYMBOL)

        self.assertGreater(delta_wild, delta_crown)

    def test_the_edit_is_hypothetical_and_leaves_the_strips_untouched(self):
        strips, lines, paytable = _default_machine()
        before = [list(s) for s in strips]
        rtp_delta_for_edit(strips, lines, paytable, 0, "crown", 1)
        self.assertEqual(strips, before)


class TestOfferEv(unittest.TestCase):
    def test_positive_when_the_gain_outruns_the_cost(self):
        self.assertAlmostEqual(offer_ev(0.5, 100.0, 33.3), 16.7, places=9)

    def test_negative_when_it_does_not(self):
        self.assertLess(offer_ev(0.1, 90.0, 33.3), 0.0)


if __name__ == "__main__":
    unittest.main()
