"""The play-phase loop (docs/02_GAME_DESIGN.md #4, D6 locked):

    bankroll -> bet -> spin -> payout -> pending -> (bank or gamble) -> winnings

under the dual limiter: play stops the instant bankroll hits zero OR the
spin cap is reached, whichever comes first. Win iff winnings >= quota at
that point.

Phase 3 (docs/05_ROADMAP.md): the pending pool no longer auto-commits.
Every win offers a bank-vs-gamble-up decision (docs/02_GAME_DESIGN.md #4),
repeatable while pending is nonzero -- gambling only ever mutates pending
(double on a win, zero on a loss); bankroll is untouched either way (D3).
"""

from dataclasses import dataclass, field
from enum import Enum

from sim.pools import Pools
from sim.reel import Machine
from sim.paytable import resolve_spin
from sim.strategy import never_gamble


class Outcome(Enum):
    WIN = "win"
    BUST = "bust"
    OUT_OF_SPINS = "out_of_spins"


@dataclass
class PlayResult:
    outcome: Outcome
    spins_used: int
    final_winnings: float
    final_bankroll: float
    payouts: list = field(default_factory=list)          # raw per-spin reel payout
    winnings_deltas: list = field(default_factory=list)  # amount actually banked per spin (post-gamble)


def run_play_phase(sim_config, bet_strategy, rng, gamble_strategy=never_gamble) -> PlayResult:
    machine = Machine(sim_config.machine.reel_strips, sim_config.machine.num_rows)
    pools = Pools(bankroll=sim_config.economy.starting_bankroll)
    payouts = []
    winnings_deltas = []
    spins_used = 0

    while True:
        if pools.winnings >= sim_config.economy.quota:
            return PlayResult(Outcome.WIN, spins_used, pools.winnings,
                               pools.bankroll, payouts, winnings_deltas)
        if pools.bankroll <= 0:
            return PlayResult(Outcome.BUST, spins_used, pools.winnings,
                               pools.bankroll, payouts, winnings_deltas)
        if spins_used >= sim_config.economy.spin_cap:
            return PlayResult(Outcome.OUT_OF_SPINS, spins_used, pools.winnings,
                               pools.bankroll, payouts, winnings_deltas)

        spins_remaining = sim_config.economy.spin_cap - spins_used
        bet = bet_strategy(pools.bankroll, sim_config.economy, spins_remaining, pools.winnings)
        bet = max(0.0, min(bet, pools.bankroll))
        if bet <= 0:
            return PlayResult(Outcome.BUST, spins_used, pools.winnings,
                               pools.bankroll, payouts, winnings_deltas)

        pools.spend_from_bankroll(bet)
        spins_used += 1

        grid = machine.spin(rng)
        payout = resolve_spin(grid, sim_config.machine.paylines,
                               sim_config.machine.paytable, bet,
                               sim_config.machine.min_match)
        payouts.append(payout)

        winnings_before = pools.winnings
        if payout > 0:
            pools.add_to_pending(payout)
            _resolve_gamble(pools, sim_config.economy, gamble_strategy, rng)
        winnings_deltas.append(pools.winnings - winnings_before)


def _resolve_gamble(pools: Pools, economy, gamble_strategy, rng) -> None:
    while pools.pending > 0:
        if not gamble_strategy(pools.pending, pools.winnings, economy):
            pools.commit_pending_to_winnings()
            return
        if rng.random() < economy.gamble_win_probability:
            pools.double_pending()
        else:
            pools.forfeit_pending()
            return
