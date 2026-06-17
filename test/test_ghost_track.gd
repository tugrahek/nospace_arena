extends GutTest

const GhostTrack = preload("res://scripts/meta/ghost_track.gd")


func test_empty_track() -> void:
	var t := GhostTrack.new()
	assert_true(t.is_empty())
	assert_eq(t.length_frames(), 0)
	assert_eq(t.position_at_frame(0), Vector2.ZERO)


func test_add_and_length() -> void:
	var t := GhostTrack.new()
	t.add_sample(Vector2(1, 2))
	t.add_sample(Vector2(3, 4))
	assert_eq(t.length_frames(), 2)
	assert_eq(t.position_at_frame(1), Vector2(3, 4))


func test_position_clamps_past_end() -> void:
	var t := GhostTrack.new()
	t.add_sample(Vector2(1, 1))
	t.add_sample(Vector2(5, 5))
	assert_eq(t.position_at_frame(99), Vector2(5, 5), "son örneğe clamp")
	assert_eq(t.position_at_frame(-3), Vector2(1, 1), "ilk örneğe clamp")


func test_array_round_trip() -> void:
	var t := GhostTrack.new()
	t.add_sample(Vector2(1.5, -2.0))
	t.add_sample(Vector2(10, 20))
	var restored := GhostTrack.from_array(t.to_array())
	assert_eq(restored.length_frames(), 2)
	assert_eq(restored.position_at_frame(0), Vector2(1.5, -2.0))
	assert_eq(restored.position_at_frame(1), Vector2(10, 20))
