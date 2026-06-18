class_name NearMiss
extends Node

## Watches the nearest enemy ↔ trail SEGMENT distance while the player is drawing (exposed).
## Two outputs, independent:
##  - `danger_changed(level)` every frame: a CONTINUOUS 0..1 proximity level (drives the
##    vignette, which darkens as an enemy nears the trail). 0 while safe.
##  - `near_miss()`: a DISCRETE event when an enemy is within `radius` (cooldown-gated;
##    drives the one-shot slow-mo).
## Distance is to the trail segments (not just the head), so a foe grazing the line counts.

signal near_miss()
signal danger_changed(level: float)

@export var radius: float = 28.0          # px from the trail that triggers the slow-mo
@export var slow_scale: float = 0.45      # time_scale during the slow-mo
@export var slow_duration: float = 0.18   # real seconds of slow-mo
@export var cooldown: float = 0.6         # seconds before another slow-mo can fire
@export var vignette_radius: float = 98.4 # distance the vignette begins (> radius, so it
                                          # ramps up BEFORE the slow-mo triggers)

var _player: Player = null
var _enemies: Array = []
var _cool: float = 0.0


func setup(player: Player, enemies: Array) -> void:
	_player = player
	_enemies = enemies


func _physics_process(delta: float) -> void:
	if _cool > 0.0:
		_cool -= delta
	var danger: float = 0.0
	if _player != null and _player.is_exposed() and GameState.is_playing():
		var trail: PackedVector2Array = _player.trail_world_points()
		if not trail.is_empty():
			var nearest: float = INF
			for e in _enemies:
				nearest = minf(nearest, JuiceMath.min_distance_to_polyline(e.position, trail))
			danger = JuiceMath.danger_from_distance(nearest, vignette_radius)
			# Discrete slow-mo: separate channel, cooldown-gated.
			if _cool <= 0.0 and nearest <= radius:
				_cool = cooldown
				near_miss.emit()
	danger_changed.emit(danger)
