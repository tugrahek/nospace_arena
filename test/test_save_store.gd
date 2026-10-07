extends GutTest

## Interrupted saves are represented by actual files at each replacement boundary.
const Store = preload("res://scripts/meta/save_store.gd")
const Profile = preload("res://scripts/meta/save_data.gd")
const PATH: String = "user://23f0_save_store_fixture.json"


func before_each() -> void:
	_cleanup()


func after_each() -> void:
	_cleanup()


func _cleanup() -> void:
	for suffix: String in ["", Store.TEMP_SUFFIX, Store.BACKUP_SUFFIX]:
		var absolute_path: String = ProjectSettings.globalize_path(PATH + suffix)
		if FileAccess.file_exists(absolute_path) or DirAccess.dir_exists_absolute(absolute_path):
			assert_eq(DirAccess.remove_absolute(absolute_path), OK)


func _profile(coins: int) -> Profile:
	var data: Profile = Profile.new_default()
	data.currency = coins
	return data


func _write(path: String, text: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(f)
	if f == null:
		return
	f.store_string(text)
	f.flush()
	assert_eq(f.get_error(), OK)
	f.close()


func _candidate(suffix: String, coins: int) -> void:
	_write(PATH + suffix, JSON.stringify(_profile(coins).to_dict()))


func test_normal_save_load_and_previous_good_backup() -> void:
	assert_true(Store.save_to(PATH, _profile(100)))
	assert_eq(Store.load_from(PATH).currency, 100)
	assert_true(Store.save_to(PATH, _profile(200)))
	assert_eq(Store.load_from(PATH).currency, 200)
	assert_eq(Store.load_from(PATH + Store.BACKUP_SUFFIX).currency, 100)
	assert_false(FileAccess.file_exists(PATH + Store.TEMP_SUFFIX))


func test_interrupted_temp_write_leaves_canonical_intact() -> void:
	assert_true(Store.save_to(PATH, _profile(100)))
	_write(PATH + Store.TEMP_SUFFIX, '{"currency": 200,')
	assert_eq(Store.load_from(PATH).currency, 100)
	assert_eq(JSON.parse_string(FileAccess.get_file_as_string(PATH))["currency"], 100.0)


func test_interrupted_replacement_recovers_previous_profile_before_new_temp() -> void:
	assert_true(Store.save_to(PATH, _profile(100)))
	_candidate(Store.TEMP_SUFFIX, 200)
	assert_eq(DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH),
		ProjectSettings.globalize_path(PATH + Store.BACKUP_SUFFIX)), OK)
	assert_false(FileAccess.file_exists(PATH))
	assert_eq(Store.load_from(PATH).currency, 100)
	assert_true(FileAccess.file_exists(PATH))
	assert_eq(Store.load_from(PATH).currency, 100)


func test_corrupt_canonical_with_backup_is_restored() -> void:
	assert_true(Store.save_to(PATH, _profile(100)))
	assert_true(Store.save_to(PATH, _profile(200)))
	_write(PATH, '{"currency":')
	assert_eq(Store.load_from(PATH).currency, 100)
	assert_eq(JSON.parse_string(FileAccess.get_file_as_string(PATH))["currency"], 100.0)


func test_valid_canonical_wins_over_stale_valid_temp_and_backup() -> void:
	_candidate("", 100)
	_candidate(Store.TEMP_SUFFIX, 200)
	_candidate(Store.BACKUP_SUFFIX, 50)
	assert_eq(Store.load_from(PATH).currency, 100)
	assert_eq(Store.load_from(PATH).currency, 100)


func test_completed_replacement_wins_over_previous_backup() -> void:
	_candidate(Store.BACKUP_SUFFIX, 100)
	_candidate(Store.TEMP_SUFFIX, 200)
	assert_eq(DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH + Store.TEMP_SUFFIX),
		ProjectSettings.globalize_path(PATH)), OK)
	assert_eq(Store.load_from(PATH).currency, 200)


func test_valid_temp_recovers_when_canonical_missing_and_backup_invalid() -> void:
	_write(PATH + Store.BACKUP_SUFFIX, "[]")
	_candidate(Store.TEMP_SUFFIX, 200)
	assert_eq(Store.load_from(PATH).currency, 200)
	assert_true(FileAccess.file_exists(PATH))
	assert_false(FileAccess.file_exists(PATH + Store.TEMP_SUFFIX))


func test_corrupt_temp_is_ignored_when_no_valid_profile_exists() -> void:
	_write(PATH + Store.TEMP_SUFFIX, '{"currency": 200,')
	var loaded: Profile = Store.load_from(PATH)
	assert_eq(loaded.currency, 0)
	assert_true(loaded.is_unlocked("character", &"pulse"))
	assert_false(FileAccess.file_exists(PATH))


func test_corrupt_canonical_recovers_valid_temp_without_backup() -> void:
	_write(PATH, "not json")
	_candidate(Store.TEMP_SUFFIX, 200)
	assert_eq(Store.load_from(PATH).currency, 200)
	assert_eq(Store.load_from(PATH).currency, 200)


func test_old_profile_still_loads_with_default_iap_state() -> void:
	_write(PATH, '{"currency": 37, "selected_character": "drag"}')
	var loaded: Profile = Store.load_from(PATH)
	assert_eq(loaded.currency, 37)
	assert_eq(loaded.selected_character_id, "drag")
	assert_true(loaded.iap_transactions.is_empty())
	assert_true(loaded.iap_entitlements.is_empty())


func test_temp_open_failure_is_observable_and_keeps_canonical() -> void:
	assert_true(Store.save_to(PATH, _profile(100)))
	assert_eq(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(PATH + Store.TEMP_SUFFIX)), OK)
	assert_false(Store.save_to(PATH, _profile(200)))
	assert_eq(Store.load_from(PATH).currency, 100)


func test_backup_rotation_failure_keeps_canonical_and_allows_retry() -> void:
	assert_true(Store.save_to(PATH, _profile(100)))
	var backup_path: String = ProjectSettings.globalize_path(PATH + Store.BACKUP_SUFFIX)
	assert_eq(DirAccess.make_dir_absolute(backup_path), OK)
	assert_false(Store.save_to(PATH, _profile(200)))
	assert_eq(Store.load_from(PATH).currency, 100)
	assert_eq(DirAccess.remove_absolute(backup_path), OK)
	assert_true(Store.save_to(PATH, _profile(200)))
	assert_eq(Store.load_from(PATH).currency, 200)


func test_save_recovers_only_good_temp_before_overwriting_it() -> void:
	_candidate(Store.TEMP_SUFFIX, 100)
	assert_true(Store.save_to(PATH, _profile(200)))
	assert_eq(Store.load_from(PATH).currency, 200)
	assert_eq(Store.load_from(PATH + Store.BACKUP_SUFFIX).currency, 100)


func test_recovery_cannot_overwrite_directory_and_save_reports_failure() -> void:
	_candidate(Store.TEMP_SUFFIX, 100)
	assert_eq(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(PATH)), OK)
	assert_eq(Store.load_from(PATH).currency, 100, "valid candidate remains readable even if promotion is blocked")
	assert_false(Store.save_to(PATH, _profile(200)))
	assert_eq(Store.load_from(PATH + Store.TEMP_SUFFIX).currency, 100)
