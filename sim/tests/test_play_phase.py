import random
import unittest

from sim.config import EconomyConfig, MachineConfig, SimConfig
from sim.play_phase import Outcome, run_play_phase
from sim.strategy import flat_min, flat_mid


def single_symbol_machine(symbol="A", num_reels=5, num_rows=1, paytable=None,
                           min_match=3):
    """A machine whose every reel strip is just one symbol, so every spin is
    a guaranteed, deterministic match -- removes RNG from the test."""
    reel_strips = [[symbol] for _ in range(num_reels)]
    paylines = [tuple(0 for _ in range(num_reels))]
    if paytable is None:
        paytable = {symbol: {num_reels: 1.0}}
    return MachineConfig(
        num_rows=num_rows,
        reel_strips=reel_strips,
        paylines=paylines,
        paytable=paytable,
        min_match=min_match,
    )


class TestDualLimiter(unittest.TestCase):
    def test_bust_when_bankroll_runs_out_before_quota(self):
        # Every spin pays 0 -- bankroll drains to zero with winnings still 0.
        machine = single_symbol_machine(paytable={"A": {5: 0.0}})
        economy = EconomyConfig(starting_bankroll=10.0, quota=1000.0,
                                 spin_cap=1000, min_bet=2.0, max_bet=2.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_play_phase(sim_config, flat_min, random.Random(0))

        self.assertEqual(result.outcome, Outcome.BUST)
        self.assertEqual(result.spins_used, 5)  # 10 / 2
        self.assertEqual(result.final_winnings, 0.0)
        self.assertEqual(result.final_bankroll, 0.0)

    def test_out_of_spins_when_cap_hits_before_quota(self):
        # Every spin pays back less than the bet, so bankroll survives past
        # the (low) spin cap while winnings never reach the (high) quota.
        machine = single_symbol_machine(paytable={"A": {5: 0.5}})
        economy = EconomyConfig(starting_bankroll=1000.0, quota=1000.0,
                                 spin_cap=3, min_bet=1.0, max_bet=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_play_phase(sim_config, flat_min, random.Random(0))

        self.assertEqual(result.outcome, Outcome.OUT_OF_SPINS)
        self.assertEqual(result.spins_used, 3)
        self.assertEqual(result.final_winnings, 1.5)  # 3 spins * 0.5
        self.assertGreater(result.final_bankroll, 0.0)

    def test_win_when_quota_cleared_before_either_limiter(self):
        # Every spin pays far more than the bet -- quota clears in one spin.
        machine = single_symbol_machine(paytable={"A": {5: 100.0}})
        economy = EconomyConfig(starting_bankroll=50.0, quota=50.0,
                                 spin_cap=1000, min_bet=1.0, max_bet=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_play_phase(sim_config, flat_min, random.Random(0))

        self.assertEqual(result.outcome, Outcome.WIN)
        self.assertEqual(result.spins_used, 1)
        self.assertEqual(result.final_winnings, 100.0)

    def test_bankroll_never_increases_over_a_run(self):
        machine = single_symbol_machine(paytable={"A": {5: 0.5}})
        economy = EconomyConfig(starting_bankroll=20.0, quota=1000.0,
                                 spin_cap=1000, min_bet=3.0, max_bet=3.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_play_phase(sim_config, flat_min, random.Random(0))

        # Bust happens once bankroll can't cover the next bet; winnings
        # racked up along the way must never have topped up the bankroll.
        self.assertEqual(result.outcome, Outcome.BUST)
        self.assertLess(result.final_bankroll, economy.starting_bankroll)
        self.assertGreater(result.final_winnings, 0.0)

    def test_deterministic_for_a_fixed_seed(self):
        from sim.config import default_sim_config

        sim_config = default_sim_config(seed=42)
        result_a = run_play_phase(sim_config, flat_mid, random.Random(42))
        result_b = run_play_phase(sim_config, flat_mid, random.Random(42))

        self.assertEqual(result_a.outcome, result_b.outcome)
        self.assertEqual(result_a.spins_used, result_b.spins_used)
        self.assertEqual(result_a.final_winnings, result_b.final_winnings)
        self.assertEqual(result_a.payouts, result_b.payouts)


if __name__ == "__main__":
    unittest.main()
