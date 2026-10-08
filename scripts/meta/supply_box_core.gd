class_name SupplyBoxCore
extends RefCounted

## Economy-owned lifecycle. Acquisition policies belong to future trusted services.
## Underscored authorization is an internal trust seam, never a Store/UI entry point.
signal box_delivered(box_id: String, reward: Dictionary)

const RESERVED: String = "reserved"
const AUTHORIZED: String = "authorized"
const DELIVERED: String = "delivered"
const RNG_UNIT_SCALE: float = 4294967296.0  # uint32 range, maps rolls strictly below one.

var _profile: Callable
var _commit: Callable
var _rng: RandomNumberGenerator


## Economy supplies current-profile and checked atomic commit callbacks.
## Tests may inject a private seeded RNG; production never uses gameplay/global RNG.
func _init(profile: Callable, commit: Callable, rng: RandomNumberGenerator = null) -> void:
	_profile = profile
	_commit = commit
	_rng = rng
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()


## Freezes and saves the selected outcome. Existing IDs cannot reserve or reroll again.
## Caller supplies a stable unique ID and opaque acquisition context for later correlation.
func reserve(box_id: String, source: String, context: String, table: SupplyRewardTable) -> bool:
	var record: Dictionary = _prepare_reservation(box_id, source, context, table)
	if record.is_empty():
		return false
	var data: SaveData = _profile.call()
	var next: SaveData = SaveData.from_dict(data.to_dict())
	next.supply_boxes[box_id] = record
	return _commit.call(next)


## Internal staging seam for acquisition's single atomic charge/reservation save.
func _prepare_reservation(box_id: String, source: String, context: String, table: SupplyRewardTable) -> Dictionary:
	var data: SaveData = _profile.call()
	if box_id.strip_edges().is_empty() or source.strip_edges().is_empty() \
			or context.strip_edges().is_empty() or table == null or data.supply_boxes.has(box_id):
		return {}
	var reward: Dictionary = table.select_reward(float(_rng.randi()) / RNG_UNIT_SCALE)
	if reward.is_empty():
		return {}
	return {
		"box_id": box_id, "source": source, "context": context,
		"table_key": String(table.table_key), "table_version": table.version,
		"reward_type": reward["reward_type"], "amount": reward["amount"], "state": RESERVED,
	}


## Detached read-only record. Malformed records remain reserved identities but are unusable.
func box_status(box_id: String) -> Dictionary:
	var data: SaveData = _profile.call()
	var record: Variant = data.supply_boxes.get(box_id)
	return record.duplicate(true) if _valid_record(box_id, record) else {}


## Stable presentation queue; reading never grants or reselects a reward.
func unpresented_deliveries() -> Array[String]:
	var data: SaveData = _profile.call()
	var ids: Array[String] = []
	for id: Variant in data.supply_boxes:
		if not id is String:
			continue
		var record: Dictionary = box_status(id)
		if record.get("state") == DELIVERED and record.get("presented", false) != true:
			ids.append(id)
	ids.sort()
	return ids


## Acknowledges presentation only. Failed persistence leaves the result available after reload.
func mark_presented(box_id: String) -> bool:
	var record: Dictionary = box_status(box_id)
	if record.get("state") != DELIVERED:
		return false
	if record.get("presented", false) == true:
		return true
	var data: SaveData = _profile.call()
	var next: SaveData = SaveData.from_dict(data.to_dict())
	next.supply_boxes[box_id]["presented"] = true
	return _commit.call(next)


## INTERNAL: trusted acquisition service calls only after proving this exact source/context.
## No verification flag or public authorize API is offered to UI. Repeated proof is harmless.
func _authorize(box_id: String, source: String, context: String) -> bool:
	var record: Dictionary = box_status(box_id)
	if record.is_empty() or record["source"] != source or record["context"] != context:
		return false
	if record["state"] != RESERVED:
		return false
	var data: SaveData = _profile.call()
	var next: SaveData = SaveData.from_dict(data.to_dict())
	next.supply_boxes[box_id]["state"] = AUTHORIZED
	return _commit.call(next)


## Grants only AUTHORIZED boxes. Reward and marker commit together before success/signals.
## Duplicate, reserved, unknown or corrupt identities return false and grant nothing.
func deliver(box_id: String) -> bool:
	var record: Dictionary = box_status(box_id)
	if record.is_empty() or record["state"] != AUTHORIZED:
		return false
	var data: SaveData = _profile.call()
	var next: SaveData = SaveData.from_dict(data.to_dict())
	var type: StringName = StringName(record["reward_type"])
	var amount: int = int(record["amount"])
	if type == &"coins":
		next.earn(amount)
	else:
		next.add_boost(type, amount)
	next.supply_boxes[box_id]["state"] = DELIVERED
	if not _commit.call(next):
		return false
	box_delivered.emit(box_id, {"reward_type": String(type), "amount": amount})
	return true


## Deterministic recovery retries authorized records only, in sorted ID order.
func recover_authorized() -> Array[String]:
	var data: SaveData = _profile.call()
	var ids: Array[String] = []
	for id: Variant in data.supply_boxes:
		if id is String:
			ids.append(id)
	ids.sort()
	var completed: Array[String] = []
	for id: String in ids:
		if deliver(id):
			completed.append(id)
	return completed


func _valid_record(box_id: String, record: Variant) -> bool:
	if not record is Dictionary or box_id.strip_edges().is_empty():
		return false
	for key: String in ["box_id", "source", "context", "table_key", "state"]:
		if not record.get(key) is String or record[key].strip_edges().is_empty():
			return false
	var version: Variant = record.get("table_version")
	return record["box_id"] == box_id and record["state"] in [RESERVED, AUTHORIZED, DELIVERED] \
		and SupplyRewardEntry.valid_reward(&"coins", version) \
		and SupplyRewardEntry.valid_reward(record.get("reward_type"), record.get("amount"))
