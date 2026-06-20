extends Control

## Local daily leaderboard view: your best score per day, ranked high→low as cards (rank +
## date + score). Top 3 get medal colors; today's entry is highlighted wherever it ranks.
## Read-only — loads LeaderboardStore; no game logic. Online + Free/Level high scores are v1.1.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const LEADERBOARD_PATH: String = "user://leaderboard.json"
const MAX_ROWS: int = 60

const EpochDay = preload("res://scripts/meta/epoch_day.gd")
const MONTHS: Array[String] = [
	"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
]

const GOLD: Color = Color(1.0, 0.82, 0.32, 1.0)
const SILVER: Color = Color(0.85, 0.88, 0.95, 1.0)
const BRONZE: Color = Color(0.85, 0.55, 0.35, 1.0)
const MUTED: Color = Color(0.74, 0.72, 0.84, 1.0)
const ACCENT: Color = Color(0.3, 0.95, 1.0, 1.0)

@onready var _title: Label = $Layout/Title
@onready var _all_best: Label = $Layout/AllBest
@onready var _list: VBoxContainer = $Layout/Scroll/List
@onready var _empty: Label = $EmptyLabel
@onready var _back: Button = $Layout/BackButton


func _ready() -> void:
	_title.text = tr("LEADERBOARD_TITLE")
	_back.text = tr("SETTINGS_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	_list.add_theme_constant_override("separation", 10)
	_populate()


func _populate() -> void:
	var lb: Leaderboard = LeaderboardStore.load_from(LEADERBOARD_PATH)
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

	var today: int = SeedManager.compute_today()
	for i in mini(rows.size(), MAX_ROWS):
		_add_card(i + 1, rows[i]["date"], rows[i]["score"], today)


## Friendly display for a YYYYMMDD date relative to today (also YYYYMMDD). Pure — the stored
## leaderboard key stays ISO. Today/Yesterday via epoch-day (handles month/year boundaries).
static func format_date(date_int: int, today_int: int) -> String:
	if date_int == today_int:
		return "Today"
	var y: int = date_int / 10000
	var m: int = (date_int / 100) % 100
	var d: int = date_int % 100
	var ty: int = today_int / 10000
	var tm: int = (today_int / 100) % 100
	var td: int = today_int % 100
	if EpochDay.from_date(y, m, d) == EpochDay.from_date(ty, tm, td) - 1:
		return "Yesterday"
	var mon: String = MONTHS[clampi(m - 1, 0, 11)]
	if y == ty:
		return "%s %d" % [mon, d]
	return "%s %d, %d" % [mon, d, y]


## One leaderboard card: rank (medal color for top 3) + date (muted) + score (large gold).
## Today's card gets an accent border + glow.
func _add_card(rank: int, date: int, score: int, today: int) -> void:
	var is_today: bool = date == today
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style(is_today))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var rank_label := Label.new()
	rank_label.text = "#%d" % rank
	rank_label.custom_minimum_size = Vector2(54, 0)
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 22)
	rank_label.add_theme_color_override("font_color", _rank_color(rank))

	var date_label := Label.new()
	date_label.text = format_date(date, today)
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	date_label.add_theme_font_size_override("font_size", 16)
	date_label.add_theme_color_override("font_color", ACCENT if is_today else MUTED)

	var score_label := Label.new()
	score_label.text = str(score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", GOLD)

	row.add_child(rank_label)
	row.add_child(date_label)
	row.add_child(score_label)
	card.add_child(row)
	_list.add_child(card)


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


func _card_style(is_today: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.15, 0.32, 0.9)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	if is_today:
		sb.set_border_width_all(2)
		sb.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.9)
		sb.shadow_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35)
		sb.shadow_size = 6
	else:
		sb.set_border_width_all(1)
		sb.border_color = Color(0.4, 0.95, 1.0, 0.28)
	return sb
