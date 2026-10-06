extends Node

## Autoload boundary for rewarded ads. No UI references, economy calls, or SDK types.
## Initialization is automatic on boot with a safe no-op backend. A future consent
## coordinator must explicitly allow requests before a network backend can run.
const Backend = preload("res://scripts/monetization/ads_backend.gd")
const NoopBackend = preload("res://scripts/monetization/noop_ads_backend.gd")

signal rewarded_ready()
signal ads_unavailable(reason: StringName)
signal ad_failed(context_id: String, request_token: int, reason: StringName)
signal reward_earned(context_id: String, request_token: int)
signal ad_closed(context_id: String, request_token: int)

enum State { UNAVAILABLE, INITIALIZING, IDLE, LOADING, READY, SHOWING, REWARDED, CLOSED, FAILED }

var state: State = State.UNAVAILABLE
var _backend: Backend
var _requests_allowed: bool = false
var _backend_locked: bool = false
var _backend_ready: bool = false
var _next_token: int = 0
var _initialization_token: int = 0
var _load_token: int = 0
var _show_token: int = 0
var _context_id: String = ""
var _reward_emitted: bool = false


func _init() -> void:
	_attach_backend(NoopBackend.new())


func _ready() -> void:
	initialize()


## Injects an adapter before initialization begins; tests use the fake backend.
func configure_backend(backend: Backend) -> bool:
	if backend == null or _backend_locked:
		return false
	_disconnect_backend()
	_attach_backend(backend)
	return true


## Future privacy gate. Default is denied; revocation invalidates pending loads.
## An already-presented ad can finish its valid reward/close sequence.
func set_requests_allowed(allowed: bool) -> void:
	_requests_allowed = allowed
	if allowed or not _backend.requires_permission() or _show_token != 0:
		return
	_initialization_token = 0
	_load_token = 0
	state = State.UNAVAILABLE
	ads_unavailable.emit(&"privacy_blocked")


## Initializes at most once concurrently and never bypasses the privacy gate.
func initialize() -> void:
	if _backend_ready or _initialization_token != 0:
		return
	if not _permission_allows_requests():
		state = State.UNAVAILABLE
		ads_unavailable.emit(&"privacy_blocked")
		return
	_backend_locked = true
	_initialization_token = _new_token()
	state = State.INITIALIZING
	_backend.initialize(_initialization_token)


## Requests one ad; overlapping loads and active presentations are rejected.
func preload_rewarded() -> bool:
	if not _backend_ready or not _permission_allows_requests():
		return false
	if state in [State.INITIALIZING, State.LOADING, State.READY, State.SHOWING, State.REWARDED]:
		return false
	_load_token = _new_token()
	state = State.LOADING
	_backend.load_rewarded(_load_token)
	return true


## Reports whether a fresh ad may be shown now.
func is_rewarded_available() -> bool:
	return state == State.READY and _backend_ready and _permission_allows_requests()


## Returns a unique positive presentation token, or 0 when rejected.
## Caller context is data only: its scene may disappear without affecting callbacks.
func show_rewarded(context_id: String) -> int:
	if context_id.strip_edges().is_empty() or not is_rewarded_available():
		return 0
	_show_token = _new_token()
	_context_id = context_id
	_reward_emitted = false
	state = State.SHOWING
	var token: int = _show_token
	_backend.show_rewarded(token)
	return token


func _permission_allows_requests() -> bool:
	return not _backend.requires_permission() or _requests_allowed


func _new_token() -> int:
	_next_token += 1
	return _next_token


func _attach_backend(backend: Backend) -> void:
	_backend = backend
	_backend.initialized.connect(_on_initialized)
	_backend.rewarded_loaded.connect(_on_loaded)
	_backend.operation_failed.connect(_on_failed)
	_backend.reward_received.connect(_on_reward)
	_backend.rewarded_closed.connect(_on_closed)


func _disconnect_backend() -> void:
	_backend.initialized.disconnect(_on_initialized)
	_backend.rewarded_loaded.disconnect(_on_loaded)
	_backend.operation_failed.disconnect(_on_failed)
	_backend.reward_received.disconnect(_on_reward)
	_backend.rewarded_closed.disconnect(_on_closed)


func _on_initialized(token: int, available: bool) -> void:
	if token == 0 or token != _initialization_token:
		return
	_initialization_token = 0
	_backend_ready = available
	state = State.IDLE if available else State.UNAVAILABLE
	if not available:
		ads_unavailable.emit(&"sdk_unavailable")


func _on_loaded(token: int) -> void:
	if token == 0 or token != _load_token or state != State.LOADING:
		return
	_load_token = 0
	state = State.READY
	rewarded_ready.emit()


func _on_reward(token: int) -> void:
	if token == 0 or token != _show_token or _reward_emitted or state != State.SHOWING:
		return
	_reward_emitted = true
	state = State.REWARDED
	reward_earned.emit(_context_id, token)


func _on_closed(token: int) -> void:
	if token == 0 or token != _show_token:
		return
	var context: String = _context_id
	_clear_presentation()
	state = State.CLOSED
	ad_closed.emit(context, token)


func _on_failed(token: int, reason: StringName) -> void:
	if token == 0:
		return
	var context: String = ""
	if token == _show_token:
		# A reward already earned stays valid; only close completes that presentation.
		if _reward_emitted:
			return
		context = _context_id
		_clear_presentation()
	elif token == _load_token:
		_load_token = 0
	elif token == _initialization_token:
		_initialization_token = 0
		_backend_ready = false
	else:
		return
	state = State.FAILED
	ad_failed.emit(context, token, reason)


func _clear_presentation() -> void:
	_show_token = 0
	_context_id = ""
	_reward_emitted = false
