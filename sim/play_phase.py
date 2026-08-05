"""The play-phase loop (docs/02_GAME_DESIGN.md #4, D6 locked):

    bankroll -> bet -> spin -> payout -> pending -> (bank or gamble) -> winnings

under the dual limiter: play stops the instant bankroll hits zero OR the
spin cap is reached, whichever comes first. Win iff winnings >= quota at
that point.

Phase 3 (docs/05_ROADMAP.md): the pending pool no longer auto-commits.
A win *may* offer a bank-vs-gamble-up decision (docs/02_GAME_DESIGN.md #4)
-- only with probability `gamble_offer_probability` (default 0.25; per
playtest feedback, offering it on every single win got old fast, and the
offer is meant to eventually be gated behind an obtainable item/boon,
Phase 4/5 -- not built yet, so this probability is the buildable part of
that today). When offered, it's a single flip, not a repeatable ladder
(D25): win doubles pending and immediately banks it; lose forfeits it.
Chaining multiple gambles on the same win is also deferred to a future
unlockable -- an uncapped ladder is an "easy out" for a lucky player.
Gambling only ever mutates pending; bankroll is untouched either way
(D3). When not offered, the win auto-banks.

D23: clearing the quota does not itself end play (D6 already only names
bankroll=0 / spin cap as the end triggers) -- it locks in a win (winnings
never decreases, D3, so it can't become a loss from here) and, every spin
from then on, offers a choice: keep playing to the natural end, or cash
out now for a deliberately-discounted guaranteed bonus. The bonus is
projected from the paytable's theoretical rate (sim/odds.py), not the
realized average so far -- the realized average is biased by whatever
win just cleared quota (often a big one on a high-variance paytable),
which made an immediate cash-out exploitably profitable in testing.
"""

from dataclasses import dataclass, field
from enum import Enum

from sim.pools import Pools
from sim.strategy import never_gamble, always_keep_playing


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
    cashed_out: bool = False
    cash_out_bonus: float = 0.0


def run_play_phase(sim_config, bet_strategy, rng, gamble_strategy=never_gamble,
                    continuation_strategy=always_keep_playing) -> PlayResult:
    """A flat play phase is exactly a stage whose every node is a plain
    spin -- so this is a thin wrapper over sim.stage.run_stage with an
    all-MINOR sequence (Phase 4.5 consolidation: one dual-limiter loop to
    maintain instead of two drifting copies). Import is deferred because
    stage.py imports this module's helpers.

    rng consumption and results are bit-identical to the old standalone
    loop for the same seed -- the deterministic tests in
    tests/test_play_phase.py pin this."""
    from sim.stage import run_stage, NodeType

    result = run_stage(sim_config, [NodeType.MINOR], bet_strategy, rng,
                        gamble_strategy=gamble_strategy,
                        continuation_strategy=continuation_strategy)
    return PlayResult(result.outcome, result.spins_used, result.final_winnings,
                       result.final_bankroll, result.payouts, result.winnings_deltas,
                       cashed_out=result.cashed_out, cash_out_bonus=result.cash_out_bonus)


def _resolve_gamble(pools: Pools, economy, gamble_strategy, rng) -> None:
    if rng.random() >= economy.gamble_offer_probability:
        # The offer doesn't appear this time -- auto-bank, same as if the
        # player had chosen bank with no gamble ever available.
        pools.commit_pending_to_winnings()
        return
    if not gamble_strategy(pools.pending, pools.winnings, economy):
        pools.commit_pending_to_winnings()
        return
    # D25: a single flip only, win or lose -- chaining into a ladder (win,
    # then get offered to gamble the double again) is a future unlockable,
    # not baseline. An uncapped ladder is an "easy out" for a lucky
    # player: a chain of wins compounds into an escape valve the design
    # shouldn't hand out for free.
    if rng.random() < economy.gamble_win_probability:
        pools.double_pending()
        pools.commit_pending_to_winnings()
    else:
        pools.forfeit_pending()


def _resolve_quota_cleared_choice(pools: Pools, sim_config, spins_used: int,
                                   continuation_strategy, machine_rtp: float) -> tuple:
    """Returns (cashed_out, bonus). bonus is None if there was no runway
    left to offer a real choice over (already at the natural end)."""
    economy = sim_config.economy
    spins_remaining, avg_bet_so_far = _estimate_remaining_spins(pools, economy, spins_used)
    if spins_remaining <= 0:
        return False, None
    if avg_bet_so_far <= 0:
        avg_bet_so_far = (economy.min_bet + economy.max_bet) / 2.0

    avg_per_spin = machine_rtp * avg_bet_so_far
    cash_out_value = spins_remaining * avg_per_spin * economy.cash_out_discount

    if continuation_strategy(spins_remaining, avg_per_spin, cash_out_value, pools, economy):
        return False, 0.0  # keep playing

    pools.add_to_pending(cash_out_value)
    pools.commit_pending_to_winnings()
    return True, cash_out_value


def _estimate_remaining_spins(pools: Pools, economy, spins_used: int) -> tuple:
    """Returns (spins_remaining, avg_bet_so_far)."""
    spin_cap_remaining = max(0, economy.spin_cap - spins_used)
    if pools.bankroll <= 0 or spin_cap_remaining <= 0:
        return 0, 0.0
    if spins_used <= 0:
        return spin_cap_remaining, 0.0

    avg_bet_so_far = (economy.starting_bankroll - pools.bankroll) / spins_used
    if avg_bet_so_far <= 0:
        return spin_cap_remaining, 0.0

    bankroll_runway = int(pools.bankroll / avg_bet_so_far)
    return min(spin_cap_remaining, bankroll_runway), avg_bet_so_far
