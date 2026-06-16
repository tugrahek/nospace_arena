class_name BalanceConfig
extends Resource

## Global run knobs (config/balance.tres). Sidegrade-neutral, never pay-to-win.
## Per-arena difficulty (enemy composition, speed_mult, target_percent) lives in
## ArenaData; this holds only run-wide values.

@export var start_lives: int = 3
@export var base_points: int = 10
@export var combo_window: float = 2.0
