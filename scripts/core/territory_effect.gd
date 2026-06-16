class_name TerritoryEffect
extends Resource

## Base living-territory effect: captured territory influences nearby enemies.
## Two hooks keep heading changes (persistent) and speed changes (transient) from
## conflicting. No-op by default; concrete effects / Step 07 characters override one.

## Persistent heading change — returns a (same-magnitude) re-aimed velocity.
func steer(velocity: Vector2, _world_pos: Vector2, _arena: ArenaController) -> Vector2:
	return velocity


## Transient per-frame speed multiplier (1.0 = no change). Recomputed every frame,
## so it never compounds the stored velocity magnitude. Position-based only.
func speed_scale(_world_pos: Vector2, _arena: ArenaController) -> float:
	return 1.0


## Seconds to freeze an enemy when it bounces off PLAYER-captured territory.
## 0 = no contact freeze. Only Stasis overrides these.
func contact_freeze_duration() -> float:
	return 0.0


## Cooldown (s) after a contact freeze before another can trigger (anti re-lock).
func contact_freeze_cooldown() -> float:
	return 0.0
