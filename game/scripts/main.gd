## Phase 2/3/4 prototype (docs/05_ROADMAP.md): one Payline machine, spin ->
## ease-to-stop -> payout, three pools shown and updating, juice on
## placeholder art, the Phase 3 play-phase decisions (bet sizing,
## bank-vs-gamble-up, D23 post-quota cash-out), and the Phase 4 loop --
## build phase (wallet -> reel editor + shelf + load bankroll) -> stage
## path (D31: minor/elite/treasure nodes over Stage) -> result -> back to
## build (D21: winnings become the next wallet). Built entirely in code
## (no hand-authored scene tree) so the whole UI is one readable,
## greppable file.
extends Control

const REEL_STAGGER := 0.15
const BASE_FLICKER := 0.5
const ANTICIPATION_HOLD := 0.7  # extra hold on the reel that decides a developing line

# Phase 4 scope note: there's no meta-progression yet (that's Phase 6), so
# a run is exactly one stage. A WIN cycles winnings into the next wallet
# (D21); a BUST/OUT_OF_SPINS has nothing to carry forward, so "Continue"
# after a loss starts over at this same seed wallet, not zero.
const STARTING_WALLET := EconomyConfig.STARTING_BANKROLL

enum GameState { BUILD, PLAY, RESULT }

signal _choice_made(result: bool)

var _state: int = GameState.BUILD
var build_phase: BuildPhase
var stage: Stage
var play_phase: PlayPhase  # alias for stage.play_phase -- the Phase 2/3 UI below reads this directly
var pools: Pools

var _build_root: Control
var _wallet_label: Label
var _reel_offers_box: VBoxContainer
var _reroll_button: Button
var _shelf_box: VBoxContainer
var _load_spinbox: SpinBox
var _load_preview_label: Label
var _load_button: Button
var _build_status_label: Label
var _start_stage_button: Button

var _play_root: Control
var _reel_row: HBoxContainer
var _reel_views: Array = []  # Array[ReelView]
var _bankroll_label: Label
var _winnings_label: Label
var _pending_label: Label
var _spins_label: Label
var _node_label: Label
var _status_label: Label
var _bet_spinbox: SpinBox
var _spin_button: Button
var _win_flash: ColorRect
var _gamble_flash: ColorRect
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

var _result_root: Control
var _result_title_label: Label
var _result_summary_label: Label
var _continue_button: Button


func _ready() -> void:
	_build_ui()
	_start_build_phase(STARTING_WALLET)


## D21: `wallet` is the currency-spine amount available to spend this
## build phase -- the prior stage's winnings, or STARTING_WALLET on a
## fresh run. Reel strips/paytable reset each stage (Phase 4 is scoped to
## one stage at a time; carrying purchased density forward across stages
## is Phase 6 meta-progression, not built yet).
func _start_build_phase(wallet: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	build_phase = BuildPhase.new(wallet, EconomyConfig.build_default_reel_strips(),
			EconomyConfig.DEFAULT_PAYTABLE.duplicate(true), EconomyConfig.MIN_BET, [], rng)
	_refresh_build_screen()
	_set_screen(GameState.BUILD)


func _start_stage() -> void:
	var finalized: Dictionary = build_phase.finalize()
	var machine := ReelMachine.new(finalized.reel_strips, EconomyConfig.NUM_ROWS)
	pools = Pools.new(finalized.starting_bankroll)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	play_phase = PlayPhase.new(
			machine, pools, build_phase.paytable, EconomyConfig.DEFAULT_PAYLINES,
			EconomyConfig.MIN_MATCH, EconomyConfig.QUOTA, EconomyConfig.SPIN_CAP, rng,
			EconomyConfig.GAMBLE_WIN_PROBABILITY, EconomyConfig.CASH_OUT_DISCOUNT,
			EconomyConfig.GAMBLE_OFFER_PROBABILITY, finalized.wild_symbol,
			EconomyConfig.MIN_BET, EconomyConfig.MAX_BET)
	stage = Stage.new(play_phase, Stage.default_node_sequence())

	_reel_views.clear()
	for child in _reel_row.get_children():
		child.queue_free()
	for strip in finalized.reel_strips:
		var reel_view := ReelView.new()
		reel_view.alignment = BoxContainer.ALIGNMENT_CENTER
		reel_view.setup(EconomyConfig.NUM_ROWS, strip)
		_reel_views.append(reel_view)
		_reel_row.add_child(reel_view)

	_bet_spinbox.value = EconomyConfig.MIN_BET
	_status_label.text = ""
	_set_screen(GameState.PLAY)
	_refresh_pool_labels()
	_advance_through_free_nodes()


func _set_screen(state: int) -> void:
	_state = state
	_build_root.visible = state == GameState.BUILD
	_play_root.visible = state == GameState.PLAY
	_info_button.visible = state == GameState.PLAY
	_result_root.visible = state == GameState.RESULT


# ---------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.11, 0.14)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	_build_build_screen()
	_build_play_screen()
	_build_result_screen()

	# Added last so they render on top of whichever screen is visible.
	_win_flash = ColorRect.new()
	_win_flash.color = Color(1.0, 0.85, 0.3, 0.0)
	_win_flash.anchor_right = 1.0
	_win_flash.anchor_bottom = 1.0
	_win_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_win_flash)

	_gamble_flash = ColorRect.new()
	_gamble_flash.color = Color(0, 0, 0, 0.0)
	_gamble_flash.anchor_right = 1.0
	_gamble_flash.anchor_bottom = 1.0
	_gamble_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gamble_flash)

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

	_big_win_banner = BigWinBanner.new()
	add_child(_big_win_banner)


func _make_pool_label(parent: Control) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 22)
	parent.add_child(label)
	return label


func _add_margin(root: Control, amount: int) -> void:
	root.add_theme_constant_override("margin_left", amount)


# --- Build-phase screen (Phase 4: wallet -> reel editor + shelf + load bankroll) ---

func _build_build_screen() -> void:
	_build_root = VBoxContainer.new()
	_build_root.anchor_right = 1.0
	_build_root.anchor_bottom = 1.0
	_build_root.add_theme_constant_override("separation", 18)
	add_child(_build_root)
	_add_margin(_build_root, 32)

	var title := Label.new()
	title.text = "BUILD PHASE"
	title.add_theme_font_size_override("font_size", 26)
	_build_root.add_child(title)

	_wallet_label = Label.new()
	_wallet_label.add_theme_font_size_override("font_size", 20)
	_build_root.add_child(_wallet_label)

	var editor_title := Label.new()
	editor_title.text = "Reel editor (D29/D32) -- pre-rolled offers"
	_build_root.add_child(editor_title)

	_reel_offers_box = VBoxContainer.new()
	_reel_offers_box.add_theme_constant_override("separation", 6)
	_build_root.add_child(_reel_offers_box)

	var reroll_row := HBoxContainer.new()
	reroll_row.add_theme_constant_override("separation", 12)
	_build_root.add_child(reroll_row)

	_reroll_button = Button.new()
	_reroll_button.pressed.connect(_on_reroll_pressed)
	reroll_row.add_child(_reroll_button)

	var shelf_title := Label.new()
	shelf_title.text = "Shelf (Relics, D28/D30)"
	_build_root.add_child(shelf_title)

	_shelf_box = VBoxContainer.new()
	_shelf_box.add_theme_constant_override("separation", 6)
	_build_root.add_child(_shelf_box)

	var load_title := Label.new()
	load_title.text = "Load bankroll (D5 -- bankroll is time)"
	_build_root.add_child(load_title)

	var load_row := HBoxContainer.new()
	load_row.add_theme_constant_override("separation", 12)
	_build_root.add_child(load_row)

	_load_spinbox = SpinBox.new()
	_load_spinbox.min_value = 0
	_load_spinbox.max_value = 1000
	_load_spinbox.step = 1
	_load_spinbox.value_changed.connect(_on_load_controls_changed)
	load_row.add_child(_load_spinbox)

	_load_preview_label = Label.new()
	load_row.add_child(_load_preview_label)

	_load_button = Button.new()
	_load_button.text = "Load"
	_load_button.pressed.connect(_on_load_bankroll_pressed)
	load_row.add_child(_load_button)

	_build_status_label = Label.new()
	_build_root.add_child(_build_status_label)

	_start_stage_button = Button.new()
	_start_stage_button.text = "START STAGE"
	_start_stage_button.custom_minimum_size = Vector2(160, 44)
	_start_stage_button.pressed.connect(_on_start_stage_pressed)
	_build_root.add_child(_start_stage_button)

	var scope_note := Label.new()
	scope_note.text = ("Leftover wallet auto-converts to bankroll when the stage starts (D5) -- "
			+ "no need to load it all manually.")
	scope_note.modulate = Color(1, 1, 1, 0.6)
	_build_root.add_child(scope_note)


func _refresh_build_screen() -> void:
	_wallet_label.text = "Wallet: %.1f" % build_phase.wallet

	for child in _reel_offers_box.get_children():
		child.queue_free()
	for i in range(build_phase.reel_offers().size()):
		var offer: BuildPhase.ReelOffer = build_phase.reel_offers()[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var label := Label.new()
		label.text = ("Add %d %s to Reel %d -- %.1f"
				% [offer.quantity, offer.symbol, offer.reel_index + 1, offer.cost])
		row.add_child(label)
		var buy_button := Button.new()
		buy_button.text = "Bought" if offer.bought else "Buy"
		buy_button.disabled = offer.bought
		buy_button.pressed.connect(_on_buy_reel_offer_pressed.bind(i))
		row.add_child(buy_button)
		_reel_offers_box.add_child(row)

	for child in _shelf_box.get_children():
		child.queue_free()
	for offer in build_phase.shelf():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var label := Label.new()
		label.text = "%s -- %.1f" % [offer.effect, offer.cost]
		row.add_child(label)
		var buy_button := Button.new()
		buy_button.text = "Buy"
		buy_button.pressed.connect(_on_buy_relic_pressed.bind(offer.id))
		row.add_child(buy_button)
		_shelf_box.add_child(row)

	_reroll_button.text = "Reroll offers (%.1f)" % build_phase.reroll_cost()
	_reroll_button.disabled = build_phase.reroll_cost() > build_phase.wallet

	_load_spinbox.max_value = max(0.0, build_phase.wallet)
	_on_load_controls_changed()


func _on_load_controls_changed(_unused = null) -> void:
	var spins := build_phase.spins_from_load(_load_spinbox.value)
	_load_preview_label.text = "-> %.0f spins" % spins


func _on_buy_reel_offer_pressed(offer_index: int) -> void:
	var offer: BuildPhase.ReelOffer = build_phase.reel_offers()[offer_index]
	if build_phase.buy_reel_offer(offer_index):
		_build_status_label.text = ("Added %d %s to reel %d."
				% [offer.quantity, offer.symbol, offer.reel_index + 1])
	else:
		_build_status_label.text = "Can't afford that offer."
	_refresh_build_screen()


func _on_reroll_pressed() -> void:
	if build_phase.reroll_reel_offers():
		_build_status_label.text = "Rerolled the offers."
	else:
		_build_status_label.text = "Can't afford a reroll."
	_refresh_build_screen()


func _on_buy_relic_pressed(relic_id: String) -> void:
	if build_phase.buy_relic(relic_id):
		_build_status_label.text = "Bought %s." % relic_id
	else:
		_build_status_label.text = "Can't afford that Relic."
	_refresh_build_screen()


func _on_load_bankroll_pressed() -> void:
	if build_phase.load_bankroll(_load_spinbox.value):
		_build_status_label.text = "Loaded %.1f into bankroll." % _load_spinbox.value
	else:
		_build_status_label.text = "Can't load more than the wallet holds."
	_refresh_build_screen()


func _on_start_stage_pressed() -> void:
	_start_stage()


# --- Play screen (Phase 2/3, extended with the Stage node badge) ---

func _build_play_screen() -> void:
	_play_root = VBoxContainer.new()
	_play_root.anchor_right = 1.0
	_play_root.anchor_bottom = 1.0
	_play_root.add_theme_constant_override("separation", 24)
	add_child(_play_root)
	_add_margin(_play_root, 32)

	var pools_row := HBoxContainer.new()
	pools_row.add_theme_constant_override("separation", 40)
	pools_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_play_root.add_child(pools_row)
	_bankroll_label = _make_pool_label(pools_row)
	_winnings_label = _make_pool_label(pools_row)
	_pending_label = _make_pool_label(pools_row)
	_spins_label = _make_pool_label(pools_row)

	_node_label = Label.new()
	_node_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_node_label.add_theme_font_size_override("font_size", 18)
	_play_root.add_child(_node_label)

	_reel_row = HBoxContainer.new()
	_reel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_reel_row.add_theme_constant_override("separation", 10)
	_reel_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reel_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_root.add_child(_reel_row)

	var controls_row := HBoxContainer.new()
	controls_row.alignment = BoxContainer.ALIGNMENT_CENTER
	controls_row.add_theme_constant_override("separation", 16)
	_play_root.add_child(controls_row)

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

	_gamble_row = HBoxContainer.new()
	_gamble_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_gamble_row.add_theme_constant_override("separation", 16)
	_gamble_row.visible = false
	_play_root.add_child(_gamble_row)

	_gamble_info_label = Label.new()
	_gamble_row.add_child(_gamble_info_label)

	_bank_button = Button.new()
	_bank_button.text = "BANK"
	_gamble_row.add_child(_bank_button)

	_gamble_button = Button.new()
	_gamble_button.text = "GAMBLE (50/50)"
	_gamble_row.add_child(_gamble_button)

	_continuation_row = HBoxContainer.new()
	_continuation_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_continuation_row.add_theme_constant_override("separation", 16)
	_continuation_row.visible = false
	_play_root.add_child(_continuation_row)

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
	_play_root.add_child(_status_label)


func _on_info_pressed() -> void:
	_paytable_panel.open_for(play_phase.machine.reel_strips, play_phase.paylines,
			play_phase.paytable, play_phase.min_match, play_phase.quota,
			build_phase.reel_ledger())


func _refresh_pool_labels() -> void:
	_bankroll_label.text = "Bankroll: %.1f" % pools.bankroll
	_winnings_label.text = "Winnings: %.1f / %.0f" % [pools.winnings, EconomyConfig.QUOTA]
	_pending_label.text = "Pending: %.1f" % pools.pending
	_update_spins_label()


func _update_spins_label() -> void:
	_spins_label.text = "Spins: %d / %d" % [play_phase.spins_used, EconomyConfig.SPIN_CAP]


## D31: node badge, shown before every spin -- ELITE calls out its bet
## bump so the extra stake is never a surprise (K3: decisions stay legible).
func _update_node_label() -> void:
	match stage.current_node_type():
		Stage.NodeType.ELITE:
			_node_label.text = "ELITE -- bet x%.2f" % Stage.ELITE_BET_MULTIPLIER
		_:
			_node_label.text = "Minor spin"


## Auto-resolves any run of free nodes (TREASURE today; EVENT/REST once
## Phase 5 populates them) the stage is currently sitting on -- there's no
## decision attached, so a click to "open" a treasure node would just be
## friction. Stops as soon as a MINOR/ELITE node (a real bet decision) is
## reached, or the stage ends.
func _advance_through_free_nodes() -> void:
	while not stage.is_over() and stage.is_free_node():
		var node := stage.current_node_type()
		stage.resolve_free_node()
		_refresh_pool_labels()
		if node == Stage.NodeType.TREASURE:
			_status_label.text = "Treasure! +%.1f winnings" % Stage.TREASURE_WINNINGS_BONUS
			await get_tree().create_timer(0.6).timeout
			_status_label.text = ""

	if stage.is_over():
		await _finish_stage()
	else:
		_update_node_label()
		_spin_button.disabled = false
		_bet_spinbox.editable = true


func _on_spin_pressed() -> void:
	if stage.is_over() or stage.has_pending_decision() or stage.is_free_node():
		return
	_spin_button.disabled = true
	_bet_spinbox.editable = false
	_status_label.text = ""

	var bet: float = _bet_spinbox.value
	var winnings_before: float = pools.winnings

	# The model resolves the spin instantly (deterministic, seedable, same
	# as sim/); the animation below just paces the reveal.
	var payout: float = stage.spin(bet)
	var final_grid: Array = play_phase.last_grid

	_bankroll_label.text = "Bankroll: %.1f" % pools.bankroll
	_update_spins_label()

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

	if stage.is_over():
		await _finish_stage()
	else:
		await _advance_through_free_nodes()


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

	if play_phase.awaiting_gamble_decision:
		_pending_label.text = "Pending: %.1f" % pools.pending
		_gamble_info_label.text = ("Bank %.1f, or gamble once for double-or-nothing?"
				% pools.pending)
		var wants_to_gamble := await _await_choice(_gamble_row, _gamble_button, _bank_button)
		if wants_to_gamble:
			var pending_before: float = pools.pending
			var won: bool = stage.gamble_pending()
			await _play_gamble_result(won, pending_before)
		else:
			stage.bank_pending()

	_pending_label.text = "Pending: 0.0"


func _play_gamble_result(won: bool, pending_before: float) -> void:
	_pending_label.text = "Pending: 0.0"

	var flash_color: Color
	if won:
		_status_label.text = "GAMBLE WON! Banked %.1f" % (pending_before * 2.0)
		flash_color = Color(0.35, 0.9, 0.4)
	else:
		_status_label.text = "GAMBLE LOST -- %.1f gone." % pending_before
		flash_color = Color(0.9, 0.3, 0.3)
	_status_label.add_theme_color_override("font_color", flash_color)

	_gamble_flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	var flash_tween := create_tween()
	flash_tween.tween_property(_gamble_flash, "color:a", 0.3, 0.06)
	flash_tween.tween_property(_gamble_flash, "color:a", 0.0, 0.35)

	await get_tree().create_timer(0.9).timeout

	_status_label.text = ""
	_status_label.remove_theme_color_override("font_color")


func _play_continuation_choice() -> void:
	_continuation_label.text = ("Quota cleared! Keep playing, or cash out now for +%.1f?"
			% play_phase.cash_out_offer)
	var wants_cash_out := await _await_choice(
			_continuation_row, _cash_out_button, _keep_playing_button)
	if wants_cash_out:
		stage.cash_out()
	else:
		stage.keep_playing()


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


# --- Result screen ---

func _build_result_screen() -> void:
	_result_root = VBoxContainer.new()
	_result_root.anchor_right = 1.0
	_result_root.anchor_bottom = 1.0
	_result_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_root.add_theme_constant_override("separation", 20)
	add_child(_result_root)

	_result_title_label = Label.new()
	_result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title_label.add_theme_font_size_override("font_size", 30)
	_result_root.add_child(_result_title_label)

	_result_summary_label = Label.new()
	_result_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_root.add_child(_result_summary_label)

	_continue_button = Button.new()
	_continue_button.text = "CONTINUE"
	_continue_button.custom_minimum_size = Vector2(160, 44)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.pressed.connect(_on_continue_pressed)
	_result_root.add_child(_continue_button)


## Called once the stage has ended (win/bust/out-of-spins) -- a short beat
## on the play screen so the deciding spin/treasure is still visible, then
## the result screen takes over.
func _finish_stage() -> void:
	match play_phase.outcome:
		PlayPhase.Outcome.WIN:
			_status_label.text = "QUOTA CLEARED -- you win."
		PlayPhase.Outcome.BUST:
			_status_label.text = "BANKROLL EMPTY -- run over."
		PlayPhase.Outcome.OUT_OF_SPINS:
			_status_label.text = ("OUT OF SPINS (%d/%d used) -- run over, %.1f short of quota."
					% [play_phase.spins_used, EconomyConfig.SPIN_CAP,
					   EconomyConfig.QUOTA - pools.winnings])
	_spin_button.disabled = true
	await get_tree().create_timer(1.2).timeout
	_show_result_screen()


func _show_result_screen() -> void:
	match play_phase.outcome:
		PlayPhase.Outcome.WIN:
			_result_title_label.text = "STAGE CLEARED"
		PlayPhase.Outcome.BUST:
			_result_title_label.text = "BANKROLL EMPTY"
		PlayPhase.Outcome.OUT_OF_SPINS:
			_result_title_label.text = "OUT OF SPINS"
		_:
			_result_title_label.text = "STAGE OVER"
	_result_summary_label.text = ("Winnings: %.1f / %.0f -- spins used: %d/%d"
			% [pools.winnings, EconomyConfig.QUOTA, play_phase.spins_used, EconomyConfig.SPIN_CAP])
	_set_screen(GameState.RESULT)


func _on_continue_pressed() -> void:
	# D21: a cleared stage's winnings become the next build phase's
	# wallet. A loss has nothing to cycle forward (Phase 4 has no
	# meta-progression yet, see STARTING_WALLET), so it restarts fresh.
	var next_wallet: float = pools.winnings if play_phase.outcome == PlayPhase.Outcome.WIN \
			else STARTING_WALLET
	_start_build_phase(next_wallet)
