class_name GhostTrack
extends RefCounted

## Recorded player path for ghost playback: one position sample per physics frame.
## Playback is frame-indexed (no resimulation) — the ghost is a visual overlay, so no
## determinism requirement. Pure (serialization + clamp), GUT-testable.

var samples: Array[Vector2] = []


func add_sample(pos: Vector2) -> void:
	samples.append(pos)


func is_empty() -> bool:
	return samples.is_empty()


func length_frames() -> int:
	return samples.size()


## Position at frame i, clamped to the last sample (ghost holds on its final pose).
func position_at_frame(i: int) -> Vector2:
	if samples.is_empty():
		return Vector2.ZERO
	return samples[clampi(i, 0, samples.size() - 1)]


## Flat [x, y, x, y, ...] for compact JSON storage.
func to_array() -> Array:
	var a: Array = []
	for s in samples:
		a.append(s.x)
		a.append(s.y)
	return a


static func from_array(a: Array) -> GhostTrack:
	var t := GhostTrack.new()
	var i: int = 0
	while i + 1 < a.size():
		t.samples.append(Vector2(a[i], a[i + 1]))
		i += 2
	return t
