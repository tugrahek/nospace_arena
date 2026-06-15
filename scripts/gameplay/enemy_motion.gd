class_name EnemyMotion
extends RefCounted

## Pure motion math for enemies — no scene / grid dependencies, fully testable.


## Reflects velocity on the blocked axes (wall bounce).
static func reflect(velocity: Vector2, block_x: bool, block_y: bool) -> Vector2:
	var v: Vector2 = velocity
	if block_x:
		v.x = -v.x
	if block_y:
		v.y = -v.y
	return v


## Deterministic starting velocity for enemy `index` at `speed` (no RNG).
## Varies direction per index so multiple enemies diverge. Step 09 seed will
## later drive this; the signature stays the same.
static func start_velocity(index: int, speed: float) -> Vector2:
	var dirs: Array[Vector2] = [
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1),
	]
	return dirs[index % dirs.size()].normalized() * speed
