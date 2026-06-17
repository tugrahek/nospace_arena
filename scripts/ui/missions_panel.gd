extends Control

## Read-only view of today's 3 missions (description + progress bar + reward + ✓). Claim
## stays automatic at run end (Step 13); this panel only displays. Functional scaffold.

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


func _add_row(m) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var desc: String = tr(m.def.description_key) % m.def.goal_amount
	var mark: String = "  ✓" if m.is_complete() else ""
	var header := Label.new()
	header.text = "%s   (+%d)%s" % [desc, m.def.reward, mark]
	header.add_theme_font_size_override("font_size", 20)
	box.add_child(header)
	var bar := ProgressBar.new()
	bar.max_value = m.def.goal_amount
	bar.value = m.progress
	bar.custom_minimum_size = Vector2(0, 24)
	box.add_child(bar)
	_list.add_child(box)
