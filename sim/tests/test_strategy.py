import unittest

from sim.config import EconomyConfig
from sim.strategy import adaptive_throttle


class TestAdaptiveThrottle(unittest.TestCase):
    def test_bets_max_when_spin_cap_is_the_tighter_clock(self):
        # bankroll=100, min_bet=1 -> 100 spins of runway, far more than
        # the 10 spins actually remaining -- spin cap binds, so throttle up.
        economy = EconomyConfig(starting_bankroll=100.0, quota=1000.0, spin_cap=50,
                                 min_bet=1.0, max_bet=3.0)
        bet = adaptive_throttle(bankroll=100.0, economy=economy,
                                 spins_remaining=10, winnings=0.0)
        self.assertEqual(bet, economy.max_bet)

    def test_bets_min_when_bankroll_is_the_tighter_clock(self):
        # bankroll=5, min_bet=1 -> only 5 spins of runway, fewer than the
        # 40 spins remaining -- bankroll binds, so ease off to stretch it.
        economy = EconomyConfig(starting_bankroll=100.0, quota=1000.0, spin_cap=50,
                                 min_bet=1.0, max_bet=3.0)
        bet = adaptive_throttle(bankroll=5.0, economy=economy,
                                 spins_remaining=40, winnings=0.0)
        self.assertEqual(bet, economy.min_bet)


if __name__ == "__main__":
    unittest.main()
