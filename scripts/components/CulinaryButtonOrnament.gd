class_name CulinaryButtonOrnament
extends Control
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var radius := minf(9.0, size.y * 0.15)
	for side in [0, 1]:
		var direction := 1.0 if side == 0 else -1.0
		var at := Vector2(14 if side == 0 else size.x - 14, size.y * 0.5)
		var curve := PackedVector2Array()
		for i in range(42):
			var t := i / 41.0
			var angle := -PI * 0.5 + t * TAU * 1.3
			var r := radius * (1.0 - t * 0.88)
			curve.append(at + Vector2(cos(angle) * r * direction, sin(angle) * r))
		draw_polyline(curve, Color("8f4a10"), 3, true)
		draw_polyline(curve, Color("ffe39b"), 1.4, true)

