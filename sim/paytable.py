"""The payout resolver -- kept as a standalone, swappable module (per the
Phase-1 brief: "keep the payout math a clearly separated, swappable module").

Payline rule (docs/07_SLOT_TYPES.md #1): matches along fixed left-to-right
lines. A line pays if its leftmost run of identical symbols is at least
`min_match` long, reading reel 0 -> reel N-1 (classic left-anchored payline).

`paytable` maps symbol -> {match_length: payout_multiplier}, defined at a
bet of 1. The caller's bet is a scalar multiplier on that base value (Phase-1
simplification -- see plan: literal per-payline betting is deferred).
"""


def resolve_spin(grid: list, paylines: list, paytable: dict, bet: float,
                  min_match: int = 3) -> float:
    total_multiplier = 0.0
    num_reels = len(grid)

    for line in paylines:
        symbols_on_line = [grid[reel][line[reel]] for reel in range(num_reels)]
        first = symbols_on_line[0]

        match_len = 1
        for symbol in symbols_on_line[1:]:
            if symbol != first:
                break
            match_len += 1

        if match_len < min_match:
            continue

        entry = paytable.get(first)
        if not entry:
            continue

        payout_multiplier = entry.get(match_len)
        if payout_multiplier is None:
            # No exact entry for this length (e.g. a 4-match on a paytable
            # that only defines 3 and 5) -- fall back to the richest defined
            # length at or below the actual match.
            eligible = [length for length in entry if length <= match_len]
            if not eligible:
                continue
            payout_multiplier = entry[max(eligible)]

        total_multiplier += payout_multiplier

    return total_multiplier * bet
