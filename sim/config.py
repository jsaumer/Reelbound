"""All economy parameters in one place (per the Phase-1 brief: "all key
economy parameters exposed at the top / via config, not scattered as magic
numbers"). D18 (spin-cap tuning) and D12 (quota curve) are OPEN decisions --
`spin_cap` and `quota` are exposed as plain fields here, not hardcoded,
precisely so the harness can sweep them to find the answer.
"""

from dataclasses import dataclass, field

from sim.reel import build_strip


@dataclass
class MachineConfig:
    num_rows: int
    reel_strips: list          # list[list[str]], one strip per reel
    paylines: list             # list[tuple[int, ...]], row index per reel
    paytable: dict             # symbol -> {match_length: payout_multiplier}
    min_match: int = 3

    @property
    def num_reels(self) -> int:
        return len(self.reel_strips)


@dataclass
class EconomyConfig:
    starting_bankroll: float
    quota: float
    spin_cap: int
    min_bet: float
    max_bet: float
    # Baseline bank-vs-gamble-up odds (docs/02_GAME_DESIGN.md #4, Phase 3).
    # No locked decision pins this number -- exposed here, not hardcoded
    # in play_phase, so it's a parameter to tune like quota/spin_cap.
    gamble_win_probability: float = 0.5
    # Chance the gamble-up choice is even offered on a given win. Per
    # playtest feedback, being asked to bank-or-gamble on *every* win got
    # old fast -- the offer itself is meant to eventually be gated behind
    # an obtainable item/boon (Phase 4/5, not built yet); this probability
    # is the buildable part of that ask today. When the offer doesn't
    # appear, the win auto-banks (same as if the player had chosen bank).
    gamble_offer_probability: float = 0.25
    # Post-quota cash-out discount (D23). Deliberately unfavorable -- the
    # guaranteed cash-out is this fraction of the projected value of
    # playing on, so cashing out is a real trade-off, not a free upgrade.
    cash_out_discount: float = 0.4


@dataclass
class SimConfig:
    machine: MachineConfig
    economy: EconomyConfig
    seed: int = 12345


# --- Default Payline machine (docs/07_SLOT_TYPES.md: start with Payline only) ---
#
# Symbols tiered low -> high (docs/03_IDEA_BACKLOG.md: "gems tiered by
# color... a clean value hierarchy players read instantly"). Weights set
# each symbol's frequency per reel strip; rarer symbols pay more.

DEFAULT_SYMBOL_WEIGHTS = {
    "cherry": 8,
    "lemon": 8,
    "bell": 6,
    "clover": 4,
    "bar": 3,
    "star": 2,
    "crown": 1,
}

DEFAULT_PAYTABLE = {
    "cherry": {3: 2, 4: 5, 5: 10},
    "lemon": {3: 2, 4: 5, 5: 10},
    "bell": {3: 4, 4: 10, 5: 25},
    "clover": {3: 8, 4: 20, 5: 50},
    "bar": {3: 15, 4: 40, 5: 100},
    "star": {3: 30, 4: 80, 5: 200},
    "crown": {3: 60, 4: 150, 5: 400},
}

# 5 reels x 3 rows, 5 classic paylines: top, middle, bottom, V, inverted-V.
DEFAULT_PAYLINES = [
    (0, 0, 0, 0, 0),
    (1, 1, 1, 1, 1),
    (2, 2, 2, 2, 2),
    (0, 1, 2, 1, 0),
    (2, 1, 0, 1, 2),
]

DEFAULT_NUM_REELS = 5
DEFAULT_NUM_ROWS = 3


def default_machine_config() -> MachineConfig:
    strip = build_strip(DEFAULT_SYMBOL_WEIGHTS)
    reel_strips = [list(strip) for _ in range(DEFAULT_NUM_REELS)]
    return MachineConfig(
        num_rows=DEFAULT_NUM_ROWS,
        reel_strips=reel_strips,
        paylines=DEFAULT_PAYLINES,
        paytable=DEFAULT_PAYTABLE,
        min_match=3,
    )


def default_economy_config() -> EconomyConfig:
    # Tuned so naive flat_mid play clears the Phase-1 tension band (see
    # docs/05_ROADMAP.md: winnable ~40-60%). starting_bankroll / min_bet /
    # max_bet give flat_mid a deterministic 50-spin natural ceiling
    # (bankroll only ever drains -- D3 -- so a flat bet burns it on a fixed
    # schedule); spin_cap=45 sits below that ceiling so it's the live
    # constraint (D18), and quota=65 lands the win rate near the middle of
    # the band. Both quota and spin_cap are sweepable via `sim.harness.sweep`.
    return EconomyConfig(
        starting_bankroll=100.0,
        quota=65.0,
        spin_cap=45,
        min_bet=1.0,
        max_bet=3.0,
        gamble_win_probability=0.5,   # fair coin flip, see field docstring
        gamble_offer_probability=0.25,  # see field docstring
        cash_out_discount=0.4,        # see field docstring (D23)
    )


def default_sim_config(seed: int = 12345) -> SimConfig:
    return SimConfig(
        machine=default_machine_config(),
        economy=default_economy_config(),
        seed=seed,
    )
