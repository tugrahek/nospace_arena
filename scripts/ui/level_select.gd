extends Control

## Campaign map presentation: compact checkpoints alternate around a winding route.
## Progression, persistence, and level selection remain owned by the existing systems.

const GAME_SCENE: String = "res://scenes/main/Game.tscn"
const MODE_SELECT_SCENE: String = "res://scenes/ui/ModeSelect.tscn"
const JuicyButton = preload("res://scripts/ui/juicy_button.gd")
const PALETTE: PaletteData = preload("res://config/palette.tres")

const MAX_CONTENT_WIDTH: float = 800.0
const NODE_W: float = 108.0
const NODE_H: float = 108.0
const ROW_H: float = 196.0
const ROW_GAP: float = 28.0
const TOP_MARGIN: float = 32.0
const BOTTOM_PADDING: float = 48.0
const X_OFFSET: float = 56.0
const PATH_NODE_HALF_SIZE: Vector2 = Vector2(NODE_W * 0.5, NODE_H * 0.5)
const META_MAX_W: float = 244.0
const META_H: float = 112.0
const META_FONT_SIZE: int = 24
const EDGE_MARGIN: float = 24.0
const META_GAP: float = 28.0
const FOCUS_PADDING: float = 24.0
const ANIMATION_SCALE_BOUND: float = 1.15
const GLOW_TEXT_GAP: float = 8.0

@export var unlock_delay: float = 0.25
@export var unlock_start_scale: float = 0.6
@export var unlock_pop_time: float = 0.35
@export var unlock_glow_time: float = 0.9
@export var unlock_glow_size: int = 14
@export var unlock_glow_alpha: float = 0.75

var _nodes: Array[Button] = []
var _celebrate_index: int = -1
var _celebrate_tween: Tween = null
var _metadata: Array[Label] = []
var _focus_regions: Array[Rect2] = []
var _layout_pending: bool = false

@onready var _bounds: Control = $SafeArea/Bounds
@onready var _center: VBoxContainer = $SafeArea/Bounds/Center
@onready var _title: Label = $SafeArea/Bounds/Center/Title
@onready var _scroll: ScrollContainer = $SafeArea/Bounds/Center/Scroll
@onready var _canvas: Control = $SafeArea/Bounds/Center/Scroll/PathCanvas
@onready var _back: Button = $SafeArea/Bounds/Center/BackButton


func _ready() -> void:
	_title.text = tr("LEVELSELECT_TITLE")
	_back.text = tr("SETTINGS_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MODE_SELECT_SCENE))
	var scrollbar: VScrollBar = _scroll.get_v_scroll_bar()
	scrollbar.custom_minimum_size.x = 4.0
	scrollbar.modulate.a = 0.3
	Economy.campaign_changed.connect(_build)
	_bounds.resized.connect(_queue_layout)
	_canvas.resized.connect(_queue_layout)
	_celebrate_index = Economy.consume_pending_unlock()
	_build()
	if _celebrate_index >= 0 and _celebrate_index < _nodes.size() and not _nodes[_celebrate_index].disabled:
		_celebrate(_nodes[_celebrate_index])
	else:
		_celebrate_index = -1


func _build() -> void:
	if _celebrate_tween != null and _celebrate_tween.is_valid():
		_celebrate_tween.kill()
	for child in _canvas.get_children():
		child.queue_free()
	_nodes.clear()
	_metadata.clear()
	_focus_regions.clear()
	var count: int = ContentCatalog.LEVELS.size()
	for index in count:
		var node: Button = _make_node(index)
		node.size = Vector2(NODE_W, NODE_H)
		_canvas.add_child(node)
		_nodes.append(node)
	_canvas.custom_minimum_size = Vector2(0.0, TOP_MARGIN + float(count) * ROW_H + BOTTOM_PADDING)
	_queue_layout()


func _queue_layout() -> void:
	if _layout_pending or not is_inside_tree():
		return
	_layout_pending = true
	_refresh_layout.call_deferred()


## Width follows the real scroll canvas; wrapped metadata determines each row's height.
func _refresh_layout() -> void:
	_layout_pending = false
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var width: float = minf(_bounds.size.x, MAX_CONTENT_WIDTH)
	_center.offset_left = -width * 0.5
	_center.offset_right = width * 0.5
	if _canvas.size.x <= 0.0:
		return
	var middle: float = _canvas.size.x * 0.5
	var gap: float = maxf(META_GAP, _animation_padding() + GLOW_TEXT_GAP)
	var metadata_width: float = minf(META_MAX_W, maxf(0.0, middle - X_OFFSET - NODE_W * 0.5 - gap - EDGE_MARGIN))
	var cursor: float = TOP_MARGIN
	var centers := PackedVector2Array()
	_focus_regions.clear()
	for index: int in _nodes.size():
		var metadata: Label = _metadata[index]
		metadata.size.x = metadata_width
		metadata.size.y = maxf(META_H, metadata.get_minimum_size().y)
		var row_height: float = maxf(ROW_H, metadata.size.y)
		var point := Vector2(middle + (X_OFFSET if index % 2 == 1 else -X_OFFSET), cursor + row_height * 0.5)
		_layout_checkpoint(index, point, gap)
		centers.append(point)
		cursor += row_height + ROW_GAP
	_canvas.custom_minimum_size.y = cursor - ROW_GAP + BOTTOM_PADDING
	_canvas.call("set_points", centers, PATH_NODE_HALF_SIZE)
	if _celebrate_tween != null and _celebrate_tween.is_running() and _celebrate_index >= 0:
		_focus_checkpoint(_nodes[_celebrate_index])


func _layout_checkpoint(index: int, point: Vector2, gap: float) -> void:
	var node: Button = _nodes[index]
	var metadata: Label = _metadata[index]
	node.position = point - PATH_NODE_HALF_SIZE
	metadata.position = Vector2(point.x - NODE_W * 0.5 - gap - metadata.size.x
		if index % 2 == 0 else point.x + NODE_W * 0.5 + gap, point.y - metadata.size.y * 0.5)
	_focus_regions.append(node.get_rect().grow(_animation_padding()).merge(metadata.get_rect()))


func _animation_padding() -> float:
	return maxf(FOCUS_PADDING, ceilf(float(unlock_glow_size) + NODE_W * 0.5 * (maxf(ANIMATION_SCALE_BOUND, unlock_start_scale) - 1.0)))


## Reveal the whole checkpoint row including metadata and the maximum glow/pop envelope.
func _focus_checkpoint(node: Button) -> void:
	var index: int = _nodes.find(node)
	if index < 0 or index >= _focus_regions.size():
		return
	var rect: Rect2 = _focus_regions[index]
	var bar: VScrollBar = _scroll.get_v_scroll_bar()
	var target: float = bar.value
	if rect.position.y < target:
		target = rect.position.y
	elif rect.end.y > target + bar.page:
		target = rect.end.y - bar.page
	_scroll.scroll_vertical = ceili(clampf(target, 0.0, maxf(0.0, bar.max_value - bar.page)))


func _make_node(index: int) -> Button:
	var level: LevelData = ContentCatalog.LEVELS[index]
	var unlocked: bool = Economy.is_level_unlocked(index)
	var stars: int = Economy.campaign_star(level.id)
	var node := JuicyButton.new()
	node.custom_minimum_size = Vector2(NODE_W, NODE_H)
	node.disabled = not unlocked
	node.text = str(index + 1)
	node.add_theme_font_size_override("font_size", 30)
	node.add_theme_color_override("font_color", PALETTE.text_primary if unlocked else PALETTE.text_secondary)
	var current: bool = unlocked and stars == 0
	var completed: bool = unlocked and stars > 0
	var idle: StyleBoxFlat = _checkpoint_style(unlocked, current, completed)
	node.set_meta("route_idle_style", idle)
	node.add_theme_stylebox_override("normal", idle)
	node.add_theme_stylebox_override("hover", idle)
	node.add_theme_stylebox_override("disabled", _checkpoint_style(false, false, false))
	var focus: StyleBoxFlat = idle.duplicate() as StyleBoxFlat
	focus.draw_center = false
	focus.border_color = PALETTE.accent
	focus.set_border_width_all(3)
	node.add_theme_stylebox_override("focus", focus)
	var metadata: Label = _make_metadata(index, level, unlocked, stars)
	_canvas.add_child(metadata)
	_metadata.append(metadata)
	metadata.minimum_size_changed.connect(_queue_layout)
	if unlocked:
		node.pressed.connect(_on_pick.bind(index))
	return node


func _checkpoint_style(unlocked: bool, current: bool, completed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if completed:
		style.bg_color = Color(PALETTE.accent, 0.36)
	elif unlocked:
		style.bg_color = Color(PALETTE.panel, 0.94)
	else:
		style.bg_color = Color(PALETTE.panel, 0.24)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	var border_width: int = 2 if current else 1
	style.set_border_width_all(border_width)
	style.border_color = PALETTE.accent if current else (Color(PALETTE.accent, 0.55) if completed else (PALETTE.border if unlocked else Color(PALETTE.text_secondary, 0.3)))
	return style


func _make_metadata(index: int, level: LevelData, unlocked: bool, stars: int) -> Label:
	var metadata := Label.new()
	metadata.mouse_filter = Control.MOUSE_FILTER_IGNORE
	metadata.size = Vector2(META_MAX_W, META_H)
	metadata.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if index % 2 == 0 else HORIZONTAL_ALIGNMENT_RIGHT
	metadata.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	metadata.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	metadata.add_theme_font_size_override("font_size", META_FONT_SIZE)
	metadata.add_theme_constant_override("line_spacing", 3)
	metadata.add_theme_color_override("font_color", PALETTE.text_primary if unlocked else PALETTE.text_secondary)
	metadata.add_theme_color_override("font_shadow_color", Color(PALETTE.void_bg, 0.8))
	metadata.add_theme_constant_override("shadow_offset_x", 1)
	metadata.add_theme_constant_override("shadow_offset_y", 1)
	var title := "%s %d" % [tr("LEVEL_LABEL"), index + 1]
	if not unlocked:
		metadata.text = "%s\n%s" % [title, tr("LEVEL_LOCKED")]
		metadata.modulate.a = 0.62
		return metadata
	var star_line := "★".repeat(stars) + "☆".repeat(3 - stars)
	# Keep caption/stars separate; authored bullet groups become intentional objective lines.
	metadata.text = "%s\n%s\n%s" % [title, star_line, tr(level.description_key).replace(" • ", "\n")]
	return metadata


func _celebrate(node: Button) -> void:
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ONE * unlock_start_scale
	node.button_down.connect(_stop_celebration.bind(node))
	var glow: StyleBoxFlat = _glow_style(node)
	_celebrate_tween = node.create_tween()
	_celebrate_tween.tween_interval(unlock_delay)
	_celebrate_tween.tween_callback(_begin_pop.bind(node, glow))
	_celebrate_tween.tween_property(node, "scale", Vector2.ONE, unlock_pop_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if glow != null:
		_celebrate_tween.parallel().tween_method(_set_glow.bind(glow), 1.0, 0.0, unlock_glow_time)
	_celebrate_tween.tween_callback(_clear_glow.bind(node))


func _begin_pop(node: Button, glow: StyleBoxFlat) -> void:
	_focus_checkpoint(node)
	AudioManager.play_sfx("unlock")
	if glow != null:
		node.add_theme_stylebox_override("normal", glow)
		node.add_theme_stylebox_override("hover", glow)


func _glow_style(node: Button) -> StyleBoxFlat:
	var base: StyleBox = node.get_theme_stylebox("normal")
	if not base is StyleBoxFlat:
		return null
	var glow: StyleBoxFlat = base.duplicate()
	glow.shadow_size = unlock_glow_size
	_set_glow(1.0, glow)
	return glow


func _set_glow(strength: float, glow: StyleBoxFlat) -> void:
	glow.border_color = PALETTE.accent
	glow.shadow_color = Color(PALETTE.accent, unlock_glow_alpha * strength)


func _clear_glow(node: Button) -> void:
	if is_instance_valid(node):
		var idle: StyleBox = node.get_meta("route_idle_style") as StyleBox
		node.add_theme_stylebox_override("normal", idle)
		node.add_theme_stylebox_override("hover", idle)


func _stop_celebration(node: Button) -> void:
	if _celebrate_tween != null and _celebrate_tween.is_valid():
		_celebrate_tween.kill()
	node.scale = Vector2.ONE
	_clear_glow(node)


func _on_pick(index: int) -> void:
	SeedManager.enter_campaign(index)
	get_tree().change_scene_to_file(GAME_SCENE)
