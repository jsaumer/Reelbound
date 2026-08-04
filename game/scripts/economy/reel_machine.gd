## Reel strips and the machine grid (docs/07_SLOT_TYPES.md: Payline only).
## GDScript port of sim/reel.py.
class_name ReelMachine
extends RefCounted

var reel_strips: Array  # Array[Array[String]], one strip per reel
var num_rows: int


func _init(strips: Array, rows: int) -> void:
	reel_strips = strips
	num_rows = rows


func num_reels() -> int:
	return reel_strips.size()


## Returns grid[reel_index][row_index] = symbol.
func spin(rng: RandomNumberGenerator) -> Array:
	var grid := []
	for strip in reel_strips:
		var n: int = strip.size()
		var stop: int = rng.randi_range(0, n - 1)
		var window := []
		for row in range(num_rows):
			window.append(strip[(stop + row) % n])
		grid.append(window)
	return grid


## Build a reel strip from a symbol -> count Dictionary, interleaved
## round-robin so identical symbols aren't clustered together. Dictionary
## insertion order is preserved (Godot 4 dictionaries are ordered).
static func build_strip(weights: Dictionary) -> Array:
	var remaining := weights.duplicate()
	var strip := []
	var any_left := true
	while any_left:
		any_left = false
		for symbol in weights.keys():
			if remaining[symbol] > 0:
				strip.append(symbol)
				remaining[symbol] -= 1
				any_left = true
	return strip
