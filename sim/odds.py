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
    """Expected payout per unit bet per spin, across every payline.

    Wild-blind (predates Wild, D30) -- fine for the no-wild machines the
    play phase has used so far, and still what the D23 cash-out
    projection runs on (mirrored in game/scripts/economy/odds.gd; change
    both sides together if that ever moves to the exact version below).
    For wild-aware numbers use theoretical_rtp_exact."""
    probs = symbol_match_probabilities(reel_strips, paytable)
    ev_per_line = 0.0
    for symbol, entry in paytable.items():
        for length, payout in entry.items():
            ev_per_line += probs[symbol][length] * payout
    return ev_per_line * len(paylines)


# --- Exact, wild-aware RTP + the Phase-4.5 per-offer EV tool ---
#
# Every payline reads one row per reel, and a uniform reel stop makes each
# row's symbol distribution equal to the strip's composition -- so every
# line has the same expected multiplier, and exact RTP is just
# num_paylines * E[single line]. E[single line] is computed by brute
# enumeration of all per-reel symbol combinations (weighted by strip
# composition), scoring each combo through the REAL resolver
# (paytable.resolve_spin on a 1-row grid) so wild substitution and the
# fallback-length rule can never drift from production behavior. ~8^5
# combos on the default machine -- fractions of a second, and memoized.

_LINE_EV_CACHE = {}


def _cache_key(reel_strips: list, paytable: dict, min_match: int, wild_symbol) -> tuple:
    strips_key = tuple(tuple(strip) for strip in reel_strips)
    paytable_key = tuple(sorted(
        (symbol, tuple(sorted(entry.items()))) for symbol, entry in paytable.items()))
    return (strips_key, paytable_key, min_match, wild_symbol)


def expected_line_multiplier(reel_strips: list, paytable: dict,
                              min_match: int = 3, wild_symbol: str = None) -> float:
    """Exact expected payout multiplier of a single payline, wild-aware."""
    from itertools import product
    from sim.paytable import resolve_spin

    key = _cache_key(reel_strips, paytable, min_match, wild_symbol)
    if key in _LINE_EV_CACHE:
        return _LINE_EV_CACHE[key]

    reel_probs = per_reel_symbol_probabilities(reel_strips)
    line = [tuple(0 for _ in reel_strips)]

    ev = 0.0
    for combo in product(*(probs.items() for probs in reel_probs)):
        p = 1.0
        for _, prob in combo:
            p *= prob
        grid = [[symbol] for symbol, _ in combo]
        ev += p * resolve_spin(grid, line, paytable, 1.0, min_match, wild_symbol)

    _LINE_EV_CACHE[key] = ev
    return ev


def theoretical_rtp_exact(reel_strips: list, paylines: list, paytable: dict,
                           min_match: int = 3, wild_symbol: str = None) -> float:
    """Exact expected payout per unit bet per spin, wild-aware."""
    return expected_line_multiplier(reel_strips, paytable, min_match,
                                     wild_symbol) * len(paylines)


def rtp_delta_for_edit(reel_strips: list, paylines: list, paytable: dict,
                        reel_index: int, symbol: str, quantity: int,
                        min_match: int = 3, wild_symbol: str = None) -> float:
    """How much a prospective reel edit (D29's fixed-slot swap) would move
    the machine's exact RTP. This is the number the D34 flat cost factor
    ignores: left-anchored evaluation makes the same symbol worth far more
    on reel 0 than reel 4, and Wild (substitution + crown's paytable)
    worth more than crown at the same tier price."""
    from sim.reel_editor import apply_reel_edit

    before = theoretical_rtp_exact(reel_strips, paylines, paytable,
                                    min_match, wild_symbol)
    edited = [list(strip) for strip in reel_strips]
    edited[reel_index] = apply_reel_edit(edited[reel_index], symbol, quantity, paytable)
    after = theoretical_rtp_exact(edited, paylines, paytable, min_match, wild_symbol)
    return after - before


def offer_ev(rtp_delta: float, total_bet_volume: float, cost: float) -> float:
    """Expected net value of buying a reel offer: the RTP gain applied to
    however much will actually be wagered this stage, minus the price.
    `total_bet_volume` is the caller's estimate of total money bet over
    the stage (~ min(bankroll, spin_cap x avg bet))."""
    return rtp_delta * total_bet_volume - cost
