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
	assert_eq(ContentCatalog.BOOSTS.size(), 2, "MVP: 2 boosts")
	assert_eq(ContentCatalog.boost_by_id(&"extra_life").cost, 150)
	assert_eq(ContentCatalog.boost_by_id(&"slow_start").cost, 120)
	assert_null(ContentCatalog.boost_by_id(&"nope"))


# --- Pure effect resolver ---

func test_resolve_applies_armed_owned() -> void:
	var armed := {"extra_life": true, "slow_start": true}
	var counts := {"extra_life": 2, "slow_start": 1}
	var r := BoostEffects.resolve(SeedManager.Mode.FREE, ContentCatalog.BOOSTS, armed, counts)
	assert_eq(r["extra_lives"], 1, "extra life magnitude")
	assert_eq(r["slow_scale"], 0.5, "slow start scale")
	assert_eq(r["slow_duration"], 5.0, "slow start duration")
	assert_eq(r["consume"].size(), 2, "both consumed")
	assert_eq(3 + int(r["extra_lives"]), 4, "start_lives + magnitude")


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
