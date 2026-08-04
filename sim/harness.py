"""Simulation harness (docs/05_ROADMAP.md Phase 1): run N play-phases and
report win rate, bust rate, out-of-spins rate, average spins-to-quota, and
payout volatility, then check the result against the tension band.

Phase-1 exit criterion (docs/02_GAME_DESIGN.md #9, docs/05_ROADMAP.md):
naive play should win roughly 40-60% of the time -- tense, not trivial or
impossible.
"""

import random
import statistics
from dataclasses import dataclass, field

from sim.play_phase import Outcome, run_play_phase
from sim.strategy import never_gamble

TENSION_BAND = (0.40, 0.60)


@dataclass
class SimStats:
    n_runs: int
    win_rate: float
    bust_rate: float
    out_of_spins_rate: float
    avg_spins_to_quota: float  # None-able (float('nan') if no wins)
    avg_spins_used: float
    payout_mean: float
    payout_variance: float
    payout_stdev: float
    final_winnings_stdev: float


def run_many(sim_config, bet_strategy, n_runs: int, base_seed: int = None,
             gamble_strategy=never_gamble) -> list:
    if base_seed is None:
        base_seed = sim_config.seed
    results = []
    for i in range(n_runs):
        rng = random.Random(base_seed + i)
        results.append(run_play_phase(sim_config, bet_strategy, rng, gamble_strategy))
    return results


def summarize(results: list) -> SimStats:
    n = len(results)
    wins = [r for r in results if r.outcome == Outcome.WIN]
    busts = [r for r in results if r.outcome == Outcome.BUST]
    oos = [r for r in results if r.outcome == Outcome.OUT_OF_SPINS]

    all_payouts = [p for r in results for p in r.payouts]
    final_winnings = [r.final_winnings for r in results]

    spins_to_quota = [r.spins_used for r in wins]

    return SimStats(
        n_runs=n,
        win_rate=len(wins) / n,
        bust_rate=len(busts) / n,
        out_of_spins_rate=len(oos) / n,
        avg_spins_to_quota=(statistics.mean(spins_to_quota) if spins_to_quota
                             else float("nan")),
        avg_spins_used=statistics.mean(r.spins_used for r in results),
        payout_mean=statistics.mean(all_payouts) if all_payouts else 0.0,
        payout_variance=statistics.pvariance(all_payouts) if len(all_payouts) > 1 else 0.0,
        payout_stdev=statistics.pstdev(all_payouts) if len(all_payouts) > 1 else 0.0,
        final_winnings_stdev=statistics.pstdev(final_winnings) if n > 1 else 0.0,
    )


def verdict(stats: SimStats) -> str:
    lo, hi = TENSION_BAND
    if lo <= stats.win_rate <= hi:
        return (f"PASS -- win rate {stats.win_rate:.1%} is within the "
                f"tense band [{lo:.0%}, {hi:.0%}].")
    elif stats.win_rate > hi:
        return (f"FAIL -- win rate {stats.win_rate:.1%} is above the tense "
                f"band [{lo:.0%}, {hi:.0%}] (too easy). Tighten quota, "
                f"lower spin_cap, or trim the paytable.")
    else:
        return (f"FAIL -- win rate {stats.win_rate:.1%} is below the tense "
                f"band [{lo:.0%}, {hi:.0%}] (too punishing). Raise "
                f"starting_bankroll/spin_cap, lower quota, or richen the "
                f"paytable.")


def print_report(stats: SimStats, label: str = "") -> None:
    header = f"=== {label} ===" if label else "=== Simulation report ==="
    print(header)
    print(f"runs:                {stats.n_runs}")
    print(f"win rate:            {stats.win_rate:.1%}")
    print(f"bust rate:           {stats.bust_rate:.1%}")
    print(f"out-of-spins rate:   {stats.out_of_spins_rate:.1%}")
    print(f"avg spins to quota:  {stats.avg_spins_to_quota:.1f}")
    print(f"avg spins used:      {stats.avg_spins_used:.1f}")
    print(f"per-spin payout:     mean={stats.payout_mean:.3f} "
          f"stdev={stats.payout_stdev:.3f} var={stats.payout_variance:.3f}")
    print(f"final winnings stdev:{stats.final_winnings_stdev:.3f}")
    print(verdict(stats))


def sweep(sim_config_factory, strategy, n_runs: int, quotas: list,
          spin_caps: list, base_seed: int = 12345) -> list:
    """Run the harness across a quota x spin_cap grid (D12/D18 exploration).

    `sim_config_factory(quota, spin_cap) -> SimConfig` builds a config for
    each cell. Returns a list of (quota, spin_cap, SimStats) tuples.
    """
    rows = []
    for quota in quotas:
        for spin_cap in spin_caps:
            cfg = sim_config_factory(quota, spin_cap)
            results = run_many(cfg, strategy, n_runs, base_seed)
            stats = summarize(results)
            rows.append((quota, spin_cap, stats))
    return rows


def compare_strategies(sim_config, strategies: list, n_runs: int,
                        base_seed: int = 12345) -> list:
    """Run several (label, bet_strategy, gamble_strategy) combos against
    the identical config/seed stream. This is the Phase-3 exit-criterion
    tool (docs/05_ROADMAP.md: "confirm... that skilled play beats
    button-mashing") -- a decision only "demonstrably matters" if it moves
    these numbers against otherwise-identical conditions.

    Returns [(label, SimStats), ...].
    """
    rows = []
    for label, bet_strategy, gamble_strategy in strategies:
        results = run_many(sim_config, bet_strategy, n_runs, base_seed, gamble_strategy)
        rows.append((label, summarize(results)))
    return rows


def print_comparison(rows: list) -> None:
    print(f"{'strategy':<28} {'win_rate':>9} {'bust':>7} {'oos':>7} {'avg_spins':>10}")
    for label, stats in rows:
        print(f"{label:<28} {stats.win_rate:9.1%} {stats.bust_rate:7.1%} "
              f"{stats.out_of_spins_rate:7.1%} {stats.avg_spins_used:10.1f}")


def print_sweep(rows: list) -> None:
    lo, hi = TENSION_BAND
    print(f"{'quota':>8} {'spin_cap':>9} {'win_rate':>9} {'bust':>7} "
          f"{'oos':>7}  in_band")
    for quota, spin_cap, stats in rows:
        in_band = lo <= stats.win_rate <= hi
        marker = "<--" if in_band else ""
        print(f"{quota:8.0f} {spin_cap:9d} {stats.win_rate:9.1%} "
              f"{stats.bust_rate:7.1%} {stats.out_of_spins_rate:7.1%}  {marker}")
