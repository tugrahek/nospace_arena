class_name AdsConsentCoordinator
extends RefCounted

## Owns one session update or privacy form. Nothing is persisted outside Google UMP.
signal consent_changed(allowed: bool, privacy_required: bool, busy: bool)

enum Stage { IDLE, UPDATE, FORM, PRIVACY }

var privacy_required: bool = false
var busy: bool = false
var _sdk: RefCounted
var _started: bool = false
var _stage: Stage = Stage.IDLE
var _operation_token: int = 0


## Uses PoingAdsBridge in production and a deterministic bridge in tests.
func _init(sdk: RefCounted) -> void:
	_sdk = sdk


## Closes the ad gate until the session update and any required form finish.
func start() -> void:
	if _started:
		return
	_started = true
	busy = true
	_stage = Stage.UPDATE
	_operation_token += 1
	consent_changed.emit(false, false, true)
	if not _sdk.is_native_available():
		_finish(_operation_token)
		return
	_sdk.update_consent(_on_updated.bind(_operation_token), _on_update_failed.bind(_operation_token))


## Only Google's REQUIRED privacy state exposes this action; overlapping forms are rejected.
func open_privacy_options() -> bool:
	if busy or not privacy_required:
		return false
	busy = true
	_stage = Stage.PRIVACY
	_operation_token += 1
	consent_changed.emit(false, privacy_required, true)
	_sdk.show_privacy_options(_finish.bind(_operation_token))
	return true


func _on_updated(token: int) -> void:
	if token != _operation_token or _stage != Stage.UPDATE:
		return
	var current: Dictionary = _sdk.consent_state()
	if current.get("form_required", false) and current.get("form_available", false):
		_stage = Stage.FORM
		_sdk.show_required_consent(_finish.bind(token), _finish.bind(token))
	else:
		_finish(token)


func _on_update_failed(token: int) -> void:
	if token == _operation_token and _stage == Stage.UPDATE:
		_finish(token)


func _finish(token: int) -> void:
	if token != _operation_token or not busy:
		return
	var current: Dictionary = _sdk.consent_state() if _sdk.is_native_available() else {}
	busy = false
	_stage = Stage.IDLE
	privacy_required = current.get("privacy_required", false)
	consent_changed.emit(current.get("allowed", false), privacy_required, false)
