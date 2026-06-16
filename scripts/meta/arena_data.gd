class_name ArenaData
extends Resource

## A playable arena: logical grid shape + theme + difficulty. Content, not code.
## Pixels are derived by fit-to-rect at runtime (ArenaController.configure), so the
## same grid fits any screen. enemy_speed is grid-relative (cells/s) so threat is
## consistent regardless of the fitted cell_size.
## Obstacles are a future mini-step; the seam is ready (capture percent already uses
## the interior capturable area, which would simply exclude obstacle cells).

@export var id: StringName
@export var display_name_key: String
@export var cols: int = 64  # logical grid incl. the 1-cell frame ring
@export var rows: int = 110
@export var theme: ThemeData
@export var enemy_count: int = 1
@export var enemy_speed_cells: float = 18.0  # cells/second (px/s = ×cell_size at runtime)
@export var target_percent: float = 75.0
@export var unlock_cost: int = 0  # Step 13 reserved
