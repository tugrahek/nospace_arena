extends Control

## Credits / künye screen: copyright + asset license attributions (see docs/credits.md).
## Functional scaffold — visual polish is Step 15.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"

@onready var _title: Label = $Title
@onready var _back: Button = $BackButton


func _ready() -> void:
	_title.text = tr("CREDITS_TITLE")
	_back.text = tr("STORE_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
