## Reusable paytable/odds overlay. Any slot-gameplay screen adds one of
## these as a child and calls open_for(...) with whatever machine is
## actually running -- this never assumes a fixed symbol set, so it stays
## correct once the build phase (Phase 4) lets players add purchased
## symbols to specific reels. Intended to be present on every play-phase
## screen, not just this Phase-2 prototype's.
class_name PaytablePanel
extends Control

var _list: VBoxContainer


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var card := PanelContainer.new()
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -220
	card.offset_top = -260
	card.offset_right = 220
	card.offset_bottom = 260
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.13, 0.17)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.4, 0.46)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation", 10)
	card.add_child(frame)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "Paytable & Odds"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(28, 28)
	close_button.pressed.connect(func(): hide())
	header.add_child(close_button)
	frame.add_child(header)
	frame.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide()


## Rebuilds the panel content from whatever machine/paytable is currently
## running, then shows it. Call this fresh every time -- never cache the
## built rows, since the paytable can change between calls (symbols
## purchased/added).
##
## `min_match` is Payline-specific (the other four types in
## docs/07_SLOT_TYPES.md -- ways-to-win, cluster+cascade, hold-and-spin,
## Megaways -- pay by a different rule entirely, e.g. adjacency or cluster
## size, not a minimum run length). Once those types exist as real modules
## (Phase 5.5, not yet built), _build_rules_section is the one place that
## needs a per-type branch to describe each one; nothing else here should
## need to change, since the symbol/odds list below is already
## type-agnostic.
func open_for(reel_strips: Array, paylines: Array, paytable: Dictionary,
		min_match: int, quota: float) -> void:
	for child in _list.get_children():
		child.queue_free()

	_list.add_child(_build_rules_section(reel_strips, paylines, min_match))
	_list.add_child(HSeparator.new())

	var probs := Odds.symbol_match_probabilities(reel_strips, paytable)
	var rtp := Odds.theoretical_rtp(reel_strips, paylines, paytable)

	var summary := Label.new()
	summary.text = "%d paylines  --  theoretical RTP %.1f%%  --  quota %.0f" % [
			paylines.size(), rtp * 100.0, quota]
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD
	_list.add_child(summary)
	_list.add_child(HSeparator.new())

	# Richest-payout symbol first. Sorted by actual payout value, not
	# insertion order, so a newly added/purchased symbol slots in wherever
	# it actually ranks.
	var symbols: Array = paytable.keys()
	symbols.sort_custom(func(a, b): return _richest(paytable[a]) > _richest(paytable[b]))

	for symbol in symbols:
		_list.add_child(_build_symbol_row(symbol, paytable[symbol], probs.get(symbol, {})))

	visible = true


## Describes the actual match rule -- Payline only, for now (docs/07:
## "start with Payline only"). Built entirely from the live paylines/
## min_match, not a hardcoded description, so it stays correct if those
## ever change (more/fewer lines, a different min_match).
func _build_rules_section(reel_strips: Array, paylines: Array, min_match: int) -> Control:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var heading := Label.new()
	heading.text = "Payline"
	heading.add_theme_font_size_override("font_size", 16)
	section.add_child(heading)

	var num_reels: int = reel_strips.size()
	var rule := Label.new()
	rule.text = ("A line pays if its leftmost %d+ symbols (of %d reels) match, "
			+ "reading left to right from reel 1.") % [min_match, num_reels]
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD
	rule.add_theme_font_size_override("font_size", 13)
	section.add_child(rule)

	# num_rows isn't passed in directly -- derive it from the pattern data
	# itself (highest row index used, +1) rather than adding another
	# parameter, so this stays correct if the grid shape ever changes.
	var num_rows := 1
	for pattern in paylines:
		for row in pattern:
			num_rows = max(num_rows, row + 1)

	for i in range(paylines.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var diagram := PaylineDiagram.new()
		diagram.custom_minimum_size = Vector2(num_reels * 16, num_rows * 16)
		diagram.setup(num_reels, num_rows, paylines[i])
		row.add_child(diagram)

		var label := Label.new()
		label.text = "Line %d" % (i + 1)
		label.add_theme_font_size_override("font_size", 13)
		row.add_child(label)

		section.add_child(row)

	return section


func _richest(entry: Dictionary) -> float:
	var best := 0.0
	for length in entry.keys():
		best = max(best, entry[length])
	return best


func _build_symbol_row(symbol: String, entry: Dictionary, probs: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(40, 40)
	# Without these, an HBoxContainer's default cross-axis FILL stretches
	# this to match the tallest sibling (the multi-line details column
	# below), which drags the icon inside it oversized along with it.
	# clip_contents is a belt-and-suspenders guard against any further
	# layout surprise inflating the icon past this box.
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	swatch.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	swatch.clip_contents = true
	swatch.color = EconomyConfig.SYMBOL_COLORS.get(symbol, Color(0.5, 0.5, 0.5))
	row.add_child(swatch)

	var icon_path: String = EconomyConfig.SYMBOL_ICON_PATHS.get(symbol, "")
	if icon_path != "":
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = swatch.custom_minimum_size
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		swatch.add_child(icon)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = symbol.capitalize()
	name_label.add_theme_font_size_override("font_size", 16)
	details.add_child(name_label)

	var lengths: Array = entry.keys()
	lengths.sort()
	for length in lengths:
		var p: float = probs.get(length, 0.0)
		var odds_text := "--"
		if p > 0.0:
			odds_text = "1 in %s" % _format_n(1.0 / p)
		var line := Label.new()
		line.text = "  %d-match: pays %sx bet  (%s)" % [length, entry[length], odds_text]
		line.add_theme_font_size_override("font_size", 13)
		details.add_child(line)

	row.add_child(details)
	return row


func _format_n(n: float) -> String:
	if n >= 1000.0:
		return "%.1fk" % (n / 1000.0)
	return "%.0f" % n
