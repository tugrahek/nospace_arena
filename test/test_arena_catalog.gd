extends GutTest

# arena_catalog.gd is dependency-free, so it's safe under GUT's isolated loader.
const ArenaCatalog = preload("res://scripts/meta/arena_catalog.gd")


# --- select (deterministic, seed mod count) ---

func test_select_zero_seed() -> void:
	assert_eq(ArenaCatalog.select(3, 0), 0)


func test_select_wraps_with_modulo() -> void:
	assert_eq(ArenaCatalog.select(3, 4), 1)


func test_select_handles_negative_seed() -> void:
	assert_eq(ArenaCatalog.select(3, -1), 2, "posmod ile negatif seed sarması")


func test_select_empty_catalog() -> void:
	assert_eq(ArenaCatalog.select(0, 5), -1)


func test_select_is_deterministic() -> void:
	assert_eq(ArenaCatalog.select(3, 7), ArenaCatalog.select(3, 7))


# --- compute_fit (fit-to-rect, centered) ---

func test_fit_matches_default_arena() -> void:
	var f: Dictionary = ArenaCatalog.compute_fit(64, 110, Rect2(40, 100, 640, 1100))
	assert_eq(f["cell_size"], 10.0, "64x110 tam oturur -> cell 10")
	assert_eq(f["origin"], Vector2(40, 100))


func test_fit_centers_smaller_grid() -> void:
	# 80x96 -> cs = floor(min(640/80=8, 1100/96=11.45)) = 8; grid 640x768; centered vertically
	var f: Dictionary = ArenaCatalog.compute_fit(80, 96, Rect2(40, 100, 640, 1100))
	assert_eq(f["cell_size"], 8.0)
	assert_eq(f["origin"], Vector2(40, 100 + (1100 - 768) / 2.0))


func test_fit_stays_within_play_rect() -> void:
	var rect := Rect2(40, 100, 640, 1100)
	var f: Dictionary = ArenaCatalog.compute_fit(56, 120, rect)
	var cs: float = f["cell_size"]
	assert_true(56 * cs <= rect.size.x, "genişlik sığmalı")
	assert_true(120 * cs <= rect.size.y, "yükseklik sığmalı")
