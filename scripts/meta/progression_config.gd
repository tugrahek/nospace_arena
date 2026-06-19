class_name ProgressionConfig
extends Resource

## Tunable knobs for the stage progression (D1=A). Data, not code — edit config/progression.tres
## in the inspector. Caps keep escalation from breaking at very high stages (endless free-play).

@export var daily_stage_count: int = 6       # daily gauntlet length (clear all = win)
@export var speed_ramp_per_stage: float = 0.12  # +12% enemy speed per stage (multiplicative cap below)
@export var speed_cap: float = 2.5            # max speed scale (plateau)
@export var enemy_add_every: int = 2          # +1 enemy every N stages
@export var enemy_cap_bonus: int = 4          # max extra enemies over the arena's base composition
@export var target_ramp_per_stage: float = 2.0  # +2% capture target per stage
@export var target_cap: float = 90.0          # max capture target (%)
