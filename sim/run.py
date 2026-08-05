"""Phase 4.5 (docs/05_ROADMAP.md): the multi-stage run skeleton, sim only.

A *run* is a sequence of stages over one cycling wallet (D21): each stage
is a build phase (spend wallet on the machine, load the rest as bankroll)
followed by a stage-path play phase (sim/stage.py); a cleared stage's
winnings become the next build phase's wallet; the run ends at the first
failed stage or after `num_stages` cleared (D11's ~8 working guess).

Two things this module exists to measure, both explicitly OPEN decisions:

- D36 (machine persistence): `machines_persist=False` re-authors the
  machine from the pristine baseline every stage (the doc set's current
  implication); `True` carries the edited strips/paytable/owned-symbols
  forward so purchases accumulate. Both variants run so the decision can
  be made on data, not vibes.
- D22 (quota escalation): `quota_curve(stage_index, wallet) -> quota` is
  pluggable; QUOTA_CURVES holds the candidate families to sweep. The
  standing constraint from the Phase-4 balance notes: the chosen curve
  must make purchases EV-positive across a run.

Everything here is cheap and disposable -- no game/ mirror until the
decisions land.
"""

import random
from dataclasses import dataclass, field

from sim.config import (MachineConfig, EconomyConfig, SimConfig,
                         default_machine_config, default_economy_config)
from sim.build_phase import BuildPhase, WILD_SYMBOL, WILD_RELIC_ID, WILD_RELIC_COST
from sim.stage import run_stage, default_node_sequence
from sim.play_phase import Outcome
from sim.odds import rtp_delta_for_edit, offer_ev
from sim.strategy import never_gamble, always_keep_playing


# --- Quota curves (D22 candidates) ---

def flat_quota(base: float = 65.0):
    return lambda stage_index, wallet: base


def linear_quota(base: float = 65.0, step: float = 10.0):
    return lambda stage_index, wallet: base + step * stage_index


def geometric_quota(base: float = 65.0, growth: float = 1.15):
    return lambda stage_index, wallet: base * (growth ** stage_index)


def wallet_ratio_quota(ratio: float = 0.65):
    """D12's locked stage-1 shape (quota = 0.65 x what you walk in with),
    applied every stage -- quota scales itself to the player's actual
    trajectory instead of an absolute schedule."""
    return lambda stage_index, wallet: ratio * wallet


QUOTA_CURVES = {
    "flat65": flat_quota(65.0),
    "linear+10": linear_quota(65.0, 10.0),
    "linear+20": linear_quota(65.0, 20.0),
    "geo1.10": geometric_quota(65.0, 1.10),
    "geo1.25": geometric_quota(65.0, 1.25),
    "ratio0.65": wallet_ratio_quota(0.65),
    "ratio0.80": wallet_ratio_quota(0.80),
}


# --- Purchase strategies: (build, economy, rng) -> None, mutating `build` ---

def hoard(build: BuildPhase, economy, rng) -> None:
    """Buy nothing; every coin becomes bankroll (the 0-purchase baseline)."""


def buy_n(n: int, max_rerolls: int = 5):
    """Buy the first affordable offers until `n` purchases land, rerolling
    (D33/D35) when the current set is exhausted or unaffordable."""
    def strategy(build: BuildPhase, economy, rng) -> None:
        bought = 0
        rerolls = 0
        while bought < n:
            for i, offer in enumerate(build.reel_offers()):
                if bought >= n:
                    break
                if not offer.bought and offer.cost <= build.wallet + 1e-9:
                    if build.buy_reel_offer(i):
                        bought += 1
            if bought >= n or rerolls >= max_rerolls:
                break
            if not build.reroll_reel_offers():
                break
            rerolls += 1
    return strategy


def ev_driven(max_rerolls: int = 3, buy_wild_relic: bool = True):
    """Buys only offers whose exact-RTP gain repays their cost over the
    stage's expected bet volume (sim/odds.py offer_ev), rerolling to hunt
    for positive ones. Optionally unlocks Wild first -- post-D35, a
    reroll can then surface wild offers in the same build phase. If this
    strategy never finds anything worth buying, that itself is the
    finding (the shop is a trap at that scope)."""
    def strategy(build: BuildPhase, economy, rng) -> None:
        if (buy_wild_relic and WILD_SYMBOL not in build.owned_symbols
                and build.wallet >= WILD_RELIC_COST * 2):
            build.buy_relic(WILD_RELIC_ID)

        paylines = default_machine_config().paylines
        mid_bet = (economy.min_bet + economy.max_bet) / 2.0
        rerolls = 0
        while True:
            bought_any = False
            for i, offer in enumerate(build.reel_offers()):
                if offer.bought or offer.cost > build.wallet + 1e-9:
                    continue
                wild = WILD_SYMBOL if WILD_SYMBOL in build.owned_symbols else None
                delta = rtp_delta_for_edit(build.reel_strips, paylines, build.paytable,
                                            offer.reel_index, offer.symbol, offer.quantity,
                                            wild_symbol=wild)
                volume = min(economy.spin_cap * mid_bet, build.wallet - offer.cost)
                if offer_ev(delta, volume, offer.cost) > 0:
                    if build.buy_reel_offer(i):
                        bought_any = True
            if bought_any:
                continue
            if rerolls >= max_rerolls:
                break
            if build.reroll_cost() > build.wallet + 1e-9:
                break
            build.reroll_reel_offers()
            rerolls += 1
    return strategy


PURCHASE_STRATEGIES = {
    "hoard": hoard,
    "buy1": buy_n(1),
    "buy2": buy_n(2),
    "ev_driven": ev_driven(),
}


# --- The run loop ---

@dataclass
class RunConfig:
    num_stages: int = 8
    starting_wallet: float = 100.0
    quota_curve: object = None          # (stage_index, wallet) -> quota
    machines_persist: bool = False      # D36 variant flag
    # EXPERIMENTAL, not designed content: extra wallet granted for
    # clearing a stage, (stage_index, quota) -> amount. Exists because the
    # first multi-stage measurements showed the run economy is
    # dissipative -- every stage converts the wallet through a sub-1.0
    # RTP machine and burns leftover bankroll, so wallets decay ~ x0.886
    # per stage and most runs die even at quota=1. Genre convention
    # (Balatro's per-blind cash, StS gold per fight) is exactly this kind
    # of clear income; the sweep uses this lever to find how much income
    # makes an 8-stage run economically possible at all. Whatever D22
    # becomes must answer this first.
    clear_bonus: object = None          # (stage_index, quota) -> float

    def __post_init__(self):
        if self.quota_curve is None:
            self.quota_curve = QUOTA_CURVES["flat65"]
        if self.clear_bonus is None:
            self.clear_bonus = lambda stage_index, quota: 0.0


@dataclass
class StageRecord:
    stage_index: int
    quota: float
    wallet_before: float
    spent_on_machine: float     # wallet that did NOT become bankroll
    starting_bankroll: float
    machine_rtp_delta: float    # exact RTP vs the pristine baseline machine
    result: object              # StageResult


@dataclass
class RunResult:
    won: bool
    stages_cleared: int
    final_wallet: float
    records: list = field(default_factory=list)


def run_run(run_config: RunConfig, purchase_strategy, bet_strategy, rng,
            gamble_strategy=never_gamble,
            continuation_strategy=always_keep_playing) -> RunResult:
    from sim.odds import theoretical_rtp_exact

    base_machine = default_machine_config()
    base_economy = default_economy_config()
    baseline_rtp = theoretical_rtp_exact(base_machine.reel_strips, base_machine.paylines,
                                          base_machine.paytable)

    wallet = run_config.starting_wallet
    carried_strips = None
    carried_paytable = None
    carried_owned = None
    records = []

    for stage_index in range(run_config.num_stages):
        if run_config.machines_persist and carried_strips is not None:
            strips = [list(s) for s in carried_strips]
            paytable = dict(carried_paytable)
            owned = set(carried_owned)
        else:
            strips = [list(s) for s in base_machine.reel_strips]
            paytable = dict(base_machine.paytable)
            owned = set()

        build = BuildPhase(wallet=wallet, reel_strips=strips, paytable=paytable,
                            min_bet=base_economy.min_bet, owned_symbols=owned, rng=rng)
        purchase_strategy(build, base_economy, rng)
        spent_on_machine = wallet - build.wallet
        build.load_bankroll(build.wallet)
        final_strips, starting_bankroll, wild_symbol = build.finalize()

        quota = run_config.quota_curve(stage_index, wallet)
        machine = MachineConfig(num_rows=base_machine.num_rows, reel_strips=final_strips,
                                 paylines=base_machine.paylines, paytable=build.paytable,
                                 min_match=base_machine.min_match, wild_symbol=wild_symbol)
        economy = EconomyConfig(
            starting_bankroll=starting_bankroll, quota=quota,
            spin_cap=base_economy.spin_cap, min_bet=base_economy.min_bet,
            max_bet=base_economy.max_bet,
            gamble_win_probability=base_economy.gamble_win_probability,
            gamble_offer_probability=base_economy.gamble_offer_probability,
            cash_out_discount=base_economy.cash_out_discount)
        sim_config = SimConfig(machine=machine, economy=economy)

        rtp_delta = theoretical_rtp_exact(final_strips, base_machine.paylines,
                                           build.paytable,
                                           wild_symbol=wild_symbol) - baseline_rtp
        result = run_stage(sim_config, default_node_sequence(), bet_strategy, rng,
                            gamble_strategy=gamble_strategy,
                            continuation_strategy=continuation_strategy)
        records.append(StageRecord(stage_index=stage_index, quota=quota,
                                    wallet_before=wallet,
                                    spent_on_machine=spent_on_machine,
                                    starting_bankroll=starting_bankroll,
                                    machine_rtp_delta=rtp_delta, result=result))

        if result.outcome != Outcome.WIN:
            return RunResult(won=False, stages_cleared=stage_index,
                              final_wallet=wallet, records=records)

        # D21: a cleared stage's winnings are the next build phase's wallet
        # (+ the experimental clear bonus, zero unless the sweep sets it).
        wallet = result.final_winnings + run_config.clear_bonus(stage_index, quota)
        if run_config.machines_persist:
            carried_strips = final_strips
            carried_paytable = build.paytable
            carried_owned = build.owned_symbols

    return RunResult(won=True, stages_cleared=run_config.num_stages,
                      final_wallet=wallet, records=records)


def run_many_runs(run_config: RunConfig, purchase_strategy, bet_strategy,
                   n_runs: int, base_seed: int = 12345) -> list:
    return [run_run(run_config, purchase_strategy, bet_strategy,
                     random.Random(base_seed + i))
            for i in range(n_runs)]
