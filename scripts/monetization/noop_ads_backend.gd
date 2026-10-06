class_name NoopAdsBackend
extends "res://scripts/monetization/ads_backend.gd"

## Safe desktop/no-SDK backend. It never initializes a native SDK or grants rewards.


## No-op initialization performs no network work and can report unavailability.
func requires_permission() -> bool:
	return false
