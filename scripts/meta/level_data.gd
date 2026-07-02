class_name LevelData
extends Resource

## One authored Campaign level: a single arena challenge with an explicit enemy composition,
## target, lives, and boost policy. Content, not code -- the difficulty curve lives in the ordered
## ContentCatalog.LEVELS list. Deterministic (fixed composition; spawn is index/seed-derived, no RNG).

@export var id: StringName
@export var description_key: String              # locale key: one-line "what's different / the goal"
@export var arena: ArenaData                    # grid shape + theme (visuals)
@export var enemies: Array[EnemyType] = []      # explicit composition (overrides the arena default)
@export var target_percent: float = 60.0        # capture % to clear the level (1 star)
@export var lives: int = 3
@export var boosts_allowed: bool = true         # read by BoostPolicy in CAMPAIGN mode
@export var speed_mult: float = 1.0             # per-level pace (enemy cells/s modifier)
@export var star2_score: int = 0                # score for the 2nd star (0 disables)
@export var star3_percent: float = 0.0          # capture % for the 3rd star (0 disables)
