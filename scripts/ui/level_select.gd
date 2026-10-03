extends Control

## Campaign map presentation: compact checkpoints alternate around a winding route.
## Progression, persistence, and level selection remain owned by the existing systems.

const GAME_SCENE: String = "res://scenes/main/Game.tscn"
const MODE_SELECT_SCENE: String = "res://scenes/ui/ModeSelect.tscn"
const JuicyButton = preload("res://scripts/ui/juicy_button.gd")
const PALETTE: PaletteData = preload("res://config/palette.tres")

const DESIGN_W: float = 560.0
const NODE_W: float = 84.0
const NODE_H: float = 84.0
const ROW_H: float = 140.0
const TOP_MARGIN: float = 72.0
const BOTTOM_PADDING: float = 96.0
const X_OFFSET: float = 96.0
const PATH_NODE_HALF_SIZE: Vector2 = Vector2(NODE_W * 0.5, NODE_H * 0.5)
const META_W: float = 140.0
const META_H: float = 126.0

@export var unlock_delay: float = 0.25
@export var unlock_start_scale: float = 0.6
@export var unlock_pop_time: float = 0.35
@export var unlock_glow_time: float = 0.9
@export var unlock_glow_size: int = 14
@export var unlock_glow_alpha: float = 0.75

var _nodes: Array[Button] = []
var _celebrate_index: int = -1
var _celebrate_tween: Tween = null

@onready var _title: Label = $Center/Title
@onready var _scroll: ScrollContainer = $Center/Scroll
@onready var _canvas: Control = $Center/Scroll/PathCanvas
@onready var _back: Button = $Center/BackButton


func _ready() -> void:
	_title.text = tr("LEVELSELECT_TITLE")
	_back.text = tr("SETTINGS_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MODE_SELECT_SCENE))
	var scrollbar: VScrollBar = _scroll.get_v_scroll_bar()
	scrollbar.custom_minimum_size.x = 4.0
	scrollbar.modulate.a = 0.3
	Economy.campaign_changed.connect(_build)
	_celebrate_index = Economy.consume_pending_unlock()
	_build()
	if _celebrate_index >= 0 and _celebrate_index < _nodes.size() and not _nodes[_celebrate_index].disabled:
		_celebrate(_nodes[_celebrate_index])
	else:
		_celebrate_index = -1


func _build() -> void:
	for child in _canvas.get_children():
		child.queue_free()
	_nodes.clear()
	var count: int = ContentCatalog.LEVELS.size()
	var center_x: float = DESIGN_W * 0.5
	var centers := PackedVector2Array()
	for index in count:
		var center := Vector2(center_x + (X_OFFSET if index % 2 == 1 else -X_OFFSET), TOP_MARGIN + float(index) * ROW_H)
		centers.append(center)
		var node: Button = _make_node(index)
		node.position = center - Vector2(NODE_W, NODE_H) * 0.5
		node.size = Vector2(NODE_W, NODE_H)
		_canvas.add_child(node)
		_nodes.append(node)
	_canvas.custom_minimum_size = Vector2(DESIGN_W, TOP_MARGIN + float(count - 1) * ROW_H + NODE_H + BOTTOM_PADDING)
	_canvas.call("set_points", centers, PATH_NODE_HALF_SIZE)


func _make_node(index: int) -> Button:
	var level: LevelData = ContentCatalog.LEVELS[index]
	var unlocked: bool = Economy.is_level_unlocked(index)
	var stars: int = Economy.campaign_star(level.id)
	var node := JuicyButton.new()
	node.custom_minimum_size = Vector2(NODE_W, NODE_H)
	node.disabled = not unlocked
	node.text = str(index + 1)
	node.add_theme_font_size_override("font_size", 24)
	node.add_theme_color_override("font_color", PALETTE.text_primary if unlocked else PALETTE.text_secondary)
	var current: bool = unlocked and stars == 0
	var completed: bool = unlocked and stars > 0
	node.add_theme_stylebox_override("normal", _checkpoint_style(unlocked, current, completed))
	node.add_theme_stylebox_override("hover", _checkpoint_style(unlocked, current, completed))
	node.add_theme_stylebox_override("disabled", _checkpoint_style(false, false, false))
	var metadata: Label = _make_metadata(index, level, unlocked, stars)
	metadata.position = _metadata_position(index)
	_canvas.add_child(metadata)
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
	metadata.size = Vector2(META_W, META_H)
	metadata.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if index % 2 == 0 else HORIZONTAL_ALIGNMENT_RIGHT
	metadata.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	metadata.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	metadata.add_theme_font_size_override("font_size", 21)
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
	metadata.text = "%s   %s\n%s" % [title, star_line, tr(level.description_key)]
	return metadata


func _metadata_position(index: int) -> Vector2:
	var center_x: float = DESIGN_W * 0.5 + (X_OFFSET if index % 2 == 1 else -X_OFFSET)
	var y: float = TOP_MARGIN + float(index) * ROW_H - META_H * 0.5
	if index % 2 == 0:
		return Vector2(maxf(0.0, center_x - NODE_W * 0.5 - META_W - 20.0), y)
	return Vector2(minf(DESIGN_W - META_W, center_x + NODE_W * 0.5 + 20.0), y)


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
	_scroll.ensure_control_visible(node)
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
		node.remove_theme_stylebox_override("normal")
		node.remove_theme_stylebox_override("hover")


func _stop_celebration(node: Button) -> void:
	if _celebrate_tween != null and _celebrate_tween.is_valid():
		_celebrate_tween.kill()
	_clear_glow(node)


func _on_pick(index: int) -> void:
	SeedManager.enter_campaign(index)
	get_tree().change_scene_to_file(GAME_SCENE)
