extends Node

## Owns the persistent player profile (soft currency + unlocked content) and the
## runtime API around it. Loads on _ready, auto-saves on every mutation (small file,
## no data loss). No class_name (autoload singleton). Leaderboard is separate (Step 11).

const SaveStore = preload("res://scripts/meta/save_store.gd")
const LoginStreak = preload("res://scripts/meta/login_streak.gd")
const PurchaseProduct = preload("res://scripts/monetization/purchase_product.gd")
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
signal iap_entitlement_granted(product_id: StringName)
signal iap_transaction_delivered(transaction_id: String, product_id: StringName)

var _data  # SaveData
var _pending_unlock: int = -1  # level index awaiting its map celebration (in-memory only)
var _save_path: String = SAVE_PATH
var _bonus_context_id: int = 0
var _bonus_base_payout: int = 0
var _bonus_epoch_day: int = -1
var _bonus_context_prepared: bool = false
var _supply_boxes: SupplyBoxCore


## Shared core for trusted acquisition services; UI consumes read-only status/results.
func supply_boxes() -> SupplyBoxCore:
	if _supply_boxes == null:
		_supply_boxes = SupplyBoxCore.new(func() -> SaveData: return _data, _commit_supply_data)
	return _supply_boxes


## Checked supply commit publishes only a successfully persisted profile/reward mutation.
func _commit_supply_data(data: SaveData) -> bool:
	if not SaveStore.save_to(_save_path, data):
		return false
	var coins_changed: bool = data.currency != _data.currency
	var charges_changed: bool = data.boost_charges != _data.boost_charges
	_data = data
	if coins_changed:
		currency_changed.emit(_data.currency)
	if charges_changed:
		boosts_changed.emit()
	return true


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


## Persists a backend transaction as pending, then atomically marks it delivered with its entitlement.
## This internal entry point is called only by the trusted PurchaseService autoload.
func _deliver_purchase_transaction(transaction_id: String, product_id: StringName, kind: int) -> Dictionary:
	if transaction_id.strip_edges().is_empty() or product_id == &"":
		return {"durable": false, "pending": false, "duplicate": false}
	if kind not in [PurchaseProduct.Kind.CONSUMABLE, PurchaseProduct.Kind.NON_CONSUMABLE]:
		return {"durable": false, "pending": false, "duplicate": false}
	var kind_name: String = "non_consumable" if kind == PurchaseProduct.Kind.NON_CONSUMABLE else "consumable"
	var id: String = String(product_id)
	var existing: Variant = _data.iap_transactions.get(transaction_id)
	if existing != null:
		if existing.get("product_id", "") != id or existing.get("kind", "") != kind_name:
			return {"durable": false, "pending": false, "duplicate": false}
		if existing.get("status", "") == "delivered":
			return {"durable": true, "pending": false, "duplicate": true}
	else:
		var pending_data: SaveData = SaveData.from_dict(_data.to_dict())
		pending_data.iap_transactions[transaction_id] = {
			"product_id": id, "kind": kind_name, "status": "pending",
		}
		if not _persist_iap_data(pending_data):
			return {"durable": false, "pending": false, "duplicate": false}
		_data = pending_data
	return _complete_iap_delivery(transaction_id)


## Completes every persisted pending transaction in stable transaction-ID order.
func recover_pending_iap_deliveries() -> Array[String]:
	var pending_ids: Array[String] = []
	for transaction_id in _data.iap_transactions:
		if _data.iap_transactions[transaction_id].get("status", "") == "pending":
			pending_ids.append(String(transaction_id))
	pending_ids.sort()
	var completed: Array[String] = []
	for transaction_id in pending_ids:
		var result: Dictionary = _complete_iap_delivery(transaction_id)
		if result.get("durable", false):
			completed.append(transaction_id)
	return completed


## Read-only entitlement query for trusted game services.
func owns_iap_entitlement(product_id: StringName) -> bool:
	return _data.iap_entitlements.has(String(product_id))


## Read-only transaction state used by service recovery and tests.
func iap_transaction_status(transaction_id: String) -> StringName:
	return StringName(_data.iap_transactions.get(transaction_id, {}).get("status", ""))


func _complete_iap_delivery(transaction_id: String) -> Dictionary:
	var record: Dictionary = _data.iap_transactions.get(transaction_id, {})
	if record.is_empty() or record.get("status", "") != "pending":
		return {"durable": false, "pending": false, "duplicate": false}
	var next_data: SaveData = SaveData.from_dict(_data.to_dict())
	var next_record: Dictionary = next_data.iap_transactions[transaction_id].duplicate(true)
	var entitlement_added: bool = false
	if next_record["kind"] == "non_consumable" and not next_data.iap_entitlements.has(next_record["product_id"]):
		next_data.iap_entitlements.append(next_record["product_id"])
		entitlement_added = true
	next_record["status"] = "delivered"
	next_data.iap_transactions[transaction_id] = next_record
	if not _persist_iap_data(next_data):
		return {"durable": false, "pending": true, "duplicate": false}
	_data = next_data
	if entitlement_added:
		iap_entitlement_granted.emit(StringName(next_record["product_id"]))
	iap_transaction_delivered.emit(transaction_id, StringName(next_record["product_id"]))
	return {"durable": true, "pending": false, "duplicate": false}


## Isolated persistence seam; the canonical SaveStore path remains authoritative.
func _persist_iap_data(data: SaveData) -> bool:
	return SaveStore.save_to(_save_path, data)


func _flush() -> void:
	SaveStore.save_to(_save_path, _data)
