class_name LivingTerritory
extends Node

## Applies the captured territory's effect to enemies each physics frame.
## Loosely coupled: it reads the arena and enemy list; neither knows about it.
## Runs before enemies (negative process priority) so steering lands the same frame.

@export var effect: TerritoryEffect

var _arena: ArenaController
var _enemies: Array[Enemy] = []


func _ready() -> void:
	process_priority = -10  # apply steering before enemies move


func setup(arena: ArenaController, enemies: Array[Enemy]) -> void:
	_arena = arena
	_enemies = enemies


func _physics_process(_delta: float) -> void:
	if _arena == null or effect == null or not GameState.is_playing():
		return
	for enemy in _enemies:
		enemy.apply_territory(effect, _arena)
