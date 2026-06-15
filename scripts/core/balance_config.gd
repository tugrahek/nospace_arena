class_name BalanceConfig
extends Resource

## Central difficulty knobs (config/balance.tres). Sidegrade-neutral, never
## pay-to-win: only lives, enemy params, and win/score parameters.

@export var start_lives: int = 3
@export var enemy_speed: float = 180.0
@export var enemy_count: int = 1
@export var target_percent: float = 75.0
@export var base_points: int = 10
@export var combo_window: float = 2.0
