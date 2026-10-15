class_name StoreShowcase
extends VBoxContainer

## Focused Store presentation. Economy writes remain in Store; this control emits intents only.

const PALETTE = preload("res://config/palette.tres")
const BoostIcon = preload("res://scripts/ui/boost_icon.gd")
const HERO_HEIGHTS: Vector2 = Vector2(208.0, 320.0)
const HERO_SHARE: float = 0.42
const BOOST_ICON_SIZES: Vector2 = Vector2(112.0, 144.0)
const BOOST_HERO_OPTICAL_OFFSET_Y: float = -15.0
const BOOST_HERO_VISUAL_SCALE: float = 1.08
const ICON_SHARE: float = 0.7
const ICON_SIZES: Vector2 = Vector2(180.0, 240.0)
const ACTION_SIZE: Vector2 = Vector2(160.0, 108.0)
const MAX_SHOWCASE_HEIGHT: float = 640.0

signal select_requested(kind: String, id: StringName)
signal purchase_requested(kind: String, id: StringName, cost: int)

enum Kind { CHARACTER, ARENA, BOOST }

var kind: int = Kind.CHARACTER
var item_id: StringName
var source_size: Vector2i = Vector2i.ONE
var _state: Label
var _action: Button
var _preview: Control
var _visual: CenterContainer
var _boost_hero_spacer: Control


func _ready() -> void:
	resized.connect(queue_redraw)


func configure_loadout(offer_kind: int, id: StringName, item_name: String, description: String,
		owned: bool, selected: bool, affordable: bool, cost: int, effect_kind: int = 0,
		arena_size: Vector2i = Vector2i.ONE, void_color: Color = Color(), border_color: Color = Color(),
		trail_color: Color = Color(), captured_color: Color = Color()) -> void:
	kind = offer_kind
	item_id = id
	source_size = arena_size
	_preview = _make_loadout_preview(effect_kind, arena_size, void_color, border_color, trail_color, captured_color)
	_build(item_name, description, owned, selected, affordable, cost, 0)


func configure_boost(id: StringName, boost: BoostData, count: int, affordable: bool) -> void:
	kind = Kind.BOOST
	item_id = id
	var icon := BoostIcon.new()
	icon.set("effect", BoostIcon.COIN_BONUS_ICON if id == &"coin_bonus" else boost.effect)
	icon.set("optical_offset_y", BOOST_HERO_OPTICAL_OFFSET_Y)
	icon.set("visual_scale", BOOST_HERO_VISUAL_SCALE)
	icon.custom_minimum_size = Vector2(142.0, 142.0)
	_preview = icon
	_build(tr(boost.display_name_key), tr(boost.description_key), false, false, affordable, boost.cost, count)


func preview_source_aspect() -> float:
	return float(source_size.x) / float(maxi(source_size.y, 1))


func preview_displayed_aspect() -> float:
	if _preview is ArenaShowcasePreview:
		return (_preview as ArenaShowcasePreview).displayed_aspect()
	return preview_source_aspect()


func state_label() -> String:
	return _state.text if _state != null else ""


func action_text() -> String:
	return _action.text if _action != null else ""


func action_disabled() -> bool:
	return _action != null and _action.disabled


## Bound spare showcase space while allowing wrapped text/actions to grow on short pages.
func fit_height(available_height: float) -> void:
	var fitted_height: float = clampf(roundf(available_height), 0.0, MAX_SHOWCASE_HEIGHT)
	custom_minimum_size.y = fitted_height
	_visual.custom_minimum_size.y = roundf(clampf(fitted_height * HERO_SHARE, HERO_HEIGHTS.x, HERO_HEIGHTS.y))
	if kind != Kind.ARENA:
		var icon_sizes: Vector2 = BOOST_ICON_SIZES if kind == Kind.BOOST else ICON_SIZES
		_preview.custom_minimum_size = Vector2.ONE * roundf(clampf(_visual.custom_minimum_size.y * ICON_SHARE, icon_sizes.x, icon_sizes.y))
	if _boost_hero_spacer != null and _action != null:
		var action_excess: float = maxf(0.0, _action.custom_minimum_size.y - _state.get_combined_minimum_size().y)
		_boost_hero_spacer.custom_minimum_size.y = maxf(0.0,
			action_excess - float(get_theme_constant("separation")))


func _build(item_name: String, description: String, owned: bool, selected: bool, affordable: bool, cost: int,
		owned_count: int) -> void:
	for child in get_children():
		child.free()
	custom_minimum_size = Vector2.ZERO
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 16)
	var visual := CenterContainer.new()
	_visual = visual
	visual.custom_minimum_size = Vector2(0.0, HERO_HEIGHTS.x)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(_preview)
	if kind == Kind.BOOST:
		# Compensate for the taller Buy row so centering keeps the hero on the shared vertical rhythm.
		_boost_hero_spacer = Control.new()
		_boost_hero_spacer.name = "HeroBalanceSpace"
		_boost_hero_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_boost_hero_spacer)
	add_child(visual)
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = item_name
	name_label.theme_type_variation = &"Heading"
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)
	var description_label := Label.new()
	description_label.name = "Description"
	description_label.text = description
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.add_theme_font_size_override("font_size", 24)
	description_label.add_theme_color_override("font_color", PALETTE.text_secondary)
	add_child(description_label)
	_build_actions(owned, selected, affordable, cost, owned_count)


func _build_actions(owned: bool, selected: bool, affordable: bool, cost: int, owned_count: int) -> void:
	var action_row := HBoxContainer.new()
	action_row.name = "Actions"
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 14)
	_state = Label.new()
	_state.name = "State"
	_state.add_theme_font_size_override("font_size", 24)
	action_row.add_child(_state)
	if kind == Kind.BOOST:
		_state.text = tr("STORE_OWNED") % owned_count
		_state.add_theme_color_override("font_color", PALETTE.accent if owned_count > 0 else PALETTE.text_secondary)
		var price := Label.new()
		price.name = "Price"
		price.text = "● %d" % cost
		price.add_theme_font_size_override("font_size", 24)
		price.add_theme_color_override("font_color", PALETTE.coin)
		action_row.add_child(price)
		_add_buy_action(action_row, affordable, cost)
	elif selected:
		_state.text = tr("STORE_SELECTED")
		_state.add_theme_color_override("font_color", PALETTE.accent)
	elif owned:
		_add_select_action(action_row)
	else:
		_state.text = "● %d" % cost
		_state.add_theme_color_override("font_color", PALETTE.coin)
		_add_buy_action(action_row, affordable, cost)
	add_child(action_row)


func _make_loadout_preview(effect_kind: int, arena_size: Vector2i, void_color: Color, border_color: Color,
		trail_color: Color, captured_color: Color) -> Control:
	if kind == Kind.CHARACTER:
		var preview := CharacterShowcasePreview.new()
		preview.effect_kind = effect_kind
		preview.custom_minimum_size = Vector2(180.0, 180.0)
		return preview
	var preview := ArenaShowcasePreview.new()
	preview.configure(arena_size, void_color, border_color, trail_color, captured_color)
	preview.custom_minimum_size = Vector2(400.0, 230.0)
	return preview


func _add_select_action(row: HBoxContainer) -> void:
	_action = Button.new()
	_action.text = tr("STORE_SELECT")
	_action.custom_minimum_size = ACTION_SIZE
	_action.add_theme_font_size_override("font_size", 28)
	_action.pressed.connect(func() -> void: select_requested.emit(_kind_name(), item_id))
	row.add_child(_action)


func _add_buy_action(row: HBoxContainer, affordable: bool, cost: int) -> void:
	_action = Button.new()
	_action.text = tr("STORE_BUY")
	_action.custom_minimum_size = ACTION_SIZE
	_action.add_theme_font_size_override("font_size", 28)
	_action.disabled = not affordable
	_action.add_theme_color_override("font_color", PALETTE.coin if affordable else PALETTE.text_secondary)
	_action.pressed.connect(func() -> void: purchase_requested.emit(_kind_name(), item_id, cost))
	row.add_child(_action)


func _kind_name() -> String:
	match kind:
		Kind.ARENA:
			return "arena"
		Kind.BOOST:
			return "boost"
		_:
			return "character"


class CharacterShowcasePreview:
	extends Control
	var effect_kind: int = 0

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.31
		draw_arc(c, r * 1.38, 0.0, TAU, 28, Color(PALETTE.accent, 0.28), 1.5, true)
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)
		]), PALETTE.text_primary)
		var cue := PALETTE.accent
		if effect_kind == 0:
			draw_line(c + Vector2(-r * 1.65, 0), c + Vector2(-r * 0.85, 0), cue, 3.0, true)
			draw_line(c + Vector2(r * 0.85, 0), c + Vector2(r * 1.65, 0), cue, 3.0, true)
		elif effect_kind == 1:
			draw_arc(c, r * 1.68, 0.0, TAU, 28, cue, 2.5, true)
		else:
			for deg in [0.0, 60.0, 120.0]:
				var direction := Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * r * 1.55
				draw_line(c - direction, c + direction, cue, 2.5, true)


class ArenaShowcasePreview:
	extends Control
	var source_size: Vector2i = Vector2i.ONE
	var void_color: Color = Color(0.1, 0.1, 0.2, 1.0)
	var border_color: Color = Color(0.4, 0.9, 1.0, 1.0)
	var trail_color: Color = Color(0.3, 0.9, 1.0, 1.0)
	var captured_color: Color = Color(0.2, 0.7, 1.0, 0.6)
	var _displayed_aspect: float = 1.0

	func _ready() -> void:
		resized.connect(queue_redraw)

	func configure(value: Vector2i, void_value: Color, border_value: Color, trail_value: Color,
			captured_value: Color) -> void:
		source_size = value
		void_color = void_value
		border_color = border_value
		trail_color = trail_value
		captured_color = captured_value
		queue_redraw()

	func displayed_aspect() -> float:
		return _displayed_aspect

	func _draw() -> void:
		var available := size - Vector2(12.0, 12.0)
		var scale := minf(available.x / float(source_size.x), available.y / float(source_size.y))
		var arena_size := Vector2(source_size) * scale
		_displayed_aspect = arena_size.x / maxf(arena_size.y, 1.0)
		var rect := Rect2((size - arena_size) * 0.5, arena_size)
		draw_rect(rect, void_color, true)
		var captured_start := rect.position + Vector2(2.0, rect.size.y * 0.54)
		var captured := Rect2(captured_start, Vector2(rect.size.x * 0.55, rect.end.y - captured_start.y))
		draw_rect(captured, captured_color, true)
		var head := captured.position + Vector2(captured.size.x, 0.0)
		draw_line(head - Vector2(rect.size.x * 0.22, 0.0), head, trail_color, 2.0, true)
		draw_line(head, head + Vector2(0.0, rect.size.y * 0.20), trail_color, 2.0, true)
		draw_colored_polygon(PackedVector2Array([
			head + Vector2(0, -4), head + Vector2(4, 0), head + Vector2(0, 4), head + Vector2(-4, 0)
		]), PALETTE.text_primary)
		draw_rect(rect, border_color, false, 2.0, true)
