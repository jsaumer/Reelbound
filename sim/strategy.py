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
    """Presses every opportunity, no matter what. A fair coin flip is
    EV-neutral, so this doesn't change expected winnings -- it just adds
    variance for its own sake, with no strategic upside. Useful as a
    "reckless" baseline to compare against a real heuristic."""
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
