"""The payout resolver -- kept as a standalone, swappable module (per the
Phase-1 brief: "keep the payout math a clearly separated, swappable module").

Payline rule (docs/07_SLOT_TYPES.md #1): matches along fixed left-to-right
lines. A line pays if its leftmost run of identical symbols is at least
`min_match` long, reading reel 0 -> reel N-1 (classic left-anchored payline).

`paytable` maps symbol -> {match_length: payout_multiplier}, defined at a
bet of 1. The caller's bet is a scalar multiplier on that base value (Phase-1
simplification -- see plan: literal per-payline betting is deferred).

`wild_symbol` (Phase 4, D30 tier 1): optional. A wild substitutes for
whatever symbol the run resolves to -- leading wilds don't fix an identity
until a non-wild symbol is seen (or the whole line is wild, in which case
the line resolves as the wild symbol itself, using its own paytable entry).
Defaults to None, which reproduces the exact pre-Phase-4 behavior (no
symbol can ever equal None), so existing callers are unaffected.
"""


def resolve_spin(grid: list, paylines: list, paytable: dict, bet: float,
                  min_match: int = 3, wild_symbol: str = None) -> float:
    total_multiplier = 0.0
    num_reels = len(grid)

    for line in paylines:
        symbols_on_line = [grid[reel][line[reel]] for reel in range(num_reels)]

        first = None
        match_len = 0
        for symbol in symbols_on_line:
            is_wild = wild_symbol is not None and symbol == wild_symbol
            if first is None:
                if is_wild:
                    match_len += 1
                    continue
                first = symbol
                match_len += 1
                continue
            if symbol == first or is_wild:
                match_len += 1
            else:
                break

        if first is None:
            # The entire line was wild -- resolves as the wild symbol itself.
            first = wild_symbol

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
