class_name NativeAdsBackend
extends AdsBackend

## Token-preserving adapter. All SDK calls are injectable for focused tests.
const NATIVE_SINGLETONS: PackedStringArray = [
	"PoingGodotAdMob", "PoingGodotAdMobRewardedAd",
	"PoingGodotAdMobConsentInformation", "PoingGodotAdMobUserMessagingPlatform",
]

var _sdk: RefCounted
var _ad_unit_id: String
var _load_token: int = 0
var _ad_load_token: int = 0
var _show_token: int = 0
var _ready_ad: Object
var _shown_ad: Object
var _reward_emitted: bool = false


## Checks availability without loading vendor classes or activating desktop mock nodes.
static func native_sdk_available() -> bool:
	if OS.get_name() != "Android":
		return false
	for singleton: String in NATIVE_SINGLETONS:
		if not Engine.has_singleton(singleton):
			return false
	return true


## Production passes PoingAdsBridge; tests supply the same small call surface.
func _init(sdk: RefCounted, ad_unit_id: String) -> void:
	_sdk = sdk
	_ad_unit_id = ad_unit_id


## SDK completion maps to the initialization request's original token.
func initialize(token: int) -> void:
	if _ad_unit_id.is_empty() or not _sdk.is_native_available():
		initialized.emit(token, false)
		return
	_sdk.initialize(func() -> void: initialized.emit(token, true))


## Replaces superseded loaded ads and retains only the current load result.
func load_rewarded(token: int) -> void:
	if _ad_unit_id.is_empty():
		operation_failed.emit(token, &"ad_config_missing")
		return
	_discard_ready_ad()
	_load_token = token
	_sdk.load_rewarded(_ad_unit_id, _on_loaded.bind(token), _on_load_failed.bind(token))


## Consumes one ready ad; every callback carries the original presentation token.
func show_rewarded(token: int) -> void:
	if _ready_ad == null or _show_token != 0:
		operation_failed.emit(token, &"ad_unavailable")
		return
	_shown_ad = _ready_ad
	_ready_ad = null
	_show_token = token
	_reward_emitted = false
	_sdk.show_rewarded(_shown_ad, _on_reward.bind(token), _on_closed.bind(token),
		_on_show_failed.bind(token))


func _on_loaded(ad: Object, token: int) -> void:
	if token != _load_token:
		# Duplicate callbacks can wrap the same native UID in another script object.
		# Do not destroy the current ad through such a duplicate wrapper.
		if token == _ad_load_token:
			return
		_sdk.destroy_rewarded(ad)
		return
	_load_token = 0
	_ad_load_token = token
	_ready_ad = ad
	rewarded_loaded.emit(token)


func _on_load_failed(reason: StringName, token: int) -> void:
	if token != _load_token:
		return
	_load_token = 0
	operation_failed.emit(token, reason)


func _on_reward(token: int) -> void:
	if token != _show_token or _reward_emitted:
		return
	_reward_emitted = true
	reward_received.emit(token)


func _on_closed(token: int) -> void:
	if token != _show_token:
		return
	_clear_show()
	rewarded_closed.emit(token)


func _on_show_failed(reason: StringName, token: int) -> void:
	if token != _show_token or _reward_emitted:
		return
	_clear_show()
	operation_failed.emit(token, reason)


func _clear_show() -> void:
	var consumed: Object = _shown_ad
	_shown_ad = null
	_show_token = 0
	_ad_load_token = 0
	_sdk.destroy_rewarded(consumed)


func _discard_ready_ad() -> void:
	if _ready_ad != null:
		_sdk.destroy_rewarded(_ready_ad)
		_ready_ad = null
		_ad_load_token = 0
