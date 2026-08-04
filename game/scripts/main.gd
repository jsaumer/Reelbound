## Phase 2/3 prototype (docs/05_ROADMAP.md): one Payline machine, spin ->
## ease-to-stop -> payout, three pools shown and updating, juice on
## placeholder art, plus the Phase 3 play-phase decisions -- bet sizing,
## bank-vs-gamble-up, and the D23 post-quota cash-out choice. Built
## entirely in code (no hand-authored scene tree) so the whole UI is one
## readable, greppable file.
extends Control

const REEL_STAGGER := 0.15
const BASE_FLICKER := 0.5
const ANTICIPATION_HOLD := 0.7  # extra hold on the reel that decides a developing line

signal _choice_made(result: bool)

var play_phase: PlayPhase
var pools: Pools

var _reel_row: HBoxContainer
var _reel_views: Array = []  # Array[ReelView]
var _bankroll_label: Label
var _winnings_label: Label
var _pending_label: Label
var _spins_label: Label
var _status_label: Label
var _bet_spinbox: SpinBox
var _spin_button: Button
var _win_flash: ColorRect
var _info_button: Button
var _paytable_panel: PaytablePanel
var _big_win_banner: BigWinBanner

var _gamble_row: HBoxContainer
var _gamble_info_label: Label
var _gamble_button: Button
var _bank_button: Button

var _continuation_row: HBoxContainer
var _continuation_label: Label
var _cash_out_button: Button
var _keep_playing_button: Button


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
			EconomyConfig.QUOTA, EconomyConfig.SPIN_CAP, rng,
			EconomyConfig.GAMBLE_WIN_PROBABILITY, EconomyConfig.CASH_OUT_DISCOUNT)


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
	_spins_label = _make_pool_label(pools_row)

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

	# Bank-vs-gamble-up row (Phase 3, docs/02_GAME_DESIGN.md #4). Hidden
	# until a win lands in pending.
	_gamble_row = HBoxContainer.new()
	_gamble_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_gamble_row.add_theme_constant_override("separation", 16)
	_gamble_row.visible = false
	root.add_child(_gamble_row)

	_gamble_info_label = Label.new()
	_gamble_row.add_child(_gamble_info_label)

	_bank_button = Button.new()
	_bank_button.text = "BANK"
	_gamble_row.add_child(_bank_button)

	_gamble_button = Button.new()
	_gamble_button.text = "GAMBLE (50/50)"
	_gamble_row.add_child(_gamble_button)

	# Post-quota keep-playing-vs-cash-out row (D23). Hidden until quota
	# first clears.
	_continuation_row = HBoxContainer.new()
	_continuation_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_continuation_row.add_theme_constant_override("separation", 16)
	_continuation_row.visible = false
	root.add_child(_continuation_row)

	_continuation_label = Label.new()
	_continuation_row.add_child(_continuation_label)

	_keep_playing_button = Button.new()
	_keep_playing_button.text = "KEEP PLAYING"
	_continuation_row.add_child(_keep_playing_button)

	_cash_out_button = Button.new()
	_cash_out_button.text = "CASH OUT"
	_continuation_row.add_child(_cash_out_button)

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

	# Added last so it renders on top of the reels -- the whole point of a
	# celebratory banner is that it sits over everything else.
	_big_win_banner = BigWinBanner.new()
	add_child(_big_win_banner)


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
	_update_spins_label()


func _update_spins_label() -> void:
	# The spin cap is the other half of the dual limiter (D6) alongside
	# bankroll -- it needs to be just as visible, or "out of spins" comes
	# as a surprise with no warning.
	_spins_label.text = "Spins: %d / %d" % [play_phase.spins_used, EconomyConfig.SPIN_CAP]


func _on_spin_pressed() -> void:
	if play_phase.is_over() or play_phase.has_pending_decision():
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
	_update_spins_label()

	# Near-miss anticipation: if some line is already 2+ into a match that
	# would pay/upgrade, hold the deciding reel longer and pulse the cells
	# that already fed into it -- the "will it keep going?" beat. The
	# outcome is already resolved above; this only paces how it's revealed.
	var anticipation := NearMiss.find_anticipation(
			final_grid, play_phase.paylines, play_phase.paytable)

	for i in range(_reel_views.size()):
		var column := []
		for row in range(EconomyConfig.NUM_ROWS):
			column.append(final_grid[i][row])
		var flicker: float = BASE_FLICKER + i * REEL_STAGGER
		if not anticipation.is_empty() and i >= anticipation.reel_index:
			flicker += ANTICIPATION_HOLD
		_reel_views[i].spin_to(column, flicker)

	if not anticipation.is_empty():
		var row_pattern: Array = anticipation.row_pattern
		var decide_at: int = anticipation.reel_index
		for prev in range(decide_at):
			var prev_settle_time: float = BASE_FLICKER + prev * REEL_STAGGER \
					+ ReelView.SETTLE_BOUNCE_DURATION
			var decide_settle_time: float = BASE_FLICKER + decide_at * REEL_STAGGER \
					+ ANTICIPATION_HOLD + ReelView.SETTLE_BOUNCE_DURATION
			_schedule_pulse(prev, row_pattern[prev], prev_settle_time,
					decide_settle_time - prev_settle_time)

	var last_reel_index: int = _reel_views.size() - 1
	var last_flicker: float = BASE_FLICKER + last_reel_index * REEL_STAGGER
	if not anticipation.is_empty() and last_reel_index >= anticipation.reel_index:
		last_flicker += ANTICIPATION_HOLD
	await get_tree().create_timer(last_flicker + ReelView.SETTLE_BOUNCE_DURATION + 0.05).timeout

	if payout > 0.0:
		await _play_win_reveal(payout, bet)
	else:
		_pending_label.text = "Pending: 0.0"

	if play_phase.awaiting_continuation_decision:
		await _play_continuation_choice()

	var winnings_tween := create_tween()
	winnings_tween.tween_method(_set_winnings_display, winnings_before, pools.winnings, 0.5)
	await winnings_tween.finished

	_refresh_pool_labels()
	_handle_outcome()


## Fire-and-forget: waits `start_delay` before pulsing, so the cell only
## glows once it's actually shown its settled symbol (not mid-flicker).
func _schedule_pulse(reel_index: int, row: int, start_delay: float, pulse_duration: float) -> void:
	await get_tree().create_timer(start_delay).timeout
	_reel_views[reel_index].pulse_cell(row, pulse_duration)


func _play_win_reveal(payout: float, bet: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_pending_display, 0.0, payout, 0.4)
	await tween.finished

	var flash_tween := create_tween()
	flash_tween.tween_property(_win_flash, "color:a", 0.35, 0.06)
	flash_tween.tween_property(_win_flash, "color:a", 0.0, 0.3)

	var bet_multiple: float = payout / bet if bet > 0.0 else 0.0
	var tier := BigWinBanner.tier_label(bet_multiple)
	if tier != "":
		await _big_win_banner.play(tier)

	# Bank-vs-gamble-up (Phase 3): repeatable while pending is nonzero.
	while play_phase.awaiting_gamble_decision:
		_pending_label.text = "Pending: %.1f" % pools.pending
		_gamble_info_label.text = "Bank %.1f, or gamble double-or-nothing?" % pools.pending
		var wants_to_gamble := await _await_choice(_gamble_row, _gamble_button, _bank_button)
		if wants_to_gamble:
			play_phase.gamble_pending()
			_pending_label.text = "Pending: %.1f" % pools.pending
		else:
			play_phase.bank_pending()

	_pending_label.text = "Pending: 0.0"


## D23: offered every spin once quota is cleared. Awaitable.
func _play_continuation_choice() -> void:
	_continuation_label.text = ("Quota cleared! Keep playing, or cash out now for +%.1f?"
			% play_phase.cash_out_offer)
	var wants_cash_out := await _await_choice(
			_continuation_row, _cash_out_button, _keep_playing_button)
	if wants_cash_out:
		play_phase.cash_out()
	else:
		play_phase.keep_playing()


## Shows `row`, waits for either button, hides `row`, and returns true if
## `button_true` was the one pressed.
func _await_choice(row: Control, button_true: Button, button_false: Button) -> bool:
	row.visible = true
	var on_true := func(): _choice_made.emit(true)
	var on_false := func(): _choice_made.emit(false)
	button_true.pressed.connect(on_true, CONNECT_ONE_SHOT)
	button_false.pressed.connect(on_false, CONNECT_ONE_SHOT)
	var result: bool = await _choice_made
	row.visible = false
	return result


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
			_status_label.text = ("OUT OF SPINS (%d/%d used) -- run over, %.1f short of quota."
					% [play_phase.spins_used, EconomyConfig.SPIN_CAP,
					   EconomyConfig.QUOTA - pools.winnings])
			_spin_button.disabled = true
		_:
			_spin_button.disabled = false
			_bet_spinbox.editable = true
