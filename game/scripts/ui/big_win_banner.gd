## A theatrical banner reserved for large wins -- distinct from the small
## flash/number-pop that plays for every win. A flat celebration for every
## payout regardless of size undersells the ones that actually matter;
## this is the payoff moment when a win crosses a real threshold.
class_name BigWinBanner
extends Control

var _label: Label
var _backdrop: ColorRect


## Tier name for a payout expressed as a multiple of the bet, or "" if it
## doesn't clear the smallest tier. Thresholds are chosen against this
## paytable's own range (payouts run 2x-400x bet, see economy_config.gd).
static func tier_label(bet_multiple: float) -> String:
	if bet_multiple >= 100.0:
		return "HUGE WIN!"
	elif bet_multiple >= 30.0:
		return "BIG WIN!"
	elif bet_multiple >= 10.0:
		return "NICE WIN!"
	return ""


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.0)
	_backdrop.anchor_right = 1.0
	_backdrop.anchor_bottom = 1.0
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 56)
	_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchor_right = 1.0
	_label.anchor_bottom = 1.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


## Bounce in, hold, fade out. Awaitable.
func play(text: String) -> void:
	_label.text = text
	_label.pivot_offset = size / 2.0
	_label.scale = Vector2(0.2, 0.2)
	_label.modulate = Color(1, 1, 1, 1)
	_backdrop.color = Color(0, 0, 0, 0.0)
	visible = true

	var in_tween := create_tween()
	in_tween.set_parallel(true)
	in_tween.tween_property(_backdrop, "color:a", 0.45, 0.15)
	in_tween.tween_property(_label, "scale", Vector2(1.15, 1.15), 0.35) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await in_tween.finished

	var settle_tween := create_tween()
	settle_tween.tween_property(_label, "scale", Vector2(1.0, 1.0), 0.15) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await settle_tween.finished

	await get_tree().create_timer(0.7).timeout

	var out_tween := create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(_backdrop, "color:a", 0.0, 0.4)
	out_tween.tween_property(_label, "modulate:a", 0.0, 0.4)
	await out_tween.finished

	visible = false
