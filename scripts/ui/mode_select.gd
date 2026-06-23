extends Control

## Mode picker reached from MainMenu's Play. Each option sets the play mode on SeedManager,
## then loads the game. The mode persists on SeedManager, so an in-run Retry replays the same
## mode and Result → Menu returns home. Campaign (Step 18.1) slots in as a 4th option later.

const GAME_SCENE: String = "res://scenes/main/Game.tscn"
const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const BoostIcon = preload("res://scripts/ui/boost_icon.gd")

@onready var _title: Label = $Center/Title
@onready var _daily: Button = $Center/Buttons/DailyRow/Button
@onready var _daily_desc: Label = $Center/Buttons/DailyRow/Desc
@onready var _free: Button = $Center/Buttons/FreeRow/Button
@onready var _free_desc: Label = $Center/Buttons/FreeRow/Desc
@onready var _level: Button = $Center/Buttons/LevelRow/Button
@onready var _level_desc: Label = $Center/Buttons/LevelRow/Desc
@onready var _back: Button = $Center/BackButton
@onready var _boost_strip: VBoxContainer = $Center/BoostStrip


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
	Economy.boosts_changed.connect(_build_boost_strip)
	_build_boost_strip()


## Arm strip for owned boosts (consumables). Boosts apply to Free / Level-Endless only — Daily
## ignores them (BoostPolicy, single source). Hidden entirely when the player owns no boosts.
func _build_boost_strip() -> void:
	for c in _boost_strip.get_children():
		c.queue_free()
	var owned: Array[BoostData] = []
	for b in ContentCatalog.BOOSTS:
		if Economy.boost_count(b.id) > 0:
			owned.append(b)
	_boost_strip.visible = not owned.is_empty()
	if owned.is_empty():
		return
	var header := Label.new()
	header.text = tr("STORE_BOOSTS")
	header.theme_type_variation = &"Heading"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boost_strip.add_child(header)
	var note := Label.new()
	note.text = "%s / %s" % [tr("MENU_FREE"), tr("MENU_LEVEL")]  # boosts apply here, not Daily
	note.theme_type_variation = &"Muted"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boost_strip.add_child(note)
	for b in owned:
		_boost_strip.add_child(_make_arm_row(b))


func _make_arm_row(b: BoostData) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 12)
	var icon := BoostIcon.new()  # distinct per-effect glyph
	icon.set("effect", b.effect)
	icon.custom_minimum_size = Vector2(32, 32)
	row.add_child(icon)
	var name_label := Label.new()
	name_label.text = "%s  x%d" % [tr(b.display_name_key), Economy.boost_count(b.id)]
	row.add_child(name_label)
	var armed: bool = Economy.is_boost_armed(b.id)
	var toggle := JuicyButton.new()
	toggle.toggle_mode = true
	toggle.button_pressed = armed
	toggle.custom_minimum_size = Vector2(120, 44)
	toggle.text = tr("BOOST_ARMED") if armed else tr("BOOST_ARM")
	toggle.toggled.connect(_on_arm_toggled.bind(b.id))
	row.add_child(toggle)
	return row


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
