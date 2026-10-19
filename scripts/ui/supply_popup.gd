class_name SupplyPopup
extends Control

## Presentation only: acquisition owns proof/charging, Economy/core own durable rewards.
signal dismissed
signal availability_changed
enum State { HIDDEN, READY, BUSY, REVEAL, ODDS }
const PALETTE: PaletteData = preload("res://config/palette.tres")
const BoostIcon = preload("res://scripts/ui/boost_icon.gd")
const REQUEST_ID_BYTES: int = 16
const MAX_CONTENT_WIDTH: float = 800.0
const HERO_SIZES: Vector2 = Vector2(224.0, 340.0)
const HERO_HEIGHT_SHARE: float = 0.45
const REWARD_KEYS: Dictionary = {"coins": "SUPPLY_REWARD_COINS", "slow_start": "SUPPLY_REWARD_SLOW",
	"coin_bonus": "SUPPLY_REWARD_BONUS", "extra_life": "SUPPLY_REWARD_LIFE"}
@export var reveal_duration: float = 0.55
@export var reveal_scale: float = 0.96
@export var embedded: bool = false
var economy: Node
var ads: Node
var acquisition: SupplyBoxAcquisition
var core: SupplyBoxCore
var state: State = State.HIDDEN
var revealed_box_id: String = ""
var _ad_token: int = 0
var _day_context: int = 0
var _motion: Tween
var _layout_pending: bool = false
@onready var _bounds: Control = $SafeArea/Bounds
@onready var _frame: Control = $SafeArea/Bounds/Frame
@onready var _identity: Control = $SafeArea/Bounds/Frame/Surface/Scroll/Body/Content/Identity
@onready var _close: SupplyActionButton = $SafeArea/Bounds/Frame/Surface/Footer/Close
@onready var _surface: VBoxContainer = $SafeArea/Bounds/Frame/Surface
@onready var _title: Label = $SafeArea/Bounds/Frame/Surface/Title
@onready var _reward_icon: Control = $SafeArea/Bounds/Frame/RevealView/Scroll/Body/Content/RewardIcon
@onready var _reward: Label = $SafeArea/Bounds/Frame/RevealView/Scroll/Body/Content/Reward
@onready var _feedback: Label = $SafeArea/Bounds/Frame/Surface/Scroll/Body/Content/Feedback
@onready var _ad: SupplyActionButton = $SafeArea/Bounds/Frame/Surface/Scroll/Body/Content/AdRow/Ad
@onready var _coin: SupplyActionButton = $SafeArea/Bounds/Frame/Surface/Scroll/Body/Content/CoinRow/Coin
@onready var _continue: SupplyActionButton = $SafeArea/Bounds/Frame/RevealView/Footer/Continue
@onready var _odds: SupplyActionButton = $SafeArea/Bounds/Frame/Surface/Footer/Odds
@onready var _cube: Control = $SafeArea/Bounds/Frame/RevealView/Scroll/Body/Content/Cube


func _ready() -> void:
	if economy == null:
		economy = Economy
	if ads == null:
		ads = AdsService
	if core == null:
		core = economy.supply_boxes()
	if acquisition == null:
		acquisition = economy.supply_acquisition()
	_ad.pressed.connect(_watch_ad)
	_coin.pressed.connect(_buy_coin)
	_continue.pressed.connect(_finish_reveal)
	_odds.pressed.connect(show_odds)
	_close.pressed.connect(close)
	$SafeArea/Bounds/Frame/OddsView/Footer/Back.pressed.connect(hide_odds)
	core.box_delivered.connect(_on_delivered)
	economy.currency_changed.connect(_on_currency)
	economy.boosts_changed.connect(refresh)
	ads.rewarded_ready.connect(refresh)
	ads.ads_unavailable.connect(_on_unavailable)
	ads.ad_closed.connect(_on_ad_closed, CONNECT_DEFERRED)
	ads.ad_failed.connect(_on_ad_failed, CONNECT_DEFERRED)
	_ad.caption_color = PALETTE.void_bg
	_coin.caption_color = PALETTE.coin
	_cube.resized.connect(func() -> void: _cube.pivot_offset = _cube.size * 0.5)
	_reward_icon.resized.connect(func() -> void: _reward_icon.pivot_offset = _reward_icon.size * 0.5)
	_bounds.resized.connect(_queue_layout)
	for view_name: String in ["Surface", "OddsView", "RevealView"]:
		var scroll: ScrollContainer = _frame.get_node(view_name + "/Scroll")
		scroll.resized.connect(_queue_layout)
	visible = false
	refresh()


func _queue_layout() -> void:
	if _layout_pending or not is_inside_tree():
		return
	_layout_pending = true
	_refresh_layout.call_deferred()


## Fit only presentation to the current host; body scrolling protects footer actions.
func _refresh_layout() -> void:
	_layout_pending = false
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var width: float = minf(_bounds.size.x, MAX_CONTENT_WIDTH)
	_frame.offset_left = -width * 0.5
	_frame.offset_right = width * 0.5
	var surface_scroll: ScrollContainer = _frame.get_node("Surface/Scroll")
	var reveal_scroll: ScrollContainer = _frame.get_node("RevealView/Scroll")
	var max_side: float = maxf(0.0, width - 32.0)
	_identity.custom_minimum_size = Vector2.ONE * minf(max_side,
		roundf(clampf(surface_scroll.size.y * HERO_HEIGHT_SHARE, HERO_SIZES.x, HERO_SIZES.y)))
	_cube.custom_minimum_size = Vector2.ONE * minf(max_side,
		roundf(clampf(reveal_scroll.size.y * HERO_HEIGHT_SHARE, HERO_SIZES.x, HERO_SIZES.y)))


## Entry denotes remaining daily reward allowance independently of ad readiness.
func daily_available() -> bool:
	var status: Dictionary = acquisition.status()
	return int(status["rewarded_count"]) < int(status["rewarded_limit"])


## Opens manually, reconciles durable pending deliveries and shows unpresented results first.
func present() -> void:
	if visible:
		refresh()
		return
	visible = true
	state = State.BUSY if _ad_token != 0 else State.READY
	revealed_box_id = ""
	_feedback.text = ""
	acquisition.recover()
	var pending: Array[String] = core.unpresented_deliveries()
	if not pending.is_empty():
		_reveal(pending[0])
	else:
		refresh()
	ads.initialize()
	ads.preload_rewarded()


## Shared gift/recovery reveal: reconcile and display an exact durable record, never acquire.
func present_delivery(id: String) -> bool:
	acquisition.recover()
	if core.box_status(id).get("state") != SupplyBoxCore.DELIVERED:
		return false
	visible = true
	_reveal(id)
	return state == State.REVEAL


## Dismissal never cancels a valid service request or acknowledges an unseen reward.
func close() -> void:
	if state == State.REVEAL:
		_finish_reveal()
		return
	_hide()


## Compact acquisition surface; reveal and odds occupy separate views.
func refresh() -> void:
	var status: Dictionary = acquisition.status()
	_day_context = int(status["day"])
	_surface.visible = state not in [State.REVEAL, State.ODDS]
	$SafeArea/Bounds/Frame/OddsView.visible = state == State.ODDS
	$SafeArea/Bounds/Frame/RevealView.visible = state == State.REVEAL
	_title.text = tr("SUPPLY_TITLE")
	$SafeArea/Bounds/Frame/RevealView/Title.text = tr("SUPPLY_RECEIVED")
	_continue.set_caption(tr("SUPPLY_CONTINUE"))
	_ad.set_caption(tr("SUPPLY_AD"))
	var rewarded_action: bool = daily_available() and (_ad_token != 0 or ads.is_rewarded_available())
	_ad.get_parent().visible = rewarded_action
	_coin.get_parent().visible = not rewarded_action
	_ad.disabled = state != State.READY or not daily_available() or not ads.is_rewarded_available()
	var limit: bool = int(status["coin_count"]) >= int(status["coin_limit"])
	var affordable: bool = economy.can_afford(int(status["coin_cost"]))
	_coin.set_caption(tr("SUPPLY_TOMORROW") if limit else tr("SUPPLY_COST") % int(status["coin_cost"]))
	$SafeArea/Bounds/Frame/Surface/Scroll/Body/Content/CoinRow/Coin/Content/Icon.visible = not limit
	_coin.disabled = state != State.READY or not acquisition.coin_available()
	_coin.tooltip_text = tr("SUPPLY_COIN_LIMIT") if limit else (tr("SUPPLY_NOT_ENOUGH") % int(status["coin_cost"])) if not affordable else ""
	_odds.set_caption(tr("SUPPLY_ODDS"))
	_odds.disabled = state != State.READY
	$SafeArea/Bounds/Frame/OddsView/Title.text = tr("SUPPLY_ODDS")
	$SafeArea/Bounds/Frame/OddsView/Footer/Back.set_caption(tr("SUPPLY_BACK_TO_BOX"))
	_feedback.visible = not _feedback.text.is_empty()
	_close.visible = not embedded
	_close.set_caption(tr("SUPPLY_CLOSE"))
	_queue_layout()
	availability_changed.emit()


## Reads the approved Resource for disclosure only; never selects an outcome.
func show_odds() -> void:
	if state != State.READY:
		return
	var table: SupplyRewardTable = acquisition._config.reward_table
	var total: float = 0.0
	var categories: Dictionary = {}
	for entry: SupplyRewardEntry in table.entries:
		total += entry.weight
		categories[entry.reward_type] = float(categories.get(entry.reward_type, 0.0)) + entry.weight
	var rows: VBoxContainer = $SafeArea/Bounds/Frame/OddsView/Scroll/Body/Content/Rows
	for child in rows.get_children():
		child.free()
	for type: StringName in categories:
		var value: float = snappedf(float(categories[type]) * 100.0 / total, 0.01)
		var row := SupplyOddsRow.new()
		var key: String = "HUD_CURRENCY" if type == &"coins" else String(ContentCatalog.boost_by_id(type).display_name_key)
		row.configure(tr(key), str(value).trim_suffix(".0") + "%", {&"coins": 2, &"slow_start": 1, &"coin_bonus": BoostIcon.COIN_BONUS_ICON, &"extra_life": 0}[type])
		rows.add_child(row)
	state = State.ODDS
	refresh()

## Returns to acquisition without a request, save or grant.
func hide_odds() -> void:
	if state == State.ODDS:
		state = State.READY
		refresh()

func _watch_ad() -> void:
	if state != State.READY or _ad.disabled:
		return
	state = State.BUSY
	var day: int = _day_context
	refresh()
	_ad_token = acquisition.show_daily_rewarded(day)
	if _ad_token == 0:
		state = State.READY
		_feedback.text = tr("SUPPLY_AD_UNAVAILABLE")
	refresh()


func _buy_coin() -> void:
	if state != State.READY or _coin.disabled:
		return
	state = State.BUSY
	var day: int = _day_context
	refresh()
	var request: String = Crypto.new().generate_random_bytes(REQUEST_ID_BYTES).hex_encode()
	var result: Dictionary = acquisition.purchase_coin_box(request, day)
	if state != State.REVEAL:
		state = State.READY
		_feedback.text = tr("SUPPLY_PENDING" if result.get("accepted", false) else "SUPPLY_REJECTED")
	refresh()


func _on_delivered(id: String, _unused_reward: Dictionary) -> void:
	if visible and state != State.REVEAL:
		_reveal(id)
	else:
		refresh()


func _reveal(id: String) -> void:
	var record: Dictionary = core.box_status(id)
	if record.get("state") != SupplyBoxCore.DELIVERED or not REWARD_KEYS.has(record.get("reward_type")):
		return
	revealed_box_id = id
	state = State.REVEAL
	_reward.text = tr(REWARD_KEYS[record["reward_type"]]) % int(record["amount"])
	_reward_icon.set("effect", {"coins": 2, "coin_bonus": BoostIcon.COIN_BONUS_ICON, "slow_start": 1, "extra_life": 0}[record["reward_type"]])
	_reward_icon.queue_redraw()
	_feedback.text = ""
	refresh()
	$SafeArea/Bounds/Frame/RevealView/Scroll/Body/Content/Feedback.text = ""
	_animate_reveal()


func _animate_reveal() -> void:
	_stop_reveal()
	_reward.pivot_offset = _reward.size * 0.5
	_cube.scale = Vector2.ONE * reveal_scale
	_cube.modulate = PALETTE.accent_alt.lightened(0.65)
	_reward_icon.scale = Vector2.ONE * 0.8
	_reward_icon.modulate.a = 0.0
	_reward.modulate.a = 0.0
	_motion = create_tween().set_parallel(true).set_ignore_time_scale(true)
	_motion.tween_property(_cube, "scale", Vector2.ONE * 1.04, reveal_duration * 0.3).set_trans(Tween.TRANS_SINE)
	_motion.tween_property(_cube, "scale", Vector2.ONE, reveal_duration * 0.7).set_delay(reveal_duration * 0.3)
	_motion.tween_property(_cube, "modulate", Color.WHITE, reveal_duration)
	_motion.tween_property(_reward_icon, "scale", Vector2.ONE, reveal_duration * 0.6).set_delay(reveal_duration * 0.15)
	_motion.tween_property(_reward_icon, "modulate:a", 1.0, reveal_duration * 0.5).set_delay(reveal_duration * 0.15)
	_motion.tween_property(_reward, "modulate:a", 1.0, reveal_duration * 0.7).set_delay(reveal_duration * 0.3)


func _stop_reveal() -> void:
	if _motion != null:
		_motion.kill()
	_cube.scale = Vector2.ONE
	_cube.modulate = Color.WHITE
	_reward_icon.scale = Vector2.ONE
	_reward_icon.modulate.a = 1.0
	_reward.modulate.a = 1.0


func _finish_reveal() -> void:
	if state != State.REVEAL:
		return
	if not core.mark_presented(revealed_box_id):
		$SafeArea/Bounds/Frame/RevealView/Scroll/Body/Content/Feedback.text = tr("SUPPLY_SAVE_RETRY")
		return
	_stop_reveal()
	if embedded:
		state = State.READY
		revealed_box_id = ""
		refresh()
	else:
		_hide()


func _hide() -> void:
	if not visible:
		return
	_stop_reveal()
	visible = false
	state = State.HIDDEN
	dismissed.emit()


func _on_currency(_amount: int) -> void:
	refresh()


func _on_unavailable(_reason: StringName) -> void:
	refresh()


func _on_ad_closed(_context: String, token: int) -> void:
	if token != _ad_token:
		return
	_ad_token = 0
	if state == State.BUSY:
		state = State.READY
	refresh()
	if visible:
		ads.preload_rewarded()


func _on_ad_failed(context: String, token: int, _reason: StringName) -> void:
	if token == _ad_token and token != 0:
		_ad_token = 0
		if state == State.BUSY:
			state = State.READY
		_feedback.text = tr("SUPPLY_AD_FAILED")
	elif context.is_empty() and visible:
		_feedback.text = tr("SUPPLY_AD_UNAVAILABLE")
	refresh()
