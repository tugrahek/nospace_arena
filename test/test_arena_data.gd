extends GutTest

# Loads arena resources at runtime (engine classes registered by then) and checks
# they are valid and distinct — catches broken .tres / missing theme refs.

const ARENAS := [
	"res://resources/arenas/arena_void.tres",
	"res://resources/arenas/arena_ember.tres",
	"res://resources/arenas/arena_frost.tres",
]


func test_arenas_are_valid() -> void:
	for path in ARENAS:
		var a = load(path)
		assert_gt(a.cols, 2, "%s cols" % path)
		assert_gt(a.rows, 2, "%s rows" % path)
		assert_gt(a.enemies.size(), 0, "%s boş olmayan kompozisyon" % path)
		assert_gt(a.speed_mult, 0.0, "%s speed_mult" % path)
		assert_not_null(a.theme, "%s theme ref" % path)
		for t in a.enemies:
			assert_not_null(t, "%s EnemyType null değil" % path)
			assert_not_null(t.behavior, "%s behavior null değil" % path)


func test_arenas_are_distinct() -> void:
	var ids := {}
	for path in ARENAS:
		var a = load(path)
		assert_false(ids.has(a.id), "id benzersiz olmalı: %s" % a.id)
		ids[a.id] = true
	assert_eq(ids.size(), ARENAS.size())
