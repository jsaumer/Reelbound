"""The build phase (docs/02_GAME_DESIGN.md #3): spend a wallet on Relics
(D28/D30 -- new symbol kinds not yet owned) and the reel editor (D29 --
density tuning among symbols already owned), then load bankroll, with any
leftover auto-converting (D5's no-waste failsafe).

Phase 4 shelf content is deliberately thin: only Wild (D30 tier 1).
Tiers 2/3 (above-crown symbols, enchantment-charge Relics) are designed
but not built -- see docs/06_OPEN_QUESTIONS.md D30.
"""

from dataclasses import dataclass, field

from sim.reel_editor import apply_reel_edit, symbol_tier_value

WILD_SYMBOL = "wild"
WILD_PAYTABLE_ENTRY = {3: 60, 4: 150, 5: 400}  # matches crown's tier

WILD_RELIC_ID = "wild_unlock"
WILD_RELIC_COST = 30.0

# Reel-editor cost per copy = the target symbol's own tier value * this
# factor. Pricier symbols cost more per copy added -- tunable, not
# validated against any particular budget yet.
REEL_EDIT_COST_FACTOR = 0.5


@dataclass
class RelicOffer:
    """A shelf item -- D28's generic Shelf Item shape. `effect` is a plain
    tag string for now; Phase 4 only ever produces "unlock_wild"."""
    id: str
    cost: float
    effect: str


def default_shelf(owned_symbols: set) -> list:
    """The Phase-4 shelf: Wild, if not already owned. Empty once bought --
    there's nothing else to offer until D30's later tiers exist."""
    if WILD_SYMBOL in owned_symbols:
        return []
    return [RelicOffer(id=WILD_RELIC_ID, cost=WILD_RELIC_COST, effect="unlock_wild")]


@dataclass
class BuildPhase:
    wallet: float
    reel_strips: list
    paytable: dict
    min_bet: float = 1.0
    owned_symbols: set = field(default_factory=set)
    loaded_bankroll: float = 0.0

    def __post_init__(self):
        if not self.owned_symbols:
            # Whatever's already on the starting reels is, by definition, owned.
            self.owned_symbols = {s for strip in self.reel_strips for s in strip}

    def shelf(self) -> list:
        return default_shelf(self.owned_symbols)

    def buy_relic(self, relic_id: str) -> bool:
        offer = next((r for r in self.shelf() if r.id == relic_id), None)
        if offer is None or offer.cost > self.wallet + 1e-9:
            return False
        self.wallet -= offer.cost
        if offer.effect == "unlock_wild":
            self.owned_symbols.add(WILD_SYMBOL)
            self.paytable.setdefault(WILD_SYMBOL, dict(WILD_PAYTABLE_ENTRY))
        return True

    def reel_edit_cost(self, target_symbol: str, quantity: int) -> float:
        return symbol_tier_value(target_symbol, self.paytable) * quantity * REEL_EDIT_COST_FACTOR

    def edit_reel(self, reel_index: int, target_symbol: str, quantity: int) -> bool:
        """D29: fixed-slot swap on a chosen reel. No-ops (returns False)
        if the symbol isn't owned yet, the quantity is non-positive, or
        the wallet can't cover it -- the caller shouldn't have offered
        the action in the first place, but this keeps it safe either way."""
        if target_symbol not in self.owned_symbols or quantity <= 0:
            return False
        cost = self.reel_edit_cost(target_symbol, quantity)
        if cost > self.wallet + 1e-9:
            return False
        self.wallet -= cost
        self.reel_strips[reel_index] = apply_reel_edit(
            self.reel_strips[reel_index], target_symbol, quantity, self.paytable)
        return True

    def spins_from_load(self, amount: float) -> float:
        """D5: show what a prospective load buys in spins, before
        committing -- bankroll is time."""
        return amount / self.min_bet if self.min_bet > 0 else 0.0

    def load_bankroll(self, amount: float) -> bool:
        if amount <= 0 or amount > self.wallet + 1e-9:
            return False
        self.wallet -= amount
        self.loaded_bankroll += amount
        return True

    def finalize(self) -> tuple:
        """D5's no-waste failsafe: any wallet remaining auto-converts to
        bankroll. Returns (reel_strips, starting_bankroll, wild_symbol)."""
        starting_bankroll = self.loaded_bankroll + self.wallet
        self.wallet = 0.0
        wild_symbol = WILD_SYMBOL if WILD_SYMBOL in self.owned_symbols else None
        return self.reel_strips, starting_bankroll, wild_symbol
