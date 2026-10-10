extends Control

## Mode picker reached from MainMenu's Play: Daily / Free / Level-Endless start a run directly;
## Campaign goes to the level map first. The mode persists on SeedManager, so an in-run Retry
## replays the same mode and Result → Menu returns home.

const GAME_SCENE: String = "res://scenes/main/Game.tscn"
const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const LEVEL_SELECT_SCENE: String = "res://scenes/ui/LevelSelect.tscn"


@onready var _title: Label = $SafeArea/Bounds/Center/Title
@onready var _daily: Button = $SafeArea/Bounds/Center/ModeGrid/DailyRow/Button
@onready var _daily_label: Label = $SafeArea/Bounds/Center/ModeGrid/DailyRow/Button/Content/ModeLabel
@onready var _daily_desc: Label = $SafeArea/Bounds/Center/ModeGrid/DailyRow/Button/Content/Desc
@onready var _free: Button = $SafeArea/Bounds/Center/ModeGrid/FreeRow/Button
@onready var _free_label: Label = $SafeArea/Bounds/Center/ModeGrid/FreeRow/Button/Content/ModeLabel
@onready var _free_desc: Label = $SafeArea/Bounds/Center/ModeGrid/FreeRow/Button/Content/Desc
@onready var _level: Button = $SafeArea/Bounds/Center/ModeGrid/LevelRow/Button
@onready var _level_label: Label = $SafeArea/Bounds/Center/ModeGrid/LevelRow/Button/Content/ModeLabel
@onready var _level_desc: Label = $SafeArea/Bounds/Center/ModeGrid/LevelRow/Button/Content/Desc
@onready var _campaign: Button = $SafeArea/Bounds/Center/ModeGrid/CampaignRow/Button
@onready var _campaign_label: Label = $SafeArea/Bounds/Center/ModeGrid/CampaignRow/Button/Content/ModeLabel
@onready var _campaign_desc: Label = $SafeArea/Bounds/Center/ModeGrid/CampaignRow/Button/Content/Desc
@onready var _back: Button = $SafeArea/Bounds/Center/BackButton
@onready var _boost_strip: VBoxContainer = $SafeArea/Bounds/Center/BoostStrip


func _ready() -> void:
	_title.text = tr("MODE_SELECT_TITLE")
	_daily_label.text = tr("MENU_DAILY")
	_daily_desc.text = tr("MODE_DAILY_DESC")
	_free_label.text = tr("MENU_FREE")
	_free_desc.text = tr("MODE_FREE_DESC")
	_level_label.text = tr("MENU_LEVEL")
	_level_desc.text = tr("MODE_LEVEL_DESC")
	_campaign_label.text = tr("MENU_CAMPAIGN")
	_campaign_desc.text = tr("MODE_CAMPAIGN_DESC")
	_back.text = tr("SETTINGS_BACK")
	_daily.pressed.connect(_start.bind(SeedManager.Mode.DAILY))
	_free.pressed.connect(_start.bind(SeedManager.Mode.FREE))
	_level.pressed.connect(_start.bind(SeedManager.Mode.LEVEL_ENDLESS))
	# Campaign needs a level pick first -> go to the level map (not straight into a run).
	_campaign.pressed.connect(_open_campaign)
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	Economy.boosts_changed.connect(_build_boost_strip)
	_build_boost_strip()


func _build_boost_strip() -> void:
	var boosts: Array[BoostData] = []
	for boost: BoostData in ContentCatalog.BOOSTS:
		boosts.append(boost)
	_build_boost_strip_for(boosts)


## Whole-chip loadout remains visible for every previous mode; zero charges disable arming.
func _build_boost_strip_for(boosts: Array[BoostData]) -> void:
	for child in _boost_strip.get_children():
		_boost_strip.remove_child(child)
		child.queue_free()
	_boost_strip.visible = not boosts.is_empty()
	if not _boost_strip.visible:
		return
	var rail := HBoxContainer.new()
	rail.name = "Boosts"
	rail.add_theme_constant_override("separation", 10)
	_boost_strip.add_child(rail)
	for boost: BoostData in boosts:
		var chip := BoostLoadoutChip.new()
		chip.configure(boost, Economy.boost_count(boost.id), Economy.is_boost_armed(boost.id))
		chip.armed_changed.connect(_on_arm_toggled)
		rail.add_child(chip)


func _open_campaign() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)

func _on_arm_toggled(pressed: bool, id: StringName) -> void:
	Economy.set_boost_armed(id, pressed)  # boosts_changed -> rebuild reflects new state/labels


func _start(mode: int) -> void:
	match mode:
		SeedManager.Mode.DAILY:
			SeedManager.enter_daily()
		SeedManager.Mode.LEVEL_ENDLESS:
			SeedManager.enter_level_endless()
		_:
			SeedManager.enter_free()
	get_tree().change_scene_to_file(GAME_SCENE)
