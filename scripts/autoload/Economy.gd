extends Node

## Owns the persistent player profile (soft currency + unlocked content) and the
## runtime API around it. Loads on _ready, auto-saves on every mutation (small file,
## no data loss). No class_name (autoload singleton). Leaderboard is separate (Step 11).

const SaveStore = preload("res://scripts/meta/save_store.gd")
const LoginStreak = preload("res://scripts/meta/login_streak.gd")
const SAVE_PATH: String = "user://save.json"
const REWARDED_MISSION_BONUS_RATE: float = 0.50
## Approved day 1..7 awards; boost-only days intentionally grant no coins.
const LOGIN_REWARDS: Array[int] = [50, 75, 0, 180, 0, 225, 0]
const LOGIN_REWARD_BOOSTS: Array[Array] = [[], [], [&"slow_start"], [], [&"coin_bonus"], [], [&"extra_life"]]

signal currency_changed(new_balance: int)
signal unlocks_changed()
signal login_reward_claimed(day: int, amount: int)
signal boosts_changed()
signal campaign_changed()

var _data  # SaveData
var _pending_unlock: int = -1  # level index awaiting its map celebration (in-memory only)
var _save_path: String = SAVE_PATH
var _bonus_context_id: int = 0
var _bonus_base_payout: int = 0
var _bonus_epoch_day: int = -1
var _bonus_context_prepared: bool = false


func _ready() -> void:
	_data = SaveStore.load_from(_save_path)
	GameState.game_started.connect(_invalidate_rewarded_mission_bonus)


## Calculates the ad bonus from the pre-Coin-Bonus mission payout only.
static func rewarded_mission_bonus_amount(base_payout: int) -> int:
	return floori(maxi(base_payout, 0) * REWARDED_MISSION_BONUS_RATE)


## Records newly paid missions for the finished run once; zero payout clears eligibility.
func prepare_rewarded_mission_bonus(base_payout: int) -> void:
	if not _run_finished() or _bonus_context_prepared:
		return
	_bonus_context_prepared = true
	_bonus_base_payout = maxi(base_payout, 0)
	_bonus_epoch_day = SeedManager.today_epoch()


## Read-only eligibility and opaque context ID for the current finished run.
func rewarded_mission_bonus_status() -> Dictionary:
	var today: int = SeedManager.today_epoch()
	var amount: int = rewarded_mission_bonus_amount(_bonus_base_payout)
	var eligible: bool = _bonus_context_prepared and _run_finished() and _bonus_base_payout > 0 \
		and _bonus_epoch_day == today and _data.rewarded_mission_bonus_epoch_day < today
	return {"eligible": eligible, "amount": amount, "context_id": _bonus_context_id}


## Caller must supply verified rewarded completion for this exact context, never close/failure.
## Saves coins and day marker together before publishing success; failed writes grant nothing.
func claim_rewarded_mission_bonus(context_id: int, verified_completion: bool) -> bool:
	if not verified_completion or context_id != _bonus_context_id:
		return false
	var status: Dictionary = rewarded_mission_bonus_status()
	if not status["eligible"]:
		return false
	var next_data: SaveData = SaveData.from_dict(_data.to_dict())
	var amount: int = int(status["amount"])
	next_data.earn(amount)
	next_data.rewarded_mission_bonus_epoch_day = _bonus_epoch_day
	if not SaveStore.save_to(_save_path, next_data):
		return false
	_data = next_data
	currency_changed.emit(_data.currency)
	return true


func _run_finished() -> bool:
	return GameState.status == GameState.Status.WON or GameState.status == GameState.Status.GAME_OVER


func _invalidate_rewarded_mission_bonus() -> void:
	_bonus_context_id += 1
	_bonus_base_payout = 0
	_bonus_epoch_day = -1
	_bonus_context_prepared = false


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


# --- Boosts (consumables) ---

func boost_count(id: StringName) -> int:
	return _data.boost_count(id)


## Buys one charge of a boost if affordable: spends then adds the charge. Returns success.
func buy_boost(id: StringName, cost: int) -> bool:
	if not _data.spend(cost):
		return false
	_data.add_boost(id, 1)
	_flush()
	currency_changed.emit(_data.currency)
	boosts_changed.emit()
	return true


## Spends one charge (e.g. consumed at run start). Returns success.
func consume_boost(id: StringName) -> bool:
	if not _data.consume_boost(id):
		return false
	_flush()
	boosts_changed.emit()
	return true


func is_boost_armed(id: StringName) -> bool:
	return _data.is_boost_armed(id)


func set_boost_armed(id: StringName, armed: bool) -> void:
	_data.set_boost_armed(id, armed)
	_flush()
	boosts_changed.emit()


func armed_boosts() -> Array:
	return _data.armed_boosts.duplicate()


# --- Campaign progress ---

func campaign_star(id: StringName) -> int:
	return _data.campaign_star(id)


## Records a level result (keeps the best stars). Persists + signals only if it improved.
## A result that opens a NEW level arms the in-memory unlock marker for the level map's
## celebration (feel P1-11; not persisted — a lost celebration on app kill is harmless).
func record_campaign_result(id: StringName, stars: int) -> void:
	var unlocked: int = CampaignStars.newly_unlocked(ContentCatalog.LEVELS, _data.campaign_stars, id, stars)
	if _data.set_campaign_star(id, stars):
		if unlocked >= 0:
			_pending_unlock = unlocked
		_flush()
		campaign_changed.emit()


## Takes the pending unlock celebration: the newly opened level index, or -1. Clears it, so the
## map celebrates each unlock exactly once (on its first showing after the unlock).
func consume_pending_unlock() -> int:
	var index: int = _pending_unlock
	_pending_unlock = -1
	return index


## Whether the level at `index` is unlocked (previous level has >= 1 star; first is always open).
func is_level_unlocked(index: int) -> bool:
	return CampaignStars.is_unlocked(index, ContentCatalog.LEVELS, _data.campaign_stars)


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


## Whether the how-to-play has been shown once (first launch).
func tutorial_seen() -> bool:
	return _data.tutorial_seen


func mark_tutorial_seen() -> void:
	if _data.tutorial_seen:
		return
	_data.tutorial_seen = true
	_flush()


## { claimable, reward, new_streak } for today's login reward (for the menu popup).
func login_reward_status() -> Dictionary:
	var status: Dictionary = LoginStreak.evaluate(SeedManager.today_epoch(), _data.last_claim_epoch_day, _data.streak_day, LOGIN_REWARDS)
	var day: int = clampi(int(status["new_streak"]), 1, LOGIN_REWARDS.size())
	status["boost_ids"] = LOGIN_REWARD_BOOSTS[day - 1].duplicate()
	return status


## Returns a day's coin/boost award definition for read-only reward previews.
func login_reward_spec(day: int) -> Dictionary:
	var index: int = clampi(day, 1, LOGIN_REWARDS.size()) - 1
	return {"coins": LOGIN_REWARDS[index], "boost_ids": LOGIN_REWARD_BOOSTS[index].duplicate()}


## Claims today's login reward if claimable: earns + advances the streak + persists.
## Returns the coin portion (also zero for a successful boost-only claim).
func claim_login_reward() -> int:
	return int(claim_login_reward_bundle().get("coins", 0))


## Atomically applies a canonical day's coin/boost bundle and persists once.
func claim_login_reward_bundle() -> Dictionary:
	var today: int = SeedManager.today_epoch()
	var r: Dictionary = LoginStreak.evaluate(today, _data.last_claim_epoch_day, _data.streak_day, LOGIN_REWARDS)
	if not r["claimable"]:
		return {}
	var spec: Dictionary = login_reward_spec(int(r["new_streak"]))
	_apply_login_reward(_data, spec)
	_data.last_claim_epoch_day = today
	_data.streak_day = r["new_streak"]
	_flush()
	if int(spec["coins"]) > 0:
		currency_changed.emit(_data.currency)
	if not spec["boost_ids"].is_empty():
		boosts_changed.emit()
	login_reward_claimed.emit(r["new_streak"], spec["coins"])
	return spec


## Applies the approved award using existing currency and boost-charge fields.
func _apply_login_reward(data: SaveData, spec: Dictionary) -> void:
	data.earn(int(spec.get("coins", 0)))
	for boost_id in spec.get("boost_ids", []):
		data.add_boost(StringName(boost_id), 1)


func _flush() -> void:
	SaveStore.save_to(_save_path, _data)
