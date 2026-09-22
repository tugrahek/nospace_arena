class_name LivingTerritory
extends Node

## Applies the captured territory's effect to enemies each physics frame.
## Loosely coupled: it reads the arena and enemy list; neither knows about it.
## Runs before enemies (negative process priority) so steering lands the same frame.

@export var effect: TerritoryEffect

var _arena: ArenaController
var _enemies: Array[Enemy] = []
var _player: Player = null
var _hunt_nearest: bool = false  # adaptive chaser rule for this stage/level (ChaserPolicy)


func _ready() -> void:
	process_priority = -10  # run before enemies move


func setup(arena: ArenaController, enemies: Array[Enemy], player: Player) -> void:
	_arena = arena
	_enemies = enemies
	_player = player


## Adaptive hunt (#19): resolved ONCE per stage/level by the game (ChaserPolicy) and handed down
## per frame, so the shared behavior resources never carry per-run state.
func set_hunt_nearest(enabled: bool) -> void:
	_hunt_nearest = enabled


## Per enemy, per physics frame (before they move): behavior decides the base velocity
## (homing/heading), then the territory effect is layered on top. Effects thus apply
## to every enemy type uniformly.
func _physics_process(_delta: float) -> void:
	if _arena == null or effect == null or _player == null or not GameState.is_playing():
		return
	var player_pos: Vector2 = _player.position
	var exposed: bool = _player.is_exposed()
	# Trail points cost one build per FRAME (shared by every hunter), and only while the adaptive
	# rule is on and the player is actually drawing. Off / safe / no hunters -> not built at all.
	var trail: PackedVector2Array = PackedVector2Array()
	if _hunt_nearest and exposed:
		trail = _player.trail_world_points()
	for enemy in _enemies:
		var base: Vector2 = enemy.decide_velocity(player_pos, exposed, trail, _hunt_nearest)
		enemy.apply_territory(effect, _arena, base)
