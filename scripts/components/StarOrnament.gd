class_name StarOrnament
extends Control
var bottle := false
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func star(at: Vector2, radius: float, color: Color, points: int = 4) -> void:
	var vertices := PackedVector2Array()
	for i in range(points * 2):
		var angle := -PI / 2 + i * PI / points
		vertices.append(at + Vector2(cos(angle), sin(angle)) * radius * (1.0 if i % 2 == 0 else 0.38))
	draw_colored_polygon(vertices, color)
func _draw() -> void:
	if bottle:
		draw_set_transform(Vector2(29, size.y * 0.48), -0.3, Vector2.ONE * minf(size.y / 60.0, 1.1))
		draw_circle(Vector2(0, 4), 24, Color(1, 0.95, 0.48, 0.15))
		var glass := StyleBoxFlat.new()
		glass.bg_color = Color(1, 1, 0.84, 0.58)
		glass.border_color = Color("fff5c7")
		glass.set_border_width_all(2)
		glass.set_corner_radius_all(10)
		draw_style_box(glass, Rect2(-16, -14, 32, 38))
		draw_arc(Vector2(0, -16), 11, 0, TAU, 32, Color("fffbe1"), 3, true)
		draw_style_box(GuideUI.box(Color("c88d42"), 3), Rect2(-10, -25, 20, 9))
		star(Vector2(0, 4), 14, Color("fff16e"), 5)
		star(Vector2(28, -18), 7, Color("fff0a0"), 5)
		return
	var w := size.x
	var h := size.y
	for i in range(65):
		var x := fposmod(i * 137.71 + 23, w)
		var y := fposmod(i * 71.37 + 9, h)
		draw_circle(Vector2(x, y), 0.7 if i % 3 else 1.3, Color(0.83, 0.88, 1, 0.25 + (i % 4) * 0.12))
	for i in range(4):
		var x := w * (0.13 + i * 0.245)
		var y := 25.0 + (i % 2) * 19
		draw_line(Vector2(x, 0), Vector2(x, y), Color(0.88, 0.79, 0.58, 0.45), 1, true)
		star(Vector2(x, y + 5), 7 if i % 2 else 5, Color("f8db8e"), 5)
	# Layered mountains and a moonlit lake frame the city collection.
	for layer in range(3):
		var ridge := PackedVector2Array([Vector2(0, h)])
		for j in range(13):
			ridge.append(Vector2(w * j / 12.0, h * (0.76 + layer * 0.045) - sin(j * 1.7 + layer) * 19 - (17 if j % 3 == 0 else 0)))
		ridge.append(Vector2(w, h))
		draw_colored_polygon(ridge, [Color("213c70"), Color("1e4775"), Color("183759")][layer])
	for i in range(12):
		var y := h * 0.89 + i * 6
		var width := 25.0 + i * 7
		draw_line(Vector2(w * 0.5 - width, y), Vector2(w * 0.5 + width, y), Color(0.83, 0.80, 0.66, 0.12 - i * 0.006), 1, true)
	for offset in [0.0, 5.0]:
		var curve := PackedVector2Array()
		for i in range(61):
			var x := w * i / 60.0
			curve.append(Vector2(x, h * 0.968 + sin(i * 0.11) * 7 + offset))
		draw_polyline(curve, Color(0.92, 0.80, 0.51, 0.42), 1, true)
