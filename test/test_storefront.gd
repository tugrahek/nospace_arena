extends GutTest

const Storefront = preload("res://scripts/meta/storefront.gd")


func test_buyable_when_locked_and_affordable() -> void:
	assert_true(Storefront.can_purchase(false, 500, 300))


func test_exact_balance_is_affordable() -> void:
	assert_true(Storefront.can_purchase(false, 300, 300))


func test_not_buyable_when_already_unlocked() -> void:
	assert_false(Storefront.can_purchase(true, 999, 300))


func test_not_buyable_when_insufficient() -> void:
	assert_false(Storefront.can_purchase(false, 200, 300))


func test_negative_cost_rejected() -> void:
	assert_false(Storefront.can_purchase(false, 999, -10))
