extends Control

## Minimal legal reader reused from the former Credits scene; closes to its Settings owner.
const NOTICES: LegalNotices = preload("res://config/legal_notices.tres")
const PALETTE: PaletteData = preload("res://config/palette.tres")

@onready var _title: Label = $Layout/Title
@onready var _notices: RichTextLabel = $Layout/Notices
@onready var _back: Button = $Layout/BackButton


func _ready() -> void:
	$Background.color = PALETTE.void_bg
	_title.text = tr("LEGAL_TITLE")
	_notices.text = NOTICES.build_text()
	_back.text = tr("SETTINGS_BACK")
	_back.pressed.connect(close)
	_back.grab_focus()


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
