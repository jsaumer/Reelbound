"""Theoretical hit probabilities and RTP, computed from the paytable/reel
strips themselves rather than any particular run's realized results.
Mirrors game/scripts/economy/odds.gd (kept structurally parallel, same as
the rest of sim/ vs. its GDScript port).

D23 needs this: the post-quota cash-out projection must reflect the
machine's true expected rate, not "winnings so far / spins so far" --
that realized average is biased by whatever win just cleared quota (often
a big one, since quota-clearing moments are disproportionately likely to
follow a large hit on a high-variance paytable), which made an early
cash-out exploitably profitable in testing.
"""


def per_reel_symbol_probabilities(reel_strips: list) -> list:
    reel_probs = []
    for strip in reel_strips:
        counts = {}
        for symbol in strip:
            counts[symbol] = counts.get(symbol, 0) + 1
        n = len(strip)
        reel_probs.append({symbol: count / n for symbol, count in counts.items()})
    return reel_probs


def symbol_match_probabilities(reel_strips: list, paytable: dict) -> dict:
    """{symbol: {match_length: probability}} -- probability a single
    payline pays exactly `match_length` of `symbol`, left-anchored at
    reel 0. Same for every payline regardless of row (see paytable.py)."""
    reel_probs = per_reel_symbol_probabilities(reel_strips)
    num_reels = len(reel_strips)
    result = {}

    for symbol, entry in paytable.items():
        by_length = {}
        for length in entry:
            p = 1.0
            for r in range(length):
                p *= reel_probs[r].get(symbol, 0.0) if r < num_reels else 0.0
            if length < num_reels:
                p *= 1.0 - reel_probs[length].get(symbol, 0.0)
            by_length[length] = p
        result[symbol] = by_length

    return result


def theoretical_rtp(reel_strips: list, paylines: list, paytable: dict) -> float:
    """Expected payout per unit bet per spin, across every payline."""
    probs = symbol_match_probabilities(reel_strips, paytable)
    ev_per_line = 0.0
    for symbol, entry in paytable.items():
        for length, payout in entry.items():
            ev_per_line += probs[symbol][length] * payout
    return ev_per_line * len(paylines)
