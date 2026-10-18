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

@onready var _play_button: Button = $SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/PlayButton
@onready var _store_button: Button = $SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/StoreButton
@onready var _missions_button: Button = $SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/MissionsButton
@onready var _leaderboard_button: Button = $SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/LeaderboardButton
@onready var _howto_button: Button = $SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/HowToButton
@onready var _store_label: Label = $SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/StoreButton/Content/Label
@onready var _missions_label: Label = $SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/MissionsButton/Content/Label
@onready var _leaderboard_label: Label = $SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/LeaderboardButton/Content/Label
@onready var _howto_label: Label = $SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/HowToButton/Content/Label
@onready var _settings_button: Button = $SafeArea/Bounds/Frame/Header/SettingsButton
@onready var _reward_entry: Button = $SafeArea/Bounds/Frame/Header/RewardEntry
@onready var _reward_progress: Label = $SafeArea/Bounds/Frame/Header/RewardEntry/Content/Labels/Progress
@onready var _daily_caption: Label = $SafeArea/Bounds/Frame/Header/RewardEntry/Content/Labels/Caption
@onready var _coins: Label = $SafeArea/Bounds/Frame/Header/CoinsPanel/Content/Coins
@onready var _reward_popup: DailyRewardPopup = $RewardPopup
@onready var _emblem: Control = $SafeArea/Bounds/Frame/ContentGroup/Center/Emblem
@onready var _menu_buttons: VBoxContainer = $SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons
@onready var _brand_title: Label = $SafeArea/Bounds/Frame/ContentGroup/Center/Title
@onready var _brand_subtitle: Label = $SafeArea/Bounds/Frame/ContentGroup/Center/Subtitle
@onready var _gift_overlay: Control = $GiftOverlay
@onready var _gift_reveal: SupplyPopup = $GiftOverlay/Reveal


func _ready() -> void:
	# Wordmark ("NoSpace" + "A R E N A") + emblem are set in the scene.
	_apply_texts()
	_play_button.pressed.connect(_on_play)
	_store_button.pressed.connect(_on_store)
	_missions_button.pressed.connect(_on_missions)
	_leaderboard_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(LEADERBOARD_SCENE))
	_howto_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(HOWTO_SCENE))
	_settings_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SETTINGS_SCENE))
	_reward_popup.reward_claimed.connect(func(_amount: int) -> void: _refresh())
	_reward_popup.dismissed.connect(_on_reward_dismissed)
	_gift_reveal.dismissed.connect(_on_gift_dismissed)
	_reward_entry.pressed.connect(_open_reward)
	Economy.currency_changed.connect(_on_currency_changed)
	_refresh()
	if not _maybe_show_reward():
		_emblem.play_intro()
		_show_daily_gift.call_deferred()
	AudioManager.play_music("menu")  # menu track
	# First launch: show how-to-play once (HowToPlay marks it seen on entry).
	if not Economy.tutorial_seen():
		get_tree().change_scene_to_file.call_deferred(HOWTO_SCENE)


## Re-applies dynamic strings when Godot changes the active translation.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_texts()
		_refresh()


## Main-menu labels are assigned in code, so refresh them when the locale changes.
func _apply_texts() -> void:
	_play_button.text = tr("MENU_PLAY")
	_store_label.text = tr("MENU_STORE")
	_missions_label.text = tr("MENU_MISSIONS_SHORT")
	_leaderboard_label.text = tr("MENU_LEADERBOARD")
	_howto_label.text = tr("MENU_HOWTO")


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
	if _show_daily_gift():
		return
	_set_reward_context(false)
	_emblem.play_intro()


## Reconciles accepted gifts, then presents only their persisted result through the shared reveal.
func _show_daily_gift() -> bool:
	Economy.supply_acquisition().recover()
	for id: String in Economy.supply_boxes().unpresented_deliveries():
		if Economy.supply_boxes().box_status(id).get("source") != DailyRewardClaim.GIFT_SOURCE:
			continue
		_gift_overlay.visible = true
		if _gift_reveal.present_delivery(id):
			_set_reward_context(true)
			return true
	_gift_overlay.visible = false
	return false


func _on_gift_dismissed() -> void:
	_gift_overlay.visible = false
	_set_reward_context(false)
	_emblem.play_intro()


func _open_reward() -> void:
	_refresh()
	_set_reward_context(_reward_popup.present(Economy.login_reward_status(), true))


func _on_currency_changed(_balance: int) -> void:
	_refresh()


func _on_play() -> void:
	get_tree().change_scene_to_file(MODE_SELECT_SCENE)  # pick Daily / Free / Level


func _on_store() -> void:
	get_tree().change_scene_to_file(STORE_SCENE)


func _on_missions() -> void:
	get_tree().change_scene_to_file(MISSIONS_SCENE)


func _refresh() -> void:
	# Missions + loadout/selection have their own panels (Missions/Store) — not here.
	_coins.text = tr("HUD_CURRENCY_VALUE") % Economy.balance()
	var status: Dictionary = Economy.login_reward_status()
	_reward_progress.text = "%d/10" % clampi(int(status["new_streak"]), 1, 10)
	_reward_entry.tooltip_text = tr("DAILY_REWARD_TITLE")
	_daily_caption.text = tr("MENU_DAILY")
	_reward_entry.modulate = Color.WHITE if status["claimable"] else Color(1, 1, 1, 0.85)
