## The payout resolver -- GDScript port of sim/paytable.py. Kept as a
## standalone, swappable module, same as the Python original.
##
## Payline rule (docs/07_SLOT_TYPES.md #1): a line pays if its leftmost run
## of identical symbols is at least `min_match` long, reading reel 0 -> N-1.
class_name Paytable
extends RefCounted


static func resolve_spin(grid: Array, paylines: Array, paytable: Dictionary,
		bet: float, min_match: int = 3) -> float:
	var total_multiplier := 0.0
	var num_reels := grid.size()

	for line in paylines:
		var symbols_on_line := []
		for reel in range(num_reels):
			symbols_on_line.append(grid[reel][line[reel]])
		var first = symbols_on_line[0]

		var match_len := 1
		for i in range(1, symbols_on_line.size()):
			if symbols_on_line[i] != first:
				break
			match_len += 1

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
