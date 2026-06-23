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
var streak_day: int = 0  # 1..7 login streak
var tutorial_seen: bool = false  # how-to-play shown once (first launch)
var boost_charges: Dictionary = {}  # boost id:String -> owned count:int (consumables)
var armed_boosts: Array = []  # boost ids:String armed for the next run


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
	return true


func is_boost_armed(id: StringName) -> bool:
	return armed_boosts.has(String(id))


## Arms / disarms a boost for the next run (idempotent).
func set_boost_armed(id: StringName, armed: bool) -> void:
	var s: String = String(id)
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
		"tutorial_seen": tutorial_seen,
		"boost_charges": boost_charges.duplicate(true),
		"armed_boosts": armed_boosts.duplicate(),
	}


static func from_dict(d: Dictionary) -> SaveData:
	var data := SaveData.new()
	data.currency = int(d.get("currency", 0))
	data.selected_character_id = String(d.get("selected_character", "pulse"))
	data.selected_arena_id = String(d.get("selected_arena", "void"))
	data.last_claim_epoch_day = int(d.get("last_claim_epoch_day", -1))
	data.streak_day = int(d.get("streak_day", 0))
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
			data.armed_boosts.append(String(id))
	return data
