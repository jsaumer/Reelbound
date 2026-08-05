"""D31: the stage path -- a linear sequence of nodes over one continuous
economy. D6's dual limiter is completely unchanged; node type only
changes what happens on a given turn, not the underlying rules. There's
no mechanically distinct "boss fight" -- the stage ends exactly when the
dual limiter says so, wherever that lands on the path.

Phase 4 content: MINOR (plain spin) and TREASURE (small free winnings,
no cost) are real. ELITE forces a bigger bet with no payout bonus --
EV-neutral versus choosing to bet bigger manually, so it's a pacing/tempo
variation, not a free-lunch node. EVENT and REST are designed (the
NodeType exists) but not populated in the default path yet -- they need
boon/curse content (Phase 5) to mean anything; see
docs/06_OPEN_QUESTIONS.md D31.

`node_sequence` is treated as a repeating pattern (cycled, not a
one-shot list) so the stage only ever ends via the dual limiter/quota
choice, never by "running out of nodes" -- the same guarantee D6 already
makes, just walked through varying turn flavors instead of a flat loop.
"""

import itertools
from dataclasses import dataclass, field
from enum import Enum

from sim.pools import Pools
from sim.reel import Machine
from sim.paytable import resolve_spin
from sim.odds import theoretical_rtp
from sim.play_phase import Outcome, _resolve_gamble, _resolve_quota_cleared_choice
from sim.strategy import never_gamble, always_keep_playing


class NodeType(Enum):
    MINOR = "minor"
    ELITE = "elite"
    EVENT = "event"        # designed, not yet populated in default_node_sequence
    REST = "rest"           # designed, not yet populated in default_node_sequence
    TREASURE = "treasure"


# Elite modifier: self-contained, no boon/curse system needed for Phase 4.
# Forces a bigger bet, no payout bonus -- close to EV-neutral versus just
# betting bigger manually, so it reads as a pacing/tempo choice rather
# than a free-lunch node. A real risk/reward elite (worse odds for a real
# edge) needs curse-like content, Phase 5.
#
# Both constants and their frequency in default_node_sequence() were
# tuned against sim/stage.py's 20k-run batch check, not guessed: because
# the economy is spin-cap-bound (D6 -- most Phase-1/2/3 losses are
# "ran out of spins near quota", not bankrupt), TREASURE's free winnings
# convert a disproportionate share of near-miss runs into wins even at
# small values, and ELITE's bet-size variance shifts win rate the same
# direction by letting lucky streaks close the gap to quota in fewer
# spins. Both had to be small AND rare to keep the D12 40-60% tension
# band intact -- see docs/06_OPEN_QUESTIONS.md D31.
ELITE_BET_MULTIPLIER = 1.25

TREASURE_WINNINGS_BONUS = 0.5


def default_node_sequence() -> list:
    """A small, fixed pattern for Phase 4 -- content is thin (D31), types
    cycle to give some turn-to-turn variety without a real balancing pass
    yet. Always contains at least one spin-consuming node so a stage
    using it is guaranteed to terminate via the dual limiter. ELITE and
    TREASURE are deliberately rare (1-in-15 each, not 1-in-3/1-in-6) --
    see the tuning note above ELITE_BET_MULTIPLIER."""
    return [NodeType.MINOR] * 13 + [NodeType.ELITE, NodeType.TREASURE]


@dataclass
class StageResult:
    outcome: Outcome
    spins_used: int
    final_winnings: float
    final_bankroll: float
    nodes_visited: list = field(default_factory=list)


def run_stage(sim_config, node_sequence, bet_strategy, rng,
              gamble_strategy=never_gamble,
              continuation_strategy=always_keep_playing) -> StageResult:
    machine = Machine(sim_config.machine.reel_strips, sim_config.machine.num_rows)
    pools = Pools(bankroll=sim_config.economy.starting_bankroll)
    spins_used = 0
    nodes_visited = []
    machine_rtp = theoretical_rtp(sim_config.machine.reel_strips,
                                   sim_config.machine.paylines,
                                   sim_config.machine.paytable)

    for node_type in itertools.cycle(node_sequence):
        if pools.winnings >= sim_config.economy.quota:
            cashed_out, bonus = _resolve_quota_cleared_choice(
                pools, sim_config, spins_used, continuation_strategy, machine_rtp)
            if cashed_out or bonus is None:
                return StageResult(Outcome.WIN, spins_used, pools.winnings,
                                    pools.bankroll, nodes_visited)
            # else: chose to keep playing -- fall through to this node.
        else:
            if pools.bankroll <= 0:
                return StageResult(Outcome.BUST, spins_used, pools.winnings,
                                    pools.bankroll, nodes_visited)
            if spins_used >= sim_config.economy.spin_cap:
                return StageResult(Outcome.OUT_OF_SPINS, spins_used, pools.winnings,
                                    pools.bankroll, nodes_visited)

        nodes_visited.append(node_type)

        if node_type == NodeType.TREASURE:
            pools.add_to_pending(TREASURE_WINNINGS_BONUS)
            pools.commit_pending_to_winnings()
            continue

        if node_type in (NodeType.EVENT, NodeType.REST):
            # Designed, not populated -- a no-op turn if one somehow shows
            # up in a caller-supplied sequence. default_node_sequence()
            # never includes these.
            continue

        # MINOR or ELITE: a spin.
        spins_remaining = sim_config.economy.spin_cap - spins_used
        bet = bet_strategy(pools.bankroll, sim_config.economy, spins_remaining, pools.winnings)
        bet = max(0.0, min(bet, pools.bankroll))

        if node_type == NodeType.ELITE:
            bet = min(bet * ELITE_BET_MULTIPLIER, pools.bankroll)

        if bet <= 0:
            outcome = Outcome.WIN if pools.winnings >= sim_config.economy.quota else Outcome.BUST
            return StageResult(outcome, spins_used, pools.winnings,
                                pools.bankroll, nodes_visited)

        pools.spend_from_bankroll(bet)
        spins_used += 1

        grid = machine.spin(rng)
        payout = resolve_spin(grid, sim_config.machine.paylines,
                               sim_config.machine.paytable, bet,
                               sim_config.machine.min_match,
                               sim_config.machine.wild_symbol)

        if payout > 0:
            pools.add_to_pending(payout)
            _resolve_gamble(pools, sim_config.economy, gamble_strategy, rng)
