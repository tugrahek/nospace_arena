extends GutTest

# Loads the effect resources at runtime (engine classes are registered by then),
# verifying the contact-freeze contract: only Stasis (Halt) freezes on contact.


func test_push_has_no_contact_freeze() -> void:
	var e = load("res://config/default_territory.tres")
	assert_eq(e.contact_freeze_duration(), 0.0, "Push temasta dondurmaz")


func test_drag_has_no_contact_freeze() -> void:
	var e = load("res://config/slow_territory.tres")
	assert_eq(e.contact_freeze_duration(), 0.0, "Drag temasta dondurmaz")


func test_stasis_contact_freeze_duration() -> void:
	# Tuned value (playtest): short freeze so enemies can't be pinned.
	var e = load("res://config/stasis_territory.tres")
	assert_almost_eq(e.contact_freeze_duration(), 0.12, 0.0001)


func test_stasis_contact_freeze_cooldown() -> void:
	var e = load("res://config/stasis_territory.tres")
	assert_almost_eq(e.contact_freeze_cooldown(), 0.5, 0.0001)
