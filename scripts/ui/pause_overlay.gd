extends CanvasLayer

## In-run pause: a pause button (during play) + an overlay (Resume/Restart/Menu). Runs with
## process_mode = ALWAYS so Esc toggles BOTH ways (pause and resume) and the overlay buttons
## work while the tree is paused. Auto-pauses on app background / focus loss (resume is manual).
## Functional scaffold — visual polish is Step 15.

signal restart_requested()
signal menu_requested()

const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/Settings.tscn")
const MISSION_ROW: Script = preload("res://scripts/ui/pause_mission_row.gd")

@onready var _pause_button: Button = $PauseButton
@onready var _overlay: Control = $Overlay
@onready var _title: Label = $Overlay/Box/Title
@onready var _resume_button: Button = $Overlay/Box/ResumeButton
@onready var _mission_section: VBoxContainer = $Overlay/Box/MissionSection
@onready var _mission_heading: Label = $Overlay/Box/MissionSection/Heading
@onready var _mission_rows: VBoxContainer = $Overlay/Box/MissionSection/Rows
@onready var _settings_button: Button = $Overlay/Box/SecondaryActions/SettingsButton
@onready var _restart_button: Button = $Overlay/Box/SecondaryActions/RestartButton
@onready var _menu_button: Button = $Overlay/Box/MenuButton

var _settings_panel: Control = null  # active in-pause Settings overlay, if open
var _missions: Array = []
var _rows: Array[PauseMissionRow] = []


func _ready() -> void:
	_overlay.visible = false
	_apply_texts()
	_pause_button.pressed.connect(pause)
	_resume_button.pressed.connect(resume)
	_settings_button.pressed.connect(_on_settings)
	_restart_button.pressed.connect(_on_restart)
	_menu_button.pressed.connect(_on_menu)


## Receives the real run missions from HUD; keeps row nodes reusable across refreshes.
func show_missions(missions: Array) -> void:
	_missions = missions.duplicate()
	_refresh_missions()


func _apply_texts() -> void:
	_title.text = tr("PAUSE_TITLE")
	_resume_button.text = tr("PAUSE_RESUME")
	_mission_heading.text = tr("MISSIONS_TITLE")
	_settings_button.text = tr("PAUSE_SETTINGS")
	_restart_button.text = tr("PAUSE_RESTART")
	_menu_button.text = tr("PAUSE_MENU")


func _refresh_missions() -> void:
	_mission_section.visible = not _missions.is_empty()
	while _rows.size() < _missions.size():
		var row: PauseMissionRow = MISSION_ROW.new()
		_mission_rows.add_child(row)
		_rows.append(row)
	for i in _rows.size():
		_rows[i].visible = i < _missions.size()
		if i < _missions.size():
			_rows[i].configure(_missions[i])


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
	panel.tree_exited.connect(_on_settings_closed, CONNECT_ONE_SHOT)


func _on_settings_closed() -> void:
	_settings_panel = null
	_apply_texts()
	_refresh_missions()


func toggle() -> void:
	if get_tree().paused:
		resume()
	else:
		pause()


## Pauses only during active play (no-op on the result screen or when already paused).
func pause() -> void:
	if not GameState.is_playing() or get_tree().paused:
		return
	_apply_texts()
	_refresh_missions()
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
