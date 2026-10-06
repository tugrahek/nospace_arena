class_name MissionProgressStrip
extends VBoxContainer

## Read-only mission heading, reward and goal-specific gameplay progress geometry.

const BoostIcon = preload("res://scripts/ui/boost_icon.gd")
const ProgressGeometry = preload("res://scripts/ui/mission_progress_geometry.gd")
const PALETTE: PaletteData = preload("res://config/palette.tres")
@export var module_corner: float = 14.0

var progress_ratio: float = 0.0
var has_active_frontier: bool = false
var shows_diamond: bool = false
var is_completed: bool = false
var uses_checkpoints: bool = false
var objective_text: String = ""
var reward_value: int = 0
var current_value: int = 0
var goal_value: int = 0

var _header: HBoxContainer
var _objective: Label
var _reward_cluster: HBoxContainer
var _reward: Label
var _patch: ProgressGeometry
var _progress: Label
var _content: VBoxContainer


func _ready() -> void:
	_ensure_children()
	resized.connect(queue_redraw)


## Reads the canonical model without advancing, claiming or saving it.
func configure(mission: Mission) -> void:
	objective_text = tr(mission.def.description_key) % mission.def.goal_amount
	reward_value = mission.def.reward
	current_value = mission.progress
	goal_value = mission.def.goal_amount
	progress_ratio = clampf(float(current_value) / float(maxi(goal_value, 1)), 0.0, 1.0)
	is_completed = mission.is_complete()
	uses_checkpoints = mission.def.goal_type in [MissionDef.GoalType.WIN_RUNS, MissionDef.GoalType.TOTAL_AREAS,
		MissionDef.GoalType.REACH_STAGE, MissionDef.GoalType.COMPLETE_RUNS]
	has_active_frontier = not is_completed
	shows_diamond = has_active_frontier
	_ensure_children()
	_objective.text = objective_text
	_reward.text = "+%d" % reward_value
	_progress.text = "%d / %d" % [current_value, goal_value]
	_patch.configure(current_value, goal_value, progress_ratio, is_completed, mission.def.goal_type)


## Returns the localized objective for layout validation.
func objective_label() -> Label:
	return _objective


## Returns the shared right-aligned coin/value group.
func reward_cluster() -> HBoxContainer:
	return _reward_cluster


## Returns the procedural progress surface.
func territory_patch() -> Control:
	return _patch


## Returns the continuous arena's captured coverage.
func rendered_captured_area_ratio() -> float:
	return _patch.captured_area_ratio()


func _ensure_children() -> void:
	if _header != null:
		return
	custom_minimum_size = Vector2(0.0, 282.0)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 16)
	margin.add_child(_content)
	_build_header()
	_patch = ProgressGeometry.new()
	_patch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_patch)
	_progress = Label.new()
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress.add_theme_font_size_override("font_size", 30)
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_progress)


func _build_header() -> void:
	_header = HBoxContainer.new()
	_header.custom_minimum_size = Vector2(0.0, 44.0)
	_header.add_theme_constant_override("separation", 18)
	_content.add_child(_header)
	_objective = Label.new()
	_objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective.theme_type_variation = &"Heading"
	_objective.add_theme_color_override("font_color", PALETTE.text_primary)
	_objective.add_theme_font_size_override("font_size", 32)
	_header.add_child(_objective)
	_build_reward_cluster()


func _build_reward_cluster() -> void:
	_reward_cluster = HBoxContainer.new()
	_reward_cluster.custom_minimum_size = Vector2(120.0, 44.0)
	_reward_cluster.add_theme_constant_override("separation", 7)
	_reward_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(_reward_cluster)
	var coin := BoostIcon.new()
	coin.set("effect", BoostData.Effect.COIN_BONUS)
	coin.custom_minimum_size = Vector2(34.0, 34.0)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reward_cluster.add_child(coin)
	_reward = Label.new()
	_reward.theme_type_variation = &"Coins"
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_reward.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reward.add_theme_font_size_override("font_size", 30)
	_reward_cluster.add_child(_reward)


func _draw() -> void:
	# A quiet shared arena perimeter; the goal-specific territory/route owns the module.
	var rect := Rect2(Vector2.ONE, size - Vector2.ONE * 2.0)
	var points := PackedVector2Array([rect.position, Vector2(rect.end.x - module_corner, rect.position.y),
		rect.position + Vector2(rect.size.x, module_corner), rect.end,
		Vector2(rect.position.x + module_corner, rect.end.y), Vector2(rect.position.x, rect.end.y - module_corner)])
	draw_colored_polygon(points, PALETTE.void_bg.darkened(0.08))
	points.append(points[0])
	draw_polyline(points, Color(PALETTE.border, 0.28), 1.0, true)
