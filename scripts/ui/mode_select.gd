extends Control

## Mode picker reached from MainMenu's Play. Each option sets the play mode on SeedManager,
## then loads the game. The mode persists on SeedManager, so an in-run Retry replays the same
## mode and Result → Menu returns home. Campaign (Step 18.1) slots in as a 4th option later.

const GAME_SCENE: String = "res://scenes/main/Game.tscn"
const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"

@onready var _title: Label = $Center/Title
@onready var _daily: Button = $Center/Buttons/DailyRow/Button
@onready var _daily_desc: Label = $Center/Buttons/DailyRow/Desc
@onready var _free: Button = $Center/Buttons/FreeRow/Button
@onready var _free_desc: Label = $Center/Buttons/FreeRow/Desc
@onready var _level: Button = $Center/Buttons/LevelRow/Button
@onready var _level_desc: Label = $Center/Buttons/LevelRow/Desc
@onready var _back: Button = $Center/BackButton


func _ready() -> void:
	_title.text = tr("MODE_SELECT_TITLE")
	_daily.text = tr("MENU_DAILY")
	_daily_desc.text = tr("MODE_DAILY_DESC")
	_free.text = tr("MENU_FREE")
	_free_desc.text = tr("MODE_FREE_DESC")
	_level.text = tr("MENU_LEVEL")
	_level_desc.text = tr("MODE_LEVEL_DESC")
	_back.text = tr("SETTINGS_BACK")
	_daily.pressed.connect(_start.bind(SeedManager.Mode.DAILY))
	_free.pressed.connect(_start.bind(SeedManager.Mode.FREE))
	_level.pressed.connect(_start.bind(SeedManager.Mode.LEVEL_ENDLESS))
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))


func _start(mode: int) -> void:
	match mode:
		SeedManager.Mode.DAILY:
			SeedManager.enter_daily()
		SeedManager.Mode.LEVEL_ENDLESS:
			SeedManager.enter_level_endless()
		_:
			SeedManager.enter_free()
	get_tree().change_scene_to_file(GAME_SCENE)
