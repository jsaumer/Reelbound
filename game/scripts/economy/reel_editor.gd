## D29: the reel editor -- fixed-slot symbol density tuning among symbols
## the player already owns. GDScript port of sim/reel_editor.py. No shelf
## slot involved (that's for symbol kinds not yet owned -- see
## reel_editor vs shelf in docs/02_GAME_DESIGN.md #3).
##
## A purchase displaces copies of a chosen reel's *cheapest-tier symbol
## present* (ranked by paytable value, cascading to the next-cheapest once
## a tier is exhausted) with copies of the target symbol, keeping that
## reel's total strip length unchanged. Zero edits leaves the machine
## exactly as it started (the validated Phase-1/2/3 baseline).
class_name ReelEditor
extends RefCounted


## A symbol's tier for ranking "cheapest filler present" -- the richest
## defined payout in its paytable entry. A symbol absent from the paytable
## (shouldn't normally happen) ranks as free/cheapest.
static func symbol_tier_value(symbol: String, paytable: Dictionary) -> float:
	if not paytable.has(symbol):
		return 0.0
	var entry: Dictionary = paytable[symbol]
	var best := 0.0
	for value in entry.values():
		best = max(best, float(value))
	return best


## Returns a new reel strip with up to `quantity` copies of the reel's
## current cheapest-tier symbol converted to `target_symbol`, one at a
## time, re-ranking after each conversion so it cascades to the next tier
## once the previous one is exhausted. Strip length is unchanged. Never
## converts existing copies of `target_symbol` into itself. Stops early
## (rather than erroring) if the reel runs out of anything left to convert.
static func apply_reel_edit(reel_strip: Array, target_symbol: String, quantity: int,
		paytable: Dictionary) -> Array:
	var strip: Array = reel_strip.duplicate()
	if quantity <= 0:
		return strip

	var remaining := quantity
	while remaining > 0:
		var candidates := []
		for s in strip:
			if s != target_symbol:
				candidates.append(s)
		if candidates.is_empty():
			break

		var cheapest = candidates[0]
		var cheapest_value := symbol_tier_value(cheapest, paytable)
		for s in candidates:
			var value := symbol_tier_value(s, paytable)
			if value < cheapest_value:
				cheapest = s
				cheapest_value = value

		strip[strip.find(cheapest)] = target_symbol
		remaining -= 1

	return strip
