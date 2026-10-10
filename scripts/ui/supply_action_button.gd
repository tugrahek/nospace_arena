class_name SupplyActionButton
extends Button

## Supply-only wrapped caption; preserves native Button text/disabled/pressed APIs.
@export var caption_color: Color = Color(0.97, 0.97, 1.0, 1.0):
	set(value):
		caption_color = value
		if is_node_ready():
			_caption.add_theme_color_override("font_color", value)
const MINIMUM_HEIGHT: float = 108.0
const VERTICAL_PADDING: float = 32.0
@onready var _content: HBoxContainer = $Content
@onready var _caption: Label = $Content/Caption


func _ready() -> void:
	for key: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color", "font_focus_color"]:
		add_theme_color_override(key, Color.TRANSPARENT)
	_content.minimum_size_changed.connect(_refresh_minimum)
	set_caption(text)


## Keep the native accessible caption while a child Label handles full multiline text.
func set_caption(value: String) -> void:
	text = value
	_caption.text = value
	_caption.add_theme_color_override("font_color", caption_color)


func _refresh_minimum() -> void:
	custom_minimum_size.y = maxf(MINIMUM_HEIGHT, _content.get_combined_minimum_size().y + VERTICAL_PADDING)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW and is_node_ready():
		_caption.modulate.a = 0.55 if disabled else 1.0
