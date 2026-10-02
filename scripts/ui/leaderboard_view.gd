extends Control

## Local daily leaderboard view: your best score per day, ranked high→low. The top three
## receive a restrained hierarchy; today's real entry gets a small diamond marker.
## Read-only — loads LeaderboardStore; no game logic. Online + Free/Level high scores are v1.1.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const LEADERBOARD_PATH: String = "user://leaderboard.json"
const MAX_ROWS: int = 60

const TodayMarker = preload("res://scripts/ui/leaderboard_today_marker.gd")

const GOLD: Color = Color(1.0, 0.82, 0.32, 1.0)
const SILVER: Color = Color(0.85, 0.88, 0.95, 1.0)
const BRONZE: Color = Color(0.85, 0.55, 0.35, 1.0)
const MUTED: Color = Color(0.74, 0.72, 0.84, 1.0)
const TOP_SURFACE: Color = Color(0.18, 0.15, 0.32, 0.9)

@onready var _title: Label = $Layout/Title
@onready var _all_best: Label = $Layout/Scroll/Content/AllBest
@onready var _list: VBoxContainer = $Layout/Scroll/Content/List
@onready var _empty: Label = $EmptyLabel
@onready var _back: Button = $Layout/BackButton


func _ready() -> void:
	_title.text = tr("LEADERBOARD_TITLE")
	_back.text = tr("SETTINGS_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	_populate()


func _populate() -> void:
	var lb: Leaderboard = LeaderboardStore.load_from(LEADERBOARD_PATH)
	_render_leaderboard(lb, SeedManager.compute_today())


## Binds persisted daily scores to view-only rows; tests may pass an in-memory board.
func _render_leaderboard(lb: Leaderboard, today: int) -> void:
	for child: Node in _list.get_children():
		child.free()
	var scores: Dictionary = lb.scores()
	var best: int = lb.best_ever()

	if best >= 0:
		_all_best.text = tr("LEADERBOARD_ALLBEST") % best
		_all_best.visible = true
	else:
		_all_best.visible = false

	# Rank high→low (tie-break: newer date first).
	var rows: Array = []
	for date in scores:
		rows.append({"date": int(date), "score": int(scores[date])})
	rows.sort_custom(func(a, b) -> bool:
		if a["score"] != b["score"]:
			return a["score"] > b["score"]
		return a["date"] > b["date"])

	if rows.is_empty():
		_empty.text = tr("LEADERBOARD_EMPTY")
		_empty.visible = true
		return
	_empty.visible = false

	for i in mini(rows.size(), MAX_ROWS):
		_add_entry(i + 1, int(rows[i]["date"]), int(rows[i]["score"]), today)


## Displays the full YYYYMMDD leaderboard key in locale order; no date semantics are inferred.
static func format_date(date_int: int) -> String:
	var y: int = date_int / 10000
	var m: int = (date_int / 100) % 100
	var d: int = date_int % 100
	var months: PackedStringArray = TranslationServer.translate(&"MONTHS_SHORT").split(",")
	var mon: String = months[clampi(m - 1, 0, months.size() - 1)] if months.size() >= 12 else str(m)
	if TranslationServer.get_locale().begins_with("tr"):
		return "%d %s %d" % [d, mon, y]
	return "%s %d, %d" % [mon, d, y]


## Builds a single flat score row, with one prominent surface for the actual first place.
func _add_entry(rank: int, date: int, score: int, today: int) -> void:
	var row := HBoxContainer.new()
	row.name = "Content"
	row.custom_minimum_size.y = 88.0 if rank == 1 else (74.0 if rank <= 3 else 58.0)
	row.add_theme_constant_override("separation", 14)
	if rank == 1:
		var rail := ColorRect.new()
		rail.color = GOLD
		rail.custom_minimum_size = Vector2(3.0, 66.0)
		row.add_child(rail)

	row.add_child(_rank_label(rank))
	if date == today:
		row.add_child(_today_marker())
	row.add_child(_date_label(date))
	row.add_child(_score_label(score, rank))
	var entry: Control = _wrap_entry(row, rank)
	entry.name = "Entry%d" % rank
	_list.add_child(entry)


func _rank_label(rank: int) -> Label:
	var rank_label := Label.new()
	rank_label.name = "Rank"
	rank_label.text = "#%d" % rank
	rank_label.custom_minimum_size = Vector2(62.0 if rank == 1 else 54.0, 0.0)
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 32 if rank == 1 else (24 if rank <= 3 else 20))
	rank_label.add_theme_color_override("font_color", _rank_color(rank))
	return rank_label


func _date_label(date: int) -> Label:
	var date_label := Label.new()
	date_label.name = "Date"
	date_label.text = format_date(date)
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	date_label.add_theme_font_size_override("font_size", 17)
	date_label.add_theme_color_override("font_color", MUTED)
	return date_label


func _score_label(score: int, rank: int) -> Label:
	var score_label := Label.new()
	score_label.name = "Score"
	score_label.text = str(score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 36 if rank == 1 else (29 if rank <= 3 else 25))
	score_label.add_theme_color_override("font_color", GOLD if rank == 1 else SILVER)
	return score_label


func _today_marker() -> Control:
	var marker: Control = TodayMarker.new()
	marker.name = "TodayMarker"
	return marker


func _wrap_entry(row: HBoxContainer, rank: int) -> Control:
	if rank != 1:
		return row
	var first := PanelContainer.new()
	first.add_theme_stylebox_override("panel", _first_style())
	first.add_child(row)
	return first


func _rank_color(rank: int) -> Color:
	match rank:
		1:
			return GOLD
		2:
			return SILVER
		3:
			return BRONZE
		_:
			return MUTED


func _first_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = TOP_SURFACE
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb
