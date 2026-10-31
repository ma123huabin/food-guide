class_name ReferenceFrame
extends Control
var kind := "city"
var _title_source: Texture2D
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "title":
		_title_source = load("res://img/界面皮肤/详情精确参考.png")
		resized.connect(queue_redraw)
		return
	var texture: Texture2D = load("res://img/界面皮肤/首页金边卡框.png" if kind == "city" else "res://img/界面皮肤/统一弹窗面板.png")
	if kind == "city" or kind == "food":
		var art := TextureRect.new()
		art.texture = texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var art := NinePatchRect.new()
		art.texture = texture
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ratio := 0.08 if kind == "title" else 0.12
		art.scale = Vector2.ONE * ratio
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			art.set_patch_margin(side, 180)
		add_child(art)
		var fit := func() -> void: art.size = size / ratio
		resized.connect(fit)
		fit.call()

func _draw() -> void:
	if _title_source == null: return
	draw_texture_rect_region(_title_source, Rect2(Vector2.ZERO, size), Rect2(258, 14, 418, 83))
	# Keep the original gold ends and clear only the baked city lettering.
	draw_texture_rect_region(load("res://img/界面皮肤/统一弹窗面板.png"), Rect2(size.x * 0.15, size.y * 0.22, size.x * 0.73, size.y * 0.60), Rect2(300, 300, 400, 400))
