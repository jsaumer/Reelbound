"""Reel strips and the machine grid (docs/07_SLOT_TYPES.md: Payline type only).

A reel is a fixed, ordered strip of symbols (docs/02_GAME_DESIGN.md #5:
"an ordered strip of symbols; depth (length) drives dilution"). A spin lands
on a random stop position on each strip and reads off `num_rows` consecutive
symbols (wrapping around), matching how a physical reel strip behaves.
"""

from dataclasses import dataclass


@dataclass
class Machine:
    reel_strips: list  # list[list[str]], one strip per reel
    num_rows: int

    @property
    def num_reels(self) -> int:
        return len(self.reel_strips)

    def spin(self, rng) -> list:
        """Return grid[reel_index][row_index] = symbol."""
        grid = []
        for strip in self.reel_strips:
            n = len(strip)
            stop = rng.randrange(n)
            window = [strip[(stop + row) % n] for row in range(self.num_rows)]
            grid.append(window)
        return grid


def build_strip(weights: dict) -> list:
    """Build a reel strip from a symbol -> count mapping, interleaved
    round-robin so identical symbols aren't clustered together.

    `weights` insertion order is preserved as the interleave order.
    """
    remaining = dict(weights)
    strip = []
    while any(count > 0 for count in remaining.values()):
        for symbol, count in weights.items():
            if remaining[symbol] > 0:
                strip.append(symbol)
                remaining[symbol] -= 1
    return strip
