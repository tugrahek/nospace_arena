extends VBoxContainer

## MainMenu-only sizing within native containers; no navigation, input or reward ownership.
@export var maximum_content_width: float = 800.0
@export var compact_height: float = 1200.0
@export var roomy_height: float = 1600.0
@export var emblem_sizes: Vector2 = Vector2(208.0, 240.0)
@export var navigation_heights: Vector2 = Vector2(256.0, 256.0)
@export var navigation_minimum_width: float = 560.0
@export var play_heights: Vector2 = Vector2(108.0, 108.0)
@export var title_font_sizes: Vector2i = Vector2i(52, 56)
@export var section_separations: Vector2i = Vector2i(16, 20)
@export var action_separations: Vector2i = Vector2i(12, 14)

@onready var _bounds: Control = get_parent() as Control
@onready var _content_group: VBoxContainer = $ContentGroup
@onready var _emblem: Control = $ContentGroup/Center/Emblem
@onready var _title: Label = $ContentGroup/Center/Title
@onready var _buttons: VBoxContainer = $ContentGroup/Footer/Buttons
@onready var _play: Button = $ContentGroup/Footer/Buttons/PlayButton
@onready var _hub: Control = $ContentGroup/Footer/Buttons/NavigationHub
var _layout_pending: bool = false


func _ready() -> void:
	_bounds.resized.connect(_queue_layout)
	_queue_layout()


func _queue_layout() -> void:
	if _layout_pending or not is_inside_tree():
		return
	_layout_pending = true
	_refresh_layout.call_deferred()


func _refresh_layout() -> void:
	_layout_pending = false
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var width: float = minf(_bounds.size.x, maximum_content_width)
	offset_left = -width * 0.5
	offset_right = width * 0.5
	var room: float = clampf((_bounds.size.y - compact_height) / maxf(roomy_height - compact_height, 1.0), 0.0, 1.0)
	_content_group.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_emblem.custom_minimum_size = Vector2.ONE * roundf(lerpf(emblem_sizes.x, emblem_sizes.y, room))
	_play.custom_minimum_size.y = roundf(lerpf(play_heights.x, play_heights.y, room))
	_hub.custom_minimum_size.y = roundf(lerpf(navigation_heights.x, navigation_heights.y, room))
	_hub.custom_minimum_size.x = minf(width, navigation_minimum_width)
	_title.add_theme_font_size_override("font_size", roundi(lerpf(title_font_sizes.x, title_font_sizes.y, room)))
	add_theme_constant_override("separation", roundi(lerpf(section_separations.x, section_separations.y, room)))
	_buttons.add_theme_constant_override("separation", roundi(lerpf(action_separations.x, action_separations.y, room)))
