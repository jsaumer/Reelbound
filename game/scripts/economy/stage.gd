## D31: the stage path -- a linear sequence of nodes over one continuous
## economy. GDScript port of sim/stage.py, adapted the same way play_phase.gd
## adapts sim/play_phase.py: a UI-driven state machine advanced one node at
## a time, instead of a batch loop with pluggable strategies.
##
## Composes a PlayPhase rather than reimplementing it -- Stage only adds
## node-path bookkeeping (which node is next, ELITE's bet bump, TREASURE's
## free bonus). D6's dual limiter, D24/D25's gamble-up, and D23's cash-out
## choice all still live in play_phase.gd; Stage calls back into its
## internal (underscore-prefixed but GDScript doesn't enforce privacy)
## _after_pending_resolved() after a free node, the same way sim/stage.py
## reuses play_phase.py's private helpers directly.
##
## Phase 4 content: MINOR (plain spin) and TREASURE (small free winnings,
## no cost) are real. ELITE forces a bigger bet with no payout bonus --
## EV-neutral versus choosing to bet bigger manually, so it's a pacing/
## tempo variation, not a free-lunch node. EVENT and REST are designed (the
## NodeType exists) but not populated in the default path yet -- they need
## boon/curse content (Phase 5) to mean anything.
class_name Stage
extends RefCounted

enum NodeType { MINOR, ELITE, EVENT, REST, TREASURE }

# Tuned against sim/stage.py's 20k-run tension-band check, not guessed --
# see docs/05_ROADMAP.md's Phase 4 balance note. The economy is spin-cap-
# bound (D18), so free winnings or bet-variance bumps convert a
# disproportionate share of near-miss losses into wins even at small
# values; both constants and their default frequency had to be small AND
# rare to keep the D12 40-60% tension band intact.
const ELITE_BET_MULTIPLIER := 1.25
const TREASURE_WINNINGS_BONUS := 0.5


## A small, fixed pattern for Phase 4 -- content is thin (D31), types cycle
## to give some turn-to-turn variety without a real balancing pass yet.
## ELITE and TREASURE are deliberately rare (1-in-15 each).
static func default_node_sequence() -> Array:
	var sequence := []
	for i in range(13):
		sequence.append(NodeType.MINOR)
	sequence.append(NodeType.ELITE)
	sequence.append(NodeType.TREASURE)
	return sequence


var play_phase: PlayPhase
var node_sequence: Array
var node_index: int = 0
var nodes_visited: Array = []


func _init(p_play_phase: PlayPhase, p_node_sequence: Array) -> void:
	play_phase = p_play_phase
	node_sequence = p_node_sequence


func current_node_type() -> int:
	return node_sequence[node_index % node_sequence.size()]


func is_over() -> bool:
	return play_phase.is_over()


func has_pending_decision() -> bool:
	return play_phase.has_pending_decision()


## True for TREASURE/EVENT/REST -- call resolve_free_node() instead of
## spin() when this is true.
func is_free_node() -> bool:
	var node := current_node_type()
	return node == NodeType.TREASURE or node == NodeType.EVENT or node == NodeType.REST


## Resolves a TREASURE/EVENT/REST node -- no bet, no spin. No-ops if the
## stage already ended or a prior decision hasn't been resolved yet.
func resolve_free_node() -> void:
	if play_phase.is_over() or play_phase.has_pending_decision():
		return

	var node := current_node_type()
	nodes_visited.append(node)
	node_index += 1

	if node == NodeType.TREASURE:
		play_phase.pools.add_to_pending(TREASURE_WINNINGS_BONUS)
		play_phase.pools.commit_pending_to_winnings()

	# EVENT/REST: defined, not populated by default_node_sequence() yet --
	# a no-op turn if one somehow shows up in a caller-supplied sequence.
	play_phase._after_pending_resolved()


## MINOR or ELITE: spends `bet` (bumped by ELITE_BET_MULTIPLIER on an
## ELITE node, same clamp-to-bankroll behavior as PlayPhase.spin()) and
## resolves one spin. No-ops (returns 0.0) if the stage already ended or a
## prior decision hasn't been resolved.
func spin(bet: float) -> float:
	if play_phase.is_over() or play_phase.has_pending_decision():
		return 0.0

	var node := current_node_type()
	nodes_visited.append(node)
	node_index += 1

	var actual_bet := bet
	if node == NodeType.ELITE:
		actual_bet *= ELITE_BET_MULTIPLIER

	return play_phase.spin(actual_bet)


func bank_pending() -> void:
	play_phase.bank_pending()


func gamble_pending() -> bool:
	return play_phase.gamble_pending()


func keep_playing() -> void:
	play_phase.keep_playing()


func cash_out() -> void:
	play_phase.cash_out()
