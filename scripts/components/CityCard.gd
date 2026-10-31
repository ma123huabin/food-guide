class_name CityCard
extends Control

var city: CityData
var highlighted: bool = false:
	set(value):
		highlighted = value
		if is_node_ready():
			_refresh()
var _frame: Panel
var _winner_effect

func play_winner(duration: float) -> void:
	highlighted = true
	_winner_effect.play(duration)

func _ready() -> void:
	size = Vector2(240, 320)
	pivot_offset = size / 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = GuideUI.panel(self, Rect2(0, 0, 240, 320), Color("fff4dc"), 26, Color("d89e35"), 3)
	GuideUI.skin_frame(self, 0.18)
	GuideUI.label(self, "❖", Rect2(15, 14, 27, 27), 23, GuideUI.GOLD, true)
	GuideUI.label(self, "❖", Rect2(198, 14, 27, 27), 23, GuideUI.GOLD, true)
	GuideUI.rounded_picture(self, GuideUI.city_art(city), Rect2(14, 49, 212, 211), 14.0)
	var title := GuideUI.label(self, city.display_name, Rect2(0, 8, 240, 40), 27, GuideUI.INK, true)
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color("fff3db"))
	GuideUI.label(self, city.tagline.replace("。", ""), Rect2(14, 270, 212, 32), 13, Color("7a4c30"), true)
	_winner_effect = preload("res://scripts/components/CityWinnerEffect.gd").new()
	add_child(_winner_effect)
	_refresh()

func _refresh() -> void:
	if is_instance_valid(_winner_effect):
		_winner_effect.visible = highlighted
	_frame.add_theme_stylebox_override("panel", GuideUI.box(Color.TRANSPARENT, 26, GuideUI.GOLD if highlighted else Color.TRANSPARENT, 5 if highlighted else 0))
	_frame.get_theme_stylebox("panel").shadow_color = Color.TRANSPARENT
	_frame.get_theme_stylebox("panel").shadow_size = 0
