class_name AdsConfig
extends RefCounted

## Official Google Android identifiers. These are public test identifiers, not credentials.
const ANDROID_TEST_APP_ID: String = "ca-app-pub-3940256099942544~3347511713"
const ANDROID_TEST_REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"
const APP_ID_SETTING: String = "admob/general/android/app_id"
const TEST_MODE_SETTING: String = "monetization/ads/use_test_ads"
const PRODUCTION_SETTING: String = "monetization/ads/production_enabled"
const REWARDED_SETTING: String = "monetization/ads/android_rewarded_id"
const TEST_PUBLISHER: String = "3940256099942544"


## Test mode is explicit and independent of signing/debug flags.
static func rewarded_id() -> String:
	return resolve_rewarded_id(ProjectSettings.get_setting(TEST_MODE_SETTING, true),
		ProjectSettings.get_setting(PRODUCTION_SETTING, false),
		str(ProjectSettings.get_setting(APP_ID_SETTING, ANDROID_TEST_APP_ID)),
		str(ProjectSettings.get_setting(REWARDED_SETTING, "")))


## Resolves one boot-time configuration; malformed flags and disabled production fail closed.
static func resolve_rewarded_id(test_mode: Variant, enabled: Variant,
		app_id: String, unit_id: String) -> String:
	if not test_mode is bool:
		return ""
	if test_mode:
		return ANDROID_TEST_REWARDED_ID
	if not enabled is bool or not enabled or not production_ids_valid(app_id, unit_id):
		return ""
	return unit_id


## Checks syntax and publisher consistency only; ownership and rewarded format need AdMob review.
static func production_ids_valid(app_id: String, unit_id: String) -> bool:
	var app_pattern: RegEx = RegEx.new()
	app_pattern.compile("^ca-app-pub-([0-9]{16})~[0-9]{10}\\z")
	var unit_pattern: RegEx = RegEx.new()
	unit_pattern.compile("^ca-app-pub-([0-9]{16})/[0-9]{10}\\z")
	var app_match: RegExMatch = app_pattern.search(app_id)
	var unit_match: RegExMatch = unit_pattern.search(unit_id)
	if app_match == null or unit_match == null:
		return false
	var publisher: String = app_match.get_string(1)
	return publisher == unit_match.get_string(1) and publisher not in [TEST_PUBLISHER, "0".repeat(16)]
