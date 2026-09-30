extends Control

## Main hub: Play (-> mode select), Store, Missions, Credits, Settings (gear). Shows coins +
## the daily login reward popup. Mode (Daily/Free/Level) is chosen on the ModeSelect screen.

const MODE_SELECT_SCENE: String = "res://scenes/ui/ModeSelect.tscn"
const STORE_SCENE: String = "res://scenes/ui/Store.tscn"
const MISSIONS_SCENE: String = "res://scenes/ui/Missions.tscn"
const CREDITS_SCENE: String = "res://scenes/ui/Credits.tscn"
const SETTINGS_SCENE: String = "res://scenes/ui/Settings.tscn"
const LEADERBOARD_SCENE: String = "res://scenes/ui/Leaderboard.tscn"
const HOWTO_SCENE: String = "res://scenes/ui/HowToPlay.tscn"

@onready var _play_button: Button = $Center/Buttons/PlayButton
@onready var _store_button: Button = $Center/Buttons/NavigationHub/StoreButton
@onready var _missions_button: Button = $Center/Buttons/NavigationHub/MissionsButton
@onready var _leaderboard_button: Button = $Center/Buttons/NavigationHub/LeaderboardButton
@onready var _credits_button: Button = $Center/Buttons/NavigationHub/CreditsButton
@onready var _store_label: Label = $Center/Buttons/NavigationHub/StoreButton/Label
@onready var _missions_label: Label = $Center/Buttons/NavigationHub/MissionsButton/Label
@onready var _leaderboard_label: Label = $Center/Buttons/NavigationHub/LeaderboardButton/Label
@onready var _credits_label: Label = $Center/Buttons/NavigationHub/CreditsButton/Label
@onready var _settings_button: Button = $SettingsButton
@onready var _help_button: Button = $HelpButton
@onready var _coins: Label = $CoinsPanel/Content/Coins
@onready var _reward_popup: Control = $RewardPopup
@onready var _reward_title: Label = $RewardPopup/Box/RewardTitle
@onready var _reward_body: Label = $RewardPopup/Box/RewardBody
@onready var _claim_button: Button = $RewardPopup/Box/ClaimButton
@onready var _emblem: Control = $Center/Emblem


func _ready() -> void:
	# Wordmark ("NoSpace" + "A R E N A") + emblem are set in the scene.
	_play_button.text = tr("MENU_PLAY")
	_store_label.text = tr("MENU_STORE")
	_missions_label.text = tr("MENU_MISSIONS_SHORT")
	_leaderboard_label.text = tr("MENU_LEADERBOARD")
	_credits_label.text = tr("MENU_CREDITS")
	_play_button.pressed.connect(_on_play)
	_store_button.pressed.connect(_on_store)
	_missions_button.pressed.connect(_on_missions)
	_leaderboard_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(LEADERBOARD_SCENE))
	_credits_button.pressed.connect(_on_credits)
	_settings_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SETTINGS_SCENE))
	_help_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(HOWTO_SCENE))
	_reward_title.text = tr("DAILY_REWARD_TITLE")
	_claim_button.text = tr("DAILY_REWARD_CLAIM")
	_claim_button.pressed.connect(_on_claim_reward)
	_refresh()
	if not _maybe_show_reward():
		_emblem.play_intro()
	AudioManager.play_music("menu")  # menu track
	# First launch: show how-to-play once (HowToPlay marks it seen on entry).
	if not Economy.tutorial_seen():
		get_tree().change_scene_to_file.call_deferred(HOWTO_SCENE)


## Shows the login-reward popup if a reward is claimable today (Step 15 polishes it).
func _maybe_show_reward() -> bool:
	var status: Dictionary = Economy.login_reward_status()
	if not status["claimable"]:
		_reward_popup.visible = false
		return false
	_reward_body.text = tr("DAILY_REWARD_BODY") % [status["new_streak"], status["reward"]]
	_reward_popup.visible = true
	return true


func _on_claim_reward() -> void:
	Economy.claim_login_reward()
	_reward_popup.visible = false
	_refresh()
	_emblem.play_intro()


func _on_play() -> void:
	get_tree().change_scene_to_file(MODE_SELECT_SCENE)  # pick Daily / Free / Level


func _on_store() -> void:
	get_tree().change_scene_to_file(STORE_SCENE)


func _on_missions() -> void:
	get_tree().change_scene_to_file(MISSIONS_SCENE)


func _on_credits() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)


func _refresh() -> void:
	# Missions + loadout/selection have their own panels (Missions/Store) — not here.
	_coins.text = tr("HUD_CURRENCY") + ": " + str(Economy.balance())
