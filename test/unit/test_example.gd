extends GutTest

## Sanity test — verifies GUT is installed and functional.


func test_gut_is_working() -> void:
	assert_eq(1 + 1, 2, "Basic arithmetic")
	assert_true(true, "True is true")
	assert_false(false, "False is false")
