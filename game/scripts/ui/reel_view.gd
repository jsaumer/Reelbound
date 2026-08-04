## One reel column of placeholder "grey box" cells. Spins by flickering
## random symbols, then eases to a stop with a settle bounce.
##
## This settle -- the deceleration and the beat of not-yet-knowing before a
## symbol locks in -- is treated as the single most important piece of feel
## in this whole prototype (docs/04_ART_DIRECTION.md pillar 1). It is not
## decorative: Phase 1 already proved the economy is tense on paper: this
## is what proves that tension actually lands, spin to spin, in the body.
## If a change here makes the stop feel flat or mechanical, that's a
## regression worth treating as seriously as an economy bug.
class_name ReelView
extends VBoxContainer

const CELL_SIZE := Vector2(96, 96)
const FLICKER_INTERVAL := 0.05

var _cells: Array = []       # Array[Label]
var _cell_styles: Array = [] # Array[StyleBoxFlat], one per cell
var _all_symbols: Array = []
var _rng := RandomNumberGenerator.new()


func setup(num_rows: int, all_symbols: Array) -> void:
	_all_symbols = all_symbols
	add_theme_constant_override("separation", 4)
	for i in range(num_rows):
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.24)
		style.set_border_width_all(2)
		style.border_color = Color(0.4, 0.4, 0.46)
		style.set_corner_radius_all(6)

		var label := Label.new()
		label.custom_minimum_size = CELL_SIZE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 30)
		label.add_theme_stylebox_override("normal", style)

		_cells.append(label)
		_cell_styles.append(style)
		add_child(label)


func set_symbols(symbols: Array) -> void:
	for i in range(_cells.size()):
		_set_cell_symbol(i, symbols[i])


func _set_cell_symbol(index: int, symbol: String) -> void:
	_cells[index].text = symbol.substr(0, 1).to_upper()
	_cell_styles[index].bg_color = EconomyConfig.SYMBOL_COLORS.get(
			symbol, Color(0.5, 0.5, 0.5))


## Flickers random symbols for `flicker_duration` seconds, lands on
## `final_symbols`, then plays a settle bounce. Awaitable.
func spin_to(final_symbols: Array, flicker_duration: float) -> void:
	var elapsed := 0.0
	while elapsed < flicker_duration:
		for i in range(_cells.size()):
			_set_cell_symbol(i, _all_symbols[_rng.randi_range(0, _all_symbols.size() - 1)])
		await get_tree().create_timer(FLICKER_INTERVAL).timeout
		elapsed += FLICKER_INTERVAL

	set_symbols(final_symbols)
	await _play_settle_bounce()


func _play_settle_bounce() -> void:
	var start_y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", start_y + 14, 0.08) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", start_y, 0.35) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tween.finished
