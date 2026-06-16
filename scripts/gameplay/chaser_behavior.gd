class_name ChaserBehavior
extends "res://scripts/gameplay/enemy_behavior.gd"

## State-aware stalker: hunts the player ONLY while they are exposed (drawing a trail
## in the open) — homing straight in, since the target is then in free space (no wall to
## camp on). While the player is safe on captured territory it ROAMS (bouncer-like), so
## it never presses into the wall the player rests against.
## Pure: positions + player state (from input) only, no RNG -> ghost-safe / deterministic.

func decide(velocity: Vector2, enemy_pos: Vector2, player_pos: Vector2, player_exposed: bool, base_speed_px: float) -> Vector2:
	if not player_exposed:
		return velocity  # roam while the player is safe
	var to_player: Vector2 = player_pos - enemy_pos
	if to_player.length() < 0.001:
		return velocity
	return to_player.normalized() * base_speed_px
