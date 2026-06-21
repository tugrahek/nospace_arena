class_name BalanceConfig
extends Resource

## Global run knobs (config/balance.tres). Sidegrade-neutral, never pay-to-win.
## Per-arena difficulty (enemy composition, speed_mult, target_percent) lives in
## ArenaData; this holds only run-wide values.

@export var start_lives: int = 3
@export var base_points: int = 10
@export var combo_window: float = 2.0
@export var exposed_points_per_sec: float = 10.0  # score/sec while drawing in the open (risk)
@export var exposed_cap_sec: float = 10.0          # max exposed seconds counted per capture
@export var life_loss_penalty: int = 400           # score lost per life (floored at 0)
