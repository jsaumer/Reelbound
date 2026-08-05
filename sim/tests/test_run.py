import random
import unittest

from sim.config import default_machine_config
from sim.play_phase import Outcome
from sim.run import (RunConfig, run_run, run_many_runs, hoard, buy_n,
                      QUOTA_CURVES, flat_quota, linear_quota, geometric_quota,
                      wallet_ratio_quota)
from sim.strategy import flat_mid


class TestQuotaCurves(unittest.TestCase):
    def test_flat_ignores_stage_and_wallet(self):
        curve = flat_quota(65.0)
        self.assertEqual(curve(0, 100.0), 65.0)
        self.assertEqual(curve(7, 500.0), 65.0)

    def test_linear_steps_per_stage(self):
        curve = linear_quota(65.0, 10.0)
        self.assertEqual(curve(0, 100.0), 65.0)
        self.assertEqual(curve(3, 100.0), 95.0)

    def test_geometric_compounds(self):
        curve = geometric_quota(65.0, 1.25)
        self.assertAlmostEqual(curve(2, 100.0), 65.0 * 1.25 ** 2)

    def test_wallet_ratio_tracks_the_wallet(self):
        curve = wallet_ratio_quota(0.65)
        self.assertAlmostEqual(curve(0, 100.0), 65.0)
        self.assertAlmostEqual(curve(5, 200.0), 130.0)


class TestRunLoop(unittest.TestCase):
    def _run(self, seed=1, **kwargs):
        config = RunConfig(**kwargs)
        return run_run(config, hoard, flat_mid, random.Random(seed))

    def test_wallet_cycles_winnings_between_stages(self):
        result = self._run(seed=3)
        for prev, nxt in zip(result.records, result.records[1:]):
            self.assertEqual(nxt.wallet_before, prev.result.final_winnings)

    def test_run_ends_at_the_first_failed_stage(self):
        result = self._run(seed=1)
        if result.won:
            self.assertEqual(result.stages_cleared, 8)
            self.assertEqual(len(result.records), 8)
        else:
            self.assertEqual(len(result.records), result.stages_cleared + 1)
            self.assertNotEqual(result.records[-1].result.outcome, Outcome.WIN)
            for record in result.records[:-1]:
                self.assertEqual(record.result.outcome, Outcome.WIN)

    def test_quota_follows_the_curve(self):
        result = self._run(seed=2, quota_curve=QUOTA_CURVES["linear+10"])
        for record in result.records:
            self.assertAlmostEqual(record.quota, 65.0 + 10.0 * record.stage_index)

    def test_hoard_never_spends_on_the_machine(self):
        result = self._run(seed=4)
        for record in result.records:
            self.assertEqual(record.spent_on_machine, 0.0)
            self.assertEqual(record.starting_bankroll, record.wallet_before)
            self.assertAlmostEqual(record.machine_rtp_delta, 0.0, places=12)

    def test_deterministic_for_a_fixed_seed(self):
        a = self._run(seed=42)
        b = self._run(seed=42)
        self.assertEqual(a.won, b.won)
        self.assertEqual(a.stages_cleared, b.stages_cleared)
        self.assertEqual(a.final_wallet, b.final_wallet)

    def test_the_run_economy_is_dissipative_without_clear_income(self):
        # THE Phase-4.5 macro finding (2026-08-05), pinned: even at a
        # quota of 1.0 -- impossible to meaningfully fail -- most runs
        # die before stage 8, because every stage force-converts the
        # wallet through a sub-1.0-RTP machine and burns leftover
        # bankroll (wallet decays ~x0.886/stage). If a design change
        # (stage-clear income, carried bankroll, RTP>1 builds) ever makes
        # this pass differently, that's D22 progress -- revisit
        # deliberately, don't "fix" this test.
        results = [self._run(seed=6000 + i, quota_curve=flat_quota(1.0))
                    for i in range(40)]
        full_clears = sum(1 for r in results if r.won)
        self.assertLess(full_clears, len(results))

        stage3_wallets = [r.records[2].wallet_before for r in results
                           if len(r.records) > 2]
        self.assertTrue(stage3_wallets)
        mean_stage3 = sum(stage3_wallets) / len(stage3_wallets)
        self.assertLess(mean_stage3, 80.0)  # well below the 100 start

    def test_clear_bonus_income_counters_the_decay(self):
        # The experimental lever works: enough per-stage income makes the
        # same trivial-quota runs survivable.
        results = [self._run(seed=6000 + i, quota_curve=flat_quota(1.0),
                              clear_bonus=lambda k, q: 40.0)
                    for i in range(40)]
        full_clears = sum(1 for r in results if r.won)
        self.assertGreater(full_clears, 30)  # vs a minority without income


class TestMachinePersistence(unittest.TestCase):
    def _buying_run(self, machines_persist, seed=7):
        config = RunConfig(machines_persist=machines_persist,
                            quota_curve=flat_quota(1.0), num_stages=4)
        return run_run(config, buy_n(1), flat_mid, random.Random(seed))

    def test_per_stage_reauthor_resets_the_machine_each_stage(self):
        result = self._buying_run(machines_persist=False)
        base_total = sum(len(s) for s in default_machine_config().reel_strips)
        # Every stage starts from the pristine baseline: with exactly one
        # purchase per stage, the RTP delta reflects one edit only.
        for record in result.records:
            self.assertEqual(record.spent_on_machine > 0, True)
        # No stage's delta compounds on the previous stage's edit -- deltas
        # stay in the single-edit range rather than growing without bound.
        deltas = [abs(r.machine_rtp_delta) for r in result.records]
        self.assertLess(max(deltas), 0.2)

    def test_persistent_machines_accumulate_edits(self):
        # seed 0 probed to clear all 4 stages at quota 1: one edit lands
        # per stage on top of the last, so the RTP delta vs baseline
        # keeps moving stage over stage instead of resetting.
        result = self._buying_run(machines_persist=True, seed=0)
        self.assertEqual(result.stages_cleared, 4)
        deltas = [r.machine_rtp_delta for r in result.records]
        self.assertNotEqual(deltas[0], deltas[-1])
        self.assertGreater(len(set(deltas)), 2)


if __name__ == "__main__":
    unittest.main()
