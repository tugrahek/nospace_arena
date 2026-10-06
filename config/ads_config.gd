class_name AdsConfig
extends RefCounted

## Official Google Android rewarded test unit. Production remains unconfigured.
const ANDROID_TEST_REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"


## Test mode is explicit and independent of signing/debug flags.
static func rewarded_id() -> String:
	if ProjectSettings.get_setting("monetization/ads/use_test_ads", true):
		return ANDROID_TEST_REWARDED_ID
	return str(ProjectSettings.get_setting("monetization/ads/android_rewarded_id", ""))
