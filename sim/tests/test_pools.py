import unittest

from sim.pools import Pools


class TestPools(unittest.TestCase):
    def test_spend_from_bankroll_decreases_bankroll(self):
        pools = Pools(bankroll=100.0)
        pools.spend_from_bankroll(30.0)
        self.assertEqual(pools.bankroll, 70.0)

    def test_spend_more_than_bankroll_raises(self):
        pools = Pools(bankroll=10.0)
        with self.assertRaises(ValueError):
            pools.spend_from_bankroll(10.01)

    def test_spend_negative_amount_raises(self):
        pools = Pools(bankroll=10.0)
        with self.assertRaises(ValueError):
            pools.spend_from_bankroll(-1.0)

    def test_pending_commits_fully_into_winnings(self):
        pools = Pools(bankroll=100.0)
        pools.add_to_pending(25.0)
        pools.commit_pending_to_winnings()
        self.assertEqual(pools.winnings, 25.0)
        self.assertEqual(pools.pending, 0.0)

    def test_bankroll_only_ever_drains_across_many_spins(self):
        # D3: bankroll never receives a payout, no matter how large.
        pools = Pools(bankroll=50.0)
        bankroll_history = [pools.bankroll]
        for bet, payout in [(5, 0), (5, 40), (5, 0), (5, 100), (5, 0)]:
            pools.spend_from_bankroll(bet)
            pools.add_to_pending(payout)
            pools.commit_pending_to_winnings()
            bankroll_history.append(pools.bankroll)

        for earlier, later in zip(bankroll_history, bankroll_history[1:]):
            self.assertLessEqual(later, earlier)
        self.assertEqual(pools.bankroll, 25.0)  # 50 - 5*5, unaffected by wins
        self.assertEqual(pools.winnings, 140.0)  # 0 + 40 + 100

    def test_winnings_never_decreases(self):
        pools = Pools(bankroll=100.0)
        winnings_history = [pools.winnings]
        for payout in [10, 0, 5, 0, 0]:
            pools.spend_from_bankroll(1.0)
            pools.add_to_pending(payout)
            pools.commit_pending_to_winnings()
            winnings_history.append(pools.winnings)

        for earlier, later in zip(winnings_history, winnings_history[1:]):
            self.assertGreaterEqual(later, earlier)

    def test_double_pending_only_affects_pending(self):
        pools = Pools(bankroll=100.0)
        pools.add_to_pending(15.0)
        pools.double_pending()
        self.assertEqual(pools.pending, 30.0)
        self.assertEqual(pools.bankroll, 100.0)
        self.assertEqual(pools.winnings, 0.0)

    def test_forfeit_pending_zeroes_pending_without_touching_bankroll(self):
        # Baseline gamble-up loss: the pending win vanishes, it does not
        # drain bankroll (that's the "Hedged Gamble" boon, not baseline).
        pools = Pools(bankroll=100.0)
        pools.add_to_pending(15.0)
        pools.double_pending()
        pools.forfeit_pending()
        self.assertEqual(pools.pending, 0.0)
        self.assertEqual(pools.bankroll, 100.0)
        self.assertEqual(pools.winnings, 0.0)

    def test_pools_has_no_way_to_credit_bankroll(self):
        # Structural guard on D3: the only public methods on Pools must not
        # be able to increase bankroll.
        public_methods = [
            name for name in dir(Pools)
            if not name.startswith("_") and callable(getattr(Pools, name))
        ]
        self.assertEqual(
            set(public_methods),
            {"spend_from_bankroll", "add_to_pending", "commit_pending_to_winnings",
             "double_pending", "forfeit_pending"},
        )


if __name__ == "__main__":
    unittest.main()
