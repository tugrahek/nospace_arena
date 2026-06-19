extends Control

## Main hub: Play (free-play), Daily, Store, Missions, Credits. Shows active loadout + coins
## + daily login reward popup. Missions have their own panel. Visual polish is Step 15.

const GAME_SCENE: String = "res://scenes/main/Game.tscn"
const STORE_SCENE: String = "res://scenes/ui/Store.tscn"
const MISSIONS_SCENE: String = "res://scenes/ui/Missions.tscn"
const CREDITS_SCENE: String = "res://scenes/ui/Credits.tscn"
const SETTINGS_SCENE: String = "res://scenes/ui/Settings.tscn"

@onready var _play_button: Button = $Center/Buttons/PlayButton
@onready var _daily_button: Button = $Center/Buttons/DailyButton
@onready var _store_button: Button = $Center/Buttons/StoreButton
@onready var _missions_button: Button = $Center/Buttons/MissionsButton
@onready var _credits_button: Button = $Center/Buttons/CreditsButton
@onready var _settings_button: Button = $SettingsButton
@onready var _coins: Label = $CoinsPanel/Coins
@onready var _reward_popup: Control = $RewardPopup
@onready var _reward_title: Label = $RewardPopup/Box/RewardTitle
@onready var _reward_body: Label = $RewardPopup/Box/RewardBody
@onready var _claim_button: Button = $RewardPopup/Box/ClaimButton


func _ready() -> void:
	# Wordmark ("NoSpace" + "A R E N A") + emblem are set in the scene.
	_play_button.text = tr("MENU_PLAY")
	_daily_button.text = tr("MENU_DAILY")
	_store_button.text = tr("MENU_STORE")
	_missions_button.text = tr("MISSIONS_TITLE")
	_credits_button.text = tr("MENU_CREDITS")
	_play_button.pressed.connect(_on_play)
	_daily_button.pressed.connect(_on_daily)
	_store_button.pressed.connect(_on_store)
	_missions_button.pressed.connect(_on_missions)
	_credits_button.pressed.connect(_on_credits)
	_settings_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SETTINGS_SCENE))
	_reward_title.text = tr("DAILY_REWARD_TITLE")
	_claim_button.text = tr("DAILY_REWARD_CLAIM")
	_claim_button.pressed.connect(_on_claim_reward)
	_refresh()
	_maybe_show_reward()
	AudioManager.play_music("menu")  # menu track (silent until 17b assets)


## Shows the login-reward popup if a reward is claimable today (Step 15 polishes it).
func _maybe_show_reward() -> void:
	var status: Dictionary = Economy.login_reward_status()
	if not status["claimable"]:
		_reward_popup.visible = false
		return
	_reward_body.text = tr("DAILY_REWARD_BODY") % [status["new_streak"], status["reward"]]
	_reward_popup.visible = true


func _on_claim_reward() -> void:
	Economy.claim_login_reward()
	_reward_popup.visible = false
	_refresh()


func _on_play() -> void:
	SeedManager.exit_daily()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_daily() -> void:
	SeedManager.enter_daily()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_store() -> void:
	get_tree().change_scene_to_file(STORE_SCENE)


func _on_missions() -> void:
	get_tree().change_scene_to_file(MISSIONS_SCENE)


func _on_credits() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)


func _refresh() -> void:
	# Missions + loadout/selection have their own panels (Missions/Store) — not here.
	_coins.text = tr("HUD_CURRENCY") + ": " + str(Economy.balance())
