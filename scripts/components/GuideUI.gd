class_name GuideUI
extends RefCounted

const INK = Color("713522")
const GOLD = Color("d5a64e")
const RED = Color("d93936")
const CREAM = Color("fff9ea")

static func box(color: Color, radius: int = 18, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(width)
	s.shadow_color = Color(0.45, 0.18, 0.12, 0.14)
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
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l

static func button(parent: Node, text: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 25 if primary else 15)
	b.add_theme_color_override("font_color", CREAM if primary else INK)
	b.add_theme_color_override("font_hover_color", Color.WHITE if primary else RED)
	b.add_theme_color_override("font_pressed_color", CREAM if primary else INK)
	b.add_theme_stylebox_override("normal", box(RED if primary else CREAM, 30 if primary else 14, GOLD if primary else Color("ead8bf"), 3 if primary else 1))
	b.add_theme_stylebox_override("hover", box(Color("ec5745") if primary else Color("fff0d4"), 30 if primary else 14, GOLD, 3 if primary else 1))
	b.add_theme_stylebox_override("pressed", box(Color("b92531") if primary else Color("f7dfb9"), 30 if primary else 14, GOLD, 2))
	b.add_theme_stylebox_override("disabled", box(Color("c49a92"), 30 if primary else 14, GOLD, 2))
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
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){vec2 p=UV; float n=fract(sin(dot(floor(p*vec2(960.,1708.)),vec2(12.9898,78.233)))*43758.5453); vec3 c=mix(vec3(1.,.94,.89),vec3(.96,.79,.83),p.y*.5+abs(p.x-.5)*.4); COLOR=vec4(c+(n-.5)*.035,1.);}"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	bg.material = mat
	parent.add_child(bg)
	for i in range(14):
		label(parent, "✦" if i % 3 else "❀", Rect2((i * 103 + 13) % 460, (i * 179 + 20) % 800, 25, 25), 13 + i % 3 * 4, Color("dcb579"), true)

static func city_art(city: CityData) -> Texture2D:
	if city.map_texture != null:
		return city.map_texture
	return atlas("res://assets/art/cities.png", GameData.city_index(city.city_id))

static func food_art(parent: Node, city: CityData, index: int, rect: Rect2) -> void:
	if city.city_id == "quanzhou":
		label(parent, ["面", "粽", "鸭", "鲜"][index], rect, 42, RED, true)
	else:
		picture(parent, atlas("res://assets/art/foods.png", GameData.city_index(city.city_id) * 4 + index, 4), rect)
