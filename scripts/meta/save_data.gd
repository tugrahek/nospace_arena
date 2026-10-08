class_name SaveData
extends RefCounted

## Persistent player profile: soft currency + unlocked content. Pure logic +
## serialization (no IO, no RNG) — GUT-testable. Negative balance is impossible;
## earn ignores negatives; unlock is idempotent. SaveStore handles the file.

var currency: int = 0
var unlocked: Dictionary = {}  # kind:String -> Array[String] of ids
var selected_character_id: String = "pulse"  # persisted loadout (free-play)
var selected_arena_id: String = "void"
var last_claim_epoch_day: int = -1  # daily login reward; -1 = never claimed
var streak_day: int = 0  # 1..10 login reward cycle
var rewarded_mission_bonus_epoch_day: int = -1  # -1 = never claimed
var tutorial_seen: bool = false  # how-to-play shown once (first launch)
var boost_charges: Dictionary = {}  # boost id:String -> owned count:int (consumables)
var armed_boosts: Array = []  # boost ids:String armed for the next run
var campaign_stars: Dictionary = {}  # campaign level id:String -> best stars:int (0-3)
var iap_transactions: Dictionary = {}  # transaction id -> {product_id, kind, status}
var iap_entitlements: Array = []  # owned non-consumable product ids:String
var supply_boxes: Dictionary = {}  # box id -> frozen reward, acquisition context and lifecycle
var supply_acquisition_days: Dictionary = {}  # epoch day -> durable acquisition counters


## Fresh profile: no currency, default content unlocked + selected (free baseline).
static func new_default() -> SaveData:
	var d := SaveData.new()
	d.unlock("character", &"pulse")
	d.unlock("arena", &"void")
	return d


## Adds currency. Negative amounts are ignored (never reduce via earn).
func earn(amount: int) -> void:
	currency += maxi(amount, 0)


## Spends if affordable and non-negative; balance never goes below 0. Returns success.
func spend(amount: int) -> bool:
	if amount < 0 or amount > currency:
		return false
	currency -= amount
	return true


func can_afford(amount: int) -> bool:
	return amount >= 0 and amount <= currency


func is_unlocked(kind: String, id: StringName) -> bool:
	return unlocked.has(kind) and unlocked[kind].has(String(id))


## Idempotent unlock (no duplicates).
func unlock(kind: String, id: StringName) -> void:
	if not unlocked.has(kind):
		unlocked[kind] = []
	var s := String(id)
	if not unlocked[kind].has(s):
		unlocked[kind].append(s)


## Owned charges of a boost (0 if none).
func boost_count(id: StringName) -> int:
	return int(boost_charges.get(String(id), 0))


## Adds `n` charges of a boost (negatives ignored).
func add_boost(id: StringName, n: int = 1) -> void:
	boost_charges[String(id)] = boost_count(id) + maxi(n, 0)


## Spends one charge if available; returns success.
func consume_boost(id: StringName) -> bool:
	var c: int = boost_count(id)
	if c <= 0:
		return false
	boost_charges[String(id)] = c - 1
	if c == 1:
		set_boost_armed(id, false)
	return true


## Best stars earned on a campaign level (0 if never cleared).
func campaign_star(id: StringName) -> int:
	return int(campaign_stars.get(String(id), 0))


## Records a level result, keeping the best (highest) star count. Returns true if it improved.
func set_campaign_star(id: StringName, stars: int) -> bool:
	var s: int = clampi(stars, 0, 3)
	if s <= campaign_star(id):
		return false
	campaign_stars[String(id)] = s
	return true


func is_boost_armed(id: StringName) -> bool:
	return boost_count(id) > 0 and armed_boosts.has(String(id))


## Arms / disarms a boost for the next run (idempotent).
func set_boost_armed(id: StringName, armed: bool) -> void:
	var s: String = String(id)
	armed = armed and boost_count(id) > 0
	if armed and not armed_boosts.has(s):
		armed_boosts.append(s)
	elif not armed and armed_boosts.has(s):
		armed_boosts.erase(s)


func to_dict() -> Dictionary:
	return {
		"currency": currency,
		"unlocked": unlocked.duplicate(true),
		"selected_character": selected_character_id,
		"selected_arena": selected_arena_id,
		"last_claim_epoch_day": last_claim_epoch_day,
		"streak_day": streak_day,
		"rewarded_mission_bonus_epoch_day": rewarded_mission_bonus_epoch_day,
		"tutorial_seen": tutorial_seen,
		"boost_charges": boost_charges.duplicate(true),
		"armed_boosts": armed_boosts.duplicate(),
		"campaign_stars": campaign_stars.duplicate(true),
		"iap_transactions": iap_transactions.duplicate(true),
		"iap_entitlements": iap_entitlements.duplicate(),
		"supply_boxes": supply_boxes.duplicate(true),
		"supply_acquisition_days": supply_acquisition_days.duplicate(true),
	}


static func from_dict(d: Dictionary) -> SaveData:
	var data := SaveData.new()
	data.currency = int(d.get("currency", 0))
	data.selected_character_id = String(d.get("selected_character", "pulse"))
	data.selected_arena_id = String(d.get("selected_arena", "void"))
	data.last_claim_epoch_day = int(d.get("last_claim_epoch_day", -1))
	data.streak_day = int(d.get("streak_day", 0))
	data.rewarded_mission_bonus_epoch_day = int(d.get("rewarded_mission_bonus_epoch_day", -1))
	data.tutorial_seen = bool(d.get("tutorial_seen", false))
	var u: Variant = d.get("unlocked", {})
	if typeof(u) == TYPE_DICTIONARY:
		for kind in u:
			data.unlocked[kind] = []
			for id in u[kind]:
				data.unlocked[kind].append(String(id))
	var bc: Variant = d.get("boost_charges", {})
	if typeof(bc) == TYPE_DICTIONARY:
		for id in bc:
			data.boost_charges[String(id)] = int(bc[id])
	var ab: Variant = d.get("armed_boosts", [])
	if typeof(ab) == TYPE_ARRAY:
		for id in ab:
			if data.boost_count(StringName(id)) > 0 and not data.armed_boosts.has(String(id)):
				data.armed_boosts.append(String(id))
	var cs: Variant = d.get("campaign_stars", {})
	if typeof(cs) == TYPE_DICTIONARY:
		for id in cs:
			data.campaign_stars[String(id)] = int(cs[id])
	var transactions: Variant = d.get("iap_transactions", {})
	if typeof(transactions) == TYPE_DICTIONARY:
		for transaction_id in transactions:
			var record: Variant = transactions[transaction_id]
			if typeof(record) != TYPE_DICTIONARY or String(transaction_id).is_empty():
				continue
			var product_id: String = String(record.get("product_id", ""))
			var kind: String = String(record.get("kind", ""))
			var status: String = String(record.get("status", ""))
			if product_id.is_empty() or kind not in ["consumable", "non_consumable"] \
					or status not in ["pending", "delivered"]:
				continue
			data.iap_transactions[String(transaction_id)] = {
				"product_id": product_id, "kind": kind, "status": status,
			}
	var entitlements: Variant = d.get("iap_entitlements", [])
	if typeof(entitlements) == TYPE_ARRAY:
		for product_id in entitlements:
			var id: String = String(product_id)
			if not id.is_empty() and not data.iap_entitlements.has(id):
				data.iap_entitlements.append(id)
	var boxes: Variant = d.get("supply_boxes", {})
	if boxes is Dictionary:
		# Retain even invalid records: never free an existing identity for a reroll.
		data.supply_boxes = boxes.duplicate(true)
	var days: Variant = d.get("supply_acquisition_days", {})
	if days is Dictionary:
		data.supply_acquisition_days = days.duplicate(true)
	return data
