extends Control

## Read-only view of today's three territory objectives. Claim stays automatic at run end;
## this panel only reflects real mission state through MissionProgressStrip.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const MISSIONS_PATH: String = "user://missions.json"
const MISSION_COUNT: int = 3
const MAX_LAYOUT_WIDTH: float = 664.0

@onready var _bounds: Control = $SafeArea/Bounds
@onready var _layout: VBoxContainer = $SafeArea/Bounds/Layout
@onready var _title: Label = $SafeArea/Bounds/Layout/Title
@onready var _list: VBoxContainer = $SafeArea/Bounds/Layout/Scroll/List
@onready var _back: Button = $SafeArea/Bounds/Layout/BackButton


func _ready() -> void:
	preload("res://scripts/ui/touch_target_sizing.gd").attach(_back)
	_bounds.resized.connect(_refresh_layout)
	_refresh_layout()
	_title.text = tr("MISSIONS_TITLE")
	_back.text = tr("STORE_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	var date: int = SeedManager.compute_today()
	var saved: Dictionary = MissionStore.load_progress(MISSIONS_PATH, date)
	var missions: Array = MissionService.build(ContentCatalog.MISSIONS, date, MISSION_COUNT, saved)
	for m in missions:
		_add_row(m)


## Preserve the authored width unless the effective safe-area bounds are narrower.
func _refresh_layout() -> void:
	var width: float = minf(MAX_LAYOUT_WIDTH, _bounds.size.x)
	_layout.offset_left = -width * 0.5
	_layout.offset_right = width * 0.5


func _add_row(m: Mission) -> void:
	var strip := MissionProgressStrip.new()
	strip.configure(m)
	_list.add_child(strip)
