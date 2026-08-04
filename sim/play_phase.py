"""The play-phase loop (docs/02_GAME_DESIGN.md #4, D6 locked):

    bankroll -> bet -> spin -> payout -> winnings

under the dual limiter: play stops the instant bankroll hits zero OR the
spin cap is reached, whichever comes first. Win iff winnings >= quota at
that point.

Phase-1 simplification: the pending pool auto-commits to winnings every
spin. Bank-vs-press (holding pending for a gamble-up) is a Phase 3 play
decision (docs/05_ROADMAP.md Phase 3), not part of the Phase-1 core loop --
pending still exists as a discrete step so that decision can be layered on
later without restructuring the pools.
"""

from dataclasses import dataclass, field
from enum import Enum

from sim.pools import Pools
from sim.reel import Machine
from sim.paytable import resolve_spin


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
    payouts: list = field(default_factory=list)


def run_play_phase(sim_config, strategy, rng) -> PlayResult:
    machine = Machine(sim_config.machine.reel_strips, sim_config.machine.num_rows)
    pools = Pools(bankroll=sim_config.economy.starting_bankroll)
    payouts = []
    spins_used = 0

    while True:
        if pools.winnings >= sim_config.economy.quota:
            return PlayResult(Outcome.WIN, spins_used, pools.winnings,
                               pools.bankroll, payouts)
        if pools.bankroll <= 0:
            return PlayResult(Outcome.BUST, spins_used, pools.winnings,
                               pools.bankroll, payouts)
        if spins_used >= sim_config.economy.spin_cap:
            return PlayResult(Outcome.OUT_OF_SPINS, spins_used, pools.winnings,
                               pools.bankroll, payouts)

        bet = strategy(pools.bankroll, sim_config.economy)
        bet = max(0.0, min(bet, pools.bankroll))
        if bet <= 0:
            return PlayResult(Outcome.BUST, spins_used, pools.winnings,
                               pools.bankroll, payouts)

        pools.spend_from_bankroll(bet)
        spins_used += 1

        grid = machine.spin(rng)
        payout = resolve_spin(grid, sim_config.machine.paylines,
                               sim_config.machine.paytable, bet,
                               sim_config.machine.min_match)
        pools.add_to_pending(payout)
        pools.commit_pending_to_winnings()
        payouts.append(payout)
