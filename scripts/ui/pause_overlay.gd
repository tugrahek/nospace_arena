extends CanvasLayer

## In-run pause: a pause button (during play) + an overlay (Resume/Restart/Menu). Runs with
## process_mode = ALWAYS so Esc toggles BOTH ways (pause and resume) and the overlay buttons
## work while the tree is paused. Auto-pauses on app background / focus loss (resume is manual).
## Functional scaffold — visual polish is Step 15.

signal restart_requested()
signal menu_requested()

const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/Settings.tscn")

@onready var _pause_button: Button = $PauseButton
@onready var _overlay: Control = $Overlay
@onready var _resume_button: Button = $Overlay/Box/ResumeButton
@onready var _settings_button: Button = $Overlay/Box/SettingsButton
@onready var _restart_button: Button = $Overlay/Box/RestartButton
@onready var _menu_button: Button = $Overlay/Box/MenuButton

var _settings_panel: Control = null  # active in-pause Settings overlay, if open


func _ready() -> void:
	_overlay.visible = false
	_resume_button.text = tr("PAUSE_RESUME")
	_settings_button.text = tr("PAUSE_SETTINGS")
	_restart_button.text = tr("PAUSE_RESTART")
	_menu_button.text = tr("PAUSE_MENU")
	_pause_button.pressed.connect(pause)
	_resume_button.pressed.connect(resume)
	_settings_button.pressed.connect(_on_settings)
	_restart_button.pressed.connect(_on_restart)
	_menu_button.pressed.connect(_on_menu)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# If the Settings overlay is open, close it first; otherwise toggle pause.
		if _settings_panel != null and is_instance_valid(_settings_panel):
			_settings_panel.call("close")
		else:
			toggle()
		get_viewport().set_input_as_handled()


## Opens the Settings panel as an overlay on top of the paused game (embedded -> Back closes it).
func _on_settings() -> void:
	if _settings_panel != null and is_instance_valid(_settings_panel):
		return
	var panel: Control = SETTINGS_SCENE.instantiate()
	panel.set("embedded", true)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS  # interactive while the tree is paused
	add_child(panel)
	_settings_panel = panel


func toggle() -> void:
	if get_tree().paused:
		resume()
	else:
		pause()


## Pauses only during active play (no-op on the result screen or when already paused).
func pause() -> void:
	if not GameState.is_playing() or get_tree().paused:
		return
	get_tree().paused = true
	_overlay.visible = true
	_pause_button.visible = false


func resume() -> void:
	if not get_tree().paused:
		return
	get_tree().paused = false
	_overlay.visible = false
	_pause_button.visible = true


func _on_restart() -> void:
	get_tree().paused = false
	restart_requested.emit()


func _on_menu() -> void:
	get_tree().paused = false  # abandon run (no submit/earn); ensure unpaused before scene change
	menu_requested.emit()


## Auto-pause when the app is backgrounded (mobile) or loses focus (desktop alt-tab).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		pause()
