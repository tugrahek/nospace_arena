class_name SupplyAcquisitionFixture
extends GutTest

const EconomyScript = preload("res://scripts/autoload/Economy.gd")
const AdsScript = preload("res://scripts/monetization/ads_service.gd")
const PATH: String = "user://23f2_acquisition_fixture.json"

class WriteProbeEconomy:
	extends "res://scripts/autoload/Economy.gd"
	var writes: int = 0
	var fail_at: int = -1
	var attempted: Array[Dictionary] = []
	func _commit_supply_data(data: SaveData) -> bool:
		writes += 1
		attempted.append(data.to_dict())
		return false if writes == fail_at else super._commit_supply_data(data)

class ImmediateAds:
	extends FakeAdsBackend
	func show_rewarded(token: int) -> void:
		super.show_rewarded(token)
		earn_reward(token)
		close(token)

var _economy: WriteProbeEconomy
var _ads: AdsScript
var _fake: FakeAdsBackend
var _acquisition: SupplyBoxAcquisition
var _day: Array[int] = [12000]
var _config: SupplyAcquisitionConfig
var _original_status: int


func before_each() -> void:
	_cleanup()
	_day[0] = 12000
	_original_status = GameState.status
	_economy = WriteProbeEconomy.new()
	_economy._save_path = PATH
	add_child_autofree(_economy)
	_economy._data.currency = 500
	assert_true(SaveStore.save_to(PATH, _economy._data))
	_config = SupplyBoxAcquisition.CONFIG.duplicate(true)
	var table := SupplyRewardTable.new()
	table.table_key = &"acquisition_fixture"
	var entry := SupplyRewardEntry.new()
	entry.reward_type = &"slow_start"
	entry.amount = 1
	entry.weight = 1
	table.entries.append(entry)
	_config.reward_table = table
	_make_ads(FakeAdsBackend.new())
	_acquisition = _make_acquisition(_economy)


func after_each() -> void:
	GameState.status = _original_status
	_cleanup()


func _cleanup() -> void:
	for suffix: String in ["", SaveStore.TEMP_SUFFIX, SaveStore.BACKUP_SUFFIX]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))


func _make_ads(fake: FakeAdsBackend) -> void:
	_fake = fake
	_ads = AdsScript.new()
	assert_true(_ads.configure_backend(fake))
	_ads.set_requests_allowed(true)
	add_child_autofree(_ads)
	_fake.complete_initialization(_fake.initialization_tokens.back())
	_load()


func _load() -> void:
	assert_true(_ads.preload_rewarded())
	_fake.complete_load(_fake.load_tokens.back())


func _make_acquisition(economy: EconomyScript) -> SupplyBoxAcquisition:
	var node := SupplyBoxAcquisition.new(func() -> SaveData: return economy._data,
		economy._commit_supply_data, economy.supply_boxes(), _ads, func() -> int: return _day[0], _config)
	add_child_autofree(node)
	return node


func _box_id(day: int = 12000) -> String:
	return "supply/rewarded/%d/0" % day
