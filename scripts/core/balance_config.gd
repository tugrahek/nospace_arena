class_name BalanceConfig
extends Resource

## Central difficulty knobs (config/balance.tres). Sidegrade-neutral, never
## pay-to-win: only lives, enemy speed, and enemy count.

@export var start_lives: int = 3
@export var enemy_speed: float = 180.0
@export var enemy_count: int = 1
