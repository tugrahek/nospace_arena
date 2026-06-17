extends Control

## Main hub: Play (free-play), Daily (seed challenge), Store, Credits. Shows the active
## loadout, coins, and today's missions (read-only). Functional scaffold — void-neon
## visual polish is Step 15.

const GAME_SCENE: String = "res://scenes/main/Game.tscn"
const STORE_SCENE: String = "res://scenes/ui/Store.tscn"
const CREDITS_SCENE: String = "res://scenes/ui/Credits.tscn"
const MISSIONS_PATH: String = "user://missions.json"
const MISSION_COUNT: int = 3

@onready var _title: Label = $Title
@onready var _play_button: Button = $VBox/PlayButton
@onready var _daily_button: Button = $VBox/DailyButton
@onready var _store_button: Button = $VBox/StoreButton
@onready var _credits_button: Button = $VBox/CreditsButton
@onready var _coins: Label = $Coins
@onready var _loadout: Label = $Loadout
@onready var _missions: Label = $Missions


func _ready() -> void:
	_title.text = tr("GAME_TITLE")
	_play_button.text = tr("MENU_PLAY")
	_daily_button.text = tr("MENU_DAILY")
	_store_button.text = tr("MENU_STORE")
	_credits_button.text = tr("MENU_CREDITS")
	_play_button.pressed.connect(_on_play)
	_daily_button.pressed.connect(_on_daily)
	_store_button.pressed.connect(_on_store)
	_credits_button.pressed.connect(_on_credits)
	_refresh()


func _on_play() -> void:
	SeedManager.exit_daily()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_daily() -> void:
	SeedManager.enter_daily()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_store() -> void:
	get_tree().change_scene_to_file(STORE_SCENE)


func _on_credits() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)


func _refresh() -> void:
	_coins.text = tr("HUD_CURRENCY") + ": " + str(Economy.balance())
	var ch: CharacterData = ContentCatalog.CHARACTERS[ContentCatalog.character_index(Economy.selected_character())]
	var ar: ArenaData = ContentCatalog.ARENAS[ContentCatalog.arena_index(Economy.selected_arena())]
	_loadout.text = "%s: %s / %s" % [tr("MENU_LOADOUT"), tr(ch.display_name_key), tr(ar.display_name_key)]
	var date: int = SeedManager.compute_today()
	var saved: Dictionary = MissionStore.load_progress(MISSIONS_PATH, date)
	var missions: Array = MissionService.build(ContentCatalog.MISSIONS, date, MISSION_COUNT, saved)
	var lines: Array[String] = [tr("MENU_MISSIONS") + ":"]
	for m in missions:
		var mark: String = " ✓" if m.is_complete() else ""
		var desc: String = tr(m.def.description_key) % m.def.goal_amount
		lines.append("  %s  %d/%d%s" % [desc, m.progress, m.def.goal_amount, mark])
	_missions.text = "\n".join(lines)
