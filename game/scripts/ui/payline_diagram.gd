## Draws one payline's row pattern as a small reels x rows grid with the
## active cells connected -- replaces a raw "0-0-0-0-0" index list with
## something that actually reads as a line at a glance. Payline's whole
## appeal is being "the legible baseline" (docs/07_SLOT_TYPES.md); the
## rules display should read that way too.
class_name PaylineDiagram
extends Control

const CELL_GAP := 3.0
const DOT_COLOR := Color(1, 1, 1, 0.14)

var _num_reels: int = 0
var _num_rows: int = 0
var _row_pattern: Array = []
var _accent_color: Color = Color(1.0, 0.85, 0.3)


func setup(num_reels: int, num_rows: int, row_pattern: Array,
		accent_color: Color = Color(1.0, 0.85, 0.3)) -> void:
	_num_reels = num_reels
	_num_rows = num_rows
	_row_pattern = row_pattern
	_accent_color = accent_color
	queue_redraw()


func _draw() -> void:
	if _num_reels <= 0 or _num_rows <= 0:
		return

	var cell_w := size.x / _num_reels
	var cell_h := size.y / _num_rows
	var cell_size := Vector2(cell_w, cell_h) - Vector2(CELL_GAP, CELL_GAP)

	for reel in range(_num_reels):
		for row in range(_num_rows):
			var pos := Vector2(reel * cell_w, row * cell_h) + Vector2(CELL_GAP, CELL_GAP) * 0.5
			draw_rect(Rect2(pos, cell_size), DOT_COLOR)

	var centers: Array = []
	for reel in range(_num_reels):
		var row: int = _row_pattern[reel]
		centers.append(Vector2(reel * cell_w + cell_w / 2.0, row * cell_h + cell_h / 2.0))

	for i in range(centers.size() - 1):
		draw_line(centers[i], centers[i + 1], _accent_color, 2.0, true)
	for center in centers:
		draw_circle(center, min(cell_w, cell_h) * 0.22, _accent_color)
