class_name TravelButton
extends Button
var _skin: ReferenceButtonSkin
var _reference_art: TextureRect
var _hovered := false
var _pressed := false
var _last_text := ""
func _ready() -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_skin = ReferenceButtonSkin.new()
	_skin.component_id = "detail_checkin_button" if size.x > 350 else "home_draw_button"
	_skin.show_behind_parent = true
	add_child(_skin)
	_skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_font_size_override("font_size", 34)
	add_theme_constant_override("outline_size", 1)
	add_theme_color_override("font_outline_color", Color("7d220a"))
	mouse_entered.connect(func() -> void: _hovered = true)
	mouse_exited.connect(func() -> void: _hovered = false)
	button_down.connect(func() -> void: _pressed = true)
	button_up.connect(func() -> void: _pressed = false)
func _process(_delta: float) -> void:
	if text != _last_text:
		_last_text = text
		var font := get_theme_font("font")
		var point_size := 34
		while point_size > 14 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x > size.x - 48:
			point_size -= 1
		add_theme_font_size_override("font_size", point_size)
	var surface: CanvasItem = _reference_art if _reference_art != null else _skin
	if surface:
		surface.modulate = Color(0.65, 0.61, 0.56) if disabled else (Color(0.87, 0.83, 0.78) if _pressed else (Color(1.06, 1.03, 1.0) if _hovered else Color.WHITE))
func use_popup_reference() -> void:
	_skin.hide()
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_outline_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://img/界面皮肤/弹窗精确参考.png")
	atlas.region = Rect2(121, 646, 368, 87)
	_reference_art = GuideUI.picture(self, atlas, Rect2(Vector2.ZERO, size))
	_reference_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reference_art.stretch_mode = TextureRect.STRETCH_SCALE
