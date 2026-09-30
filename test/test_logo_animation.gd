extends GutTest

const Logo = preload("res://scripts/ui/logo.gd")


func test_logo_intro_reaches_locked_final_state_without_restarting() -> void:
	var logo: Control = Logo.new()
	logo.trail_reveal_duration = 0.0
	logo.diamond_settle_duration = 0.0
	logo.custom_minimum_size = Vector2(190.0, 190.0)
	add_child_autofree(logo)
	logo.play_intro()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(logo.intro_started())
	assert_true(logo.intro_finished())
	assert_eq(logo.trail_progress(), 1.0)
	assert_eq(logo._glow_strength, 0.0, "static final state must not retain a diamond halo")
	assert_eq(logo._diamond_scale, 1.0, "diamond returns to its canonical gameplay scale")
	logo.play_intro()
	assert_eq(logo.trail_progress(), 1.0, "same Logo instance must not restart")


func test_logo_path_tip_draws_vertical_before_continuous_corner_and_horizontal() -> void:
	var logo: Control = Logo.new()
	var start := Vector2(40.0, 10.0)
	var corner := Vector2(40.0, 70.0)
	var endpoint := Vector2(140.0, 70.0)
	var corner_progress := start.distance_to(corner) / (start.distance_to(corner) + corner.distance_to(endpoint))
	var vertical_tip: Vector2 = logo.path_tip(start, corner, endpoint, corner_progress * 0.5)
	var transition_tip: Vector2 = logo.path_tip(start, corner, endpoint, corner_progress)
	var horizontal_tip: Vector2 = logo.path_tip(start, corner, endpoint, (corner_progress + 1.0) * 0.5)
	assert_eq(vertical_tip.x, start.x, "first segment remains vertically aligned")
	assert_between(vertical_tip.y, start.y, corner.y)
	assert_eq(transition_tip, corner, "path reaches the shared corner without a jump")
	assert_eq(horizontal_tip.y, corner.y, "second segment remains horizontally aligned")
	assert_gt(horizontal_tip.x, corner.x)
	logo.free()
