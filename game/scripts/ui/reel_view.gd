## One reel column of placeholder cells. Spins by flickering random symbols,
## then eases to a stop with a settle bounce. Each cell is a tier-colored
## panel with a generic silhouette icon on top -- color encodes value tier,
## shape encodes symbol identity (docs/04_ART_DIRECTION.md pillar 4).
##
## The settle -- the deceleration and the beat of not-yet-knowing before a
## symbol locks in -- is treated as the single most important piece of feel
## in this whole prototype (docs/04_ART_DIRECTION.md pillar 1). It is not
## decorative: Phase 1 already proved the economy is tense on paper: this
## is what proves that tension actually lands, spin to spin, in the body.
## If a change here makes the stop feel flat or mechanical, that's a
## regression worth treating as seriously as an economy bug.
class_name ReelView
extends VBoxContainer

const CELL_SIZE := Vector2(96, 96)
const ICON_SIZE := Vector2(60, 60)
const FLICKER_INTERVAL := 0.05
const SETTLE_BOUNCE_DURATION := 0.08 + 0.35  # matches _play_settle_bounce's two legs
const PULSE_CYCLE := 0.5

static var _texture_cache: Dictionary = {}

var _cell_panels: Array = []  # Array[Panel]
var _cell_styles: Array = []  # Array[StyleBoxFlat], one per cell
var _cell_icons: Array = []   # Array[TextureRect]
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

		var panel := Panel.new()
		panel.custom_minimum_size = CELL_SIZE
		panel.add_theme_stylebox_override("panel", style)

		var icon := TextureRect.new()
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.anchor_left = 0.5
		icon.anchor_top = 0.5
		icon.anchor_right = 0.5
		icon.anchor_bottom = 0.5
		icon.offset_left = -ICON_SIZE.x / 2.0
		icon.offset_top = -ICON_SIZE.y / 2.0
		icon.offset_right = ICON_SIZE.x / 2.0
		icon.offset_bottom = ICON_SIZE.y / 2.0
		panel.add_child(icon)

		_cell_panels.append(panel)
		_cell_styles.append(style)
		_cell_icons.append(icon)
		add_child(panel)


func set_symbols(symbols: Array) -> void:
	for i in range(_cell_panels.size()):
		_set_cell_symbol(i, symbols[i])


func _set_cell_symbol(index: int, symbol: String) -> void:
	_cell_icons[index].texture = _get_icon_texture(symbol)
	_cell_styles[index].bg_color = EconomyConfig.SYMBOL_COLORS.get(
			symbol, Color(0.5, 0.5, 0.5))


static func _get_icon_texture(symbol: String) -> Texture2D:
	if not _texture_cache.has(symbol):
		var path: String = EconomyConfig.SYMBOL_ICON_PATHS.get(symbol, "")
		_texture_cache[symbol] = load(path) if path != "" else null
	return _texture_cache[symbol]


## Flickers random symbols for `flicker_duration` seconds, lands on
## `final_symbols`, then plays a settle bounce. Awaitable.
func spin_to(final_symbols: Array, flicker_duration: float) -> void:
	var elapsed := 0.0
	while elapsed < flicker_duration:
		for i in range(_cell_panels.size()):
			_set_cell_symbol(i, _all_symbols[_rng.randi_range(0, _all_symbols.size() - 1)])
		await get_tree().create_timer(FLICKER_INTERVAL).timeout
		elapsed += FLICKER_INTERVAL

	set_symbols(final_symbols)
	await _play_settle_bounce()


## Pulses one already-settled cell's brightness for `duration` seconds --
## the "this already matches, will the next reel keep it going?" cue that
## anchors near-miss anticipation on the reels that already stopped.
func pulse_cell(row_index: int, duration: float) -> void:
	if row_index < 0 or row_index >= _cell_panels.size():
		return
	var panel: Panel = _cell_panels[row_index]
	var loops: int = max(1, int(round(duration / PULSE_CYCLE)))
	var tween := create_tween()
	tween.set_loops(loops)
	tween.tween_property(panel, "modulate", Color(1.5, 1.5, 1.15), PULSE_CYCLE / 2.0) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_property(panel, "modulate", Color(1, 1, 1), PULSE_CYCLE / 2.0) \
			.set_trans(Tween.TRANS_SINE)


func _play_settle_bounce() -> void:
	var start_y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", start_y + 14, 0.08) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", start_y, 0.35) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tween.finished
