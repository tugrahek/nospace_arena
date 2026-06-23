class_name BoostData
extends Resource

## A pre-run consumable boost (coin sink). Bought with coins, armed before a run, and consumed
## at run start when the play mode allows it (see BoostPolicy). Data-driven so adding boosts is a
## new .tres + a catalog entry — no code. Sidegrade/forgiveness only, never raw power (pay-to-win
## safe; disabled in Daily for leaderboard fairness).

enum Effect {
	EXTRA_LIFE,   # magnitude = extra starting lives
	SLOW_START,   # magnitude = enemy speed scale (0..1) for `duration` seconds at run start
	COIN_BONUS,   # magnitude = extra fraction of run-end coins (0.5 -> +50%, i.e. x1.5)
}

@export var id: StringName
@export var display_name_key: String  # locale key (player-facing name)
@export var description_key: String   # locale key (one-line description)
@export var cost: int = 0             # coin price per charge
@export var effect: Effect = Effect.EXTRA_LIFE
@export var magnitude: float = 1.0    # EXTRA_LIFE: extra lives; SLOW_START: speed scale (0..1)
@export var duration: float = 0.0     # SLOW_START: seconds; unused by EXTRA_LIFE
