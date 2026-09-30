class_name StoreOfferTile
extends Control

## A single, full-cell Store selector hit target. Focus is visual-only and never persists.

const BoostIcon = preload("res://scripts/ui/boost_icon.gd")
const PALETTE = preload("res://config/palette.tres")

signal focus_requested(index: int)

enum Kind { CHARACTER, ARENA, BOOST }

var kind: int = Kind.CHARACTER
var item_id: StringName
var selector_index: int = 0
var is_focused: bool = false
var source_size: Vector2i = Vector2i.ONE


func _ready() -> void:
	resized.connect(queue_redraw)


## The transparent button deliberately covers preview, label and padding alike.
func configure_selector(offer_kind: int, id: StringName, index: int, item_name: String,
		focused: bool, effect_kind: int = 0, arena_size: Vector2i = Vector2i.ONE,
		void_color: Color = Color(), border_color: Color = Color()) -> void:
	kind = offer_kind
	item_id = id
	selector_index = index
	is_focused = focused
	source_size = arena_size
	for child in get_children():
		child.free()
	custom_minimum_size = Vector2(0.0, 140.0)
	var visual := CenterContainer.new()
	visual.name = "Visual"
	visual.set_anchors_preset(Control.PRESET_TOP_WIDE)
	visual.offset_bottom = 92.0
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(_make_preview(effect_kind, arena_size, void_color, border_color))
	add_child(visual)
	var label := Label.new()
	label.name = "Label"
	label.text = item_name
	label.theme_type_variation = &"Body"
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", PALETTE.accent if focused else PALETTE.text_secondary)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 94.0
	label.offset_bottom = 120.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var target := Button.new()
	target.name = "HitTarget"
	target.flat = true
	target.tooltip_text = item_name
	target.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target.pressed.connect(func() -> void: focus_requested.emit(selector_index))
	add_child(target)
	queue_redraw()


func preview_source_aspect() -> float:
	return float(source_size.x) / float(maxi(source_size.y, 1))


func _make_preview(effect_kind: int, arena_size: Vector2i, void_color: Color, border_color: Color) -> Control:
	if kind == Kind.CHARACTER:
		var preview := CharacterSelectorPreview.new()
		preview.effect_kind = effect_kind
		preview.custom_minimum_size = Vector2(70.0, 70.0)
		return preview
	if kind == Kind.BOOST:
		var icon := BoostIcon.new()
		icon.set("effect", effect_kind)
		icon.custom_minimum_size = Vector2(66.0, 66.0)
		return icon
	var preview := ArenaSelectorPreview.new()
	preview.configure(arena_size, void_color, border_color)
	preview.custom_minimum_size = Vector2(100.0, 72.0)
	return preview


func _draw() -> void:
	if not is_focused:
		return
	var c := PALETTE.accent
	var y := size.y - 7.0
	draw_line(Vector2(size.x * 0.30, y), Vector2(size.x * 0.70, y), c, 2.5, true)
	var x := size.x * 0.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(x, y - 11.0), Vector2(x + 5.0, y - 6.0),
		Vector2(x, y - 1.0), Vector2(x - 5.0, y - 6.0)
	]), c)


class CharacterSelectorPreview:
	extends Control
	var effect_kind: int = 0

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.25
		var cue := PALETTE.accent
		if effect_kind == 0:
			draw_line(c + Vector2(-r * 2.0, 0), c + Vector2(-r * 1.05, 0), cue, 2.0, true)
			draw_line(c + Vector2(r * 1.05, 0), c + Vector2(r * 2.0, 0), cue, 2.0, true)
		elif effect_kind == 1:
			draw_arc(c, r * 1.65, 0.0, TAU, 24, cue, 1.8, true)
		else:
			for deg in [0.0, 60.0, 120.0]:
				var direction := Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * r * 1.45
				draw_line(c - direction, c + direction, cue, 1.7, true)
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)
		]), PALETTE.text_primary)


class ArenaSelectorPreview:
	extends Control
	var source_size: Vector2i = Vector2i.ONE
	var void_color: Color = Color(0.1, 0.1, 0.2, 1.0)
	var border_color: Color = Color(0.4, 0.9, 1.0, 1.0)

	func _ready() -> void:
		resized.connect(queue_redraw)

	func configure(value: Vector2i, void_value: Color, border_value: Color) -> void:
		source_size = value
		void_color = void_value
		border_color = border_value
		queue_redraw()

	func _draw() -> void:
		var available := size - Vector2(6.0, 6.0)
		var scale := minf(available.x / float(source_size.x), available.y / float(source_size.y))
		var arena_size := Vector2(source_size) * scale
		var rect := Rect2((size - arena_size) * 0.5, arena_size)
		draw_rect(rect, void_color, true)
		draw_rect(rect, border_color, false, 1.5, true)
