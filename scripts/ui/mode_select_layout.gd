extends VBoxContainer

## ModeSelect-only bounded sizing; native containers retain layout and input ownership.
@export var maximum_content_width: float = 800.0
@export var height_range: Vector2 = Vector2(1200.0, 1600.0)
@export var grid_heights: Vector2 = Vector2(600.0, 780.0)
@export var art_widths: Vector2 = Vector2(224.0, 280.0)
@export var title_font_sizes: Vector2i = Vector2i(52, 60)
@export var section_separations: Vector2i = Vector2i(24, 36)
const ART_HEIGHT_RATIO: float = 4.0 / 7.0
const TILE_WIDTH_INSET: float = 40.0
@onready var _bounds: Control = get_parent() as Control
@onready var _grid: Control = $ModeGrid
@onready var _title: Label = $Title
@onready var _artworks: Array[Control] = [$ModeGrid/DailyRow/Button/Content/Art,
	$ModeGrid/FreeRow/Button/Content/Art, $ModeGrid/LevelRow/Button/Content/Art,
	$ModeGrid/CampaignRow/Button/Content/Art]
var _pending: bool = false


func _ready() -> void:
	_bounds.resized.connect(_queue_layout)
	_queue_layout()


func _queue_layout() -> void:
	if _pending or not is_inside_tree():
		return
	_pending = true
	_refresh_layout.call_deferred()


func _refresh_layout() -> void:
	_pending = false
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var width: float = minf(_bounds.size.x, maximum_content_width)
	offset_left = -width * 0.5
	offset_right = width * 0.5
	var room: float = clampf((_bounds.size.y - height_range.x) / maxf(height_range.y - height_range.x, 1.0), 0.0, 1.0)
	_grid.custom_minimum_size.y = roundf(lerpf(grid_heights.x, grid_heights.y, room))
	_title.add_theme_font_size_override("font_size", roundi(lerpf(title_font_sizes.x, title_font_sizes.y, room)))
	add_theme_constant_override("separation", roundi(lerpf(section_separations.x, section_separations.y, room)))
	# Fit artwork by width as well as height; preserve its aspect on narrow inset screens.
	var art_width: float = minf(roundf(lerpf(art_widths.x, art_widths.y, room)), width * 0.5 - TILE_WIDTH_INSET)
	for art: Control in _artworks:
		art.custom_minimum_size = Vector2(art_width, art_width * ART_HEIGHT_RATIO)
