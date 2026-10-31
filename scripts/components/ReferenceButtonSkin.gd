class_name ReferenceButtonSkin
extends TextureRect
var component_id := "home_draw_button"
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture = GuideUI.component(component_id)
