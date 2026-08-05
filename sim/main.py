"""CLI entry point for the economy sim.

    python -m sim.main run                     # default config, flat_mid strategy
    python -m sim.main run --strategy flat_min --runs 20000
    python -m sim.main sweep                    # quota x spin_cap grid search
    python -m sim.main compare                  # Phase 3: do decisions matter?
"""

import argparse
import copy

from sim.config import default_sim_config
from sim.harness import (run_many, summarize, print_report, sweep, print_sweep,
                          compare_strategies, print_comparison)
from sim.strategy import (BET_STRATEGIES, GAMBLE_STRATEGIES, CONTINUATION_STRATEGIES,
                           STRATEGIES)


def cmd_run(args):
    sim_config = default_sim_config(seed=args.seed)
    if args.bankroll is not None:
        sim_config.economy.starting_bankroll = args.bankroll
    if args.quota is not None:
        sim_config.economy.quota = args.quota
    if args.spin_cap is not None:
        sim_config.economy.spin_cap = args.spin_cap
    bet_strategy = BET_STRATEGIES[args.strategy]
    gamble_strategy = GAMBLE_STRATEGIES[args.gamble_strategy]
    continuation_strategy = CONTINUATION_STRATEGIES[args.continuation_strategy]

    results = run_many(sim_config, bet_strategy, args.runs, gamble_strategy=gamble_strategy,
                        continuation_strategy=continuation_strategy)
    stats = summarize(results)
    print_report(stats, label=(f"strategy={args.strategy} "
                                f"gamble={args.gamble_strategy} "
                                f"continuation={args.continuation_strategy} runs={args.runs}"))


def cmd_compare(args):
    sim_config = default_sim_config(seed=args.seed)
    akp = GAMBLE_STRATEGIES["never_gamble"], CONTINUATION_STRATEGIES["always_keep_playing"]
    strategies = [
        ("naive: flat_mid + never_gamble + always_keep_playing",
         BET_STRATEGIES["flat_mid"], *akp),
        ("reckless: flat_max + always_gamble + always_keep_playing",
         BET_STRATEGIES["flat_max"], GAMBLE_STRATEGIES["always_gamble"],
         CONTINUATION_STRATEGIES["always_keep_playing"]),
        ("adaptive bet only: adaptive_throttle + never_gamble + always_keep_playing",
         BET_STRATEGIES["adaptive_throttle"], *akp),
        ("adaptive gamble only: flat_mid + gamble_while_behind + always_keep_playing",
         BET_STRATEGIES["flat_mid"], GAMBLE_STRATEGIES["gamble_while_behind"],
         CONTINUATION_STRATEGIES["always_keep_playing"]),
        ("skilled bet+gamble: adaptive_throttle + gamble_while_behind + always_keep_playing",
         BET_STRATEGIES["adaptive_throttle"], GAMBLE_STRATEGIES["gamble_while_behind"],
         CONTINUATION_STRATEGIES["always_keep_playing"]),
        # Isolate the continuation (cash-out, D23) decision by holding bet+gamble fixed.
        ("continuation: skilled bet/gamble + always_cash_out",
         BET_STRATEGIES["adaptive_throttle"], GAMBLE_STRATEGIES["gamble_while_behind"],
         CONTINUATION_STRATEGIES["always_cash_out"]),
        ("continuation: skilled bet/gamble + cash_out_near_the_end",
         BET_STRATEGIES["adaptive_throttle"], GAMBLE_STRATEGIES["gamble_while_behind"],
         CONTINUATION_STRATEGIES["cash_out_near_the_end"]),
    ]
    rows = compare_strategies(sim_config, strategies, args.runs, base_seed=args.seed)
    print_comparison(rows)

    # K4 (docs/06_OPEN_QUESTIONS.md): the skill gap -- best strategy vs
    # the naive baseline -- is the standing KPI behind the "two skills"
    # niche claim. Phase-3 baseline ~5 points; Phase 5's exit needs >=10.
    naive_label, naive_stats = rows[0]
    best_label, best_stats = max(rows, key=lambda row: row[1].win_rate)
    gap = best_stats.win_rate - naive_stats.win_rate
    print(f"\nK4 skill gap: {gap:+.1%} "
          f"(best '{best_label}' {best_stats.win_rate:.1%} "
          f"vs naive {naive_stats.win_rate:.1%}; Phase-5 exit target >= +10pts)")


def cmd_runsweep(args):
    """Phase 4.5: the D22/D36 evidence run -- three experiments over the
    multi-stage skeleton (sim/run.py). See docs/05_ROADMAP.md Phase 4.5."""
    from sim.run import (RunConfig, run_many_runs, summarize_runs,
                          QUOTA_CURVES, PURCHASE_STRATEGIES)

    bet_strategy = BET_STRATEGIES[args.strategy]
    n = args.runs

    def report(label, config, purchase_strategy):
        results = run_many_runs(config, purchase_strategy, bet_strategy, n,
                                 base_seed=args.seed)
        stats = summarize_runs(results, config.num_stages)
        stage_rates = " ".join(f"{r:.0%}" for r in stats.per_stage_clear_rate)
        wallets = " ".join(f"{w:.0f}" for w in stats.mean_wallet_by_stage)
        print(f"{label:<42} full={stats.full_clear_rate:6.1%} "
              f"avg_stages={stats.mean_stages_cleared:4.2f}")
        print(f"{'':<42} stage clear%: {stage_rates}")
        print(f"{'':<42} wallet@stage: {wallets}")
        return stats

    print(f"=== Experiment 1: income requirement (flat65 quota, hoard) n={n} ===")
    for bonus_label, bonus in [("bonus=0", lambda k, q: 0.0),
                                ("bonus=20", lambda k, q: 20.0),
                                ("bonus=40", lambda k, q: 40.0),
                                ("bonus=0.5xquota", lambda k, q: 0.5 * q),
                                ("bonus=1.0xquota", lambda k, q: 1.0 * q)]:
        config = RunConfig(quota_curve=QUOTA_CURVES["flat65"], clear_bonus=bonus)
        report(bonus_label, config, PURCHASE_STRATEGIES["hoard"])

    print(f"\n=== Experiment 2: quota curves at bonus=1.0xquota (hoard) n={n} ===")
    for curve_name, curve in QUOTA_CURVES.items():
        config = RunConfig(quota_curve=curve, clear_bonus=lambda k, q: 1.0 * q)
        report(curve_name, config, PURCHASE_STRATEGIES["hoard"])

    print(f"\n=== Experiment 3: purchases x D36 at flat65 + bonus=1.0xquota n={n} ===")
    for strat_name, strat in PURCHASE_STRATEGIES.items():
        for persist in (False, True):
            config = RunConfig(quota_curve=QUOTA_CURVES["flat65"],
                                clear_bonus=lambda k, q: 1.0 * q,
                                machines_persist=persist)
            label = f"{strat_name} ({'persist' if persist else 'per-stage'})"
            report(label, config, strat)

    print(f"\n=== Experiment 4: bet escalation (+25%/stage) x quota curves, "
          f"bonus=1.0xquota n={n} ===")
    bet_up = lambda k, wallet: 1.0 + 0.25 * k
    for curve_name in ("flat65", "linear+10", "linear+20", "geo1.10", "geo1.25"):
        config = RunConfig(quota_curve=QUOTA_CURVES[curve_name],
                            clear_bonus=lambda k, q: 1.0 * q, bet_scale=bet_up)
        report(f"{curve_name} + bets x(1+0.25k)", config, PURCHASE_STRATEGIES["hoard"])
    for strat_name in ("hoard", "ev_driven"):
        config = RunConfig(quota_curve=QUOTA_CURVES["linear+10"],
                            clear_bonus=lambda k, q: 1.0 * q, bet_scale=bet_up,
                            machines_persist=True)
        report(f"linear+10 + bets up + {strat_name} (persist)", config,
                PURCHASE_STRATEGIES[strat_name])


def cmd_sweep(args):
    strategy = STRATEGIES[args.strategy]
    quotas = [float(q) for q in args.quotas.split(",")]
    spin_caps = [int(c) for c in args.spin_caps.split(",")]

    def factory(quota, spin_cap):
        cfg = copy.deepcopy(default_sim_config(seed=args.seed))
        cfg.economy.starting_bankroll = args.bankroll
        cfg.economy.quota = quota
        cfg.economy.spin_cap = spin_cap
        return cfg

    rows = sweep(factory, strategy, args.runs, quotas, spin_caps, base_seed=args.seed)
    print_sweep(rows)


def main():
    parser = argparse.ArgumentParser(description="Reelbound Phase-1 economy sim")
    sub = parser.add_subparsers(dest="command", required=True)

    p_run = sub.add_parser("run", help="run N play-phases and report stats")
    p_run.add_argument("--runs", type=int, default=10000)
    p_run.add_argument("--seed", type=int, default=12345)
    p_run.add_argument("--strategy", choices=BET_STRATEGIES.keys(), default="flat_mid")
    p_run.add_argument("--gamble-strategy", choices=GAMBLE_STRATEGIES.keys(),
                        default="never_gamble")
    p_run.add_argument("--continuation-strategy", choices=CONTINUATION_STRATEGIES.keys(),
                        default="always_keep_playing")
    p_run.add_argument("--bankroll", type=float, default=None,
                        help="override starting bankroll (default: config default)")
    p_run.add_argument("--quota", type=float, default=None,
                        help="override quota (default: config default)")
    p_run.add_argument("--spin-cap", type=int, default=None,
                        help="override spin cap (default: config default)")
    p_run.set_defaults(func=cmd_run)

    p_compare = sub.add_parser("compare", help="Phase 3: do decisions demonstrably matter?")
    p_compare.add_argument("--runs", type=int, default=5000)
    p_compare.add_argument("--seed", type=int, default=12345)
    p_compare.set_defaults(func=cmd_compare)

    p_runsweep = sub.add_parser("runsweep",
                                  help="Phase 4.5: multi-stage D22/D36 evidence sweep")
    p_runsweep.add_argument("--runs", type=int, default=400)
    p_runsweep.add_argument("--seed", type=int, default=12345)
    p_runsweep.add_argument("--strategy", choices=BET_STRATEGIES.keys(), default="flat_mid")
    p_runsweep.set_defaults(func=cmd_runsweep)

    p_sweep = sub.add_parser("sweep", help="grid search quota x spin_cap")
    p_sweep.add_argument("--runs", type=int, default=3000)
    p_sweep.add_argument("--seed", type=int, default=12345)
    p_sweep.add_argument("--strategy", choices=STRATEGIES.keys(), default="flat_mid")
    p_sweep.add_argument("--bankroll", type=float, default=100.0)
    p_sweep.add_argument("--quotas", type=str, default="100,125,150,175,200")
    p_sweep.add_argument("--spin-caps", type=str, default="40,60,80,100,120")
    p_sweep.set_defaults(func=cmd_sweep)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
