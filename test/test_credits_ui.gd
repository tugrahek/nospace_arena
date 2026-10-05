extends GutTest

## Covers the credits scene's content, localization, portrait layout, and route back.

const CREDITS_SCENE: PackedScene = preload("res://scenes/ui/Credits.tscn")
const MENU_SCENE_PATH: String = "res://scenes/main/MainMenu.tscn"

var _screen: Control
var _viewport: SubViewport


func before_each() -> void:
	TranslationServer.set_locale("en")
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(720, 1280)
	add_child_autofree(_viewport)
	_screen = CREDITS_SCENE.instantiate() as Control
	_viewport.add_child(_screen)
	await get_tree().process_frame
	await get_tree().process_frame


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_credits_scene_has_required_attribution_and_reachable_back() -> void:
	assert_eq(_label("Creator").text, "Tuğra Hekimoğlu")
	assert_true(_label("Technology").text.contains("Godot Engine 4.6"))
	assert_true(_label("Technology").text.contains("Tom 'Butch' Wesley"))
	assert_true(_label("Fonts").text.contains("OFL 1.1"))
	assert_true(_label("Fonts").text.contains("Tuğra Hekimoğlu"))
	assert_true(_label("Licenses").text.contains("MIT License"))
	var button: Button = _screen.get_node("SafeArea/Layout/BackButton") as Button
	assert_true(button.global_position.y + button.size.y <= 1280.0, "Back stays inside the portrait viewport")
	var constants: Dictionary = _screen.get_script().get_script_constant_map()
	assert_eq(constants["MENU_SCENE"], MENU_SCENE_PATH, "Back targets MainMenu")


func test_credits_localize_headings_and_back_in_english_and_turkish() -> void:
	assert_eq(_label("Title").text, "Credits")
	assert_eq(_screen.get_node("SafeArea/Layout/BackButton").text, "Back")
	TranslationServer.set_locale("tr")
	_screen.queue_free()
	_screen = CREDITS_SCENE.instantiate() as Control
	_viewport.add_child(_screen)
	await get_tree().process_frame
	assert_eq(_label("Title").text, "Künye")
	assert_eq(_label("CreatedHeading").text, "Geliştiren")
	assert_eq(_label("TechHeading").text, "Teknoloji")
	assert_eq(_screen.get_node("SafeArea/Layout/BackButton").text, "Geri")
	assert_true(_label("Fonts").text.contains("Ses efektleri"), "audio description localizes to Turkish")


func test_credits_content_fits_portrait_width_without_horizontal_overflow() -> void:
	var layout: VBoxContainer = _screen.get_node("SafeArea/Layout") as VBoxContainer
	assert_true(layout.size.x <= 720.0, "credits column remains within the viewport")
	for node: Node in layout.get_children():
		if node is Label:
			var label: Label = node as Label
			assert_true(label.size.x <= layout.size.x, "%s has no horizontal overflow" % label.name)
			assert_true(label.get_theme_font_size("font_size") >= 16, "%s remains readable" % label.name)


func _label(label_name: String) -> Label:
	return _screen.get_node("SafeArea/Layout/%s" % label_name) as Label
