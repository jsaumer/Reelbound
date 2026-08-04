import random
import unittest

from sim.config import EconomyConfig, MachineConfig, SimConfig
from sim.play_phase import Outcome, run_play_phase
from sim.strategy import (flat_min, always_keep_playing, always_cash_out,
                           cash_out_near_the_end)


def _single_symbol_machine(symbol="A", num_reels=5, num_rows=1, paytable=None):
    reel_strips = [[symbol] for _ in range(num_reels)]
    paylines = [tuple(0 for _ in range(num_reels))]
    if paytable is None:
        paytable = {symbol: {num_reels: 1.0}}
    return MachineConfig(num_rows=num_rows, reel_strips=reel_strips,
                          paylines=paylines, paytable=paytable, min_match=3)


class TestQuotaClearedNoRunway(unittest.TestCase):
    def test_no_runway_left_ends_as_win_without_a_choice(self):
        # spin_cap reached in the same spin that clears quota -- nothing
        # left to decide, no bonus offered.
        machine = _single_symbol_machine(paytable={"A": {5: 100.0}})
        economy = EconomyConfig(starting_bankroll=100.0, quota=50.0,
                                 spin_cap=1, min_bet=1.0, max_bet=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_play_phase(sim_config, flat_min, random.Random(0),
                                 continuation_strategy=always_keep_playing)

        self.assertEqual(result.outcome, Outcome.WIN)
        self.assertEqual(result.spins_used, 1)
        self.assertFalse(result.cashed_out)
        self.assertEqual(result.cash_out_bonus, 0.0)
        self.assertEqual(result.final_winnings, 100.0)  # no bonus applied


class TestCashOutNeverBusts(unittest.TestCase):
    def test_bankroll_hitting_zero_after_quota_clear_is_still_a_win(self):
        machine = _single_symbol_machine(paytable={"A": {5: 10.0}})
        economy = EconomyConfig(starting_bankroll=5.0, quota=5.0,
                                 spin_cap=1000, min_bet=1.0, max_bet=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_play_phase(sim_config, flat_min, random.Random(0),
                                 continuation_strategy=always_keep_playing)

        self.assertEqual(result.outcome, Outcome.WIN)
        self.assertEqual(result.final_bankroll, 0.0)


class TestCashOutNearTheEndStrategy(unittest.TestCase):
    def test_keeps_playing_with_meaningful_runway(self):
        economy = EconomyConfig(starting_bankroll=100.0, quota=50.0, spin_cap=100,
                                 min_bet=1.0, max_bet=1.0)
        self.assertTrue(cash_out_near_the_end(
            spins_remaining=10, avg_winnings_per_spin=5.0, cash_out_value=20.0,
            pools=None, economy=economy))

    def test_cashes_out_near_the_end(self):
        economy = EconomyConfig(starting_bankroll=100.0, quota=50.0, spin_cap=100,
                                 min_bet=1.0, max_bet=1.0)
        self.assertFalse(cash_out_near_the_end(
            spins_remaining=2, avg_winnings_per_spin=5.0, cash_out_value=4.0,
            pools=None, economy=economy))


if __name__ == "__main__":
    unittest.main()
