extends GutTest

## Settings UI wiring: panel instantiates, reflects current settings, and slider changes
## apply to AudioManager. (Actual audibility is verified by Tuğra once assets land.)

func test_panel_instantiates_and_reflects_settings() -> void:
	var panel: Node = load("res://scenes/ui/Settings.tscn").instantiate()
	add_child_autofree(panel)
	await get_tree().process_frame
	var master: HSlider = panel.get_node("Center/Rows/MasterRow/Slider")
	assert_almost_eq(master.value, AudioManager.settings().master, 0.0001)


func test_slider_change_applies_to_audiomanager() -> void:
	var panel: Node = load("res://scenes/ui/Settings.tscn").instantiate()
	add_child_autofree(panel)
	await get_tree().process_frame
	var sfx: HSlider = panel.get_node("Center/Rows/SfxRow/Slider")
	sfx.value = 0.25
	await get_tree().process_frame
	assert_almost_eq(AudioManager.settings().sfx, 0.25, 0.0001)
	# restore so other tests/sessions aren't affected by this in-memory change
	sfx.value = 1.0


func test_settings_locale_keys() -> void:
	assert_eq(tr("SETTINGS_TITLE"), "Settings")
	assert_eq(tr("SETTINGS_MUTE"), "Mute")
