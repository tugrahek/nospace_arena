extends Control

## Read-only view of today's three territory objectives. Claim stays automatic at run end;
## this panel only reflects real mission state through MissionProgressStrip.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const MISSIONS_PATH: String = "user://missions.json"
const MISSION_COUNT: int = 3

@onready var _title: Label = $Title
@onready var _list: VBoxContainer = $List
@onready var _back: Button = $BackButton


func _ready() -> void:
	_title.text = tr("MISSIONS_TITLE")
	_back.text = tr("STORE_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	var date: int = SeedManager.compute_today()
	var saved: Dictionary = MissionStore.load_progress(MISSIONS_PATH, date)
	var missions: Array = MissionService.build(ContentCatalog.MISSIONS, date, MISSION_COUNT, saved)
	for m in missions:
		_add_row(m)


func _add_row(m: Mission) -> void:
	var strip := MissionProgressStrip.new()
	strip.configure(m)
	_list.add_child(strip)
