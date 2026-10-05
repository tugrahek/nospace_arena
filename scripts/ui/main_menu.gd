extends Control

## Main hub: Play (-> mode select), Store, Missions, Leaderboard, How to Play, Settings (gear). Shows coins +
## the daily login reward popup. Mode (Daily/Free/Level) is chosen on the ModeSelect screen.

const MODE_SELECT_SCENE: String = "res://scenes/ui/ModeSelect.tscn"
const STORE_SCENE: String = "res://scenes/ui/Store.tscn"
const MISSIONS_SCENE: String = "res://scenes/ui/Missions.tscn"
const SETTINGS_SCENE: String = "res://scenes/ui/Settings.tscn"
const LEADERBOARD_SCENE: String = "res://scenes/ui/Leaderboard.tscn"
const HOWTO_SCENE: String = "res://scenes/ui/HowToPlay.tscn"
@export var reward_context_alpha: float = 0.25

@onready var _play_button: Button = $Center/Buttons/PlayButton
@onready var _store_button: Button = $Center/Buttons/NavigationHub/StoreButton
@onready var _missions_button: Button = $Center/Buttons/NavigationHub/MissionsButton
@onready var _leaderboard_button: Button = $Center/Buttons/NavigationHub/LeaderboardButton
@onready var _howto_button: Button = $Center/Buttons/NavigationHub/HowToButton
@onready var _store_label: Label = $Center/Buttons/NavigationHub/StoreButton/Label
@onready var _missions_label: Label = $Center/Buttons/NavigationHub/MissionsButton/Label
@onready var _leaderboard_label: Label = $Center/Buttons/NavigationHub/LeaderboardButton/Label
@onready var _howto_label: Label = $Center/Buttons/NavigationHub/HowToButton/Label
@onready var _settings_button: Button = $SettingsButton
@onready var _reward_entry: Button = $RewardEntry
@onready var _reward_progress: Label = $RewardEntry/Progress
@onready var _coins: Label = $CoinsPanel/Content/Coins
@onready var _reward_popup: DailyRewardPopup = $RewardPopup
@onready var _emblem: Control = $Center/Emblem
@onready var _menu_buttons: VBoxContainer = $Center/Buttons
@onready var _brand_title: Label = $Center/Title
@onready var _brand_subtitle: Label = $Center/Subtitle


func _ready() -> void:
	# Wordmark ("NoSpace" + "A R E N A") + emblem are set in the scene.
	_play_button.text = tr("MENU_PLAY")
	_store_label.text = tr("MENU_STORE")
	_missions_label.text = tr("MENU_MISSIONS_SHORT")
	_leaderboard_label.text = tr("MENU_LEADERBOARD")
	_howto_label.text = tr("MENU_HOWTO")
	_play_button.pressed.connect(_on_play)
	_store_button.pressed.connect(_on_store)
	_missions_button.pressed.connect(_on_missions)
	_leaderboard_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(LEADERBOARD_SCENE))
	_howto_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(HOWTO_SCENE))
	_settings_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SETTINGS_SCENE))
	_reward_popup.reward_claimed.connect(func(_amount: int) -> void: _refresh())
	_reward_popup.dismissed.connect(_on_reward_dismissed)
	_reward_entry.pressed.connect(_open_reward)
	_refresh()
	if not _maybe_show_reward():
		_emblem.play_intro()
	AudioManager.play_music("menu")  # menu track
	# First launch: show how-to-play once (HowToPlay marks it seen on entry).
	if not Economy.tutorial_seen():
		get_tree().change_scene_to_file.call_deferred(HOWTO_SCENE)


## Shows the login-reward popup if a reward is claimable today (Step 15 polishes it).
func _maybe_show_reward() -> bool:
	var shown: bool = _reward_popup.present(Economy.login_reward_status())
	_set_reward_context(shown)
	return shown


func _set_reward_context(active: bool) -> void:
	var opacity: float = reward_context_alpha if active else 1.0
	_menu_buttons.modulate.a = opacity
	_play_button.modulate.a = 0.0 if active else 1.0
	_brand_title.modulate.a = opacity
	_brand_subtitle.modulate.a = opacity
	_emblem.modulate.a = opacity


func _on_reward_dismissed() -> void:
	_set_reward_context(false)
	_emblem.play_intro()


func _open_reward() -> void:
	_refresh()
	_set_reward_context(_reward_popup.present(Economy.login_reward_status(), true))


func _on_play() -> void:
	get_tree().change_scene_to_file(MODE_SELECT_SCENE)  # pick Daily / Free / Level


func _on_store() -> void:
	get_tree().change_scene_to_file(STORE_SCENE)


func _on_missions() -> void:
	get_tree().change_scene_to_file(MISSIONS_SCENE)


func _refresh() -> void:
	# Missions + loadout/selection have their own panels (Missions/Store) — not here.
	_coins.text = tr("HUD_CURRENCY") + ": " + str(Economy.balance())
	var status: Dictionary = Economy.login_reward_status()
	_reward_progress.text = "%d/7" % clampi(int(status["new_streak"]), 1, 7)
	_reward_entry.tooltip_text = tr("DAILY_REWARD_TITLE")
	_reward_entry.modulate = Color.WHITE if status["claimable"] else Color(1, 1, 1, 0.55)
