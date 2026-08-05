import random
import unittest

from sim.config import EconomyConfig, MachineConfig, SimConfig, default_sim_config
from sim.stage import (
    NodeType,
    StageResult,
    default_node_sequence,
    run_stage,
    ELITE_BET_MULTIPLIER,
    TREASURE_WINNINGS_BONUS,
)
from sim.play_phase import Outcome
from sim.strategy import flat_min, flat_mid


def single_symbol_machine(symbol="A", num_reels=5, num_rows=1, paytable=None,
                           min_match=3):
    """Same deterministic fixture pattern as test_play_phase.py -- every
    reel strip is one symbol, so every spin is a guaranteed match and RNG
    plays no role in the outcome."""
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


class TestNodeBehavior(unittest.TestCase):
    def test_treasure_adds_winnings_without_consuming_a_spin(self):
        # Every real spin pays 0, so any winnings must have come from
        # TREASURE nodes, not the machine.
        machine = single_symbol_machine(paytable={"A": {5: 0.0}})
        economy = EconomyConfig(starting_bankroll=10.0, quota=1000.0,
                                 spin_cap=2, min_bet=1.0, max_bet=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)
        sequence = [NodeType.TREASURE, NodeType.MINOR]

        result = run_stage(sim_config, sequence, flat_min, random.Random(0))

        self.assertEqual(result.spins_used, 2)  # only MINOR nodes consumed the cap
        self.assertEqual(result.final_winnings, 2 * TREASURE_WINNINGS_BONUS)
        self.assertEqual(result.nodes_visited.count(NodeType.TREASURE), 2)

    def test_elite_forces_a_bigger_bet_than_the_strategy_chose(self):
        # flat_min always asks for min_bet; on an ELITE node the actual
        # spend must be inflated by ELITE_BET_MULTIPLIER.
        machine = single_symbol_machine(paytable={"A": {5: 0.0}})
        economy = EconomyConfig(starting_bankroll=100.0, quota=1000.0,
                                 spin_cap=1, min_bet=2.0, max_bet=2.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_stage(sim_config, [NodeType.ELITE], flat_min, random.Random(0))

        self.assertEqual(result.final_bankroll,
                          100.0 - 2.0 * ELITE_BET_MULTIPLIER)

    def test_elite_bet_is_clamped_to_available_bankroll(self):
        # min_bet=2.0 * ELITE_BET_MULTIPLIER (1.25) = 2.5, more than the
        # 2.0 bankroll actually holds -- must clamp, not overdraw.
        machine = single_symbol_machine(paytable={"A": {5: 0.0}})
        economy = EconomyConfig(starting_bankroll=2.0, quota=1000.0,
                                 spin_cap=1, min_bet=2.0, max_bet=2.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_stage(sim_config, [NodeType.ELITE], flat_min, random.Random(0))

        self.assertEqual(result.final_bankroll, 0.0)

    def test_event_and_rest_nodes_are_a_no_op_turn(self):
        machine = single_symbol_machine(paytable={"A": {5: 0.0}})
        economy = EconomyConfig(starting_bankroll=10.0, quota=1000.0,
                                 spin_cap=1, min_bet=1.0, max_bet=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)
        sequence = [NodeType.EVENT, NodeType.REST, NodeType.MINOR]

        result = run_stage(sim_config, sequence, flat_min, random.Random(0))

        self.assertEqual(result.spins_used, 1)
        self.assertEqual(result.final_bankroll, 9.0)
        self.assertIn(NodeType.EVENT, result.nodes_visited)
        self.assertIn(NodeType.REST, result.nodes_visited)


class TestDualLimiterStillGoverns(unittest.TestCase):
    def test_bust_when_bankroll_runs_out_before_quota(self):
        machine = single_symbol_machine(paytable={"A": {5: 0.0}})
        economy = EconomyConfig(starting_bankroll=10.0, quota=1000.0,
                                 spin_cap=1000, min_bet=2.0, max_bet=2.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_stage(sim_config, [NodeType.MINOR], flat_min, random.Random(0))

        self.assertEqual(result.outcome, Outcome.BUST)
        self.assertEqual(result.final_bankroll, 0.0)

    def test_out_of_spins_when_cap_hits_before_quota(self):
        machine = single_symbol_machine(paytable={"A": {5: 0.5}})
        economy = EconomyConfig(starting_bankroll=1000.0, quota=1000.0,
                                 spin_cap=3, min_bet=1.0, max_bet=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_stage(sim_config, [NodeType.MINOR], flat_min, random.Random(0))

        self.assertEqual(result.outcome, Outcome.OUT_OF_SPINS)
        self.assertEqual(result.spins_used, 3)

    def test_win_when_quota_is_cleared(self):
        machine = single_symbol_machine(paytable={"A": {5: 100.0}})
        economy = EconomyConfig(starting_bankroll=1.0, quota=50.0,
                                 spin_cap=1000, min_bet=1.0, max_bet=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        result = run_stage(sim_config, [NodeType.MINOR], flat_min, random.Random(0))

        self.assertEqual(result.outcome, Outcome.WIN)
        self.assertGreaterEqual(result.final_winnings, 50.0)

    def test_node_sequence_cycles_and_never_runs_out(self):
        # A short sequence over a long spin cap must keep cycling -- the
        # stage can only end via the dual limiter, never "out of nodes".
        machine = single_symbol_machine(paytable={"A": {5: 0.1}})
        economy = EconomyConfig(starting_bankroll=1000.0, quota=1000.0,
                                 spin_cap=20, min_bet=1.0, max_bet=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)
        sequence = [NodeType.MINOR, NodeType.TREASURE]  # length 2, cap needs 20 spins

        result = run_stage(sim_config, sequence, flat_min, random.Random(0))

        self.assertEqual(result.outcome, Outcome.OUT_OF_SPINS)
        self.assertEqual(result.spins_used, 20)
        # 20 MINOR (hits the cap) + 19 TREASURE (the limiter check fires
        # before the 20th TREASURE would be appended).
        self.assertEqual(len(result.nodes_visited), 39)

    def test_deterministic_for_a_fixed_seed(self):
        sim_config = default_sim_config(seed=42)
        sequence = default_node_sequence()

        result_a = run_stage(sim_config, sequence, flat_mid, random.Random(42))
        result_b = run_stage(sim_config, sequence, flat_mid, random.Random(42))

        self.assertEqual(result_a.outcome, result_b.outcome)
        self.assertEqual(result_a.spins_used, result_b.spins_used)
        self.assertEqual(result_a.final_winnings, result_b.final_winnings)


class TestTensionBandHolds(unittest.TestCase):
    def test_default_node_sequence_stays_in_the_40_60_band(self):
        # D12's exit criterion, re-verified for the stage path: ELITE and
        # TREASURE add pacing variety (D31) without breaking the tension
        # band the flat economy was tuned to hit. See the tuning note
        # above ELITE_BET_MULTIPLIER/TREASURE_WINNINGS_BONUS in stage.py.
        cfg = default_sim_config(seed=1)
        sequence = default_node_sequence()
        runs = 3000

        wins = sum(
            1 for i in range(runs)
            if run_stage(cfg, sequence, flat_mid, random.Random(1000 + i)).outcome
            == Outcome.WIN
        )
        win_rate = wins / runs

        self.assertGreaterEqual(win_rate, 0.40)
        self.assertLessEqual(win_rate, 0.60)


if __name__ == "__main__":
    unittest.main()
