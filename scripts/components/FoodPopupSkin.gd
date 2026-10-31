class_name FoodPopupSkin
extends TextureRect
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture = load("res://img/界面皮肤/统一弹窗面板.png")
