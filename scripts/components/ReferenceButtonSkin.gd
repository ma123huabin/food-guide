class_name ReferenceButtonSkin
extends TextureRect
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://img/界面皮肤/朱红祥云按钮.png")
	atlas.region = Rect2(0, 88, 2101, 565)
	texture = atlas
