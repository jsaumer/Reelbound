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
from sim.strategy import BET_STRATEGIES, GAMBLE_STRATEGIES, STRATEGIES


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

    results = run_many(sim_config, bet_strategy, args.runs, gamble_strategy=gamble_strategy)
    stats = summarize(results)
    print_report(stats, label=(f"strategy={args.strategy} "
                                f"gamble={args.gamble_strategy} runs={args.runs}"))


def cmd_compare(args):
    sim_config = default_sim_config(seed=args.seed)
    strategies = [
        ("naive: flat_mid + never_gamble",
         BET_STRATEGIES["flat_mid"], GAMBLE_STRATEGIES["never_gamble"]),
        ("reckless: flat_max + always_gamble",
         BET_STRATEGIES["flat_max"], GAMBLE_STRATEGIES["always_gamble"]),
        ("adaptive bet only: adaptive_throttle + never_gamble",
         BET_STRATEGIES["adaptive_throttle"], GAMBLE_STRATEGIES["never_gamble"]),
        ("adaptive gamble only: flat_mid + gamble_while_behind",
         BET_STRATEGIES["flat_mid"], GAMBLE_STRATEGIES["gamble_while_behind"]),
        ("skilled: adaptive_throttle + gamble_while_behind",
         BET_STRATEGIES["adaptive_throttle"], GAMBLE_STRATEGIES["gamble_while_behind"]),
    ]
    rows = compare_strategies(sim_config, strategies, args.runs, base_seed=args.seed)
    print_comparison(rows)


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
    p_run.add_argument("--bankroll", type=float, default=None,
                        help="override starting bankroll (default: config default)")
    p_run.add_argument("--quota", type=float, default=None,
                        help="override quota (default: config default)")
    p_run.add_argument("--spin-cap", type=int, default=None,
                        help="override spin cap (default: config default)")
    p_run.set_defaults(func=cmd_run)

    p_compare = sub.add_parser("compare", help="Phase 3: do decisions demonstrably matter?")
    p_compare.add_argument("--runs", type=int, default=20000)
    p_compare.add_argument("--seed", type=int, default=12345)
    p_compare.set_defaults(func=cmd_compare)

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
