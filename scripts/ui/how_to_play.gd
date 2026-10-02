extends Control

## Four-page tutorial. The shared presentation changes topic; navigation and exit semantics stay local.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const PAGE_TITLE_KEYS := [
	"HOWTO_GOAL_TITLE", "HOWTO_CONTROLS_TITLE", "HOWTO_ENEMIES_TITLE", "HOWTO_LIVES_TITLE",
]
const PAGE_COUNT: int = 4

var _index: int = 0

@onready var _close: Button = $CloseButton
@onready var _context: Label = $SafeMargin/MainVBox/ContextLabel
@onready var _title: Label = $SafeMargin/MainVBox/PageTitle
@onready var _art: HowToPageArt = $SafeMargin/MainVBox/DemoCenter/PageArt
@onready var _body: Label = $SafeMargin/MainVBox/BodyCenter/BodyText
@onready var _progress: HowToPageProgress = $SafeMargin/MainVBox/ProgressCenter/TutorialProgress
@onready var _prev: Button = $SafeMargin/MainVBox/NavigationRow/PrevButton
@onready var _next: Button = $SafeMargin/MainVBox/NavigationRow/NextButton


func _ready() -> void:
	Economy.mark_tutorial_seen()
	_context.text = tr("HOWTO_TITLE")
	_prev.text = tr("SETTINGS_BACK")
	_close.pressed.connect(_exit)
	_prev.pressed.connect(_on_prev)
	_next.pressed.connect(_on_next)
	_show(0)


## Changes the shared page presentation without replacing the scene or altering navigation.
func _show(index: int) -> void:
	_index = clampi(index, 0, PAGE_COUNT - 1)
	_title.text = tr(String(PAGE_TITLE_KEYS[_index]))
	_body.text = _body_for_page(_index)
	_art.set_page_mode(_index)
	_progress.page_index = _index
	_prev.visible = _index > 0
	_next.text = tr("HOWTO_DONE") if _index == PAGE_COUNT - 1 else tr("HOWTO_NEXT")


func _body_for_page(index: int) -> String:
	match index:
		0:
			return tr("HOWTO_GOAL_BODY")
		1:
			return "%s\n%s\n%s\n%s" % [
				tr("HOWTO_CONTROLS_SWIPE"), tr("HOWTO_CONTROLS_TAP"),
				tr("HOWTO_CONTROLS_DPAD"), tr("HOWTO_CONTROLS_HINT"),
			]
		2:
			return tr("HOWTO_ENEMIES_BODY")
		3:
			return tr("HOWTO_LIVES_BODY")
	return ""


func _on_prev() -> void:
	_show(_index - 1)


func _on_next() -> void:
	if _index >= PAGE_COUNT - 1:
		_exit()
	else:
		_show(_index + 1)


func _exit() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
