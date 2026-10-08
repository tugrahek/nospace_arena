class_name SupplyStoreBadge
extends Control

## Notification attached to the Store's Supply tab only; no acquisition or mutation.
const PALETTE: PaletteData = preload("res://config/palette.tres")
var acquisition: SupplyBoxAcquisition
var ads: Node


func _ready() -> void:
	if acquisition == null:
		acquisition = Economy.supply_acquisition()
	if ads == null:
		ads = AdsService
	Economy.currency_changed.connect(_on_currency)
	Economy.boosts_changed.connect(refresh)
	ads.rewarded_ready.connect(refresh)
	ads.rewarded_availability_changed.connect(_on_rewarded_availability_changed)
	ads.ads_unavailable.connect(_on_unavailable)
	ads.ad_closed.connect(_on_ad_closed)
	ads.ad_failed.connect(_on_ad_failed)
	acquisition._core.box_delivered.connect(_on_delivered)
	refresh()


## Reflects the unused daily opportunity only while a rewarded ad can be shown.
func refresh() -> void:
	var status: Dictionary = acquisition.status()
	visible = int(status["rewarded_count"]) < int(status["rewarded_limit"]) and ads.is_rewarded_available()
	queue_redraw()


func _on_rewarded_availability_changed(_available: bool) -> void:
	refresh()


func _on_currency(_balance: int) -> void:
	refresh()


func _on_unavailable(_reason: StringName) -> void:
	refresh()


func _on_ad_closed(_context: String, _token: int) -> void:
	refresh()


func _on_ad_failed(_context: String, _token: int, _reason: StringName) -> void:
	refresh()


func _on_delivered(_id: String, _reward: Dictionary) -> void:
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and is_node_ready():
		refresh()


func _draw() -> void:
	draw_circle(size * 0.5, minf(size.x, size.y) * 0.5, PALETTE.void_bg)
	draw_circle(size * 0.5, minf(size.x, size.y) * 0.35, PALETTE.accent)
