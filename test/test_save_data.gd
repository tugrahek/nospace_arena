extends GutTest

const SaveData = preload("res://scripts/meta/save_data.gd")


func test_new_default_unlocks_baseline() -> void:
	var d := SaveData.new_default()
	assert_eq(d.currency, 0)
	assert_true(d.is_unlocked("character", &"pulse"))
	assert_true(d.is_unlocked("arena", &"void"))
	assert_false(d.is_unlocked("character", &"drag"), "diğerleri kilitli")


func test_earn_adds_currency() -> void:
	var d := SaveData.new()
	d.earn(120)
	assert_eq(d.currency, 120)


func test_earn_ignores_negative() -> void:
	var d := SaveData.new()
	d.currency = 50
	d.earn(-30)
	assert_eq(d.currency, 50, "negatif kazanç yok")


func test_spend_success() -> void:
	var d := SaveData.new()
	d.currency = 100
	assert_true(d.spend(40))
	assert_eq(d.currency, 60)


func test_spend_insufficient_fails() -> void:
	var d := SaveData.new()
	d.currency = 30
	assert_false(d.spend(100))
	assert_eq(d.currency, 30, "negatif bakiye imkânsız")


func test_spend_negative_rejected() -> void:
	var d := SaveData.new()
	d.currency = 30
	assert_false(d.spend(-10))
	assert_eq(d.currency, 30)


func test_can_afford() -> void:
	var d := SaveData.new()
	d.currency = 50
	assert_true(d.can_afford(50))
	assert_false(d.can_afford(51))
	assert_false(d.can_afford(-1))


func test_unlock_is_idempotent() -> void:
	var d := SaveData.new()
	d.unlock("character", &"drag")
	d.unlock("character", &"drag")
	assert_eq(d.unlocked["character"].size(), 1, "çift eklemez")
	assert_true(d.is_unlocked("character", &"drag"))


func test_round_trip_preserves_currency_and_unlocks() -> void:
	var d := SaveData.new_default()
	d.earn(250)
	d.unlock("arena", &"ember")
	var restored := SaveData.from_dict(d.to_dict())
	assert_eq(restored.currency, 250)
	assert_true(restored.is_unlocked("character", &"pulse"))
	assert_true(restored.is_unlocked("arena", &"ember"))
	assert_false(restored.is_unlocked("arena", &"frost"))


func test_default_selection() -> void:
	var d := SaveData.new_default()
	assert_eq(d.selected_character_id, "pulse")
	assert_eq(d.selected_arena_id, "void")


func test_round_trip_preserves_selection() -> void:
	var d := SaveData.new_default()
	d.selected_character_id = "halt"
	d.selected_arena_id = "frost"
	var restored := SaveData.from_dict(d.to_dict())
	assert_eq(restored.selected_character_id, "halt")
	assert_eq(restored.selected_arena_id, "frost")


func test_default_streak_state() -> void:
	var d := SaveData.new_default()
	assert_eq(d.last_claim_epoch_day, -1)
	assert_eq(d.streak_day, 0)


func test_round_trip_preserves_streak() -> void:
	var d := SaveData.new_default()
	d.last_claim_epoch_day = 20567
	d.streak_day = 4
	var restored := SaveData.from_dict(d.to_dict())
	assert_eq(restored.last_claim_epoch_day, 20567)
	assert_eq(restored.streak_day, 4)


func test_tutorial_seen_round_trip() -> void:
	var d := SaveData.new()
	assert_false(d.tutorial_seen, "default unseen")
	d.tutorial_seen = true
	assert_true(SaveData.from_dict(d.to_dict()).tutorial_seen)
	assert_false(SaveData.from_dict({}).tutorial_seen, "missing key -> false")
