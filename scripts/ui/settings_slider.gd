class_name SettingsSlider
extends HSlider

## Draws the saved Range value as captured territory with a frontier and diamond.

const PALETTE: PaletteData = preload("res://config/palette.tres")
const HANDLE_SIZE: int = 16
const TRACK_INSET: float = 10.0
const TRACK_HEIGHT: float = 10.0
const DIAMOND_RADIUS: float = 7.0
const FRONTIER_HEIGHT: float = 20.0


func _ready() -> void:
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("slider", empty)
	add_theme_stylebox_override("grabber_area", empty)
	add_theme_stylebox_override("grabber_area_highlight", empty)
	var clear := Image.create(HANDLE_SIZE, HANDLE_SIZE, false, Image.FORMAT_RGBA8)
	clear.fill(Color.TRANSPARENT)
	var invisible_handle := ImageTexture.create_from_image(clear)
	add_theme_icon_override("grabber", invisible_handle)
	add_theme_icon_override("grabber_highlight", invisible_handle)
	add_theme_icon_override("grabber_disabled", invisible_handle)
	value_changed.connect(func(_value: float) -> void: queue_redraw())
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var y: float = size.y * 0.5
	var left: float = TRACK_INSET
	var right: float = maxf(left, size.x - TRACK_INSET)
	var ratio: float = clampf((value - min_value) / maxf(max_value - min_value, 0.001), 0.0, 1.0)
	var head_x: float = lerpf(left, right, ratio)
	draw_rect(Rect2(left, y - TRACK_HEIGHT * 0.5, right - left, TRACK_HEIGHT), PALETTE.panel.darkened(0.15))
	if ratio > 0.0:
		draw_rect(Rect2(left, y - TRACK_HEIGHT * 0.5, head_x - left, TRACK_HEIGHT), PALETTE.accent)
	draw_line(Vector2(head_x, y - FRONTIER_HEIGHT * 0.5), Vector2(head_x, y + FRONTIER_HEIGHT * 0.5), PALETTE.accent_alt, 2.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(head_x, y - DIAMOND_RADIUS), Vector2(head_x + DIAMOND_RADIUS, y),
		Vector2(head_x, y + DIAMOND_RADIUS), Vector2(head_x - DIAMOND_RADIUS, y)
	]), PALETTE.text_primary)
