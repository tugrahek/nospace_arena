class_name DailyRewardPopup
extends Control

## Manual daily reward presentation. Economy remains responsible for eligibility and saving.
signal reward_claimed(amount: int)
signal dismissed
enum State { HIDDEN, READY, CLAIMING, CLAIMED, DISMISSING, INSPECTING }
const PALETTE: PaletteData = preload("res://config/palette.tres")
const BoostIcon = preload("res://scripts/ui/boost_icon.gd")
const MAX_POPUP_WIDTH: float = 760.0
const MAX_POPUP_HEIGHT: float = 1280.0
const POPUP_HEIGHT_SHARE: float = 0.88
const HERO_SIZES: Vector2 = Vector2(160.0, 220.0)
const HERO_HEIGHT_SHARE: float = 0.25
const RING_DIAMETER_SHARE: float = 1.5
const HERO_PADDING: float = 16.0
@export var entrance_duration: float = 0.20
@export var claim_pulse_duration: float = 0.22
@export var claimed_hold_duration: float = 0.7
@export var dismissal_duration: float = 0.16
@export var pulse_scale: float = 1.12
var state: State = State.HIDDEN
var reward_amount: int = 0
var preview_spec: Dictionary = {}
var current_day: int = 1
var selected_day: int = 1
var completed_days: int = 0
var _eligible: bool = false
var _active_reward_icon: Control
var _ring_progress: float = 1.0:
	set(value):
		_ring_progress = value
		queue_redraw()
var claim_action: Callable
var _motion: Tween
var _layout_pending: bool = false
@onready var _bounds: Control = $SafeArea/Bounds
@onready var _scroll: ScrollContainer = $SafeArea/Bounds/Box/Scroll
@onready var _hero: CenterContainer = $SafeArea/Bounds/Box/Scroll/Body/Content/Hero
@onready var _route_scroll: ScrollContainer = $SafeArea/Bounds/Box/Scroll/Body/Content/RouteScroll
@onready var _box: VBoxContainer = $SafeArea/Bounds/Box
@onready var _title: Label = $SafeArea/Bounds/Box/RewardTitle
@onready var _coin: Control = $SafeArea/Bounds/Box/Scroll/Body/Content/Hero/Coin
@onready var _bonus_icon: Control = $SafeArea/Bounds/Box/Scroll/Body/Content/Hero/BoostIcon
@onready var _gift_icon: Control = $SafeArea/Bounds/Box/Scroll/Body/Content/Hero/SupplyGift
@onready var _amount: Label = $SafeArea/Bounds/Box/Scroll/Body/Content/RewardAmount
@onready var _currency: Label = $SafeArea/Bounds/Box/Scroll/Body/Content/Currency
@onready var _day: Label = $SafeArea/Bounds/Box/Scroll/Body/Content/RewardBody
@onready var _claim: Button = $SafeArea/Bounds/Box/Footer/ClaimButton
@onready var _route: DailyRewardRoute = $SafeArea/Bounds/Box/Scroll/Body/Content/RouteScroll/Route
@onready var _received: Label = $SafeArea/Bounds/Box/Scroll/Body/Content/Received
@onready var _close: Button = $SafeArea/Bounds/Box/Footer/CloseButton


func _ready() -> void:
	if not claim_action.is_valid():
		claim_action = Economy.claim_login_reward_bundle
	_claim.pressed.connect(_on_claim)
	_close.pressed.connect(close)
	_route.day_selected.connect(preview_day)
	_style_claim()
	_claim.add_theme_color_override("font_disabled_color", PALETTE.accent)
	_amount.add_theme_color_override("font_color", PALETTE.coin)
	visible = false
	_box.resized.connect(func() -> void: _box.pivot_offset = _box.size * 0.5)
	_coin.resized.connect(func() -> void: _coin.pivot_offset = _coin.size * 0.5)
	_bonus_icon.resized.connect(func() -> void: _bonus_icon.pivot_offset = _bonus_icon.size * 0.5)
	_amount.resized.connect(func() -> void: _amount.pivot_offset = _amount.size * 0.5)
	_gift_icon.resized.connect(func() -> void: _gift_icon.pivot_offset = _gift_icon.size * 0.5)
	_bounds.resized.connect(_queue_layout)
	_scroll.resized.connect(_queue_layout)
	_route_scroll.resized.connect(_focus_route)
	_queue_layout()


func _queue_layout() -> void:
	if _layout_pending or not is_inside_tree():
		return
	_layout_pending = true
	_refresh_layout.call_deferred()


func _refresh_layout() -> void:
	_layout_pending = false
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var width: float = minf(_bounds.size.x, MAX_POPUP_WIDTH)
	var height: float = minf(_bounds.size.y * POPUP_HEIGHT_SHARE, MAX_POPUP_HEIGHT)
	_box.offset_left = -width * 0.5
	_box.offset_right = width * 0.5
	_box.offset_top = -height * 0.5
	_box.offset_bottom = height * 0.5
	var side: float = roundf(clampf(_scroll.size.y * HERO_HEIGHT_SHARE, HERO_SIZES.x, HERO_SIZES.y))
	for icon: Control in [_coin, _bonus_icon, _gift_icon]:
		icon.custom_minimum_size = Vector2.ONE * side
	_hero.custom_minimum_size.y = ceilf(side * RING_DIAMETER_SHARE + HERO_PADDING)
	_focus_route()


func _focus_route() -> void:
	if is_inside_tree() and _box.scale.is_equal_approx(Vector2.ONE) and _route.checkpoints.size() == DailyRewardRoute.DAYS:
		_route_scroll.ensure_control_visible(_route.checkpoints[selected_day - 1])


func _focus_hero() -> void:
	_scroll.ensure_control_visible(_hero)


func _style_claim() -> void:
	var active := StyleBoxFlat.new()
	active.bg_color = PALETTE.accent
	active.set_corner_radius_all(8)
	var claimed := active.duplicate() as StyleBoxFlat
	claimed.bg_color = PALETTE.panel
	claimed.border_color = PALETTE.accent.darkened(0.4)
	claimed.set_border_width_all(1)
	for key in ["normal", "hover", "pressed", "focus"]:
		_claim.add_theme_stylebox_override(key, active)
	_claim.add_theme_stylebox_override("disabled", claimed)
	_claim.add_theme_color_override("font_color", PALETTE.void_bg)
	_claim.add_theme_color_override("font_hover_color", PALETTE.void_bg)
	_claim.add_theme_color_override("font_pressed_color", PALETTE.void_bg)


## Binds a canonical Economy status without claiming it; returns whether shown.
func present(status: Dictionary, inspect: bool = false) -> bool:
	if state in [State.CLAIMING, State.CLAIMED, State.DISMISSING]:
		return visible
	_eligible = bool(status.get("claimable", false))
	if not _eligible and not inspect:
		visible = false
		state = State.HIDDEN
		return false
	current_day = clampi(int(status.get("new_streak", 1)), 1, Economy.LOGIN_REWARDS.size())
	selected_day = current_day
	completed_days = current_day - 1 if _eligible else current_day
	_title.text = tr("DAILY_REWARD_TITLE")
	_currency.text = tr("HUD_CURRENCY")
	_claim.text = tr("DAILY_REWARD_CLAIM_TODAY")
	_received.text = tr("DAILY_REWARD_RECEIVED")
	_close.text = tr("STORE_BACK")
	_close.disabled = false
	state = State.READY if _eligible else State.INSPECTING
	_update_selection()
	visible = true
	modulate.a = 0.0
	_box.scale = Vector2.ONE * 0.97
	_start_motion()
	_motion.set_parallel(true)
	_motion.tween_property(self, "modulate:a", 1.0, entrance_duration)
	_motion.tween_property(_box, "scale", Vector2.ONE, entrance_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion.chain().tween_callback(_focus_route)
	return true


## Read-only preview never changes canonical eligibility or the claim day.
func preview_day(day: int) -> void:
	if state not in [State.READY, State.INSPECTING] or day < 1 or day > Economy.LOGIN_REWARDS.size():
		return
	selected_day = day
	_update_selection()


func _update_selection() -> void:
	preview_spec = Economy.login_reward_spec(selected_day)
	reward_amount = int(preview_spec["coins"])
	_show_reward_spec(preview_spec)
	if selected_day == current_day:
		_day.text = tr("DAILY_REWARD_DAY") % current_day
	else:
		_day.text = tr("DAILY_REWARD_PREVIEW") % selected_day
	_claim.visible = _eligible
	_claim.disabled = not _claim.visible
	_received.visible = true
	_received.text = tr("DAILY_REWARD_RECEIVED") if selected_day <= completed_days else ""
	_route.bind(current_day, completed_days, selected_day, Economy.LOGIN_REWARDS)
	_queue_layout()
	_focus_route.call_deferred()


func _show_reward_spec(spec: Dictionary) -> void:
	_gift_icon.visible = bool(spec.get("supply_box", false))
	var coins: int = int(spec.get("coins", 0))
	var boost_ids: Array = spec.get("boost_ids", [])
	_coin.visible = coins > 0
	_amount.visible = coins > 0 or not boost_ids.is_empty() or bool(spec.get("supply_box", false))
	_currency.visible = _amount.visible
	_amount.text = "+%d" % coins if coins > 0 else "1×"
	_currency.text = tr("HUD_CURRENCY")
	_bonus_icon.visible = not boost_ids.is_empty()
	var names: PackedStringArray = []
	if not boost_ids.is_empty():
		var data: BoostData = ContentCatalog.boost_by_id(StringName(boost_ids[0]))
		if data != null:
			_bonus_icon.set("effect", BoostIcon.COIN_BONUS_ICON if StringName(boost_ids[0]) == &"coin_bonus" else data.effect)
			_bonus_icon.queue_redraw()
		for boost_id in boost_ids:
			var boost: BoostData = ContentCatalog.boost_by_id(StringName(boost_id))
			if boost != null:
				names.append(tr(boost.display_name_key))
	if not boost_ids.is_empty():
		_currency.text = ", ".join(names)
	if spec.get("supply_box", false):
		_gift_icon.visible = true
		if boost_ids.is_empty() and coins == 0:
			_currency.text = tr("SUPPLY_TITLE")


func _on_claim() -> void:
	if state != State.READY or not _eligible:
		return
	selected_day = current_day
	_update_selection()
	state = State.CLAIMING
	_focus_hero()
	_claim.disabled = true
	_close.disabled = true
	var claim_result: Variant = claim_action.call()
	var actual_coins: int = int(claim_result.get("coins", 0)) if claim_result is Dictionary else int(claim_result)
	var actual_boosts: Array = claim_result.get("boost_ids", []) if claim_result is Dictionary else []
	var actual_gift: bool = claim_result is Dictionary and bool(claim_result.get("supply_box", false))
	if actual_coins <= 0 and actual_boosts.is_empty() and not actual_gift:
		_dismiss.call_deferred()
		return
	reward_amount = actual_coins
	preview_spec = {"coins": actual_coins, "boost_ids": actual_boosts}
	if claim_result is Dictionary and claim_result.get("supply_box", false):
		preview_spec["supply_box"] = true
	_show_reward_spec(preview_spec)
	_active_reward_icon = _coin if _coin.visible else _bonus_icon if _bonus_icon.visible else _gift_icon
	_claim.text = "✓ " + tr("DAILY_REWARD_RECEIVED")
	_eligible = false
	completed_days = current_day
	_route.bind(current_day, completed_days, selected_day, Economy.LOGIN_REWARDS)
	state = State.CLAIMED
	modulate.a = 1.0
	_box.scale = Vector2.ONE
	reward_claimed.emit(actual_coins)
	_start_motion()
	_ring_progress = 0.0
	_motion.set_parallel(true)
	_motion.tween_property(self, "_ring_progress", 1.0, claim_pulse_duration)
	if _amount.visible:
		_motion.tween_property(_amount, "scale", Vector2.ONE * 1.08, claim_pulse_duration * 0.5)
	_motion.tween_property(_active_reward_icon, "scale", Vector2.ONE * pulse_scale, claim_pulse_duration * 0.5).set_trans(Tween.TRANS_SINE)
	_motion.chain().set_parallel(true)
	if _amount.visible:
		_motion.tween_property(_amount, "scale", Vector2.ONE, claim_pulse_duration * 0.5)
	_motion.tween_property(_active_reward_icon, "scale", Vector2.ONE, claim_pulse_duration * 0.5).set_trans(Tween.TRANS_SINE)
	_motion.chain().set_parallel(false)
	_motion.tween_interval(maxf(0.0, claimed_hold_duration - claim_pulse_duration))
	_motion.tween_callback(_dismiss)


## Dismisses inspection/available views without claiming; claim feedback owns its hold.
func close() -> void:
	if state in [State.READY, State.INSPECTING]:
		_dismiss()


func _draw() -> void:
	if _ring_progress < 1.0 and is_instance_valid(_active_reward_icon):
		var center: Vector2 = _active_reward_icon.global_position - global_position + _active_reward_icon.size * 0.5
		var color: Color = PALETTE.coin
		color.a = (1.0 - _ring_progress) * 0.5
		draw_arc(center, _active_reward_icon.size.x * (0.55 + 0.2 * _ring_progress), 0.0, TAU, 48, color, 2.0, true)


func _start_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = create_tween().set_ignore_time_scale(true)


func _dismiss() -> void:
	state = State.DISMISSING
	# Defer a new tween so we never kill the tween executing this callback.
	_finish_dismissal.call_deferred()


func _finish_dismissal() -> void:
	_start_motion()
	_motion.tween_property(self, "modulate:a", 0.0, dismissal_duration)
	_motion.tween_callback(func() -> void:
		visible = false
		state = State.HIDDEN
		dismissed.emit()
	)
