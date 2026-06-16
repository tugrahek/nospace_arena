class_name LivingTerritory
extends Node

## Applies the captured territory's effect to enemies each physics frame.
## Loosely coupled: it reads the arena and enemy list; neither knows about it.
## Runs before enemies (negative process priority) so steering lands the same frame.

@export var effect: TerritoryEffect

var _arena: ArenaController
var _enemies: Array[Enemy] = []
var _player: Player = null


func _ready() -> void:
	process_priority = -10  # run before enemies move


func setup(arena: ArenaController, enemies: Array[Enemy], player: Player) -> void:
	_arena = arena
	_enemies = enemies
	_player = player


## Per enemy, per physics frame (before they move): behavior decides the base velocity
## (homing/heading), then the territory effect is layered on top. Effects thus apply
## to every enemy type uniformly.
func _physics_process(_delta: float) -> void:
	if _arena == null or effect == null or _player == null or not GameState.is_playing():
		return
	var player_pos: Vector2 = _player.position
	var exposed: bool = _player.is_exposed()
	for enemy in _enemies:
		var base: Vector2 = enemy.decide_velocity(player_pos, exposed)
		enemy.apply_territory(effect, _arena, base)
