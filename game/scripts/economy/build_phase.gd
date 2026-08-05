## The build phase (docs/02_GAME_DESIGN.md #3): spend a wallet on Relics
## (D28/D30 -- new symbol kinds not yet owned) and the reel editor (D29 --
## density tuning among symbols already owned), then load bankroll, with
## any leftover auto-converting (D5's no-waste failsafe). GDScript port of
## sim/build_phase.py.
##
## Phase 4 shelf content is deliberately thin: only Wild (D30 tier 1).
class_name BuildPhase
extends RefCounted

const WILD_SYMBOL := "wild"
const WILD_PAYTABLE_ENTRY := {3: 60, 4: 150, 5: 400}  # matches crown's tier

const WILD_RELIC_ID := "wild_unlock"
const WILD_RELIC_COST := 30.0

# Reel-editor cost per copy = the target symbol's own tier value * this
# factor. Pricier symbols cost more per copy added -- tunable, not
# validated against any particular budget yet.
const REEL_EDIT_COST_FACTOR := 0.5

# D32: the reel editor is presented as a few pre-rolled offers, not a
# free reel/symbol/quantity picker -- picking from a small drafted set
# reads as a real decision instead of spreadsheet-shopping (matches D5's
# stated goal, which the original freeform picker didn't actually meet).
const REEL_OFFER_COUNT := 3
const REEL_OFFER_QUANTITY := 1


## A shelf item -- D28's generic Shelf Item shape, player-facing name
## "Relics".
class RelicOffer:
	var id: String
	var cost: float
	var effect: String

	func _init(p_id: String, p_cost: float, p_effect: String) -> void:
		id = p_id
		cost = p_cost
		effect = p_effect


## The Phase-4 shelf: Wild, if not already owned. Empty once bought --
## there's nothing else to offer until D30's later tiers exist.
static func default_shelf(owned_symbols: Array) -> Array:
	if owned_symbols.has(WILD_SYMBOL):
		return []
	return [RelicOffer.new(WILD_RELIC_ID, WILD_RELIC_COST, "unlock_wild")]


## A single pre-rolled reel-editor purchase (D32): symbol, target reel,
## and quantity are all decided when the offer is generated, not picked
## freely by the player -- buying it applies the same fixed-slot swap
## edit_reel() always has, just reached through a curated choice instead
## of three raw dropdowns.
class ReelOffer:
	var reel_index: int
	var symbol: String
	var quantity: int
	var cost: float
	var bought: bool = false

	func _init(p_reel_index: int, p_symbol: String, p_quantity: int, p_cost: float) -> void:
		reel_index = p_reel_index
		symbol = p_symbol
		quantity = p_quantity
		cost = p_cost


var wallet: float
var reel_strips: Array
var paytable: Dictionary
var min_bet: float
var owned_symbols: Array
var loaded_bankroll: float = 0.0
var rng: RandomNumberGenerator
var _reel_offers: Array = []


func _init(p_wallet: float, p_reel_strips: Array, p_paytable: Dictionary,
		p_min_bet: float = 1.0, p_owned_symbols: Array = [],
		p_rng: RandomNumberGenerator = null) -> void:
	wallet = p_wallet
	reel_strips = p_reel_strips
	paytable = p_paytable
	min_bet = p_min_bet
	if p_owned_symbols.is_empty():
		# Whatever's already on the starting reels is, by definition, owned.
		var seen := {}
		for strip in reel_strips:
			for symbol in strip:
				seen[symbol] = true
		owned_symbols = seen.keys()
	else:
		owned_symbols = p_owned_symbols.duplicate()
	rng = p_rng if p_rng != null else RandomNumberGenerator.new()
	# D32: rolled once per build phase, from whatever's owned at the start
	# of it -- a symbol bought from the shelf mid-phase (Wild) doesn't
	# retroactively appear in this phase's offers, only the next one's.
	_reel_offers = _generate_reel_offers()


func shelf() -> Array:
	return default_shelf(owned_symbols)


func _generate_reel_offers() -> Array:
	var symbols: Array = owned_symbols.duplicate()
	symbols.sort()
	var offers := []
	for i in range(REEL_OFFER_COUNT):
		var symbol: String = symbols[rng.randi_range(0, symbols.size() - 1)]
		var reel_index := rng.randi_range(0, reel_strips.size() - 1)
		var cost := (ReelEditor.symbol_tier_value(symbol, paytable)
				* REEL_OFFER_QUANTITY * REEL_EDIT_COST_FACTOR)
		offers.append(ReelOffer.new(reel_index, symbol, REEL_OFFER_QUANTITY, cost))
	return offers


func reel_offers() -> Array:
	return _reel_offers


## Buys one of this build phase's pre-rolled offers (D32). False if the
## index is out of range, already bought, or unaffordable -- edit_reel()
## (reused here, not duplicated) is the actual source of truth on
## affordability.
func buy_reel_offer(offer_index: int) -> bool:
	if offer_index < 0 or offer_index >= _reel_offers.size():
		return false
	var offer: ReelOffer = _reel_offers[offer_index]
	if offer.bought:
		return false
	if edit_reel(offer.reel_index, offer.symbol, offer.quantity):
		offer.bought = true
		return true
	return false


func buy_relic(relic_id: String) -> bool:
	var offer: RelicOffer = null
	for r in shelf():
		if r.id == relic_id:
			offer = r
			break
	if offer == null or offer.cost > wallet + 1e-9:
		return false
	wallet -= offer.cost
	if offer.effect == "unlock_wild":
		if not owned_symbols.has(WILD_SYMBOL):
			owned_symbols.append(WILD_SYMBOL)
		if not paytable.has(WILD_SYMBOL):
			paytable[WILD_SYMBOL] = WILD_PAYTABLE_ENTRY.duplicate()
	return true


func reel_edit_cost(target_symbol: String, quantity: int) -> float:
	return ReelEditor.symbol_tier_value(target_symbol, paytable) * quantity * REEL_EDIT_COST_FACTOR


## D29: fixed-slot swap on a chosen reel. No-ops (returns false) if the
## symbol isn't owned yet, the quantity is non-positive, or the wallet
## can't cover it -- the caller shouldn't have offered the action in the
## first place, but this keeps it safe either way.
func edit_reel(reel_index: int, target_symbol: String, quantity: int) -> bool:
	if not owned_symbols.has(target_symbol) or quantity <= 0:
		return false
	var cost := reel_edit_cost(target_symbol, quantity)
	if cost > wallet + 1e-9:
		return false
	wallet -= cost
	reel_strips[reel_index] = ReelEditor.apply_reel_edit(
			reel_strips[reel_index], target_symbol, quantity, paytable)
	return true


## D5: show what a prospective load buys in spins, before committing --
## bankroll is time.
func spins_from_load(amount: float) -> float:
	return amount / min_bet if min_bet > 0 else 0.0


func load_bankroll(amount: float) -> bool:
	if amount <= 0 or amount > wallet + 1e-9:
		return false
	wallet -= amount
	loaded_bankroll += amount
	return true


## D5's no-waste failsafe: any wallet remaining auto-converts to bankroll.
## Returns {reel_strips, starting_bankroll, wild_symbol}; wild_symbol is
## "" if Wild wasn't bought.
func finalize() -> Dictionary:
	var starting_bankroll := loaded_bankroll + wallet
	wallet = 0.0
	var wild_symbol := WILD_SYMBOL if owned_symbols.has(WILD_SYMBOL) else ""
	return {
		"reel_strips": reel_strips,
		"starting_bankroll": starting_bankroll,
		"wild_symbol": wild_symbol,
	}
