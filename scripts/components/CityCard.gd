class_name CityCard
extends Control

var city: CityData
var highlighted: bool = false:
	set(value):
		highlighted = value
		if is_node_ready():
			_refresh()
var _badge: Label
var _frame: Panel

func _ready() -> void:
	size = Vector2(240, 320)
	pivot_offset = size / 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = GuideUI.panel(self, Rect2(0, 0, 240, 320), GuideUI.CREAM, 22, GuideUI.GOLD, 4)
	GuideUI.panel(self, Rect2(8, 8, 224, 304), Color("fff5e1"), 17, Color("b75b32"), 1)
	GuideUI.label(self, "❖", Rect2(15, 14, 27, 27), 23, GuideUI.GOLD, true)
	GuideUI.label(self, "❖", Rect2(198, 14, 27, 27), 23, GuideUI.GOLD, true)
	GuideUI.picture(self, GuideUI.city_art(city), Rect2(14, 49, 212, 211))
	var title := GuideUI.label(self, city.display_name, Rect2(0, 8, 240, 40), 27, GuideUI.INK, true)
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color("ffe2a0"))
	GuideUI.label(self, "✧  一城一味 · 风物收藏  ✧", Rect2(0, 263, 240, 24), 13, Color("956d3d"), true)
	_badge = GuideUI.label(self, "", Rect2(0, 287, 240, 23), 13, GuideUI.RED, true)
	_refresh()

func _refresh() -> void:
	var lit: bool = GameData.is_lit(city.city_id)
	_badge.text = "已点亮 · 点击探索  →" if lit else "等待你的美食奇遇"
	_frame.add_theme_stylebox_override("panel", GuideUI.box(GuideUI.CREAM, 22, Color("ffd367") if highlighted else GuideUI.GOLD, 5 if highlighted else 3))
	_frame.get_theme_stylebox("panel").shadow_color = Color(0.92, 0.58, 0.13, 0.4) if highlighted else Color(0.45, 0.18, 0.12, 0.14)
	_frame.get_theme_stylebox("panel").shadow_size = 16 if highlighted else 6
