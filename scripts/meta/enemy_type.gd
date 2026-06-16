class_name EnemyType
extends Resource

## A spawnable enemy archetype: its movement behavior + base speed + placeholder
## shape. Color comes from the arena theme (Step 08); shape distinguishes types
## (placeholder until Step 14 sprites). base_speed is grid-relative (cells/s).

@export var id: StringName
@export var behavior: EnemyBehavior
@export var base_speed_cells: float = 18.0
@export_enum("Circle", "Triangle") var shape: int = 0
