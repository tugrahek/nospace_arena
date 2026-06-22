extends Control

## How-to-play carousel (4 pages, each with a motoriçi visual): goal, controls (ALL schemes),
## enemies, lives. Shown automatically once on first launch and from the "?" icon. A persistent
## "X" exits to the menu from any page. Marks the tutorial seen on entry (auto-show happens once).

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const DOT_ON: Color = Color(0.3, 0.95, 1.0, 1.0)
const DOT_OFF: Color = Color(0.6, 0.58, 0.7, 0.5)

var _index: int = 0
var _pages: Array[Control] = []
var _dots: Array[Label] = []

@onready var _close: Button = $CloseButton
@onready var _screen_title: Label = $Center/ScreenTitle
@onready var _goal: VBoxContainer = $Center/GoalPage
@onready var _controls: VBoxContainer = $Center/ControlsPage
@onready var _enemies: VBoxContainer = $Center/EnemiesPage
@onready var _lives: VBoxContainer = $Center/LivesPage
@onready var _dots_box: HBoxContainer = $Center/Dots
@onready var _prev: Button = $Center/Nav/PrevButton
@onready var _next: Button = $Center/Nav/NextButton


func _ready() -> void:
	Economy.mark_tutorial_seen()  # entry -> seen once (auto-show + early exit both count)
	_pages = [_goal, _controls, _enemies, _lives]
	_screen_title.text = tr("HOWTO_TITLE")
	_apply_texts()
	($Center/LivesPage/Hearts as HeartsHud).set_max(3)
	_build_dots()
	_close.pressed.connect(_exit)
	_prev.pressed.connect(_on_prev)
	_next.pressed.connect(_on_next)
	_show(0)


## All page text from locale (controls page lists ALL three schemes, not the active one).
func _apply_texts() -> void:
	_goal.get_node("Title").text = tr("HOWTO_GOAL_TITLE")
	_goal.get_node("Body").text = tr("HOWTO_GOAL_BODY")
	_controls.get_node("Title").text = tr("HOWTO_CONTROLS_TITLE")
	_controls.get_node("SwipeRow/Label").text = tr("HOWTO_CONTROLS_SWIPE")
	_controls.get_node("TapRow/Label").text = tr("HOWTO_CONTROLS_TAP")
	_controls.get_node("DpadRow/Label").text = tr("HOWTO_CONTROLS_DPAD")
	_controls.get_node("Hint").text = tr("HOWTO_CONTROLS_HINT")
	_enemies.get_node("Title").text = tr("HOWTO_ENEMIES_TITLE")
	_enemies.get_node("EnemyRow/BouncerCol/Name").text = tr("ENEMY_BOUNCER_NAME")
	_enemies.get_node("EnemyRow/StalkerCol/Name").text = tr("ENEMY_STALKER_NAME")
	_enemies.get_node("EnemyRow/SparxCol/Name").text = tr("ENEMY_SPARX_NAME")
	_enemies.get_node("Body").text = tr("HOWTO_ENEMIES_BODY")
	_lives.get_node("Title").text = tr("HOWTO_LIVES_TITLE")
	_lives.get_node("Body").text = tr("HOWTO_LIVES_BODY")


func _build_dots() -> void:
	for p in _pages.size():
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 18)
		_dots_box.add_child(dot)
		_dots.append(dot)


func _show(i: int) -> void:
	_index = clampi(i, 0, _pages.size() - 1)
	for p in _pages.size():
		_pages[p].visible = p == _index
	for d in _dots.size():
		_dots[d].add_theme_color_override("font_color", DOT_ON if d == _index else DOT_OFF)
	_prev.visible = _index > 0
	_next.text = tr("HOWTO_DONE") if _index == _pages.size() - 1 else tr("HOWTO_NEXT")


func _on_prev() -> void:
	_show(_index - 1)


func _on_next() -> void:
	if _index >= _pages.size() - 1:
		_exit()
	else:
		_show(_index + 1)


func _exit() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
