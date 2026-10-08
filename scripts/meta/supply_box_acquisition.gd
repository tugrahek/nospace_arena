class_name SupplyBoxAcquisition
extends Node

## Economy-owned acquisition coordinator. Only AdsService's correlated reward signal proves ads.
const CONFIG: SupplyAcquisitionConfig = preload("res://config/supply_box.tres")
const REWARDED_SOURCE: String = "daily_rewarded"
const COIN_SOURCE: String = "coin"

var _profile: Callable
var _commit: Callable
var _core: SupplyBoxCore
var _ads: Node
var _today: Callable
var _config: SupplyAcquisitionConfig
var _active: Dictionary = {}
var _verified: Dictionary = {}
var _busy: bool = false


## Dependencies are injected for isolated tests; production uses canonical SeedManager day.
func _init(profile: Callable, commit: Callable, core: SupplyBoxCore, ads: Node,
		day: Callable, config: SupplyAcquisitionConfig = CONFIG) -> void:
	_profile = profile
	_commit = commit
	_core = core
	_ads = ads
	_today = day
	_config = config


func _ready() -> void:
	# Deferred callbacks also handle backends that complete synchronously during show().
	_ads.reward_earned.connect(_on_reward, CONNECT_DEFERRED)
	_ads.ad_closed.connect(_on_close, CONNECT_DEFERRED)
	_ads.ad_failed.connect(_on_failure, CONNECT_DEFERRED)
	recover()


## Read-only canonical day/cost/usage context. Corrupt counters fail closed.
func status() -> Dictionary:
	var day: int = _today.call()
	var counters: Dictionary = _counters(_profile.call(), day)
	return {"day": day, "coin_cost": _config.coin_cost,
		"coin_count": counters.get("coin_count", _config.coin_daily_limit),
		"rewarded_count": counters.get("rewarded_count", _config.rewarded_daily_limit),
		"coin_limit": _config.coin_daily_limit, "rewarded_limit": _config.rewarded_daily_limit}


## Atomically accepts charge, daily counter and frozen AUTHORIZED box; delivery is retryable.
## A stable request ID is required; duplicates never charge or create another box.
func purchase_coin_box(request_id: String, day_context: int) -> Dictionary:
	if _busy or not _config.is_valid() or day_context != int(_today.call()) \
			or request_id.strip_edges().is_empty():
		return {"accepted": false}
	var data: SaveData = _profile.call()
	var counters: Dictionary = _counters(data, day_context)
	if counters.is_empty() or counters["coin_count"] >= _config.coin_daily_limit \
			or not data.can_afford(_config.coin_cost):
		return {"accepted": false}
	# Ready daily rewarded acquisition takes priority; unavailability never consumes a coin right.
	if not _coin_priority_allows(counters):
		return {"accepted": false}
	var id: String = "supply/coin/" + request_id
	var record: Dictionary = _core._prepare_reservation(id, COIN_SOURCE, request_id, _config.reward_table)
	if record.is_empty():
		return {"accepted": false}
	_busy = true
	var next: SaveData = SaveData.from_dict(data.to_dict())
	next.spend(_config.coin_cost)
	counters["coin_count"] += 1
	next.supply_acquisition_days[str(day_context)] = counters
	record["state"] = SupplyBoxCore.AUTHORIZED
	record["acquisition_day"] = day_context
	next.supply_boxes[id] = record
	var accepted: bool = _commit.call(next)
	var delivered: bool = accepted and _core.deliver(id)
	_busy = false
	return {"accepted": accepted, "delivered": delivered, "box_id": id if accepted else ""}


## Canonical coin availability, including rewarded-first priority; no mutation.
func coin_available() -> bool:
	var data: SaveData = _profile.call()
	var counters: Dictionary = _counters(data, int(_today.call()))
	return _config.is_valid() and not counters.is_empty() and _coin_priority_allows(counters) \
		and counters["coin_count"] < _config.coin_daily_limit and data.can_afford(_config.coin_cost)


func _coin_priority_allows(counters: Dictionary) -> bool:
	return _active.is_empty() and (counters["rewarded_count"] >= _config.rewarded_daily_limit \
		or not _ads.is_rewarded_available())


## Reserves before presenting an ad; failures/close reuse this exact daily slot and reward.
func show_daily_rewarded(day_context: int) -> int:
	if _busy or not _active.is_empty() or not _config.is_valid() \
			or day_context != int(_today.call()):
		return 0
	recover()
	if not _verified.is_empty():
		return 0
	var counters: Dictionary = _counters(_profile.call(), day_context)
	if counters.is_empty() or counters["rewarded_count"] >= _config.rewarded_daily_limit:
		return 0
	var id: String = "supply/rewarded/%d/%d" % [day_context, counters["rewarded_count"]]
	var record: Dictionary = _core.box_status(id)
	if record.is_empty() and not _reserve_daily(id, day_context):
		return 0
	record = _core.box_status(id)
	if record.get("state") != SupplyBoxCore.RESERVED:
		return 0
	_active = {"box_id": id, "day": day_context, "token": 0, "rewarded": false}
	var token: int = _ads.show_rewarded(id)
	if token == 0:
		_active.clear()
	else:
		_active["token"] = token
	return token


## Retries proof held in memory and all durable authorized deliveries, never reserved boxes.
func recover() -> Array[String]:
	if not _verified.is_empty():
		var id: String = _verified["box_id"]
		if _core._authorize(id, REWARDED_SOURCE, id) \
				or _core.box_status(id).get("state") in [SupplyBoxCore.AUTHORIZED, SupplyBoxCore.DELIVERED]:
			_verified.clear()
	return _core.recover_authorized()


func _reserve_daily(id: String, day: int) -> bool:
	var record: Dictionary = _core._prepare_reservation(id, REWARDED_SOURCE, id, _config.reward_table)
	if record.is_empty():
		return false
	var next: SaveData = SaveData.from_dict((_profile.call() as SaveData).to_dict())
	record["acquisition_day"] = day
	next.supply_boxes[id] = record
	return _commit.call(next)


func _on_reward(context: String, token: int) -> void:
	if _active.is_empty() or token <= 0 or token != _active["token"] \
			or context != _active["box_id"] or _active["rewarded"]:
		return
	_active["rewarded"] = true
	_verified = {"box_id": context}
	recover()


func _on_close(context: String, token: int) -> void:
	if not _active.is_empty() and context == _active["box_id"] and token == _active["token"]:
		_active.clear()


func _on_failure(context: String, token: int, _reason: StringName) -> void:
	_on_close(context, token)


## Internal atomic commit hook: count rewarded success in the SAME save as reward/DELIVERED.
static func mark_deliveries(previous: SaveData, next: SaveData) -> bool:
	for id: Variant in next.supply_boxes:
		var record: Variant = next.supply_boxes[id]
		if not record is Dictionary or record.get("source") != REWARDED_SOURCE \
				or record.get("state") != SupplyBoxCore.DELIVERED:
			continue
		var old: Variant = previous.supply_boxes.get(id)
		if old is Dictionary and old.get("state") == SupplyBoxCore.DELIVERED:
			continue
		var day: Variant = record.get("acquisition_day")
		if not (day is int or day is float) or not is_finite(float(day)) or float(day) != floor(float(day)):
			return false
		var counters: Dictionary = _counters(next, int(day))
		if counters.is_empty():
			return false
		counters["rewarded_count"] += 1
		next.supply_acquisition_days[str(int(day))] = counters
	return true


static func _counters(data: SaveData, day: int) -> Dictionary:
	var record: Variant = data.supply_acquisition_days.get(str(day), {"coin_count": 0, "rewarded_count": 0})
	if not record is Dictionary:
		return {}
	for key: String in ["coin_count", "rewarded_count"]:
		var count: Variant = record.get(key)
		if not (count is int or count is float) or not is_finite(float(count)) \
				or float(count) < 0 or float(count) != floor(float(count)) or float(count) > SupplyRewardEntry.MAX_AMOUNT:
			return {}
	return {"coin_count": int(record["coin_count"]), "rewarded_count": int(record["rewarded_count"])}
