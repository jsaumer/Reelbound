## Phase-2 spin-feel prototype (docs/05_ROADMAP.md Phase 2): one Payline
## machine, spin -> ease-to-stop -> payout, three pools shown and updating,
## juice on placeholder art. Built entirely in code (no hand-authored
## scene tree) so the whole UI is one readable, greppable file.
extends Control

const REEL_STAGGER := 0.15
const BASE_FLICKER := 0.5

var play_phase: PlayPhase
var pools: Pools

var _reel_row: HBoxContainer
var _reel_views: Array = []  # Array[ReelView]
var _bankroll_label: Label
var _winnings_label: Label
var _pending_label: Label
var _status_label: Label
var _bet_spinbox: SpinBox
var _spin_button: Button
var _win_flash: ColorRect
var _info_button: Button
var _paytable_panel: PaytablePanel


func _ready() -> void:
	_build_play_phase()
	_build_ui()
	_refresh_pool_labels()


func _build_play_phase() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var machine := ReelMachine.new(
			EconomyConfig.build_default_reel_strips(), EconomyConfig.NUM_ROWS)
	pools = Pools.new(EconomyConfig.STARTING_BANKROLL)
	play_phase = PlayPhase.new(
			machine, pools, EconomyConfig.DEFAULT_PAYTABLE,
			EconomyConfig.DEFAULT_PAYLINES, EconomyConfig.MIN_MATCH,
			EconomyConfig.QUOTA, EconomyConfig.SPIN_CAP, rng)


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.11, 0.14)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 24)
	root.set("theme_override_constants/separation", 24)
	add_child(root)
	_add_margin(root, 32)

	var pools_row := HBoxContainer.new()
	pools_row.add_theme_constant_override("separation", 40)
	pools_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(pools_row)
	_bankroll_label = _make_pool_label(pools_row)
	_winnings_label = _make_pool_label(pools_row)
	_pending_label = _make_pool_label(pools_row)

	_win_flash = ColorRect.new()
	_win_flash.color = Color(1.0, 0.85, 0.3, 0.0)
	_win_flash.anchor_right = 1.0
	_win_flash.anchor_bottom = 1.0
	_win_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_win_flash)

	_reel_row = HBoxContainer.new()
	_reel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_reel_row.add_theme_constant_override("separation", 10)
	_reel_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reel_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_reel_row)

	var reel_strips: Array = EconomyConfig.build_default_reel_strips()
	for strip in reel_strips:
		var reel_view := ReelView.new()
		reel_view.alignment = BoxContainer.ALIGNMENT_CENTER
		reel_view.setup(EconomyConfig.NUM_ROWS, strip)
		_reel_views.append(reel_view)
		_reel_row.add_child(reel_view)

	var controls_row := HBoxContainer.new()
	controls_row.alignment = BoxContainer.ALIGNMENT_CENTER
	controls_row.add_theme_constant_override("separation", 16)
	root.add_child(controls_row)

	var bet_label := Label.new()
	bet_label.text = "Bet:"
	controls_row.add_child(bet_label)

	_bet_spinbox = SpinBox.new()
	_bet_spinbox.min_value = EconomyConfig.MIN_BET
	_bet_spinbox.max_value = EconomyConfig.MAX_BET
	_bet_spinbox.step = 0.5
	_bet_spinbox.value = EconomyConfig.MIN_BET
	controls_row.add_child(_bet_spinbox)

	_spin_button = Button.new()
	_spin_button.text = "SPIN"
	_spin_button.custom_minimum_size = Vector2(120, 40)
	_spin_button.pressed.connect(_on_spin_pressed)
	controls_row.add_child(_spin_button)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 20)
	root.add_child(_status_label)

	# Info button + paytable/odds overlay. Every slot-gameplay screen should
	# carry one of these -- it's always computed live from play_phase's
	# actual machine, never a fixed list, so it stays correct as symbols get
	# purchased/added (build phase, Phase 4).
	_info_button = Button.new()
	_info_button.text = "i"
	_info_button.tooltip_text = "Paytable & odds"
	_info_button.custom_minimum_size = Vector2(36, 36)
	_info_button.anchor_left = 1.0
	_info_button.anchor_right = 1.0
	_info_button.offset_left = -52.0
	_info_button.offset_right = -16.0
	_info_button.offset_top = 16.0
	_info_button.offset_bottom = 52.0
	_info_button.pressed.connect(_on_info_pressed)
	add_child(_info_button)

	_paytable_panel = PaytablePanel.new()
	add_child(_paytable_panel)


func _make_pool_label(parent: Control) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 22)
	parent.add_child(label)
	return label


func _add_margin(root: Control, amount: int) -> void:
	root.add_theme_constant_override("margin_left", amount)


func _on_info_pressed() -> void:
	_paytable_panel.open_for(play_phase.machine.reel_strips, play_phase.paylines,
			play_phase.paytable, play_phase.min_match, play_phase.quota)


func _refresh_pool_labels() -> void:
	_bankroll_label.text = "Bankroll: %.1f" % pools.bankroll
	_winnings_label.text = "Winnings: %.1f / %.0f" % [pools.winnings, EconomyConfig.QUOTA]
	_pending_label.text = "Pending: %.1f" % pools.pending


func _on_spin_pressed() -> void:
	if play_phase.is_over():
		return
	_spin_button.disabled = true
	_bet_spinbox.editable = false
	_status_label.text = ""

	var bet: float = _bet_spinbox.value
	var winnings_before: float = pools.winnings

	# The model resolves the spin instantly (deterministic, seedable, same
	# as sim/play_phase.py); the animation below just paces the reveal.
	var payout: float = play_phase.spin(bet)
	var final_grid: Array = play_phase.last_grid

	_bankroll_label.text = "Bankroll: %.1f" % pools.bankroll

	for i in range(_reel_views.size()):
		var column := []
		for row in range(EconomyConfig.NUM_ROWS):
			column.append(final_grid[i][row])
		_reel_views[i].spin_to(column, BASE_FLICKER + i * REEL_STAGGER)

	var total_duration: float = BASE_FLICKER + (_reel_views.size() - 1) * REEL_STAGGER + 0.45
	await get_tree().create_timer(total_duration).timeout

	if payout > 0.0:
		await _play_win_reveal(payout, winnings_before)
	else:
		_pending_label.text = "Pending: 0.0"

	_refresh_pool_labels()
	_handle_outcome()


func _play_win_reveal(payout: float, winnings_before: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_pending_display, 0.0, payout, 0.4)
	await tween.finished

	var flash_tween := create_tween()
	flash_tween.tween_property(_win_flash, "color:a", 0.35, 0.06)
	flash_tween.tween_property(_win_flash, "color:a", 0.0, 0.3)

	var settle_tween := create_tween()
	settle_tween.tween_method(_set_winnings_display, winnings_before, pools.winnings, 0.5)
	await settle_tween.finished

	_pending_label.text = "Pending: 0.0"


func _set_pending_display(value: float) -> void:
	_pending_label.text = "Pending: %.1f" % value


func _set_winnings_display(value: float) -> void:
	_winnings_label.text = "Winnings: %.1f / %.0f" % [value, EconomyConfig.QUOTA]


func _handle_outcome() -> void:
	match play_phase.outcome:
		PlayPhase.Outcome.WIN:
			_status_label.text = "QUOTA CLEARED -- you win."
			_spin_button.disabled = true
		PlayPhase.Outcome.BUST:
			_status_label.text = "BANKROLL EMPTY -- run over."
			_spin_button.disabled = true
		PlayPhase.Outcome.OUT_OF_SPINS:
			_status_label.text = "OUT OF SPINS -- run over."
			_spin_button.disabled = true
		_:
			_spin_button.disabled = false
			_bet_spinbox.editable = true
