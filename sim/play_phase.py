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
that today). When offered, it's repeatable while pending is nonzero --
gambling only ever mutates pending (double on a win, zero on a loss);
bankroll is untouched either way (D3). When not offered, the win
auto-banks.

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
from sim.reel import Machine
from sim.paytable import resolve_spin
from sim.odds import theoretical_rtp
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
    machine = Machine(sim_config.machine.reel_strips, sim_config.machine.num_rows)
    pools = Pools(bankroll=sim_config.economy.starting_bankroll)
    payouts = []
    winnings_deltas = []
    spins_used = 0
    # Fixed for the whole run (same machine throughout) -- computed once
    # rather than on every quota-cleared spin, which could otherwise mean
    # re-deriving it dozens of times per run across thousands of runs.
    machine_rtp = theoretical_rtp(sim_config.machine.reel_strips,
                                   sim_config.machine.paylines,
                                   sim_config.machine.paytable)

    while True:
        if pools.winnings >= sim_config.economy.quota:
            cashed_out, bonus = _resolve_quota_cleared_choice(
                pools, sim_config, spins_used, continuation_strategy, machine_rtp)
            if cashed_out or bonus is None:
                # bonus is None only when there's no runway left to choose
                # from at all -- the natural end, reached exactly at/after
                # clearing quota.
                return PlayResult(Outcome.WIN, spins_used, pools.winnings,
                                   pools.bankroll, payouts, winnings_deltas,
                                   cashed_out=cashed_out, cash_out_bonus=bonus or 0.0)
            # else: chose to keep playing -- fall through to spin again.
        else:
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
            outcome = Outcome.WIN if pools.winnings >= sim_config.economy.quota else Outcome.BUST
            return PlayResult(outcome, spins_used, pools.winnings,
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
    if rng.random() >= economy.gamble_offer_probability:
        # The offer doesn't appear this time -- auto-bank, same as if the
        # player had chosen bank with no gamble ever available.
        pools.commit_pending_to_winnings()
        return
    while pools.pending > 0:
        if not gamble_strategy(pools.pending, pools.winnings, economy):
            pools.commit_pending_to_winnings()
            return
        if rng.random() < economy.gamble_win_probability:
            pools.double_pending()
        else:
            pools.forfeit_pending()
            return


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
