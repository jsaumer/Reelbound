"""Pluggable bet-size strategies. A strategy is any callable
`(bankroll: float, economy: EconomyConfig) -> float`; `play_phase` clamps
the returned bet to what's actually left in the bankroll.

Only flat strategies are provided for Phase 1's naive auto-player -- the
brief asks for a pluggable strategy so future strategies (e.g. bet scaling
with remaining spins) can be compared against this baseline.
"""


def flat_min(bankroll: float, economy) -> float:
    return economy.min_bet


def flat_mid(bankroll: float, economy) -> float:
    return (economy.min_bet + economy.max_bet) / 2.0


def flat_max(bankroll: float, economy) -> float:
    return economy.max_bet


STRATEGIES = {
    "flat_min": flat_min,
    "flat_mid": flat_mid,
    "flat_max": flat_max,
}
