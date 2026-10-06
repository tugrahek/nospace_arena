class_name PoingAdsBridge
extends RefCounted

## The only project class that knows Poing v5.1.0 types. Editor mocks are never enabled.
## Requires the actual Android SDK, not the plugin's desktop mock fallback.
func is_native_available() -> bool:
	return NativeAdsBackend.native_sdk_available()


## Initializes only when called through the service's consent gate.
func initialize(completed: Callable) -> void:
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		completed.call()
	MobileAds.initialize(listener)


## Loads one rewarded ad; lifecycle ownership stays with the native backend.
func load_rewarded(ad_unit_id: String, loaded: Callable, failed: Callable) -> void:
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void: loaded.call(ad)
	callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void: failed.call(&"load_failed")
	RewardedAdLoader.new().load(ad_unit_id, AdRequest.new(), callback)


## Installs all callbacks before presentation; reward and dismissal remain separate.
func show_rewarded(ad: Object, rewarded: Callable, closed: Callable, failed: Callable) -> void:
	var native_ad: RewardedAd = ad as RewardedAd
	var callback := FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content = closed
	callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		failed.call(&"show_failed")
	native_ad.full_screen_content_callback = callback
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void: rewarded.call()
	native_ad.show(listener)


## Releases a consumed or superseded native ad.
func destroy_rewarded(ad: Object) -> void:
	(ad as RewardedAd).destroy()


## Refreshes Google's consent information once each app session, without forced geography.
func update_consent(updated: Callable, failed: Callable) -> void:
	UserMessagingPlatform.consent_information.update(ConsentRequestParameters.new(), updated,
		func(_error: FormError) -> void: failed.call())


## Uses the actual UMP state. Google documents canRequestAds as NOT_REQUIRED or OBTAINED
## after update; Poing 5.1 exposes these enums rather than a canRequestAds wrapper.
func consent_state() -> Dictionary:
	var info: ConsentInformation = UserMessagingPlatform.consent_information
	var status: ConsentInformation.ConsentStatus = info.get_consent_status()
	return {
		"allowed": status in [ConsentInformation.ConsentStatus.NOT_REQUIRED,
			ConsentInformation.ConsentStatus.OBTAINED],
		"form_required": status == ConsentInformation.ConsentStatus.REQUIRED,
		"form_available": info.get_is_consent_form_available(),
		"privacy_required": info.get_privacy_options_requirement_status() ==
			ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED,
	}


## Loads and presents the required UMP form once; no dismissal/reload loop.
func show_required_consent(completed: Callable, failed: Callable) -> void:
	UserMessagingPlatform.load_consent_form(func(form: ConsentForm) -> void:
		form.show(func(_error: FormError) -> void: completed.call()),
		func(_error: FormError) -> void: failed.call())


## Opens Google's privacy-options form and refreshes state after any outcome.
func show_privacy_options(completed: Callable) -> void:
	UserMessagingPlatform.show_privacy_options_form(func(_error: FormError) -> void:
		completed.call())
