## All economy parameters in one place -- GDScript port of sim/config.py's
## defaults, kept numerically identical so what you feel in Godot matches
## the numbers validated by the Phase-1 sim (55.1% win rate at 20k runs).
## D18/D12 (locked, docs/06_OPEN_QUESTIONS.md): spin_cap and quota here are
## the same tuned values sim/config.py ships.
class_name EconomyConfig
extends RefCounted

const DEFAULT_SYMBOL_WEIGHTS := {
	"cherry": 8,
	"lemon": 8,
	"bell": 6,
	"clover": 4,
	"bar": 3,
	"star": 2,
	"crown": 1,
}

const DEFAULT_PAYTABLE := {
	"cherry": {3: 2, 4: 5, 5: 10},
	"lemon": {3: 2, 4: 5, 5: 10},
	"bell": {3: 4, 4: 10, 5: 25},
	"clover": {3: 8, 4: 20, 5: 50},
	"bar": {3: 15, 4: 40, 5: 100},
	"star": {3: 30, 4: 80, 5: 200},
	"crown": {3: 60, 4: 150, 5: 400},
}

# 5 reels x 3 rows, 5 classic paylines: top, middle, bottom, V, inverted-V.
const DEFAULT_PAYLINES := [
	[0, 0, 0, 0, 0],
	[1, 1, 1, 1, 1],
	[2, 2, 2, 2, 2],
	[0, 1, 2, 1, 0],
	[2, 1, 0, 1, 2],
]

const NUM_REELS := 5
const NUM_ROWS := 3
const MIN_MATCH := 3

# Tuned so naive flat-bet play clears the Phase-1 tension band (D12/D18).
const STARTING_BANKROLL := 100.0
const QUOTA := 65.0
const SPIN_CAP := 45
const MIN_BET := 1.0
const MAX_BET := 3.0

# Phase 3 (docs/05_ROADMAP.md). Baseline bank-vs-gamble-up odds -- a fair
# coin flip (docs/02_GAME_DESIGN.md #4).
const GAMBLE_WIN_PROBABILITY := 0.5

# D23: post-quota cash-out discount. Deliberately unfavorable -- the
# guaranteed cash-out is this fraction of the projected value of playing
# on, so cashing out is a real trade-off, not a free upgrade.
const CASH_OUT_DISCOUNT := 0.4

# Symbol -> display color, for the placeholder grey-box reel cells.
const SYMBOL_COLORS := {
	"cherry": Color(0.85, 0.25, 0.3),
	"lemon": Color(0.9, 0.85, 0.2),
	"bell": Color(0.85, 0.65, 0.2),
	"clover": Color(0.3, 0.7, 0.35),
	"bar": Color(0.6, 0.4, 0.2),
	"star": Color(0.4, 0.55, 0.9),
	"crown": Color(0.75, 0.35, 0.85),
}

# Symbol -> generic silhouette icon (placeholder art, not final style --
# see docs/04_ART_DIRECTION.md). Read together with SYMBOL_COLORS: color
# encodes value tier, shape encodes identity (pillar 4, "readable symbol
# hierarchy" -- shape/color/size together, not one alone).
const SYMBOL_ICON_PATHS := {
	"cherry": "res://assets/symbols/cherry.svg",
	"lemon": "res://assets/symbols/lemon.svg",
	"bell": "res://assets/symbols/bell.svg",
	"clover": "res://assets/symbols/clover.svg",
	"bar": "res://assets/symbols/bar.svg",
	"star": "res://assets/symbols/star.svg",
	"crown": "res://assets/symbols/crown.svg",
}


static func build_default_reel_strips() -> Array:
	var strip := ReelMachine.build_strip(DEFAULT_SYMBOL_WEIGHTS)
	var strips := []
	for i in range(NUM_REELS):
		strips.append(strip.duplicate())
	return strips
