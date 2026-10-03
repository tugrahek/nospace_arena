class_name PauseMissionRow
extends VBoxContainer

## Compact, read-only pause presentation of one authoritative Mission.

const PALETTE: PaletteData = preload("res://config/palette.tres")

var objective_text: String = ""
var progress_text: String = ""
var completed: bool = false

var _objective: Label
var _progress: Label
var _track: TerritoryTrack


func _ready() -> void:
	_ensure_children()


func configure(mission: Mission) -> void:
	_ensure_children()
	objective_text = tr(mission.def.description_key) % mission.def.goal_amount
	progress_text = "%d / %d" % [mission.progress, mission.def.goal_amount]
	completed = mission.is_complete()
	_objective.text = objective_text
	_progress.text = progress_text + ("  ✓" if completed else "")
	_track.configure(float(mission.progress) / float(maxi(mission.def.goal_amount, 1)), completed)
	_track.visible = true


func _ensure_children() -> void:
	if _objective != null:
		return
	custom_minimum_size.y = 72.0
	add_theme_constant_override("separation", 6)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	add_child(heading)
	_objective = Label.new()
	_objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.add_theme_font_size_override("font_size", 19)
	_objective.add_theme_color_override("font_color", PALETTE.text_primary)
	_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(_objective)
	_progress = Label.new()
	_progress.custom_minimum_size.x = 100.0
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_progress.add_theme_font_size_override("font_size", 17)
	_progress.add_theme_color_override("font_color", PALETTE.text_secondary)
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(_progress)
	_track = TerritoryTrack.new()
	_track.custom_minimum_size.y = 14.0
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_track)


class TerritoryTrack:
	extends Control
	const PALETTE: PaletteData = preload("res://config/palette.tres")

	var ratio: float = 0.0
	var is_complete: bool = false


	func configure(value: float, complete: bool) -> void:
		ratio = clampf(value, 0.0, 1.0)
		is_complete = complete
		queue_redraw()


	func _draw() -> void:
		var line_y := size.y * 0.5
		var width := size.x
		if is_complete:
			draw_line(Vector2(0.0, line_y), Vector2(width, line_y), PALETTE.accent.darkened(0.22), 5.0)
			return
		draw_line(Vector2(0.0, line_y), Vector2(width, line_y), PALETTE.void_bg.lightened(0.13), 5.0)
		var head_x := width * ratio
		if head_x > 0.0:
			draw_line(Vector2(0.0, line_y), Vector2(head_x, line_y), PALETTE.accent.darkened(0.22), 5.0)
		if ratio > 0.0:
			draw_line(Vector2(head_x, line_y - 6.0), Vector2(head_x, line_y + 6.0), PALETTE.accent_alt, 1.5)
			draw_colored_polygon(PackedVector2Array([
				Vector2(head_x, line_y - 3.0), Vector2(head_x + 3.0, line_y),
				Vector2(head_x, line_y + 3.0), Vector2(head_x - 3.0, line_y)
			]), PALETTE.text_primary)
