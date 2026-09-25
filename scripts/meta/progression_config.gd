class_name ProgressionConfig
extends Resource

## Tunable knobs for the Level-Endless stage progression (D1=A). Data, not code — edit
## config/progression.tres in the inspector. Caps keep escalation from breaking at very high
## stages. (Daily is single-arena — the multi-stage daily was rolled back in 18a.)

@export var speed_ramp_per_stage: float = 0.12  # +12% enemy speed per stage (multiplicative cap below)
@export var speed_cap: float = 2.5            # max speed scale (plateau)
@export var enemy_add_every: int = 2          # +1 enemy every N stages
@export var enemy_cap_bonus: int = 4          # max extra enemies over the arena's base composition
@export var target_ramp_per_stage: float = 2.0  # +2% capture target per stage
@export var target_cap: float = 90.0          # max capture target (%)
## Adaptive chaser (#19): from this 0-based stage on, Stalkers hunt the nearest threat point
## (head OR active trail) instead of just the head. Negative disables it for the whole run.
@export var chaser_hunts_nearest_stage: int = 5

## Fix-pass #22: authored onboarding followed by an anchored procedural Endless ramp. These
## values are read only by StagePlan.compute_endless; Free, Daily, and Campaign keep their paths.
@export var early_stages: Array[EndlessStageSpec] = []
@export var late_enemy_add_every: int = 3
@export var late_enemy_cap: int = 2
@export var late_add_order: Array[EnemyType] = []
@export var late_speed_ramp: float = 0.03
@export var late_speed_cap: float = 1.75
@export var late_target_ramp: float = 1.0
@export var late_target_cap: float = 90.0
