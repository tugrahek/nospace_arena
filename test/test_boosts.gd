extends GutTest

## Step 20a: boost data + policy + pure effect resolver + SaveData persistence (no UI, no game wiring).

const SaveData = preload("res://scripts/meta/save_data.gd")


# --- Policy (central hook) ---

func test_policy_daily_off() -> void:
	assert_false(BoostPolicy.boosts_allowed(SeedManager.Mode.DAILY), "Daily -> boosts off")


func test_policy_free_and_endless_on() -> void:
	assert_true(BoostPolicy.boosts_allowed(SeedManager.Mode.FREE))
	assert_true(BoostPolicy.boosts_allowed(SeedManager.Mode.LEVEL_ENDLESS))


func test_policy_unknown_mode_default_on() -> void:
	# Campaign-ready: a future mode the enum doesn't have yet defaults ON (hook is ready).
	assert_true(BoostPolicy.boosts_allowed(99), "unknown/future mode -> default on")


# --- Catalog wiring ---

func test_catalog_has_boosts() -> void:
	assert_eq(ContentCatalog.BOOSTS.size(), 3, "MVP: 3 boosts")
	assert_eq(ContentCatalog.boost_by_id(&"extra_life").cost, 250)
	assert_eq(ContentCatalog.boost_by_id(&"coin_bonus").cost, 200)
	assert_eq(ContentCatalog.boost_by_id(&"slow_start").cost, 180)
	assert_null(ContentCatalog.boost_by_id(&"nope"))


# --- Pure effect resolver ---

func test_resolve_applies_armed_owned() -> void:
	var armed := {"extra_life": true, "slow_start": true}
	var counts := {"extra_life": 2, "slow_start": 1}
	var r := BoostEffects.resolve(SeedManager.Mode.FREE, ContentCatalog.BOOSTS, armed, counts)
	assert_eq(r["extra_lives"], 1, "extra life magnitude")
	assert_eq(r["slow_scale"], 0.5, "slow start scale")
	assert_eq(r["slow_duration"], 3.0, "slow start duration (tuned to 3s)")
	assert_eq(r["consume"].size(), 2, "both consumed")
	assert_eq(3 + int(r["extra_lives"]), 4, "start_lives + magnitude")


func test_resolve_coin_bonus() -> void:
	var r := BoostEffects.resolve(SeedManager.Mode.FREE, ContentCatalog.BOOSTS,
		{"coin_bonus": true}, {"coin_bonus": 1})
	assert_almost_eq(float(r["coin_multiplier"]), 1.5, 0.001, "coin bonus -> x1.5")
	assert_eq(r["consume"].size(), 1)
	assert_eq(int(round(100 * float(r["coin_multiplier"]))), 150, "100 coins -> 150")
	# Daily ignores it -> multiplier stays 1.0, nothing consumed.
	var d := BoostEffects.resolve(SeedManager.Mode.DAILY, ContentCatalog.BOOSTS,
		{"coin_bonus": true}, {"coin_bonus": 1})
	assert_almost_eq(float(d["coin_multiplier"]), 1.0, 0.001, "no coin bonus in Daily")
	assert_eq(d["consume"].size(), 0)


func test_resolve_daily_applies_nothing() -> void:
	var armed := {"extra_life": true, "slow_start": true}
	var counts := {"extra_life": 2, "slow_start": 1}
	var r := BoostEffects.resolve(SeedManager.Mode.DAILY, ContentCatalog.BOOSTS, armed, counts)
	assert_eq(r["extra_lives"], 0, "no effect in Daily")
	assert_eq(r["slow_scale"], 1.0)
	assert_eq(r["consume"].size(), 0, "no charge consumed in Daily")


func test_resolve_skips_unowned_or_unarmed() -> void:
	var only_armed := BoostEffects.resolve(SeedManager.Mode.FREE, ContentCatalog.BOOSTS,
		{"extra_life": true}, {"extra_life": 0})  # armed but 0 charges
	assert_eq(only_armed["extra_lives"], 0)
	assert_eq(only_armed["consume"].size(), 0)
	var only_owned := BoostEffects.resolve(SeedManager.Mode.FREE, ContentCatalog.BOOSTS,
		{}, {"extra_life": 5})  # owned but not armed
	assert_eq(only_owned["extra_lives"], 0)
	assert_eq(only_owned["consume"].size(), 0)


# --- SaveData persistence (pure) ---

func test_savedata_charges_add_consume() -> void:
	var d := SaveData.new()
	d.add_boost(&"extra_life", 2)
	assert_eq(d.boost_count(&"extra_life"), 2)
	assert_true(d.consume_boost(&"extra_life"))
	assert_eq(d.boost_count(&"extra_life"), 1)
	assert_false(d.consume_boost(&"slow_start"), "none owned -> cannot consume")


func test_savedata_arm_disarm() -> void:
	var d := SaveData.new()
	d.set_boost_armed(&"extra_life", true)
	assert_true(d.is_boost_armed(&"extra_life"))
	d.set_boost_armed(&"extra_life", true)  # idempotent
	assert_eq(d.armed_boosts.size(), 1)
	d.set_boost_armed(&"extra_life", false)
	assert_false(d.is_boost_armed(&"extra_life"))


## Smoke: the boost-touching UI scenes instantiate + run _ready without runtime errors (build the
## Store boost rows and the ModeSelect arm strip against live Economy/ContentCatalog).
func test_store_scene_instantiates() -> void:
	var s: Control = load("res://scenes/ui/Store.tscn").instantiate()
	add_child_autofree(s)
	assert_not_null(s, "Store builds (boost section included)")


func test_mode_select_scene_instantiates() -> void:
	var s: Control = load("res://scenes/ui/ModeSelect.tscn").instantiate()
	add_child_autofree(s)
	assert_not_null(s, "ModeSelect builds (arm strip included)")


## Slow Start mechanism: run_speed_scale scales actual travel (game sets it from the boost).
func test_run_speed_scale_slows_enemy() -> void:
	var arena := ArenaController.new()
	add_child_autofree(arena)
	arena.configure(load("res://resources/arenas/arena_frost.tres"), Rect2(40, 100, 640, 1100))
	GameState.start_run(3)
	var c: Vector2 = arena.get_rect().get_center()
	var vel: Vector2 = Vector2(1, 0) * (8.0 * arena.cell_size)
	var fast := Enemy.new()
	add_child_autofree(fast)
	fast.setup(arena, c, vel, null, 8.0 * arena.cell_size)
	var slow := Enemy.new()
	add_child_autofree(slow)
	slow.setup(arena, c, vel, null, 8.0 * arena.cell_size)
	slow.run_speed_scale = 0.5
	var f0: Vector2 = fast.position
	var s0: Vector2 = slow.position
	for i in 10:
		fast._physics_process(0.02)
		slow._physics_process(0.02)
	var fd: float = fast.position.distance_to(f0)
	var sd: float = slow.position.distance_to(s0)
	assert_gt(fd, 0.0, "fast enemy moved")
	assert_almost_eq(sd, fd * 0.5, fd * 0.15, "run_speed_scale=0.5 halves travel")
	GameState.reset()


func test_savedata_boost_round_trip() -> void:
	var d := SaveData.new_default()
	d.add_boost(&"extra_life", 3)
	d.add_boost(&"slow_start", 1)
	d.set_boost_armed(&"slow_start", true)
	var r := SaveData.from_dict(d.to_dict())
	assert_eq(r.boost_count(&"extra_life"), 3)
	assert_eq(r.boost_count(&"slow_start"), 1)
	assert_true(r.is_boost_armed(&"slow_start"))
	assert_false(r.is_boost_armed(&"extra_life"))
