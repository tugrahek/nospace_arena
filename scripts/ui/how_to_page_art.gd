class_name HowToPageArt
extends Control

## Four static gameplay freeze-frames. All geometry is recomputed from this Control's local size.

const ENEMY_COLOR: Color = Color(1.0, 0.45, 0.45, 1.0)  # Void arena enemy color.
const CAPTURED_COLOR: Color = Color(0.12, 0.5, 0.95, 0.55)  # ArenaController default.
const NEW_CAPTURE_COLOR: Color = Color(0.20, 0.85, 0.98, 0.74)
const ARENA_VOID: Color = Color(0.03, 0.02, 0.08, 1.0)
const ARENA_BORDER: Color = Color(0.25, 0.65, 1.0, 1.0)
const PLAYER_COLOR: Color = Color(0.2, 0.95, 1.0, 1.0)
const TRAIL_COLOR: Color = Color(1.0, 0.45, 0.85, 1.0)

enum PageMode { CAPTURE, MOVE, ENEMIES, LIVES }

@export var page_mode: PageMode = PageMode.CAPTURE:
	set(value):
		page_mode = value
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)


## Keeps scene control and drawing state in sync without cached geometry.
func set_page_mode(value: int) -> void:
	page_mode = clampi(value, 0, PageMode.size() - 1) as PageMode


## Returns the arena's actual local rectangle, inset from the current canvas size.
func get_arena_rect() -> Rect2:
	return Rect2(Vector2(20.0, 20.0), Vector2(maxf(0.0, size.x - 40.0), maxf(0.0, size.y - 40.0)))


## The draw path consumes this same scene data, so tests can inspect the depicted mechanics.
func get_composition() -> Dictionary:
	var arena: Rect2 = get_arena_rect()
	var scene: Dictionary = {
		"arena": arena, "captured": [], "newly_captured": Rect2(),
		"trail": PackedVector2Array(),
		"reconnect": PackedVector2Array(), "directions": PackedVector2Array(),
		"player": arena.get_center(), "enemies": [], "hearts": 0,
	}
	match page_mode:
		PageMode.CAPTURE:
			_setup_capture(scene, arena)
		PageMode.MOVE:
			_setup_move(scene, arena)
		PageMode.ENEMIES:
			_setup_enemies(scene, arena)
		PageMode.LIVES:
			_setup_lives(scene, arena)
	return scene


func _setup_capture(scene: Dictionary, arena: Rect2) -> void:
	scene["captured"] = [
		Rect2(_point(arena, 0.02, 0.76), arena.size * Vector2(0.96, 0.22)),
		Rect2(_point(arena, 0.02, 0.43), arena.size * Vector2(0.20, 0.33)),
	]
	# The brighter interior previews the territory gained when the trail reconnects.
	scene["newly_captured"] = Rect2(_point(arena, 0.34, 0.22), arena.size * Vector2(0.38, 0.54))
	var trail := PackedVector2Array([
		_point(arena, 0.34, 0.76), _point(arena, 0.34, 0.22),
		_point(arena, 0.72, 0.22), _point(arena, 0.72, 0.65),
	])
	scene["trail"] = trail
	scene["player"] = trail[-1]
	scene["reconnect"] = PackedVector2Array([trail[-1], _point(arena, 0.72, 0.76)])


func _setup_move(scene: Dictionary, arena: Rect2) -> void:
	var player: Vector2 = _point(arena, 0.50, 0.46)
	scene["captured"] = [Rect2(_point(arena, 0.02, 0.79), arena.size * Vector2(0.96, 0.19))]
	scene["player"] = player
	scene["directions"] = PackedVector2Array([Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN])
	scene["trail"] = PackedVector2Array([
		_point(arena, 0.30, 0.79), _point(arena, 0.30, 0.61),
		_point(arena, 0.50, 0.61), player,
	])


func _setup_enemies(scene: Dictionary, arena: Rect2) -> void:
	var player: Vector2 = _point(arena, 0.39, 0.43)
	scene["captured"] = [Rect2(_point(arena, 0.02, 0.77), arena.size * Vector2(0.96, 0.21))]
	scene["player"] = player
	scene["trail"] = PackedVector2Array([_point(arena, 0.39, 0.77), player])
	scene["enemies"] = [
		{"type": &"bouncer", "position": _point(arena, 0.78, 0.27), "scale": 1.15},
		{"type": &"chaser", "position": _point(arena, 0.70, 0.60), "scale": 1.15},
		{"type": &"sparx", "position": _point(arena, 0.14, 0.77), "scale": 1.15},
	]


func _setup_lives(scene: Dictionary, arena: Rect2) -> void:
	var player: Vector2 = _point(arena, 0.39, 0.28)
	scene["captured"] = [Rect2(_point(arena, 0.02, 0.77), arena.size * Vector2(0.96, 0.21))]
	scene["player"] = player
	scene["trail"] = PackedVector2Array([_point(arena, 0.39, 0.77), player])
	scene["enemies"] = [{"type": &"bouncer", "position": _point(arena, 0.43, 0.52)}]
	scene["hearts"] = 3


func _draw() -> void:
	var scene: Dictionary = get_composition()
	var arena: Rect2 = scene["arena"]
	if arena.size.x <= 0.0 or arena.size.y <= 0.0:
		return
	draw_rect(arena, ARENA_VOID)
	for region: Rect2 in scene["captured"]:
		draw_rect(region, CAPTURED_COLOR)
	var new_region: Rect2 = scene["newly_captured"]
	if new_region.has_area():
		draw_rect(new_region, NEW_CAPTURE_COLOR)
	var reconnect: PackedVector2Array = scene["reconnect"]
	if reconnect.size() == 2:
		_draw_reconnect(reconnect)
	var trail: PackedVector2Array = scene["trail"]
	if trail.size() >= 2:
		_draw_trail(trail)
	for direction: Vector2 in scene["directions"]:
		_draw_movement_cue(scene["player"], direction, arena)
	for enemy: Dictionary in scene["enemies"]:
		_draw_enemy(enemy, scene["player"])
	if scene["hearts"] > 0:
		_draw_hearts(arena, scene["hearts"])
	_draw_player(scene["player"])
	_draw_border(arena)


func _point(arena: Rect2, x: float, y: float) -> Vector2:
	return arena.position + arena.size * Vector2(x, y)


func _draw_border(arena: Rect2) -> void:
	draw_polyline(PackedVector2Array([
		arena.position, Vector2(arena.end.x, arena.position.y), arena.end,
		Vector2(arena.position.x, arena.end.y), arena.position,
	]), ARENA_BORDER, 4.0, true)


func _draw_trail(points: PackedVector2Array) -> void:
	draw_polyline(points, Color(TRAIL_COLOR, 0.22), 10.0, true)
	draw_polyline(points, TRAIL_COLOR, 5.0, true)


func _draw_reconnect(points: PackedVector2Array) -> void:
	var midpoint: Vector2 = points[0].lerp(points[1], 0.5)
	var hint: Color = Color(TRAIL_COLOR, 0.46)
	draw_line(points[0], midpoint - Vector2(0.0, 4.0), hint, 3.0, true)
	draw_line(midpoint + Vector2(0.0, 4.0), points[1], hint, 3.0, true)


func _draw_player(center: Vector2) -> void:
	var radius: float = 14.0
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-radius, 0.0), center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0), center + Vector2(0.0, radius),
	]), PLAYER_COLOR)


func _draw_movement_cue(center: Vector2, direction: Vector2, arena: Rect2) -> void:
	var tip: Vector2 = center + direction * minf(arena.size.y * 0.27, 75.0)
	var start: Vector2 = center + direction * 26.0
	var side: Vector2 = Vector2(-direction.y, direction.x) * 7.0
	draw_line(start, tip, Color(PLAYER_COLOR, 0.76), 3.0, true)
	draw_line(tip, tip - direction * 12.0 + side, Color(PLAYER_COLOR, 0.76), 3.0, true)
	draw_line(tip, tip - direction * 12.0 - side, Color(PLAYER_COLOR, 0.76), 3.0, true)


func _draw_enemy(enemy: Dictionary, player: Vector2) -> void:
	var center: Vector2 = enemy["position"]
	var scale_factor: float = enemy.get("scale", 1.0)
	match enemy["type"]:
		&"bouncer":
			draw_circle(center, 19.0 * scale_factor, ENEMY_COLOR)
		&"chaser":
			var forward: Vector2 = (player - center).normalized()
			var side: Vector2 = Vector2(-forward.y, forward.x)
			draw_colored_polygon(PackedVector2Array([
				center + forward * (23.0 * scale_factor),
				center - forward * (15.0 * scale_factor) + side * (17.0 * scale_factor),
				center - forward * (15.0 * scale_factor) - side * (17.0 * scale_factor),
			]), ENEMY_COLOR)
		&"sparx":
			draw_set_transform(center, PI * 0.25)
			var radius: float = 15.0 * scale_factor
			draw_rect(Rect2(Vector2(-radius, -radius), Vector2.ONE * radius * 2.0), ENEMY_COLOR)
			draw_set_transform(Vector2.ZERO, 0.0)


func _draw_hearts(arena: Rect2, count: int) -> void:
	for index in count:
		var center: Vector2 = _point(arena, 0.075 + index * 0.075, 0.14)
		var color: Color = Color(ENEMY_COLOR, 0.18) if index == count - 1 else ENEMY_COLOR
		var points := PackedVector2Array()
		for point_index in 32:
			var t: float = TAU * float(point_index) / 32.0
			var x: float = 16.0 * pow(sin(t), 3.0)
			var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
			points.append(center + Vector2(x * 0.72, -(y + 6.0) * 0.72))
		draw_colored_polygon(points, color)
