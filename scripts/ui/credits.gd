extends Control

## Presents localized credits while preserving the legal attribution details.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const PALETTE: PaletteData = preload("res://config/palette.tres")

@export_range(0.0, 0.1, 0.005) var horizontal_inset_ratio: float = 0.05
@export var minimum_horizontal_inset: float = 24.0
@export var maximum_horizontal_inset: float = 48.0
@export var vertical_inset: float = 24.0

@onready var _labels: Dictionary = {
	"Title": $SafeArea/Layout/Title,
	"CreatedHeading": $SafeArea/Layout/CreatedHeading,
	"Creator": $SafeArea/Layout/Creator,
	"Copyright": $SafeArea/Layout/Copyright,
	"TechHeading": $SafeArea/Layout/TechHeading,
	"Technology": $SafeArea/Layout/Technology,
	"FontsHeading": $SafeArea/Layout/FontsHeading,
	"Fonts": $SafeArea/Layout/Fonts,
	"LicensesHeading": $SafeArea/Layout/LicensesHeading,
	"Licenses": $SafeArea/Layout/Licenses,
}
@onready var _back: Button = $SafeArea/Layout/BackButton

const LABEL_KEYS: Dictionary = {
	"Title": "CREDITS_TITLE",
	"CreatedHeading": "CREDITS_CREATED",
	"Creator": "CREDITS_CREATOR",
	"Copyright": "CREDITS_COPYRIGHT",
	"TechHeading": "CREDITS_TECH",
	"Technology": "CREDITS_TECH_CONTENT",
	"FontsHeading": "CREDITS_FONTS",
	"Fonts": "CREDITS_FONTS_CONTENT",
	"LicensesHeading": "CREDITS_LICENSES",
	"Licenses": "CREDITS_LICENSES_CONTENT",
}


func _ready() -> void:
	$Background.color = PALETTE.void_bg
	for label_name: String in LABEL_KEYS:
		var label: Label = _labels[label_name] as Label
		label.text = tr(str(LABEL_KEYS[label_name]))
	_back.text = tr("STORE_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


## Applies a small desktop inset and the device safe rectangle on mobile.
func _on_viewport_resized() -> void:
	var safe_area: MarginContainer = $SafeArea
	var horizontal_margin: float = clampf(size.x * horizontal_inset_ratio, minimum_horizontal_inset, maximum_horizontal_inset)
	var inset_left: float = horizontal_margin
	var inset_top: float = vertical_inset
	var inset_right: float = horizontal_margin
	var inset_bottom: float = vertical_inset
	if OS.has_feature("mobile"):
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var device_safe_rect: Rect2i = DisplayServer.get_display_safe_area()
		if screen_size.x > 0 and screen_size.y > 0 and device_safe_rect.size.x > 0 and device_safe_rect.size.y > 0:
			var scale_x: float = size.x / float(screen_size.x)
			var scale_y: float = size.y / float(screen_size.y)
			inset_left += float(device_safe_rect.position.x) * scale_x
			inset_top += float(device_safe_rect.position.y) * scale_y
			inset_right += float(screen_size.x - device_safe_rect.end.x) * scale_x
			inset_bottom += float(screen_size.y - device_safe_rect.end.y) * scale_y
	safe_area.offset_left = inset_left
	safe_area.offset_top = inset_top
	safe_area.offset_right = -inset_right
	safe_area.offset_bottom = -inset_bottom
