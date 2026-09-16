extends Control

## Campaign level map: a winding vertical path. Level nodes zigzag left/right down a scrollable
## canvas, joined by a connector line, each showing its number, best stars, and a one-line "what's
## different" subtitle. Locked levels (previous not cleared) are disabled. Picking a level starts it;
## the result screen returns here for a tight pick-next loop.
## A freshly unlocked level is celebrated once on the map's first showing (feel P1-11, visual only).

const GAME_SCENE: String = "res://scenes/main/Game.tscn"
const MODE_SELECT_SCENE: String = "res://scenes/ui/ModeSelect.tscn"
const JuicyButton = preload("res://scripts/ui/juicy_button.gd")
const PALETTE: PaletteData = preload("res://config/palette.tres")

const DESIGN_W: float = 560.0   # usable width between the screen margins (portrait reference)
const NODE_W: float = 220.0
const NODE_H: float = 108.0
const ROW_H: float = 140.0      # vertical distance between nodes
const TOP_MARGIN: float = 60.0
const X_OFFSET: float = 96.0    # zigzag horizontal offset from center

# Unlock celebration knobs (visual only):
@export var unlock_delay: float = 0.25       # wait after the scene appears before the pop
@export var unlock_start_scale: float = 0.6  # node scale the pop grows from
@export var unlock_pop_time: float = 0.35    # scale-pop duration (BACK ease)
@export var unlock_glow_time: float = 0.9    # accent glow fade-out duration
@export var unlock_glow_size: int = 14       # StyleBox shadow size (fake glow under gl_compatibility)
@export var unlock_glow_alpha: float = 0.75  # glow strength at its peak

var _nodes: Array[Button] = []
var _celebrate_index: int = -1   # level being celebrated this visit (-1 = none)
var _celebrate_tween: Tween = null

@onready var _title: Label = $Center/Title
@onready var _scroll: ScrollContainer = $Center/Scroll
@onready var _canvas: Control = $Center/Scroll/PathCanvas
@onready var _back: Button = $Center/BackButton


func _ready() -> void:
	_title.text = tr("LEVELSELECT_TITLE")
	_back.text = tr("SETTINGS_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MODE_SELECT_SCENE))
	Economy.campaign_changed.connect(_build)
	_celebrate_index = Economy.consume_pending_unlock()
	_build()
	if _celebrate_index >= 0 and _celebrate_index < _nodes.size() and not _nodes[_celebrate_index].disabled:
		_celebrate(_nodes[_celebrate_index])
	else:
		_celebrate_index = -1


func _build() -> void:
	for c in _canvas.get_children():
		c.queue_free()
	_nodes.clear()
	var count: int = ContentCatalog.LEVELS.size()
	var center_x: float = DESIGN_W * 0.5
	var centers: PackedVector2Array = PackedVector2Array()
	for i in count:
		var x: float = center_x + (X_OFFSET if i % 2 == 1 else -X_OFFSET)
		var y: float = TOP_MARGIN + float(i) * ROW_H
		centers.append(Vector2(x, y))
		var node: Button = _make_node(i)
		node.position = Vector2(x - NODE_W * 0.5, y - NODE_H * 0.5)
		node.size = Vector2(NODE_W, NODE_H)
		_canvas.add_child(node)
		_nodes.append(node)
	_canvas.custom_minimum_size = Vector2(DESIGN_W, TOP_MARGIN * 2.0 + float(count - 1) * ROW_H + NODE_H)
	_canvas.call("set_points", centers)


func _make_node(index: int) -> Button:
	var lvl: LevelData = ContentCatalog.LEVELS[index]
	var unlocked: bool = Economy.is_level_unlocked(index)
	var stars: int = Economy.campaign_star(lvl.id)
	var node := JuicyButton.new()
	node.custom_minimum_size = Vector2(NODE_W, NODE_H)
	node.disabled = not unlocked
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var star_line: String = ("★".repeat(stars) + "☆".repeat(3 - stars)) if unlocked else tr("LEVEL_LOCKED")
	var sub: String = tr(lvl.description_key) if unlocked else ""
	node.text = "%s %d\n%s\n%s" % [tr("LEVEL_LABEL"), index + 1, star_line, sub]
	if unlocked:
		node.pressed.connect(_on_pick.bind(index))
	return node


## Unlock celebration: after a short beat, scroll the node into view, scale-pop it in and flash an
## accent glow that fades out. Pressing the node mid-celebration stops it (JuicyButton's own press
## pop then owns the scale — no two tweens fighting over it).
func _celebrate(node: Button) -> void:
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ONE * unlock_start_scale
	node.button_down.connect(_stop_celebration.bind(node))
	var glow: StyleBoxFlat = _glow_style(node)
	_celebrate_tween = node.create_tween()
	_celebrate_tween.tween_interval(unlock_delay)
	_celebrate_tween.tween_callback(_begin_pop.bind(node, glow))
	_celebrate_tween.tween_property(node, "scale", Vector2.ONE, unlock_pop_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if glow != null:
		_celebrate_tween.parallel().tween_method(_set_glow.bind(glow), 1.0, 0.0, unlock_glow_time)
	_celebrate_tween.tween_callback(_clear_glow.bind(node))


func _begin_pop(node: Button, glow: StyleBoxFlat) -> void:
	_scroll.ensure_control_visible(node)
	AudioManager.play_sfx("unlock")  # hook — silent until an asset is bound
	if glow != null:
		node.add_theme_stylebox_override("normal", glow)
		node.add_theme_stylebox_override("hover", glow)


## A copy of the node's normal StyleBoxFlat with an accent border + shadow (fake glow). Null when
## the theme style isn't flat (then the celebration is scale-pop only).
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
