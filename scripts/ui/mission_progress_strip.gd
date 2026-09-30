class_name MissionProgressStrip
extends VBoxContainer

## Presentation-only mission composition: a semantic header above a wide rounded territory surface.

const BoostIcon = preload("res://scripts/ui/boost_icon.gd")

var progress_ratio: float = 0.0
var has_active_frontier: bool = false
var shows_diamond: bool = false
var is_completed: bool = false
var objective_text: String = ""
var reward_value: int = 0
var current_value: int = 0
var goal_value: int = 0

var _header: HBoxContainer
var _objective: Label
var _reward_cluster: HBoxContainer
var _reward: Label
var _patch: TerritoryPatch


func _ready() -> void:
	_ensure_children()


## Binds only real Mission data; Containers own all width-dependent header layout.
func configure(mission: Mission) -> void:
	objective_text = tr(mission.def.description_key) % mission.def.goal_amount
	reward_value = mission.def.reward
	current_value = mission.progress
	goal_value = mission.def.goal_amount
	progress_ratio = clampf(float(current_value) / float(maxi(goal_value, 1)), 0.0, 1.0)
	is_completed = mission.is_complete()
	has_active_frontier = progress_ratio > 0.0 and progress_ratio < 1.0
	shows_diamond = has_active_frontier
	_ensure_children()
	_objective.text = objective_text
	_reward.text = "+%d" % reward_value
	_patch.configure(current_value, goal_value, progress_ratio, is_completed, has_active_frontier)


func objective_label() -> Label:
	return _objective


func reward_cluster() -> HBoxContainer:
	return _reward_cluster


func territory_patch() -> Control:
	return _patch


## Exposes the rendered area math for monotonic presentation regression coverage.
func rendered_captured_area_ratio() -> float:
	return _patch.captured_area_ratio()


func _ensure_children() -> void:
	if _header != null:
		return
	custom_minimum_size = Vector2(0.0, 158.0)
	add_theme_constant_override("separation", 16)
	_header = HBoxContainer.new()
	_header.custom_minimum_size = Vector2(0.0, 34.0)
	_header.add_theme_constant_override("separation", 12)
	add_child(_header)
	_objective = Label.new()
	_objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_objective.clip_text = true
	_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective.add_theme_font_size_override("font_size", 22)
	_header.add_child(_objective)
	_reward_cluster = HBoxContainer.new()
	_reward_cluster.custom_minimum_size = Vector2(92.0, 34.0)
	_reward_cluster.add_theme_constant_override("separation", 5)
	_reward_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(_reward_cluster)
	var coin := BoostIcon.new()
	coin.set("effect", BoostData.Effect.COIN_BONUS)
	coin.custom_minimum_size = Vector2(27.0, 27.0)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reward_cluster.add_child(coin)
	_reward = Label.new()
	_reward.theme_type_variation = &"Coins"
	_reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_reward.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reward.add_theme_font_size_override("font_size", 20)
	_reward_cluster.add_child(_reward)
	_patch = TerritoryPatch.new()
	_patch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_patch)


class TerritoryPatch:
	extends Control

	const PALETTE = preload("res://config/palette.tres")
	const BORDER_WIDTH: float = 2.0
	const CORNER_RADIUS: float = 20.0
	const INNER_MARGIN: float = 3.0

	var _ratio: float = 0.0
	var _complete: bool = false
	var _frontier_active: bool = false
	var _current: int = 0
	var _goal: int = 0
	var _progress: Label
	var _check: Label
	var _background: StyleBoxFlat
	var _border: StyleBoxFlat


	func _init() -> void:
		custom_minimum_size = Vector2(510.0, 108.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_create_surface_style()
		_ensure_labels()


	func _ready() -> void:
		_ensure_labels()
		resized.connect(_on_resized)


	func configure(current: int, goal: int, ratio: float, complete: bool, frontier_active: bool) -> void:
		_current = current
		_goal = goal
		_ratio = ratio
		_complete = complete
		_frontier_active = frontier_active
		_ensure_labels()
		_progress.text = "%d / %d" % [_current, _goal]
		_check.text = "✓" if _complete else ""
		_on_resized()


	func captured_area_ratio() -> float:
		return _ratio


	func _create_surface_style() -> void:
		_background = StyleBoxFlat.new()
		_background.bg_color = _alpha(PALETTE.panel, 0.96)
		_background.set_corner_radius_all(int(CORNER_RADIUS))
		_border = StyleBoxFlat.new()
		_border.bg_color = Color.TRANSPARENT
		_border.border_color = _alpha(PALETTE.accent, 0.70)
		_border.set_border_width_all(int(BORDER_WIDTH))
		_border.set_corner_radius_all(int(CORNER_RADIUS))


	func _ensure_labels() -> void:
		if _progress != null:
			return
		_progress = Label.new()
		_progress.add_theme_font_size_override("font_size", 18)
		_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_progress)
		_check = Label.new()
		_check.add_theme_font_size_override("font_size", 25)
		_check.anchor_left = 0.77
		_check.anchor_top = 0.20
		_check.anchor_right = 0.91
		_check.anchor_bottom = 0.52
		_check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_check)


	func _on_resized() -> void:
		_layout_progress_label()
		queue_redraw()


	func _layout_progress_label() -> void:
		_progress.anchor_left = 0.38
		_progress.anchor_right = 0.62
		_progress.anchor_top = 0.56
		_progress.anchor_bottom = 0.86
		_progress.offset_left = 0.0
		_progress.offset_right = 0.0
		_progress.offset_top = 0.0
		_progress.offset_bottom = 0.0
		_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


	func _draw() -> void:
		var surface := Rect2(Vector2.ZERO, size)
		draw_style_box(_background, surface)
		var inner := surface.grow(-INNER_MARGIN)
		if _complete:
			_draw_complete_fill(inner)
		elif _ratio > 0.0:
			_draw_partial_capture(inner)
		draw_style_box(_border, surface)


	func _draw_complete_fill(inner: Rect2) -> void:
		var fill := StyleBoxFlat.new()
		fill.bg_color = _alpha(PALETTE.accent, 0.76)
		fill.set_corner_radius_all(int(maxf(CORNER_RADIUS - INNER_MARGIN, 1.0)))
		draw_style_box(fill, inner)


	func _draw_partial_capture(inner: Rect2) -> void:
		# Square-root extent lets captured territory grow in both axes while preserving ratio truth.
		var extent: float = sqrt(_ratio)
		var captured_size := Vector2(inner.size.x * extent, inner.size.y * extent)
		var captured := Rect2(inner.position.x, inner.end.y - captured_size.y, captured_size.x, captured_size.y)
		draw_colored_polygon(_captured_polygon(captured), _alpha(PALETTE.accent, 0.76))
		_draw_frontier(captured)


	func _captured_polygon(captured: Rect2) -> PackedVector2Array:
		var radius: float = minf(CORNER_RADIUS - INNER_MARGIN, minf(captured.size.x, captured.size.y))
		var points := PackedVector2Array([
			Vector2(captured.position.x, captured.position.y),
			Vector2(captured.end.x, captured.position.y),
			Vector2(captured.end.x, captured.end.y),
			Vector2(captured.position.x + radius, captured.end.y),
		])
		for index in 5:
			var angle: float = lerpf(PI * 0.5, PI, float(index) / 4.0)
			points.append(Vector2(captured.position.x + radius, captured.end.y - radius) + Vector2(cos(angle), sin(angle)) * radius)
		points.append(Vector2(captured.position.x, captured.position.y))
		return points


	func _draw_frontier(captured: Rect2) -> void:
		var corner := Vector2(captured.end.x, captured.position.y)
		var start := corner - Vector2(minf(captured.size.x - 2.0, 38.0), 0.0)
		var end := corner + Vector2(0.0, minf(captured.size.y - 2.0, 26.0))
		var color: Color = PALETTE.accent_alt.lightened(0.25)
		draw_line(start, corner, color, 2.0, true)
		draw_line(corner, end, color, 2.0, true)
		var radius := 5.0
		draw_colored_polygon(PackedVector2Array([
			corner + Vector2(0.0, -radius), corner + Vector2(radius, 0.0),
			corner + Vector2(0.0, radius), corner + Vector2(-radius, 0.0)
		]), PALETTE.accent.lightened(0.6))


	func _alpha(color: Color, alpha: float) -> Color:
		return Color(color.r, color.g, color.b, alpha)
