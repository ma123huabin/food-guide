extends Control
## Transient winner light only; never modulates the carousel or its neighbours.

var _age: float = 0.0
var _duration: float = 0.7
var _playing: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(240, 320)
	set_process(false)

func play(duration: float) -> void:
	_duration = maxf(duration, 0.1)
	_age = 0.0
	_playing = true
	show()
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_age = minf(_age + delta, _duration)
	queue_redraw()
	if _age >= _duration:
		set_process(false)

func _draw() -> void:
	if not _playing:
		return
	var progress := _age / _duration
	var ignition := minf(progress / 0.14, 1.0)
	var power := ignition * (0.55 + 0.45 * exp(-progress * 2.0))
	var bounds := Rect2(2, 2, 236, 316)
	# Layered outlines create a warm bloom without a full-screen dark overlay.
	for i in range(10, 0, -1):
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color.TRANSPARENT
		glow.border_color = Color(1.0, 0.70, 0.12, 0.028 * power)
		glow.set_border_width_all(i + 2)
		glow.set_corner_radius_all(24 + i)
		glow.draw(get_canvas_item(), bounds.grow(i * 0.6))
	var edge := StyleBoxFlat.new()
	edge.bg_color = Color.TRANSPARENT
	edge.border_color = Color(1.0, 0.85, 0.35, 0.85 * power)
	edge.set_border_width_all(3)
	edge.set_corner_radius_all(24)
	edge.draw(get_canvas_item(), bounds)
	# Clip the moving gold ribbon to the face of this card.
	var sweep := clampf((progress - 0.05) / 0.75, 0.0, 1.0)
	var x := lerpf(-60.0, 420.0, sweep)
	var ribbon := PackedVector2Array([Vector2(x - 42, 5), Vector2(x, 5), Vector2(x - 130, 315), Vector2(x - 172, 315)])
	var face := PackedVector2Array([Vector2(12, 5), Vector2(228, 5), Vector2(228, 315), Vector2(12, 315)])
	for polygon in Geometry2D.intersect_polygons(ribbon, face):
		draw_colored_polygon(polygon, Color(1.0, 0.91, 0.52, 0.20 * sin(sweep * PI)))
	for i in range(18):
		var angle := i * 2.39996
		var outward := progress * (10.0 + (i % 4) * 5.0)
		var point := Vector2(120, 160) + Vector2(cos(angle) * (117.0 + outward), sin(angle) * (155.0 + outward))
		var alpha := ignition * (1.0 - progress) * 0.85
		draw_circle(point, 1.0 + (i % 3) * 0.45, Color(1.0, 0.82, 0.28, alpha))
	for point in [Vector2(16, 16), Vector2(224, 16), Vector2(16, 304), Vector2(224, 304)]:
		var radius := (5.0 + 4.0 * sin(progress * PI)) * ignition
		var star := PackedVector2Array([point + Vector2(-radius, 0), point + Vector2(-1.5, -1.5), point + Vector2(0, -radius), point + Vector2(1.5, -1.5), point + Vector2(radius, 0), point + Vector2(1.5, 1.5), point + Vector2(0, radius), point + Vector2(-1.5, 1.5)])
		draw_colored_polygon(star, Color(1.0, 0.97, 0.75, power))
