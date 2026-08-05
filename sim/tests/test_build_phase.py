import random
import unittest

from sim.build_phase import (
    BuildPhase, WILD_SYMBOL, WILD_RELIC_ID, WILD_RELIC_COST, REEL_OFFER_COUNT,
)

PAYTABLE = {
    "cherry": {3: 2, 4: 5, 5: 10},
    "lemon": {3: 2, 4: 5, 5: 10},
    "crown": {3: 60, 4: 150, 5: 400},
}


def _reel_strips():
    return [["cherry", "cherry", "lemon", "lemon", "crown"] for _ in range(5)]


class TestShelf(unittest.TestCase):
    def test_wild_is_offered_when_not_owned(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        ids = [r.id for r in build.shelf()]
        self.assertIn(WILD_RELIC_ID, ids)

    def test_wild_disappears_from_the_shelf_once_bought(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        build.buy_relic(WILD_RELIC_ID)
        self.assertEqual(build.shelf(), [])


class TestBuyRelic(unittest.TestCase):
    def test_buying_wild_adds_it_to_owned_symbols_and_paytable(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        bought = build.buy_relic(WILD_RELIC_ID)
        self.assertTrue(bought)
        self.assertIn(WILD_SYMBOL, build.owned_symbols)
        self.assertIn(WILD_SYMBOL, build.paytable)
        self.assertEqual(build.wallet, 100.0 - WILD_RELIC_COST)

    def test_cannot_afford_relic_is_a_safe_noop(self):
        build = BuildPhase(wallet=5.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        bought = build.buy_relic(WILD_RELIC_ID)
        self.assertFalse(bought)
        self.assertEqual(build.wallet, 5.0)
        self.assertNotIn(WILD_SYMBOL, build.owned_symbols)

    def test_unknown_relic_id_is_a_safe_noop(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        self.assertFalse(build.buy_relic("not_a_real_relic"))
        self.assertEqual(build.wallet, 100.0)


class TestEditReel(unittest.TestCase):
    def test_cannot_edit_with_an_unowned_symbol(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        self.assertFalse(build.edit_reel(0, WILD_SYMBOL, 2))  # wild not bought yet
        self.assertEqual(build.wallet, 100.0)

    def test_owned_symbol_edit_spends_wallet_and_changes_the_reel(self):
        # "cherry" converts the (cheaper) lemons on this reel -- affordable
        # at this wallet, unlike the premium "crown" (covered separately).
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        wallet_before = build.wallet
        strip_before = list(build.reel_strips[0])

        edited = build.edit_reel(0, "cherry", 1)

        self.assertTrue(edited)
        self.assertLess(build.wallet, wallet_before)
        self.assertNotEqual(build.reel_strips[0], strip_before)
        self.assertEqual(len(build.reel_strips[0]), len(strip_before))  # D29: length conserved

    def test_other_reels_are_untouched(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        other_before = list(build.reel_strips[1])
        self.assertTrue(build.edit_reel(0, "cherry", 2))
        self.assertEqual(build.reel_strips[1], other_before)

    def test_cannot_afford_edit_is_a_safe_noop(self):
        build = BuildPhase(wallet=1.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        strip_before = list(build.reel_strips[0])
        self.assertFalse(build.edit_reel(0, "crown", 5))  # crown is expensive
        self.assertEqual(build.wallet, 1.0)
        self.assertEqual(build.reel_strips[0], strip_before)


class TestReelOffers(unittest.TestCase):
    def test_generates_the_configured_number_of_offers(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                            rng=random.Random(1))
        self.assertEqual(len(build.reel_offers()), REEL_OFFER_COUNT)

    def test_offers_only_draw_from_owned_symbols(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                            rng=random.Random(1))
        for offer in build.reel_offers():
            self.assertIn(offer.symbol, build.owned_symbols)

    def test_offer_reel_index_is_within_range(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                            rng=random.Random(1))
        for offer in build.reel_offers():
            self.assertGreaterEqual(offer.reel_index, 0)
            self.assertLess(offer.reel_index, len(build.reel_strips))

    def test_offer_cost_matches_reel_edit_cost_for_its_symbol(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                            rng=random.Random(1))
        for offer in build.reel_offers():
            self.assertEqual(offer.cost, build.reel_edit_cost(offer.symbol, offer.quantity))

    def test_deterministic_for_a_fixed_seed(self):
        build_a = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                              rng=random.Random(42))
        build_b = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                              rng=random.Random(42))
        offers_a = [(o.reel_index, o.symbol) for o in build_a.reel_offers()]
        offers_b = [(o.reel_index, o.symbol) for o in build_b.reel_offers()]
        self.assertEqual(offers_a, offers_b)

    def test_buying_an_offer_applies_the_edit_and_marks_it_bought(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                            rng=random.Random(1))
        offer = build.reel_offers()[0]
        strip_before = list(build.reel_strips[offer.reel_index])
        wallet_before = build.wallet

        bought = build.buy_reel_offer(0)

        self.assertTrue(bought)
        self.assertTrue(offer.bought)
        self.assertNotEqual(build.reel_strips[offer.reel_index], strip_before)
        self.assertEqual(build.wallet, wallet_before - offer.cost)

    def test_buying_an_already_bought_offer_is_a_noop(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                            rng=random.Random(1))
        self.assertTrue(build.buy_reel_offer(0))
        wallet_after_first_buy = build.wallet
        self.assertFalse(build.buy_reel_offer(0))
        self.assertEqual(build.wallet, wallet_after_first_buy)

    def test_buying_an_unaffordable_offer_is_a_safe_noop(self):
        build = BuildPhase(wallet=0.5, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                            rng=random.Random(1))
        self.assertFalse(build.buy_reel_offer(0))
        self.assertEqual(build.wallet, 0.5)

    def test_invalid_offer_index_is_a_safe_noop(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                            rng=random.Random(1))
        self.assertFalse(build.buy_reel_offer(-1))
        self.assertFalse(build.buy_reel_offer(REEL_OFFER_COUNT))
        self.assertEqual(build.wallet, 100.0)

    def test_buying_one_offer_leaves_the_others_untouched(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE),
                            rng=random.Random(1))
        build.buy_reel_offer(0)
        for offer in build.reel_offers()[1:]:
            self.assertFalse(offer.bought)


class TestLoadBankrollAndFinalize(unittest.TestCase):
    def test_spins_from_load_uses_min_bet(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(),
                            paytable=dict(PAYTABLE), min_bet=2.0)
        self.assertEqual(build.spins_from_load(20.0), 10.0)

    def test_load_bankroll_moves_wallet_into_loaded_bankroll(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        self.assertTrue(build.load_bankroll(60.0))
        self.assertEqual(build.wallet, 40.0)
        self.assertEqual(build.loaded_bankroll, 60.0)

    def test_cannot_load_more_than_the_wallet_holds(self):
        build = BuildPhase(wallet=10.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        self.assertFalse(build.load_bankroll(20.0))
        self.assertEqual(build.wallet, 10.0)

    def test_finalize_auto_converts_leftover_wallet_to_bankroll(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        build.load_bankroll(60.0)  # explicit load

        reel_strips, starting_bankroll, wild_symbol = build.finalize()

        self.assertEqual(starting_bankroll, 100.0)  # 60 loaded + 40 leftover, no waste
        self.assertIsNone(wild_symbol)

    def test_finalize_reports_wild_symbol_when_bought(self):
        build = BuildPhase(wallet=100.0, reel_strips=_reel_strips(), paytable=dict(PAYTABLE))
        build.buy_relic(WILD_RELIC_ID)
        _, _, wild_symbol = build.finalize()
        self.assertEqual(wild_symbol, WILD_SYMBOL)

    def test_zero_purchases_baseline_is_the_unmodified_starting_machine(self):
        strips = _reel_strips()
        build = BuildPhase(wallet=100.0, reel_strips=[list(s) for s in strips],
                            paytable=dict(PAYTABLE))
        reel_strips, starting_bankroll, wild_symbol = build.finalize()
        self.assertEqual(reel_strips, strips)
        self.assertEqual(starting_bankroll, 100.0)  # all wallet auto-converts
        self.assertIsNone(wild_symbol)


if __name__ == "__main__":
    unittest.main()
