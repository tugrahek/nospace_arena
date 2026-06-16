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
		assert_gte(a.enemy_count, 1, "%s enemy_count" % path)
		assert_gt(a.enemy_speed_cells, 0.0, "%s speed" % path)
		assert_not_null(a.theme, "%s theme ref" % path)


func test_arenas_are_distinct() -> void:
	var ids := {}
	for path in ARENAS:
		var a = load(path)
		assert_false(ids.has(a.id), "id benzersiz olmalı: %s" % a.id)
		ids[a.id] = true
	assert_eq(ids.size(), ARENAS.size())
