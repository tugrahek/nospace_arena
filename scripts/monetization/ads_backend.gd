class_name AdsBackend
extends RefCounted

## Project-owned callback contract. Native adapters must echo the supplied token.
signal initialized(token: int, available: bool)
signal rewarded_loaded(token: int)
signal operation_failed(token: int, reason: StringName)
signal reward_received(token: int)
signal rewarded_closed(token: int)


## Network-capable backends require an explicit future privacy-gate decision.
func requires_permission() -> bool:
	return true


## Starts initialization; the default implementation has no SDK.
func initialize(token: int) -> void:
	initialized.emit(token, false)


## Starts loading one rewarded ad.
func load_rewarded(token: int) -> void:
	operation_failed.emit(token, &"sdk_unavailable")


## Presents one ad and associates all presentation callbacks with this token.
func show_rewarded(token: int) -> void:
	operation_failed.emit(token, &"sdk_unavailable")
