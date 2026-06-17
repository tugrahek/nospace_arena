extends Node

## Owns the persistent player profile (soft currency + unlocked content) and the
## runtime API around it. Loads on _ready, auto-saves on every mutation (small file,
## no data loss). No class_name (autoload singleton). Leaderboard is separate (Step 11).

const SaveStore = preload("res://scripts/meta/save_store.gd")
const SAVE_PATH: String = "user://save.json"

signal currency_changed(new_balance: int)
signal unlocks_changed()

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


func _flush() -> void:
	SaveStore.save_to(SAVE_PATH, _data)
