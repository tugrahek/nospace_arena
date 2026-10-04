class_name SettingsControlOption
extends Button

## A compact, explicit control-method target with a procedural explanatory icon.
const PALETTE: PaletteData = preload("res://config/palette.tres")
const ICON_Y: float = 34.0
const ICON_SPAN: float = 22.0
@export_enum("Swipe", "Tap", "D-pad") var icon_kind: int = 0


func _ready() -> void:
	var idle := StyleBoxFlat.new()
	idle.bg_color = PALETTE.panel.darkened(0.3)
	idle.border_color = PALETTE.text_secondary.darkened(0.55)
	idle.border_width_bottom = 1
	idle.content_margin_top = 66.0
	idle.content_margin_bottom = 12.0
	var selected := idle.duplicate() as StyleBoxFlat
	selected.bg_color = PALETTE.accent.darkened(0.78)
	selected.border_color = PALETTE.accent
	selected.border_width_bottom = 3
	var hover := idle.duplicate() as StyleBoxFlat
	hover.border_color = PALETTE.accent
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		add_theme_stylebox_override(state, selected if state in ["pressed", "hover_pressed"] else hover if state in ["hover", "focus"] else idle)
	add_theme_font_size_override("font_size", 23)
	toggled.connect(_refresh)
	_refresh(button_pressed)


func _refresh(_selected: bool) -> void:
	add_theme_color_override("font_color", PALETTE.text_secondary)
	add_theme_color_override("font_pressed_color", PALETTE.accent)
	add_theme_color_override("font_hover_pressed_color", PALETTE.accent)
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, ICON_Y)
	var color: Color = PALETTE.accent if button_pressed else PALETTE.text_secondary
	if icon_kind == 0:
		_arrow(center - Vector2(ICON_SPAN, 0), center + Vector2(ICON_SPAN, 0), color)
	elif icon_kind == 1:
		for direction in [-1.0, 1.0]:
			var point: Vector2 = center + Vector2(direction * 18.0, 0)
			draw_circle(point, 9.0, color, false, 2.0, true)
			draw_circle(point, 3.0, color)
	else:
		for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
			_arrow(center + direction * 6.0, center + direction * ICON_SPAN, color)
	if button_pressed:
		var tip := Vector2(size.x - 14.0, 14.0)
		draw_colored_polygon(PackedVector2Array([tip + Vector2.UP * 4, tip + Vector2.RIGHT * 4, tip + Vector2.DOWN * 4, tip + Vector2.LEFT * 4]), PALETTE.accent)


func _arrow(start: Vector2, end: Vector2, color: Color) -> void:
	var direction: Vector2 = (end - start).normalized()
	var side: Vector2 = direction.orthogonal()
	draw_line(start, end, color, 2.5, true)
	draw_polyline(PackedVector2Array([end - direction * 7 + side * 5, end, end - direction * 7 - side * 5]), color, 2.5, true)
