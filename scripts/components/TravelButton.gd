class_name TravelButton
extends Button

var _surface: ShaderMaterial
var _hovered := false
var _pressed := false

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var shadow := GuideUI.panel(self, Rect2(Vector2.ZERO, size), Color("1573b5"), 30, Color("dce7ec"), 3)
	shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shadow.show_behind_parent = true
	var style := shadow.get_theme_stylebox("panel") as StyleBoxFlat
	style.shadow_color = Color(0.03, 0.20, 0.32, 0.28)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 5)
	var surface := ColorRect.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.show_behind_parent = true
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec2 button_size = vec2(236.0, 46.0);
uniform float state = 0.0;
void fragment() {
 vec2 p = (UV - 0.5) * button_size;
 float radius = button_size.y * 0.5;
 float d = length(vec2(max(abs(p.x) - (button_size.x * 0.5 - radius), 0.0), p.y)) - radius;
 vec3 rim = mix(vec3(0.96,0.99,1.0), vec3(0.43,0.53,0.63), UV.y);
 vec3 blue = mix(vec3(0.40,0.91,1.0), vec3(0.0,0.43,0.88), smoothstep(0.0,0.65,UV.y));
 blue = mix(blue, vec3(0.0,0.27,0.63), smoothstep(0.70,1.0,UV.y)*0.50);
 blue += vec3(0.15) * exp(-pow((UV.y-0.16)*17.0,2.0));
 blue += vec3(0.05)*step(0.5,state)*(1.0-step(1.5,state));
 blue *= 1.0 - 0.16*step(1.5,state);
 if(state > 2.5) { blue = mix(blue, vec3(0.48,0.62,0.70),0.72); }
 vec3 c = mix(rim, blue, 1.0-smoothstep(-4.0,-3.0,d));
 COLOR = vec4(c, 1.0-smoothstep(-0.8,0.3,d));
}"""
	_surface = ShaderMaterial.new()
	_surface.shader = shader
	surface.material = _surface
	add_child(surface)
	resized.connect(_resize_surface)
	_resize_surface()
	mouse_entered.connect(func() -> void: _hovered = true)
	mouse_exited.connect(func() -> void: _hovered = false)
	button_down.connect(func() -> void: _pressed = true)
	button_up.connect(func() -> void: _pressed = false)

func _resize_surface() -> void:
	if _surface:
		_surface.set_shader_parameter("button_size", size)

func _process(_delta: float) -> void:
	if _surface:
		_surface.set_shader_parameter("state", 3.0 if disabled else (2.0 if _pressed else (1.0 if _hovered else 0.0)))
