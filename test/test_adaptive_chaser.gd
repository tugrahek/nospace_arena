extends GutTest

## Fix-pass #19 — adaptive chaser: where the difficulty curve calls for it, the Stalker aims at the
## nearest threat point (head OR the active trail) instead of only the head, so a long line is a
## real risk. Off everywhere else, and OFF byte-for-byte (regression guards below).

const JuiceMath = preload("res://scripts/fx/juice_math.gd")


func _arena() -> ArenaController:
	var a := ArenaController.new()
	add_child_autofree(a)
	a.configure(load("res://resources/arenas/arena_frost.tres"), Rect2(40, 100, 640, 1100))
	return a


func _chaser(arena: ArenaController, cell: Vector2i, velocity: Vector2 = Vector2(0, -150)) -> Enemy:
	var e := Enemy.new()
	e.shape = Enemy.Shape.TRIANGLE
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(cell), velocity, ChaserBehavior.new(), 150.0)
	return e


## A trail that runs far from the head: head high up, the line trailing down past the chaser.
func _trail(arena: ArenaController, from_y: int, to_y: int, x: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for y in range(from_y, to_y, -1):
		pts.append(arena.cell_to_world(Vector2i(x, y)))
	return pts


# --- Pure geometry ---

func test_closest_point_on_polyline() -> void:
	assert_eq(JuiceMath.closest_point_on_polyline(Vector2(5, 5), PackedVector2Array()), Vector2(5, 5),
		"empty polyline -> the point itself")
	assert_eq(JuiceMath.closest_point_on_polyline(Vector2(5, 5), PackedVector2Array([Vector2(1, 1)])),
		Vector2(1, 1), "single vertex -> that vertex")
	var line := PackedVector2Array([Vector2(0, 0), Vector2(10, 0)])
	assert_eq(JuiceMath.closest_point_on_polyline(Vector2(4, 7), line), Vector2(4, 0),
		"projects onto the segment")
	assert_eq(JuiceMath.closest_point_on_polyline(Vector2(-20, 3), line), Vector2(0, 0),
		"clamped to the near end")
	assert_eq(JuiceMath.closest_point_on_polyline(Vector2(99, -3), line), Vector2(10, 0),
		"clamped to the far end")
	var bent := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])
	assert_eq(JuiceMath.closest_point_on_polyline(Vector2(13, 6), bent), Vector2(10, 6),
		"picks the nearer of several segments")
	# The distance helper must agree with the point helper (shared segment math).
	var p := Vector2(4, 7)
	assert_almost_eq(JuiceMath.min_distance_to_polyline(p, line),
		p.distance_to(JuiceMath.closest_point_on_polyline(p, line)), 0.0001, "distance == |p - closest|")


# --- Policy ---

func test_policy_modes() -> void:
	var m := SeedManager.Mode
	assert_false(ChaserPolicy.hunts_nearest(m.FREE, true, 99, 0), "free is always off")
	assert_false(ChaserPolicy.hunts_nearest(m.DAILY, true, 99, 0), "daily is always off")
	assert_false(ChaserPolicy.hunts_nearest(999, true, 99, 0), "unknown mode -> off")
	assert_true(ChaserPolicy.hunts_nearest(m.CAMPAIGN, true, 0, 5), "campaign follows the level flag")
	assert_false(ChaserPolicy.hunts_nearest(m.CAMPAIGN, false, 99, 0), "unflagged level stays off")
	assert_false(ChaserPolicy.hunts_nearest(m.LEVEL_ENDLESS, false, 4, 5), "below the stage threshold")
	assert_true(ChaserPolicy.hunts_nearest(m.LEVEL_ENDLESS, false, 5, 5), "at the threshold")
	assert_true(ChaserPolicy.hunts_nearest(m.LEVEL_ENDLESS, false, 12, 5), "above the threshold")
	assert_false(ChaserPolicy.hunts_nearest(m.LEVEL_ENDLESS, false, 99, -1), "negative disables it")


func test_level_catalog_flags() -> void:
	# Authored curve: the rule joins at c09 and stays on to the finale.
	for i in ContentCatalog.LEVELS.size():
		var lvl: LevelData = ContentCatalog.LEVELS[i]
		if i >= 8:
			assert_true(lvl.chaser_hunts_nearest, "%s hunts the nearest threat" % lvl.id)
		else:
			assert_false(lvl.chaser_hunts_nearest, "%s keeps the classic head-hunt" % lvl.id)
	var progression: ProgressionConfig = load("res://config/progression.tres")
	assert_eq(progression.chaser_hunts_nearest_stage, 5, "endless threshold authored")


# --- Target selection ---

func test_off_keeps_the_classic_head_hunt() -> void:
	# Regression guard: with the rule off, a long trail right next to the chaser changes nothing.
	var arena := _arena()
	GameState.start_run(3)
	var c := _chaser(arena, Vector2i(20, 60))
	var head: Vector2 = arena.cell_to_world(Vector2i(20, 20))
	var trail: PackedVector2Array = _trail(arena, 61, 20, 22)  # passes right beside the chaser
	var classic: Vector2 = c.decide_velocity(head, true)
	assert_eq(c.decide_velocity(head, true, trail, false), classic, "flag off -> identical vector")
	assert_eq(c.decide_velocity(head, true, PackedVector2Array(), true), classic, "no trail -> identical")
	assert_false(bool(c.get("_hunting_trail")), "no trail-hunt state while off")
	GameState.reset()


func test_on_hunts_the_nearer_of_head_and_line() -> void:
	var arena := _arena()
	GameState.start_run(3)
	var c := _chaser(arena, Vector2i(20, 60))
	var head: Vector2 = arena.cell_to_world(Vector2i(20, 20))   # far above
	var trail: PackedVector2Array = _trail(arena, 61, 20, 24)   # nearby column, runs past the chaser
	var v: Vector2 = c.decide_velocity(head, true, trail, true)
	assert_gt(v.x, 0.0, "turns toward the nearby line (+x), not straight up to the head")
	assert_true(bool(c.get("_hunting_trail")), "trail-hunt tell is on")
	# Head closer than the line -> back to the head, tell clears.
	var near_head: Vector2 = arena.cell_to_world(Vector2i(20, 57))
	var far_trail: PackedVector2Array = _trail(arena, 30, 10, 60)
	var v2: Vector2 = c.decide_velocity(near_head, true, far_trail, true)
	assert_lt(v2.y, 0.0, "homes up to the head")
	assert_almost_eq(v2.x, 0.0, 1.0, "no sideways pull toward the distant line")
	assert_false(bool(c.get("_hunting_trail")), "tell cleared")
	GameState.reset()


func test_trail_bias_shifts_the_choice() -> void:
	var arena := _arena()
	GameState.start_run(3)
	var c := _chaser(arena, Vector2i(20, 60))
	var head: Vector2 = arena.cell_to_world(Vector2i(20, 52))   # 8 cells up
	var trail: PackedVector2Array = _trail(arena, 61, 50, 26)   # 6 cells sideways
	var behavior: ChaserBehavior = c.get("_behavior")
	behavior.trail_bias = 1.0
	c.decide_velocity(head, true, trail, true)
	assert_true(bool(c.get("_hunting_trail")), "pure distance -> the line wins")
	behavior.trail_bias = 2.0  # head wins while it is within 2x the line's distance
	c.decide_velocity(head, true, trail, true)
	assert_false(bool(c.get("_hunting_trail")), "bias > 1 favours the head")
	behavior.trail_bias = 0.5  # the line must be twice as close-ish -> it still wins here
	c.decide_velocity(head, true, trail, true)
	assert_true(bool(c.get("_hunting_trail")), "bias < 1 favours the line")
	GameState.reset()


func test_only_hunting_behaviors_pick_a_target() -> void:
	var arena := _arena()
	GameState.start_run(3)
	var e := Enemy.new()
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(20, 60)), Vector2(10, -150), BouncerBehavior.new(), 150.0)
	var head: Vector2 = arena.cell_to_world(Vector2i(20, 20))
	var trail: PackedVector2Array = _trail(arena, 61, 20, 22)
	assert_eq(e.decide_velocity(head, true, trail, true), Vector2(10, -150), "bouncer is unaffected")
	assert_false(bool(e.get("_hunting_trail")), "and never enters the trail-hunt state")
	GameState.reset()


# --- Line of sight on the CHOSEN target (#18 interaction) ---

func test_sight_is_tested_against_the_chosen_target() -> void:
	var arena := _arena()
	GameState.start_run(3)
	var g: CaptureGrid = arena.grid
	var wall: Array = []
	for x in range(1, 60):
		wall.append(Vector2i(x, 50))
	g.lay_trail(wall)
	g.close_and_capture([Vector2i(20, 30), Vector2i(20, 80)])
	# Non-axis-aligned start velocity: isolates "roam keeps its heading" from #20's axis-unstick.
	var c := _chaser(arena, Vector2i(20, 60), Vector2(-90, -120))
	var head: Vector2 = arena.cell_to_world(Vector2i(20, 20))  # behind the wall
	var trail: PackedVector2Array = _trail(arena, 45, 20, 24)  # ALSO behind the wall
	var before: Vector2 = c.get("_velocity")
	assert_eq(c.decide_velocity(head, true, trail, true), before,
		"chosen target behind the wall -> roam (no pinning, #18 preserved)")
	GameState.reset()


# --- Shared-resource leak guard (the critical trap) ---

func test_flag_never_leaks_through_the_shared_resource() -> void:
	# The rule travels as a per-frame argument. A campaign-style hunting frame must not change how
	# the SHARED type_chaser resource behaves in a later Free run.
	var arena := _arena()
	GameState.start_run(3)
	var shared: EnemyType = load("res://resources/enemies/type_chaser.tres")
	var e := Enemy.new()
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(20, 60)), Vector2(0, -150), shared.behavior, 150.0)
	var head: Vector2 = arena.cell_to_world(Vector2i(20, 20))
	var trail: PackedVector2Array = _trail(arena, 61, 20, 24)
	e.decide_velocity(head, true, trail, true)   # "campaign" frame: hunts the line
	assert_true(bool(e.get("_hunting_trail")), "hunted the line while the rule was on")
	var free_run: Vector2 = e.decide_velocity(head, true, trail, false)  # later Free run
	assert_false(bool(e.get("_hunting_trail")), "free run is back to the head-hunt")
	assert_eq(free_run, e.decide_velocity(head, true), "identical to a call with no trail at all")
	GameState.reset()


# --- Determinism ---

func test_same_setup_same_path() -> void:
	var arena := _arena()
	GameState.start_run(3)
	var effect := TerritoryEffect.new()
	var a := _chaser(arena, Vector2i(20, 60))
	var b := _chaser(arena, Vector2i(20, 60))
	var head: Vector2 = arena.cell_to_world(Vector2i(20, 20))
	var trail: PackedVector2Array = _trail(arena, 61, 20, 24)
	for f in 120:
		a.apply_territory(effect, arena, a.decide_velocity(head, true, trail, true))
		a._physics_process(1.0 / 60.0)
		b.apply_territory(effect, arena, b.decide_velocity(head, true, trail, true))
		b._physics_process(1.0 / 60.0)
	assert_eq(a.position, b.position, "identical setup -> identical path (no RNG)")
	assert_eq(a.get("_velocity"), b.get("_velocity"), "and identical velocity")
	GameState.reset()


func test_campaign_c09_run_enables_the_rule() -> void:
	# End to end: the real Game scene on c09 hands the rule to LivingTerritory; c01 does not.
	SeedManager.enter_campaign(8)
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	assert_true(bool(game.get_node("LivingTerritory").get("_hunt_nearest")), "c09 -> rule on")
	SeedManager.enter_campaign(0)
	var early: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(early)
	assert_false(bool(early.get_node("LivingTerritory").get("_hunt_nearest")), "c01 -> rule off")
	SeedManager.enter_free()
	var free_game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(free_game)
	assert_false(bool(free_game.get_node("LivingTerritory").get("_hunt_nearest")), "free -> rule off")
	GameState.reset()
