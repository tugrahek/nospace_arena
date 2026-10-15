extends Control

## Four-page tutorial. The shared presentation changes topic; navigation and exit semantics stay local.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const PAGE_TITLE_KEYS := [
	"HOWTO_GOAL_TITLE", "HOWTO_CONTROLS_TITLE", "HOWTO_ENEMIES_TITLE", "HOWTO_LIVES_TITLE",
]
const PAGE_COUNT: int = 4
const MAX_CONTENT_WIDTH: float = 800.0
const TouchTargets = preload("res://scripts/ui/touch_target_sizing.gd")
const ART_SIZE: Vector2 = Vector2(540.0, 350.0)
const BODY_WIDTH: float = 520.0
const CLOSE_ICON_SIZE: Vector2 = Vector2(64.0, 64.0)
@export var minimum_section_gap: int = 18

var _index: int = 0
var _layout_pending: bool = false

@onready var _close: Button = $SafeArea/Bounds/CloseButton
@onready var _close_icon: Control = $SafeArea/Bounds/CloseButton/Icon
@onready var _bounds: Control = $SafeArea/Bounds
@onready var _main_vbox: VBoxContainer = $SafeArea/Bounds/MainVBox
@onready var _content_scroll: ScrollContainer = $SafeArea/Bounds/MainVBox/ContentScroll
@onready var _page_content: VBoxContainer = $SafeArea/Bounds/MainVBox/ContentScroll/PageContent
@onready var _navigation: HBoxContainer = $SafeArea/Bounds/MainVBox/NavigationRow
@onready var _title: Label = $SafeArea/Bounds/MainVBox/ContentScroll/PageContent/PageTitle
@onready var _art: HowToPageArt = $SafeArea/Bounds/MainVBox/ContentScroll/PageContent/DemoCenter/PageArt
@onready var _body: Label = $SafeArea/Bounds/MainVBox/ContentScroll/PageContent/BodyCenter/BodyText
@onready var _progress: HowToPageProgress = $SafeArea/Bounds/MainVBox/ContentScroll/PageContent/ProgressCenter/TutorialProgress
@onready var _prev: Button = $SafeArea/Bounds/MainVBox/NavigationRow/PrevButton
@onready var _next: Button = $SafeArea/Bounds/MainVBox/NavigationRow/NextButton


func _ready() -> void:
	_close_icon.set_anchors_preset(Control.PRESET_CENTER)
	_close_icon.offset_left = -CLOSE_ICON_SIZE.x * 0.5
	_close_icon.offset_right = CLOSE_ICON_SIZE.x * 0.5
	_close_icon.offset_top = -CLOSE_ICON_SIZE.y * 0.5
	_close_icon.offset_bottom = CLOSE_ICON_SIZE.y * 0.5
	for button: Button in [_close, _prev, _next]:
		TouchTargets.attach(button)
	_bounds.resized.connect(_queue_layout)
	_content_scroll.resized.connect(_queue_layout)
	_content_scroll.get_v_scroll_bar().visibility_changed.connect(_queue_layout)
	_page_content.minimum_size_changed.connect(_queue_layout)
	_navigation.minimum_size_changed.connect(_queue_layout)
	_queue_layout()
	Economy.mark_tutorial_seen()
	_prev.text = tr("SETTINGS_BACK")
	_close.pressed.connect(_exit)
	_prev.pressed.connect(_on_prev)
	_next.pressed.connect(_on_next)
	_show(0)


func _queue_layout() -> void:
	if _layout_pending or not is_inside_tree():
		return
	_layout_pending = true
	_refresh_layout.call_deferred()


func _refresh_layout() -> void:
	_layout_pending = false
	var width: float = minf(_bounds.size.x, MAX_CONTENT_WIDTH)
	_main_vbox.offset_left = -width * 0.5
	_main_vbox.offset_right = width * 0.5
	if _content_scroll.size.x <= 0.0:
		return
	var scrollbar: VScrollBar = _content_scroll.get_v_scroll_bar()
	var available_width: float = maxf(0.0, minf(width, _content_scroll.size.x) - (scrollbar.size.x if scrollbar.visible else 0.0))
	var art_width: float = minf(ART_SIZE.x, available_width)
	_art.custom_minimum_size = Vector2(art_width, art_width * ART_SIZE.y / ART_SIZE.x)
	_body.custom_minimum_size.x = minf(BODY_WIDTH, available_width)
	_distribute_height()


## Share spare portrait height between sections; short screens retain minimum gaps and scrolling.
func _distribute_height() -> void:
	var usable_height: float = _bounds.size.y + _main_vbox.offset_bottom - _main_vbox.offset_top
	var sections_height: float = 0.0
	for section: Control in _page_content.get_children():
		sections_height += section.get_combined_minimum_size().y
	var gap_count: int = _page_content.get_child_count()
	var gap: int = maxi(minimum_section_gap, floori((usable_height - sections_height
		- _navigation.get_combined_minimum_size().y) / float(gap_count)))
	_main_vbox.add_theme_constant_override("separation", gap)
	_page_content.add_theme_constant_override("separation", gap)
	var available_height: float = maxf(0.0, usable_height - _navigation.get_combined_minimum_size().y
		- float(_main_vbox.get_theme_constant("separation")))
	_content_scroll.custom_minimum_size.y = minf(_page_content.get_combined_minimum_size().y, available_height)


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
