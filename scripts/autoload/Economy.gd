extends Node

## Owns the persistent player profile (soft currency + unlocked content) and the
## runtime API around it. Loads on _ready, auto-saves on every mutation (small file,
## no data loss). No class_name (autoload singleton). Leaderboard is separate (Step 11).

const SaveStore = preload("res://scripts/meta/save_store.gd")
const LoginStreak = preload("res://scripts/meta/login_streak.gd")
const SAVE_PATH: String = "user://save.json"
const LOGIN_REWARDS: Array[int] = [50, 75, 100, 125, 150, 200, 300]  # day 1..7 (first-pass)

signal currency_changed(new_balance: int)
signal unlocks_changed()
signal login_reward_claimed(day: int, amount: int)

var _data  # SaveData


func _ready() -> void:
	_data = SaveStore.load_from(SAVE_PATH)


func balance() -> int:
	return _data.currency


func earn(amount: int) -> void:
	_data.earn(amount)
	_flush()
	currency_changed.emit(_data.currency)


## Spends if affordable; returns success. Balance never goes negative.
func spend(amount: int) -> bool:
	if not _data.spend(amount):
		return false
	_flush()
	currency_changed.emit(_data.currency)
	return true


func can_afford(amount: int) -> bool:
	return _data.can_afford(amount)


func is_unlocked(kind: String, id: StringName) -> bool:
	return _data.is_unlocked(kind, id)


func unlock(kind: String, id: StringName) -> void:
	if _data.is_unlocked(kind, id):
		return
	_data.unlock(kind, id)
	_flush()
	unlocks_changed.emit()


## Buys a locked item if affordable: spends then unlocks. Returns success.
func purchase(kind: String, id: StringName, cost: int) -> bool:
	if _data.is_unlocked(kind, id):
		return false
	if not _data.spend(cost):
		return false
	_data.unlock(kind, id)
	_flush()
	currency_changed.emit(_data.currency)
	unlocks_changed.emit()
	return true


func selected_character() -> StringName:
	return StringName(_data.selected_character_id)


func selected_arena() -> StringName:
	return StringName(_data.selected_arena_id)


func set_selected_character(id: StringName) -> void:
	_data.selected_character_id = String(id)
	_flush()


func set_selected_arena(id: StringName) -> void:
	_data.selected_arena_id = String(id)
	_flush()


## { claimable, reward, new_streak } for today's login reward (for the menu popup).
func login_reward_status() -> Dictionary:
	return LoginStreak.evaluate(SeedManager.today_epoch(), _data.last_claim_epoch_day, _data.streak_day, LOGIN_REWARDS)


## Claims today's login reward if claimable: earns + advances the streak + persists.
## Idempotent — a second call the same day returns 0 (already claimed). Returns the amount.
func claim_login_reward() -> int:
	var today: int = SeedManager.today_epoch()
	var r: Dictionary = LoginStreak.evaluate(today, _data.last_claim_epoch_day, _data.streak_day, LOGIN_REWARDS)
	if not r["claimable"]:
		return 0
	_data.earn(r["reward"])
	_data.last_claim_epoch_day = today
	_data.streak_day = r["new_streak"]
	_flush()
	currency_changed.emit(_data.currency)
	login_reward_claimed.emit(r["new_streak"], r["reward"])
	return r["reward"]


func _flush() -> void:
	SaveStore.save_to(SAVE_PATH, _data)
