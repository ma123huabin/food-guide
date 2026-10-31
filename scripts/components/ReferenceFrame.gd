class_name ReferenceFrame
extends Control
var kind := "city"
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var id := "home_city_card_frame"
	match kind:
		"food": id = "detail_food_card"
		"title": id = "detail_title_plaque"
		"tray": id = "detail_recommendation_panel"
	var art := GuideUI.component_picture(self, id, Rect2(Vector2.ZERO, size))
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
