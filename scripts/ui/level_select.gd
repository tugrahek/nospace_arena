extends Control

## Campaign level map: a winding vertical path. Level nodes zigzag left/right down a scrollable
## canvas, joined by a connector line, each showing its number, best stars, and a one-line "what's
## different" subtitle. Locked levels (previous not cleared) are disabled. Picking a level starts it;
## the result screen returns here for a tight pick-next loop.

const GAME_SCENE: String = "res://scenes/main/Game.tscn"
const MODE_SELECT_SCENE: String = "res://scenes/ui/ModeSelect.tscn"
const JuicyButton = preload("res://scripts/ui/juicy_button.gd")

const DESIGN_W: float = 560.0   # usable width between the screen margins (portrait reference)
const NODE_W: float = 220.0
const NODE_H: float = 108.0
const ROW_H: float = 140.0      # vertical distance between nodes
const TOP_MARGIN: float = 60.0
const X_OFFSET: float = 96.0    # zigzag horizontal offset from center

@onready var _title: Label = $Center/Title
@onready var _canvas: Control = $Center/Scroll/PathCanvas
@onready var _back: Button = $Center/BackButton


func _ready() -> void:
	_title.text = tr("LEVELSELECT_TITLE")
	_back.text = tr("SETTINGS_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MODE_SELECT_SCENE))
	Economy.campaign_changed.connect(_build)
	_build()


func _build() -> void:
	for c in _canvas.get_children():
		c.queue_free()
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


func _on_pick(index: int) -> void:
	SeedManager.enter_campaign(index)
	get_tree().change_scene_to_file(GAME_SCENE)
