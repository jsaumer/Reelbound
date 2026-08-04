"""Pluggable bet-size and bank-vs-gamble strategies -- the two live
decisions in the play phase (docs/02_GAME_DESIGN.md #4). Both are plain
callables of primitives (no object coupling) so they're trivial to write,
compare, and test in isolation.

A bet strategy: `(bankroll, economy, spins_remaining, winnings) -> float`.
`play_phase` clamps the returned bet to what's actually left in bankroll.

A gamble strategy: `(pending, winnings, economy) -> bool` -- True gambles
(double-or-nothing on the current pending), False banks it. Called
repeatedly while pending is nonzero after a win (see play_phase._resolve_gamble).
"""


# --- Bet-size strategies ---

def flat_min(bankroll: float, economy, spins_remaining: int, winnings: float) -> float:
    return economy.min_bet


def flat_mid(bankroll: float, economy, spins_remaining: int, winnings: float) -> float:
    return (economy.min_bet + economy.max_bet) / 2.0


def flat_max(bankroll: float, economy, spins_remaining: int, winnings: float) -> float:
    return economy.max_bet


def adaptive_throttle(bankroll: float, economy, spins_remaining: int, winnings: float) -> float:
    """Bet size as a throttle between the two clocks (docs/02_GAME_DESIGN.md
    #4: "a big bet burns bankroll faster but reaches quota in fewer spins;
    a small bet stretches bankroll but eats spins"). If bankroll could
    outlast the spin cap even at min bet, the spin cap is the tighter
    clock -- there's no payoff to holding back, so bet big to convert
    faster. Otherwise bankroll is the tighter clock -- ease off to stretch
    it as far as the spin cap allows.
    """
    remaining = max(1, spins_remaining)
    runway_at_min_bet = bankroll / economy.min_bet if economy.min_bet > 0 else remaining
    if runway_at_min_bet > remaining:
        return economy.max_bet
    return economy.min_bet


BET_STRATEGIES = {
    "flat_min": flat_min,
    "flat_mid": flat_mid,
    "flat_max": flat_max,
    "adaptive_throttle": adaptive_throttle,
}

# Kept for backward compatibility with earlier Phase-1 call sites.
STRATEGIES = BET_STRATEGIES


# --- Bank-vs-gamble strategies ---

def never_gamble(pending: float, winnings: float, economy) -> bool:
    """Always banks -- the Phase-1/2 default behavior (pending auto-committed
    every spin), kept as an explicit strategy now that gambling exists."""
    return False


def always_gamble(pending: float, winnings: float, economy) -> bool:
    """Takes the gamble whenever it's offered (D25: a single flip, not a
    ladder). A fair coin flip is EV-neutral, so this doesn't change
    expected winnings -- it just adds variance for its own sake, with no
    strategic upside. Useful as a "reckless" baseline to compare against a
    real heuristic."""
    return True


def gamble_while_behind(pending: float, winnings: float, economy) -> bool:
    """Presses while banking the current pending still wouldn't clear the
    quota; banks the moment it would. Never risks a win that's already
    enough to finish the run -- a simple, explainable "skilled" heuristic."""
    return (winnings + pending) < economy.quota


GAMBLE_STRATEGIES = {
    "never_gamble": never_gamble,
    "always_gamble": always_gamble,
    "gamble_while_behind": gamble_while_behind,
}


# --- Post-quota continuation strategies (D23) ---
#
# Once winnings clear quota, the run is a locked win (D3: winnings never
# decreases) -- but play doesn't stop. Every subsequent spin re-offers a
# choice: keep playing to the natural end (D6), or cash out now for a
# guaranteed, deliberately-discounted bonus. A continuation strategy is
# `(spins_remaining, avg_winnings_per_spin, cash_out_value, pools, economy)
# -> bool`: True keeps playing, False cashes out.

def always_keep_playing(spins_remaining: int, avg_winnings_per_spin: float,
                         cash_out_value: float, pools, economy) -> bool:
    """Never engages with the offer -- the 'button-mashing' baseline: plays
    every spin out to the natural end regardless."""
    return True


def always_cash_out(spins_remaining: int, avg_winnings_per_spin: float,
                     cash_out_value: float, pools, economy) -> bool:
    """Takes the very first cash-out offer, however little runway is left.
    Maximally risk-averse, not necessarily smart -- the discount
    (economy.cash_out_discount) makes this generally worse in expectation
    than playing out real runway."""
    return False


def cash_out_near_the_end(spins_remaining: int, avg_winnings_per_spin: float,
                           cash_out_value: float, pools, economy) -> bool:
    """Keeps playing while there's meaningful runway left -- continuing has
    higher expected value than the discounted guarantee gives up -- but
    cashes out once only a couple of spins remain, where a little bad luck
    could easily do worse than the guarantee."""
    return spins_remaining > 2


CONTINUATION_STRATEGIES = {
    "always_keep_playing": always_keep_playing,
    "always_cash_out": always_cash_out,
    "cash_out_near_the_end": cash_out_near_the_end,
}
