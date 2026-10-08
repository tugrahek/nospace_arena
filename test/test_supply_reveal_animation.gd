extends "res://test/helpers/supply_acquisition_fixture.gd"

const SCENE: PackedScene = preload("res://scenes/ui/SupplyPopup.tscn")


func _popup() -> SupplyPopup:
	var popup: SupplyPopup = SCENE.instantiate()
	popup.economy = _economy
	popup.ads = _ads
	popup.acquisition = _acquisition
	popup.core = _economy.supply_boxes()
	add_child_autofree(popup)
	return popup


func test_reveal_animation_reopens_same_durable_result_without_mutating_model_or_rng() -> void:
	_ads.set_requests_allowed(false)
	var result: Dictionary = _acquisition.purchase_coin_box("animation", _day[0])
	assert_true(result["delivered"])
	var before: Dictionary = _economy._data.to_dict()
	var rng_state: int = _economy.supply_boxes()._rng.state
	var popup: SupplyPopup = _popup()
	assert_gte(popup.reveal_duration, 0.4)
	assert_lte(popup.reveal_duration, 0.7)
	popup.present()
	await wait_process_frames(2)
	assert_eq(_economy._data.to_dict(), before)
	assert_eq(_economy.supply_boxes()._rng.state, rng_state)
	var reward_text: String = popup._reward.text
	popup.free()
	var reopened: SupplyPopup = _popup()
	reopened.present()
	assert_eq(reopened._reward.text, reward_text)
	assert_eq(reopened.revealed_box_id, result["box_id"])
	assert_eq(_economy._data.to_dict(), before)
	reopened.close()
	assert_eq(_economy.supply_boxes().box_status(result["box_id"])["state"], "delivered")
	assert_eq(_economy.balance(), int(before["currency"]))
	assert_eq(_economy._data.boost_charges, before["boost_charges"])
	assert_eq(_economy.supply_boxes()._rng.state, rng_state)
