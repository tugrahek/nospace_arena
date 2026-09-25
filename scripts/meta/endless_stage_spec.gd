class_name EndlessStageSpec
extends Resource

## One authored Level-Endless stage. Arena offset is resolved against the player's selected
## base arena; composition, effective enemy pace, and target remain identical for every base.

@export var arena_offset: int = 0
@export var enemies: Array[EnemyType] = []
@export var pace_scale: float = 1.0
@export var target_percent: float = 75.0
