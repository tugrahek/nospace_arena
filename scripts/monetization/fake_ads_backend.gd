class_name FakeAdsBackend
extends "res://scripts/monetization/ads_backend.gd"

## Deterministic manual callback driver for service tests; no native dependencies.
var initialization_tokens: Array[int] = []
var load_tokens: Array[int] = []
var show_tokens: Array[int] = []


## Records initialization without automatically completing it.
func initialize(token: int) -> void:
	initialization_tokens.append(token)


## Records a pending load; tests choose its success/failure callback.
func load_rewarded(token: int) -> void:
	load_tokens.append(token)


## Records a presentation; tests choose reward, close, failure, or stale events.
func show_rewarded(token: int) -> void:
	show_tokens.append(token)


## Emits an initialization result, including duplicates or stale tokens.
func complete_initialization(token: int, available: bool = true) -> void:
	initialized.emit(token, available)


## Emits a loaded callback, including duplicates or stale tokens.
func complete_load(token: int) -> void:
	rewarded_loaded.emit(token)


## Emits no-fill or another operation failure without changing service state directly.
func fail(token: int, reason: StringName = &"no_fill") -> void:
	operation_failed.emit(token, reason)


## Emits a reward callback; service owns validation and deduplication.
func earn_reward(token: int) -> void:
	reward_received.emit(token)


## Emits a close callback independently of whether a reward was earned.
func close(token: int) -> void:
	rewarded_closed.emit(token)
