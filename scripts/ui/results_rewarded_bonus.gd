class_name ResultsRewardedBonus
extends Button

## Optional Results action. Only a matching AdsService reward callback can claim.
const AdsServiceScript = preload("res://scripts/monetization/ads_service.gd")
const EconomyScript = preload("res://scripts/autoload/Economy.gd")
const PALETTE: PaletteData = preload("res://config/palette.tres")

var ads_service: AdsServiceScript
var economy: EconomyScript
var _finalized: bool = false
var _attempted: bool = false
var _handled: bool = false
var _economy_context: int = -1
var _ad_context: String = ""
var _request_token: int = 0
@onready var _action_label: Label = $Content/ActionLabel
@onready var _amount_label: Label = $Content/Reward/Amount


func _ready() -> void:
	if ads_service == null:
		ads_service = AdsService
	if economy == null:
		economy = Economy
	visible = false
	pressed.connect(_on_pressed)
	visibility_changed.connect(_on_visibility_changed)
	GameState.game_started.connect(_reset_offer)
	ads_service.rewarded_ready.connect(_refresh)
	ads_service.ads_unavailable.connect(_on_unavailable)
	# Deferred delivery also supports synchronous backend callbacks during show_rewarded.
	ads_service.reward_earned.connect(_on_reward_earned, CONNECT_DEFERRED)
	ads_service.ad_closed.connect(_on_ad_closed, CONNECT_DEFERRED)
	ads_service.ad_failed.connect(_on_ad_failed, CONNECT_DEFERRED)
	economy.currency_changed.connect(_on_currency_changed)
	_action_label.add_theme_color_override("font_color", PALETTE.text_primary)
	_amount_label.add_theme_color_override("font_color", PALETTE.coin)


## Called only after mission payouts and all other run-result bookkeeping finish.
func present() -> void:
	_finalized = true
	var status: Dictionary = economy.rewarded_mission_bonus_status()
	if status["eligible"] and not _attempted:
		ads_service.preload_rewarded()  # best effort; no loading UI or blocked navigation
	_refresh()


func _reset_offer() -> void:
	_finalized = false
	_attempted = false
	_handled = false
	_request_token = 0
	_ad_context = ""
	visible = false


func _refresh() -> void:
	if not is_inside_tree():
		return
	if _attempted:
		visible = _request_token > 0 and not _handled
		disabled = true
		return
	var status: Dictionary = economy.rewarded_mission_bonus_status()
	visible = _finalized and status["eligible"] and ads_service.is_rewarded_available()
	disabled = not visible
	var amount: int = int(status["amount"])
	text = tr("RESULT_REWARDED_BONUS") % amount
	_action_label.text = tr("RESULT_REWARDED_BONUS_ACTION")
	_amount_label.text = tr("RESULT_REWARDED_BONUS_AMOUNT") % amount


func _on_pressed() -> void:
	if not _finalized or _attempted or not _results_active():
		return
	var status: Dictionary = economy.rewarded_mission_bonus_status()
	if not status["eligible"] or not ads_service.is_rewarded_available():
		_refresh()
		return
	_attempted = true
	disabled = true
	_economy_context = int(status["context_id"])
	_ad_context = "mission_bonus:%d:%d" % [get_instance_id(), _economy_context]
	_request_token = ads_service.show_rewarded(_ad_context)
	_refresh()


func _matches(context: String, token: int) -> bool:
	return _results_active() and _finalized and _attempted and not _handled \
		and _request_token > 0 and token == _request_token and context == _ad_context


## queue_free is deferred: reject a pending deletion anywhere in the Results hierarchy.
func _results_active() -> bool:
	if not is_inside_tree() or not is_visible_in_tree():
		return false
	var ancestor: Node = self
	while ancestor != null:
		if ancestor.is_queued_for_deletion():
			return false
		ancestor = ancestor.get_parent()
	return true


## Disappearing Results permanently retires its active request, even if shown again.
func _on_visibility_changed() -> void:
	if _finalized and _attempted and not is_visible_in_tree():
		_finalized = false
		_handled = true
		_request_token = 0


## Trust boundary: this handler alone authorizes the existing durable claim API.
func _on_reward_earned(context: String, token: int) -> void:
	if not _matches(context, token):
		return
	_handled = true  # consume before claiming/signals to reject reentrant callbacks
	var status: Dictionary = economy.rewarded_mission_bonus_status()
	if status["eligible"] and int(status["context_id"]) == _economy_context:
		economy.claim_rewarded_mission_bonus(_economy_context, true)
	_refresh()


func _on_ad_closed(context: String, token: int) -> void:
	if _matches(context, token):
		_handled = true
	_refresh()


func _on_ad_failed(context: String, token: int, _reason: StringName) -> void:
	if _matches(context, token):
		_handled = true
	_refresh()


func _on_unavailable(_reason: StringName) -> void:
	_refresh()


func _on_currency_changed(_balance: int) -> void:
	_refresh()


func _exit_tree() -> void:
	_finalized = false
	_request_token = 0
