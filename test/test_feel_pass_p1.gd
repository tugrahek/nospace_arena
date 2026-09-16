extends GutTest

## Feel-pass P1 (visual layer): enemy facing/breathing, campaign unlock celebration and combo
## escalation. Pure math is pinned here, plus the key invariant — the visual clock never changes
## gameplay (enemy position/velocity/heading identical with or without it).


# --- JuiceMath: facing ---

func test_turn_toward_converges() -> void:
	var a: float = 0.0
	for i in 60:
		a = JuiceMath.turn_toward(a, 1.0, 14.0, 1.0 / 60.0)
	assert_almost_eq(a, 1.0, 0.001, "eases onto the target heading")


func test_turn_toward_takes_shortest_arc_across_pi() -> void:
	# From just under +PI to just over -PI the short way is +0.2 rad (through PI), not -6.08.
	var a: float = JuiceMath.turn_toward(PI - 0.1, -PI + 0.1, 14.0, 1.0 / 60.0)
	assert_gt(a, PI - 0.1, "first step heads toward +PI (short arc), not back across zero")
	for i in 60:
		a = JuiceMath.turn_toward(a, -PI + 0.1, 14.0, 1.0 / 60.0)
	assert_lt(absf(angle_difference(a, -PI + 0.1)), 0.001, "settles on the target after wrapping")
	assert_between(a, -PI, PI, "angle stays wrapped (no unbounded drift)")


func test_turn_toward_zero_dt_and_snap() -> void:
	assert_almost_eq(JuiceMath.turn_toward(0.5, 2.0, 14.0, 0.0), 0.5, 0.00001, "dt=0 -> unchanged")
	assert_almost_eq(JuiceMath.turn_toward(0.5, 2.0, 0.0, 0.016), 2.0, 0.00001, "rate 0 -> snap")


# --- JuiceMath: combo ---

func test_combo_punch_x1_monotonic_clamped() -> void:
	assert_eq(JuiceMath.combo_punch(1, 1.25, 0.12, 1.8), 1.0, "x1 = no punch")
	assert_almost_eq(JuiceMath.combo_punch(2, 1.25, 0.12, 1.8), 1.25, 0.0001, "x2 = base")
	var prev: float = 1.0
	for m in range(2, 12):
		var p: float = JuiceMath.combo_punch(m, 1.25, 0.12, 1.8)
		assert_true(p >= prev, "x%d punch never shrinks" % m)
		assert_true(p <= 1.8, "x%d punch clamped" % m)
		prev = p
	assert_eq(JuiceMath.combo_punch(20, 1.25, 0.12, 1.8), 1.8, "long chain hits the ceiling")


func test_combo_heat_ramp() -> void:
	assert_eq(JuiceMath.combo_heat(1, 3, 5), 0.0)
	assert_eq(JuiceMath.combo_heat(2, 3, 5), 0.0, "below x3 -> no gold")
	var h3: float = JuiceMath.combo_heat(3, 3, 5)
	assert_true(h3 > 0.0 and h3 < 1.0, "x3 visibly starts warming")
	assert_true(JuiceMath.combo_heat(4, 3, 5) > h3, "x4 warmer")
	assert_eq(JuiceMath.combo_heat(5, 3, 5), 1.0, "x5 fully gold")
	assert_eq(JuiceMath.combo_heat(9, 3, 5), 1.0)


# --- Enemy determinism invariant ---

func _arena() -> ArenaController:
	var a := ArenaController.new()
	add_child_autofree(a)
	a.configure(load("res://resources/arenas/arena_void.tres"), Rect2(40, 100, 640, 1100))
	return a


func _chaser(arena: ArenaController) -> Enemy:
	var e := Enemy.new()
	e.shape = Enemy.Shape.TRIANGLE
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(20, 30)), Vector2(90, 40), ChaserBehavior.new(), 120.0, 0.3)
	return e


func _sparx(arena: ArenaController) -> Enemy:
	var e := Enemy.new()
	e.shape = Enemy.Shape.SQUARE
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(1, 1)), Vector2.ZERO, null, 200.0, 0.0, true, Vector2i(1, 1), Vector2i.DOWN)
	return e


func test_visual_clock_never_changes_gameplay() -> void:
	GameState.start_run(3)
	var arena := _arena()
	var effect := TerritoryEffect.new()  # base = no-op steer/scale
	var a := _chaser(arena)
	var b := _chaser(arena)
	var sa := _sparx(arena)
	var sb := _sparx(arena)
	var r0: float = a.radius
	var dt: float = 1.0 / 60.0
	for step in 240:
		var player: Vector2 = arena.cell_to_world(Vector2i(40, 60 + (step % 20)))
		a.apply_territory(effect, arena, a.decide_velocity(player, true))
		b.apply_territory(effect, arena, b.decide_velocity(player, true))
		a._physics_process(dt)
		b._physics_process(dt)
		sa._physics_process(dt)
		sb._physics_process(dt)
		# Only B-side enemies get the visual clock, at uneven render deltas.
		b._process(dt * (0.5 + float(step % 3)))
		sb._process(0.033)
	assert_eq(a.position, b.position, "chaser position identical with/without the visual clock")
	assert_eq(a.get("_velocity"), b.get("_velocity"), "chaser velocity identical")
	assert_eq(sa.position, sb.position, "sparx position identical")
	assert_eq(sa.get("_heading"), sb.get("_heading"), "sparx heading identical")
	assert_eq(b.rotation, 0.0, "node transform untouched (paint-space rotation only)")
	assert_eq(sb.rotation, 0.0, "sparx node transform untouched")
	assert_eq(b.radius, r0, "collision radius untouched")
	assert_ne(float(b.get("_visual_angle")), float(a.get("_visual_angle")), "only the clocked chaser's paint turned")
	GameState.reset()


func test_bouncer_breath_draw_only() -> void:
	GameState.start_run(3)
	var arena := _arena()
	var e := Enemy.new()
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(20, 30)), Vector2(80, 60), BouncerBehavior.new(), 100.0)
	var r0: float = e.radius
	e._process(0.5)
	assert_gt(float(e.get("_breath_t")), 0.0, "breath clock advances")
	assert_eq(e.radius, r0, "breathing never touches the collision radius")
	assert_eq(float(e.get("_visual_angle")), 0.0, "circles don't rotate")
	GameState.reset()


# --- Campaign unlock detection ---

func test_frontier() -> void:
	var levels := ContentCatalog.LEVELS
	assert_eq(CampaignStars.frontier([], {}), -1, "no levels -> -1")
	assert_eq(CampaignStars.frontier(levels, {}), 0, "no progress -> first level")
	var stars := {String(levels[0].id): 1, String(levels[1].id): 2}
	assert_eq(CampaignStars.frontier(levels, stars), 2, "chain: L1+L2 cleared -> L3 open")
	var all := {}
	for l in levels:
		all[String(l.id)] = 3
	assert_eq(CampaignStars.frontier(levels, all), levels.size() - 1, "all cleared -> last level")


func test_newly_unlocked_only_when_frontier_grows() -> void:
	var levels := ContentCatalog.LEVELS
	var id0: StringName = levels[0].id
	assert_eq(CampaignStars.newly_unlocked(levels, {}, id0, 1), 1, "first clear opens L2")
	assert_eq(CampaignStars.newly_unlocked(levels, {}, id0, 0), -1, "a failed run opens nothing")
	var cleared := {String(id0): 1}
	assert_eq(CampaignStars.newly_unlocked(levels, cleared, id0, 3), -1, "star improvement: no new unlock")
	assert_eq(CampaignStars.newly_unlocked(levels, cleared, id0, 1), -1, "replay: no new unlock")
	assert_eq(cleared, {String(id0): 1}, "input stars not modified (pure)")


func test_consume_pending_unlock_clears() -> void:
	Economy.set("_pending_unlock", 4)
	assert_eq(Economy.consume_pending_unlock(), 4, "pending index returned")
	assert_eq(Economy.consume_pending_unlock(), -1, "consumed -> celebrates once")


# --- Level map celebration ---

func _level_select() -> Control:
	var s: Control = load("res://scenes/ui/LevelSelect.tscn").instantiate()
	s.unlock_delay = 0.01
	return s


func test_level_select_consumes_pending_and_celebrates_index() -> void:
	Economy.set("_pending_unlock", 0)  # level 1 is always unlocked (save-state independent)
	var s := _level_select()
	add_child_autofree(s)
	assert_eq(int(s.get("_celebrate_index")), 0, "celebrates the pending level")
	assert_eq(Economy.consume_pending_unlock(), -1, "map consumed the marker")
	var tween: Tween = s.get("_celebrate_tween")
	assert_true(tween != null and tween.is_valid(), "celebration tween running")


func test_level_select_no_pending_no_celebration() -> void:
	Economy.set("_pending_unlock", -1)
	var s := _level_select()
	add_child_autofree(s)
	assert_eq(int(s.get("_celebrate_index")), -1, "nothing pending -> no celebration")


func test_press_during_celebration_stops_it() -> void:
	Economy.set("_pending_unlock", 0)
	var s := _level_select()
	add_child_autofree(s)
	var node: Button = (s.get("_nodes") as Array)[0]
	var tween: Tween = s.get("_celebrate_tween")
	tween.custom_step(0.05)  # deterministic: past the delay, pop mid-flight (headless frame deltas vary)
	assert_true(node.has_theme_stylebox_override("normal"), "glow applied during the pop")
	assert_lt(node.scale.x, 1.0, "pop still growing")
	node.button_down.emit()  # JuicyButton's own press pop takes over
	assert_false(tween.is_valid(), "celebration tween killed (no two tweens on scale)")
	assert_false(node.has_theme_stylebox_override("normal"), "glow cleared")
	for i in 120:  # JuicyButton's press pop (0.16s) runs on real frames
		if is_equal_approx(node.scale.x, 1.0):
			break
		await get_tree().process_frame
	assert_almost_eq(node.scale.x, 1.0, 0.001, "press pop settles at 1.0")


# --- Combo readouts ---

func test_hud_combo_escalates_and_warms() -> void:
	var hud: CanvasLayer = load("res://scenes/ui/HUD.tscn").instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var label: Label = hud.get_node("ComboLabel")
	hud.call("_on_score_changed", 10, 1)  # x2
	var s2: float = label.scale.x
	var c2: Color = label.get_theme_color("font_color")
	hud.call("_on_score_changed", 20, 4)  # x5
	var s5: float = label.scale.x
	var c5: Color = label.get_theme_color("font_color")
	assert_gt(s5, s2, "x5 punches harder than x2")
	var palette: PaletteData = load("res://config/palette.tres")
	assert_true(c2.is_equal_approx(palette.accent), "x2 stays accent")
	assert_true(c5.is_equal_approx(palette.coin), "x5 is gold")
	label.scale = Vector2.ONE
	hud.call("_on_score_changed", 20, 4)  # same combo re-emitted (e.g. life lost) -> no re-punch
	assert_eq(label.scale.x, 1.0, "no punch unless the chain grows")


func test_floating_score_x1_unchanged_and_escalates() -> void:
	# Not added to the tree: _ready's self-animating/self-freeing tween is not under test.
	var scene: PackedScene = load("res://scenes/fx/FloatingScore.tscn")
	var p1: Label = autofree(scene.instantiate())
	p1.show_value(50, Color.RED)
	assert_almost_eq(p1.start_scale(), p1.punch_scale, 0.0001, "x1 punch = original")
	assert_true(p1.get_theme_color("font_color").is_equal_approx(Color.RED), "x1 color = original")
	var p5: Label = autofree(scene.instantiate())
	p5.show_value(50, Color.RED, 5)
	assert_gt(p5.start_scale(), p1.start_scale(), "x5 popup punches bigger")
	var palette: PaletteData = load("res://config/palette.tres")
	assert_true(p5.get_theme_color("font_color").is_equal_approx(palette.coin), "x5 popup is gold")
