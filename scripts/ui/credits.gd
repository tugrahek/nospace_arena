extends Control

## Minimal legal reader reused from the former Credits scene; closes to its Settings owner.
const NOTICES: LegalNotices = preload("res://config/legal_notices.tres")
const PALETTE: PaletteData = preload("res://config/palette.tres")

@onready var _bounds: Control = $SafeArea/Bounds
@onready var _layout: VBoxContainer = $SafeArea/Bounds/Layout
@onready var _title: Label = $SafeArea/Bounds/Layout/Title
@onready var _notices: RichTextLabel = $SafeArea/Bounds/Layout/Notices
@onready var _back: Button = $SafeArea/Bounds/Layout/BackButton


func _ready() -> void:
	_bounds.resized.connect(_refresh_layout)
	_refresh_layout()
	$Background.color = PALETTE.void_bg
	_title.text = tr("LEGAL_TITLE")
	_notices.text = NOTICES.build_text()
	_back.text = tr("SETTINGS_BACK")
	_back.pressed.connect(close)
	_back.grab_focus()


func _refresh_layout() -> void:
	var width: float = minf(maxf(0.0, _bounds.size.x - 72.0), 800.0)
	_layout.offset_left = -width * 0.5
	_layout.offset_right = width * 0.5


## Returns to the same Settings instance without changing gameplay or Settings state.
func close() -> void:
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		close()
