"""D29: the reel editor -- fixed-slot symbol density tuning among symbols
the player already owns. No shelf slot involved (that's for symbol kinds
not yet owned -- see reel_editor vs shelf in docs/02_GAME_DESIGN.md #3).

A purchase displaces copies of a chosen reel's *cheapest-tier symbol
present* (ranked by paytable value, cascading to the next-cheapest once a
tier is exhausted) with copies of the target symbol, keeping that reel's
total strip length unchanged. Probability mass per reel is conserved, so
every purchase is a clean, legible trade -- not a growing strip. Zero
edits leaves the machine exactly as it started (the validated Phase-1/2/3
baseline).
"""


def symbol_tier_value(symbol: str, paytable: dict) -> float:
    """A symbol's tier for ranking "cheapest filler present" -- the
    richest defined payout in its paytable entry. A symbol absent from
    the paytable (shouldn't normally happen) ranks as free/cheapest."""
    entry = paytable.get(symbol)
    if not entry:
        return 0.0
    return max(entry.values())


def apply_reel_edit(reel_strip: list, target_symbol: str, quantity: int,
                     paytable: dict) -> list:
    """Returns a new reel strip with up to `quantity` copies of the reel's
    current cheapest-tier symbol converted to `target_symbol`, one at a
    time, re-ranking after each conversion so it cascades to the next
    tier once the previous one is exhausted. Strip length is unchanged.
    Never converts existing copies of `target_symbol` into itself. Stops
    early (rather than raising) if the reel runs out of anything left to
    convert.
    """
    if quantity <= 0:
        return list(reel_strip)

    strip = list(reel_strip)
    remaining = quantity

    while remaining > 0:
        candidates = {s for s in strip if s != target_symbol}
        if not candidates:
            break
        cheapest = min(candidates, key=lambda s: symbol_tier_value(s, paytable))
        strip[strip.index(cheapest)] = target_symbol
        remaining -= 1

    return strip
