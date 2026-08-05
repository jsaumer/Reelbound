## The payout resolver -- GDScript port of sim/paytable.py. Kept as a
## standalone, swappable module, same as the Python original.
##
## Payline rule (docs/07_SLOT_TYPES.md #1): a line pays if its leftmost run
## of identical symbols is at least `min_match` long, reading reel 0 -> N-1.
class_name Paytable
extends RefCounted


## `wild_symbol`, if non-empty, substitutes for whatever symbol a payline's
## leftmost run resolves to (D30 tier 1). A leading wild defers its
## identity to the first non-wild symbol scanned; an all-wild run pays the
## wild's own paytable entry. Empty string (the default) reproduces the
## pre-Phase-4 behavior exactly, since no real symbol is ever "".
static func resolve_spin(grid: Array, paylines: Array, paytable: Dictionary,
		bet: float, min_match: int = 3, wild_symbol: String = "") -> float:
	var total_multiplier := 0.0
	var num_reels := grid.size()

	for line in paylines:
		var symbols_on_line := []
		for reel in range(num_reels):
			symbols_on_line.append(grid[reel][line[reel]])

		var first = null
		var match_len := 0
		for symbol in symbols_on_line:
			var is_wild: bool = wild_symbol != "" and symbol == wild_symbol
			if first == null:
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
		if first == null:
			first = wild_symbol  # entire line was wild

		if match_len < min_match:
			continue

		if not paytable.has(first):
			continue
		var entry: Dictionary = paytable[first]

		var payout_multiplier = entry.get(match_len)
		if payout_multiplier == null:
			# No exact entry for this length -- fall back to the richest
			# defined length at or below the actual match.
			var best_length = -1
			for length in entry.keys():
				if length <= match_len and length > best_length:
					best_length = length
			if best_length == -1:
				continue
			payout_multiplier = entry[best_length]

		total_multiplier += payout_multiplier

	return total_multiplier * bet
