import unittest

from sim.config import EconomyConfig, MachineConfig, SimConfig
from sim.play_phase import Outcome, run_play_phase
from sim.strategy import flat_min, never_gamble, always_gamble, gamble_while_behind


def _single_symbol_machine(symbol="A", num_reels=5, num_rows=1, paytable=None):
    reel_strips = [[symbol] for _ in range(num_reels)]
    paylines = [tuple(0 for _ in range(num_reels))]
    if paytable is None:
        paytable = {symbol: {num_reels: 1.0}}
    return MachineConfig(num_rows=num_rows, reel_strips=reel_strips,
                          paylines=paylines, paytable=paytable, min_match=3)


class _ScriptedRNG:
    """A stub RNG for deterministic gamble-flip tests: .randrange always
    returns 0 (fine for the length-1 strips used by _single_symbol_machine),
    .random() pops pre-scripted coin-flip values in order."""

    def __init__(self, gamble_values):
        self._gamble_values = list(gamble_values)

    def randrange(self, n):
        return 0

    def random(self):
        return self._gamble_values.pop(0)


def _gamble_once_then_bank():
    """A one-shot gamble strategy: presses exactly once, then always banks."""
    state = {"gambled": False}

    def strategy(pending, winnings, economy):
        if not state["gambled"]:
            state["gambled"] = True
            return True
        return False

    return strategy


class TestGambleUp(unittest.TestCase):
    def test_never_gamble_matches_old_auto_commit_behavior(self):
        machine = _single_symbol_machine(paytable={"A": {5: 10.0}})
        economy = EconomyConfig(starting_bankroll=100.0, quota=1000.0,
                                 spin_cap=1, min_bet=1.0, max_bet=1.0,
                                 gamble_offer_probability=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        # First value is the offer-appears roll (any value < 1.0 passes);
        # never_gamble then banks immediately regardless.
        result = run_play_phase(sim_config, flat_min, _ScriptedRNG([0.0]),
                                 gamble_strategy=never_gamble)

        self.assertEqual(result.final_winnings, 10.0)
        self.assertEqual(result.winnings_deltas, [10.0])

    def test_offer_not_appearing_auto_banks(self):
        machine = _single_symbol_machine(paytable={"A": {5: 10.0}})
        economy = EconomyConfig(starting_bankroll=100.0, quota=1000.0,
                                 spin_cap=1, min_bet=1.0, max_bet=1.0,
                                 gamble_offer_probability=0.25)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        # 0.9 >= 0.25 gamble_offer_probability -- offer never appears, even
        # with always_gamble as the strategy the player would have used.
        rng = _ScriptedRNG([0.9])
        result = run_play_phase(sim_config, flat_min, rng,
                                 gamble_strategy=always_gamble)

        self.assertEqual(result.final_winnings, 10.0)

    def test_gamble_win_then_bank_doubles_the_win(self):
        machine = _single_symbol_machine(paytable={"A": {5: 10.0}})
        economy = EconomyConfig(starting_bankroll=100.0, quota=1000.0,
                                 spin_cap=1, min_bet=1.0, max_bet=1.0,
                                 gamble_offer_probability=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        # 0.0: offer appears. 0.1 < 0.5 gamble_win_probability -> win.
        rng = _ScriptedRNG([0.0, 0.1])
        result = run_play_phase(sim_config, flat_min, rng,
                                 gamble_strategy=_gamble_once_then_bank())

        self.assertEqual(result.final_winnings, 20.0)

    def test_gamble_loss_forfeits_the_entire_win(self):
        machine = _single_symbol_machine(paytable={"A": {5: 10.0}})
        economy = EconomyConfig(starting_bankroll=100.0, quota=1000.0,
                                 spin_cap=1, min_bet=1.0, max_bet=1.0,
                                 gamble_offer_probability=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        # 0.0: offer appears. Then win once (double), then lose (forfeit).
        rng = _ScriptedRNG([0.0, 0.1, 0.9])
        result = run_play_phase(sim_config, flat_min, rng,
                                 gamble_strategy=always_gamble)

        self.assertEqual(result.final_winnings, 0.0)
        self.assertEqual(result.winnings_deltas, [0.0])

    def test_gambling_never_touches_bankroll(self):
        machine = _single_symbol_machine(paytable={"A": {5: 10.0}})
        economy = EconomyConfig(starting_bankroll=100.0, quota=1000.0,
                                 spin_cap=1, min_bet=1.0, max_bet=1.0,
                                 gamble_offer_probability=1.0)
        sim_config = SimConfig(machine=machine, economy=economy, seed=1)

        rng = _ScriptedRNG([0.0, 0.1, 0.9])
        result = run_play_phase(sim_config, flat_min, rng,
                                 gamble_strategy=always_gamble)

        self.assertEqual(result.final_bankroll, 99.0)  # 100 - 1 bet, win or lose


class TestGambleWhileBehindStrategy(unittest.TestCase):
    def test_presses_when_banking_would_not_clear_quota(self):
        economy = EconomyConfig(starting_bankroll=100.0, quota=50.0, spin_cap=10,
                                 min_bet=1.0, max_bet=1.0)
        self.assertTrue(gamble_while_behind(pending=10.0, winnings=20.0, economy=economy))

    def test_banks_once_it_would_clear_the_quota(self):
        economy = EconomyConfig(starting_bankroll=100.0, quota=50.0, spin_cap=10,
                                 min_bet=1.0, max_bet=1.0)
        self.assertFalse(gamble_while_behind(pending=30.0, winnings=20.0, economy=economy))


if __name__ == "__main__":
    unittest.main()
