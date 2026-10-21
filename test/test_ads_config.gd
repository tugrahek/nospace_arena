extends GutTest

## Synthetic numeric fixtures exist only in tests; they are not publisher-supplied IDs.
var _app: String = "ca-app-pub-" + "1".repeat(16) + "~" + "2".repeat(10)
var _unit: String = "ca-app-pub-" + "1".repeat(16) + "/" + "3".repeat(10)


func test_repository_defaults_remain_test_ads_with_production_disabled() -> void:
	assert_true(ProjectSettings.get_setting(AdsConfig.TEST_MODE_SETTING))
	assert_false(ProjectSettings.get_setting(AdsConfig.PRODUCTION_SETTING))
	assert_eq(ProjectSettings.get_setting(AdsConfig.REWARDED_SETTING), "")
	assert_eq(AdsConfig.rewarded_id(), AdsConfig.ANDROID_TEST_REWARDED_ID)


func test_test_mode_never_selects_a_production_unit() -> void:
	assert_eq(AdsConfig.resolve_rewarded_id(true, true, _app, _unit), AdsConfig.ANDROID_TEST_REWARDED_ID)
	assert_eq(AdsConfig.resolve_rewarded_id(true, false, "", ""), AdsConfig.ANDROID_TEST_REWARDED_ID)


func test_production_requires_explicit_enable_and_a_complete_valid_pair() -> void:
	assert_eq(AdsConfig.resolve_rewarded_id(false, false, _app, _unit), "")
	assert_eq(AdsConfig.resolve_rewarded_id(false, true, "", _unit), "")
	assert_eq(AdsConfig.resolve_rewarded_id(false, true, _app, ""), "")
	assert_eq(AdsConfig.resolve_rewarded_id(false, true, _app, _unit), _unit)


func test_non_boolean_configuration_flags_fail_closed() -> void:
	for flag: Variant in [null, "false", "true", 0, 1]:
		assert_eq(AdsConfig.resolve_rewarded_id(flag, true, _app, _unit), "")
		assert_eq(AdsConfig.resolve_rewarded_id(false, flag, _app, _unit), "")


func test_malformed_mixed_publisher_and_test_identifiers_are_rejected() -> void:
	for invalid: String in ["", "placeholder", _app + "\n", " " + _app, _unit, _app.replace("1", "X")]:
		assert_false(AdsConfig.production_ids_valid(invalid, _unit), invalid)
	for invalid: String in ["", "placeholder", _unit + " ", _app, _unit.replace("1", "4")]:
		assert_false(AdsConfig.production_ids_valid(_app, invalid), invalid)
	assert_false(AdsConfig.production_ids_valid(AdsConfig.ANDROID_TEST_APP_ID, AdsConfig.ANDROID_TEST_REWARDED_ID))
	assert_false(AdsConfig.production_ids_valid(_app.replace("1", "0"), _unit.replace("1", "0")))
