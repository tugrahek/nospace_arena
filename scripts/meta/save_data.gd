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


func to_dict() -> Dictionary:
	return {
		"currency": currency,
		"unlocked": unlocked.duplicate(true),
		"selected_character": selected_character_id,
		"selected_arena": selected_arena_id,
		"last_claim_epoch_day": last_claim_epoch_day,
		"streak_day": streak_day,
		"tutorial_seen": tutorial_seen,
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
	return data
