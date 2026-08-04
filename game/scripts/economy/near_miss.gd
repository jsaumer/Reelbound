## Detects a developing line before it's fully revealed -- the reel whose
## reveal decides whether it extends into (or upgrades) a payout. Pure
## data-in/data-out (final grid + paylines + paytable -> which reel to hold
## on) so it's testable without touching the UI; reel_view.gd/main.gd use
## the result to slow that reel's reveal and pulse the cells already
## feeding into it. This is what "near-miss anticipation" actually is: not
## a separate mechanic, just noticing early that a line is close.
class_name NearMiss
extends RefCounted


## Returns {reel_index, symbol, run_length, row_pattern, potential_payout_multiplier}
## for the richest developing line, or {} if nothing is developing.
## `reel_index` is the 0-based reel whose reveal decides the line.
static func find_anticipation(final_grid: Array, paylines: Array, paytable: Dictionary) -> Dictionary:
	var num_reels: int = final_grid.size()
	var best: Dictionary = {}
	var best_upside := 0.0

	for line in paylines:
		var first = final_grid[0][line[0]]
		var run_length := 1
		for reel in range(1, num_reels):
			if final_grid[reel][line[reel]] != first:
				break
			run_length += 1

		# < 2: nothing has even started matching yet. >= num_reels: the line
		# is already fully resolved, there's nothing left to decide.
		if run_length < 2 or run_length >= num_reels:
			continue
		if not paytable.has(first):
			continue
		var entry: Dictionary = paytable[first]
		if not entry.has(run_length + 1):
			continue

		var upside: float = entry[run_length + 1]
		if best.is_empty() or upside > best_upside:
			best_upside = upside
			best = {
				"reel_index": run_length,
				"symbol": first,
				"run_length": run_length,
				"row_pattern": line,
				"potential_payout_multiplier": upside,
			}

	return best
