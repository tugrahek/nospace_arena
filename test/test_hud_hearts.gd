extends GutTest

## 3-heart HUD + stage-clear flourish wiring (the feel/juice is verified by Tuğra).

func test_hearts_reflect_lives() -> void:
	var hud: Node = load("res://scenes/ui/HUD.tscn").instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	hud.call("setup", 3)
	var hearts: Node = hud.get_node("TopBar/Hearts")
	assert_eq(hearts.get("_max"), 3)
	assert_eq(hearts.get("_current"), 3)
	hud.call("_on_life_lost", 2)
	assert_eq(hearts.get("_current"), 2, "lost a heart")
	hud.call("_on_life_lost", 0)
	assert_eq(hearts.get("_current"), 0, "all hearts gone")


func test_stage_banner_runs() -> void:
	var hud: Node = load("res://scenes/ui/HUD.tscn").instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	hud.call("show_stage_banner", 3)  # must not error (tween + locale)
	await get_tree().process_frame
	assert_eq(tr("HUD_STAGE") % 3, "Stage 3")


func test_stage_clear_sfx_bound() -> void:
	assert_not_null(load("res://config/sound_bank.tres").sfx("stage_clear"))
