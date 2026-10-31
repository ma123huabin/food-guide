class_name GuideUI
extends RefCounted

const INK = Color("6b2615")
const GOLD = Color("e6b54d")
const RED = Color("b9240b")
const CREAM = Color("fff5df")

static func box(color: Color, radius: int = 18, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(width)
	s.shadow_color = Color(0.25, 0.12, 0.03, 0.20)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 4)
	return s

static func panel(parent: Node, rect: Rect2, color: Color, radius: int = 18, border: Color = Color.TRANSPARENT, width: int = 0) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", box(color, radius, border, width))
	parent.add_child(p)
	return p

static func label(parent: Node, text: String, rect: Rect2, font_size: int = 18, color: Color = INK, centered: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	if font_size >= 13:
		l.add_theme_font_override("font", load("res://assets/fonts/楷体.ttf"))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l

static func button(parent: Node, text: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
	var b: Button = TravelButton.new() if primary else Button.new()
	b.text = text
	b.add_theme_font_override("font", load("res://assets/fonts/行楷.ttf"))
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 25 if primary else 15)
	b.add_theme_color_override("font_color", Color("fff8e7") if primary else INK)
	b.add_theme_color_override("font_hover_color", Color.WHITE if primary else RED)
	b.add_theme_color_override("font_pressed_color", Color("fff8e7") if primary else INK)
	b.add_theme_stylebox_override("normal", box(RED if primary else CREAM, 30 if primary else 18))
	b.add_theme_stylebox_override("hover", box(Color("ffe6a1") if primary else Color("ffebc4"), 30 if primary else 18))
	b.add_theme_stylebox_override("pressed", box(Color("dfad59") if primary else Color("f5dbaa"), 30 if primary else 18))
	b.add_theme_stylebox_override("disabled", box(Color("e2d4b9"), 30 if primary else 18))
	b.add_theme_color_override("font_disabled_color", Color("8a7a64"))
	b.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, 18))
	b.pressed.connect(action)
	parent.add_child(b)
	return b

static func atlas(path: String, index: int, columns: int = 2) -> AtlasTexture:
	var texture := load(path) as Texture2D
	var a := AtlasTexture.new()
	a.atlas = texture
	var cell := texture.get_size() / float(columns)
	a.region = Rect2(Vector2(index % columns, index / columns) * cell, cell)
	return a

static func picture(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.texture = texture
	t.position = rect.position
	t.size = rect.size
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t

static func background(parent: Control) -> void:
	var bg := picture(parent, load("res://img/界面皮肤/首页精确背景.png"), Rect2(Vector2.ZERO, parent.size))
	bg.name = "CulinaryBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func skin_frame(parent: Control, detail_scale: float = 0.10) -> ReferenceFrame:
	var frame := ReferenceFrame.new()
	frame.kind = "city" if parent is CityCard else ("food" if parent is Button else "tray")
	parent.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return frame

static func locked_art() -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://img/界面皮肤/待解锁参考.png")
	atlas.region = Rect2(0, 0, atlas.atlas.get_width() / 2.0, atlas.atlas.get_height())
	return atlas

static func city_art(city: CityData) -> Texture2D:
	return city.cover_texture

static func food_art(parent: Node, city: CityData, index: int, rect: Rect2) -> void:
	if city.popular_foods[index].image_texture != null:
		var food_image := picture(parent, city.popular_foods[index].image_texture, rect)
		food_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		label(parent, city.popular_foods[index].name.left(1), rect, 42, RED, true)
