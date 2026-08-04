## Theoretical hit probabilities and RTP, computed live from whatever
## paytable/reel strips are actually loaded -- never a hardcoded symbol
## list. This is what keeps the in-game paytable/odds display correct once
## the build phase (Phase 4) lets players buy symbols onto specific reels:
## a symbol added to just one reel changes its odds, and this recomputes
## from the real strip contents rather than an assumed uniform reel.
class_name Odds
extends RefCounted


## { symbol: { match_length: probability } } -- probability that a single
## payline pays out exactly `match_length` of `symbol`, left-anchored at
## reel 0. Every payline shares these odds regardless of which row it
## reads, because match length is always evaluated in reel order 0..N-1;
## only the row differs between paylines, and row doesn't affect the
## marginal probability of a symbol landing on a given reel.
static func symbol_match_probabilities(reel_strips: Array, paytable: Dictionary) -> Dictionary:
	var reel_probs := _per_reel_symbol_probabilities(reel_strips)
	var num_reels := reel_strips.size()
	var result := {}

	for symbol in paytable.keys():
		var entry: Dictionary = paytable[symbol]
		var by_length := {}
		for length in entry.keys():
			var p := 1.0
			for r in range(length):
				p *= (reel_probs[r].get(symbol, 0.0) if r < num_reels else 0.0)
			if length < num_reels:
				p *= (1.0 - reel_probs[length].get(symbol, 0.0))
			by_length[length] = p
		result[symbol] = by_length

	return result


## Expected payout per unit bet per spin, across every payline. Every
## payline has identical odds (see above), so this is (per-line EV) times
## the number of paylines.
static func theoretical_rtp(reel_strips: Array, paylines: Array, paytable: Dictionary) -> float:
	var probs := symbol_match_probabilities(reel_strips, paytable)
	var ev_per_line := 0.0
	for symbol in paytable.keys():
		var entry: Dictionary = paytable[symbol]
		for length in entry.keys():
			ev_per_line += probs[symbol][length] * entry[length]
	return ev_per_line * paylines.size()


static func _per_reel_symbol_probabilities(reel_strips: Array) -> Array:
	var reel_probs := []
	for strip in reel_strips:
		var counts := {}
		for s in strip:
			counts[s] = counts.get(s, 0) + 1
		var probs := {}
		for s in counts.keys():
			probs[s] = float(counts[s]) / strip.size()
		reel_probs.append(probs)
	return reel_probs
