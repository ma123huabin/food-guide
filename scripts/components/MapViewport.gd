class_name MapViewport
extends Control

signal spot_pressed(index: int)

@export_range(1.0, 8.0, 0.25) var maximum_zoom: float = 4.0
@export var wheel_zoom_factor: float = 1.2
var _world: Control
var _texture: Texture2D
var _cover_scale: float = 1.0
var _zoom: float = 1.0
var _dragging := false
var _moved := false
var _start := Vector2.ZERO
var _touches: Dictionary = {}
var _spots: Array[Vector2] = []

func configure(texture: Texture2D, spots: Array[FoodSpotData]) -> void:
	_texture = texture
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_world = Control.new()
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_world)
	_world.size = texture.get_size()
	GuideUI.picture(_world, texture, Rect2(Vector2.ZERO, _world.size)).stretch_mode = TextureRect.STRETCH_SCALE
	for i in range(spots.size()):
		var point := Vector2(spots[i].pos_x, spots[i].pos_y) * _world.size
		_spots.append(point)
		# Pin graphics ignore input so dragging over a pin still pans the map.
		GuideUI.panel(_world, Rect2(point - Vector2(19, 19), Vector2(38, 38)), Color("e84035"), 19, Color("fff5ce"), 3)
		GuideUI.label(_world, "●", Rect2(point - Vector2(15, 15), Vector2(30, 30)), 14, Color("ffcf73"), true)
		GuideUI.panel(_world, Rect2(point + Vector2(-46, 23), Vector2(92, 25)), Color(1, 0.97, 0.85, 0.95), 12)
		GuideUI.label(_world, spots[i].name, Rect2(point + Vector2(-46, 23), Vector2(92, 25)), 12, GuideUI.INK, true)
	_fit()
	resized.connect(_fit)

func _fit() -> void:
	if _texture == null or size.x <= 0 or size.y <= 0:
		return
	_cover_scale = maxf(size.x / _texture.get_width(), size.y / _texture.get_height())
	_world.scale = Vector2.ONE * _cover_scale * _zoom
	_world.position = (size - _world.size * _world.scale) / 2
	_clamp_position()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_dragging = false
		_touches.clear()

func _clamp_position() -> void:
	var extent := _world.size * _world.scale
	_world.position.x = clampf(_world.position.x, minf(0.0, size.x - extent.x), 0.0)
	_world.position.y = clampf(_world.position.y, minf(0.0, size.y - extent.y), 0.0)

func pan_by(delta: Vector2) -> void:
	_world.position += delta
	_clamp_position()

func zoom_at(factor: float, anchor: Vector2) -> void:
	var before := (anchor - _world.position) / _world.scale
	_zoom = clampf(_zoom * factor, 1.0, maximum_zoom)
	_world.scale = Vector2.ONE * _cover_scale * _zoom
	_world.position = anchor - before * _world.scale
	_clamp_position()

func _pick(point: Vector2) -> void:
	var local := (point - _world.position) / _world.scale
	for i in range(_spots.size()):
		if local.distance_to(_spots[i]) <= 22.0:
			spot_pressed.emit(i)
			return

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and not _touches.is_empty():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_at(wheel_zoom_factor, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_at(1.0 / wheel_zoom_factor, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_moved = false
				_start = event.position
			elif _dragging:
				_dragging = false
				if not _moved:
					_pick(event.position)
	elif event is InputEventMouseMotion and _dragging:
		_moved = _moved or event.position.distance_to(_start) > 8.0
		if _moved:
			pan_by(event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 1:
				_start = event.position
				_moved = false
			else:
				_moved = true
		else:
			if _touches.size() == 1 and not _moved:
				_pick(event.position)
			_touches.erase(event.index)
	elif event is InputEventScreenDrag and _touches.has(event.index):
		if _touches.size() == 1:
			_moved = _moved or event.position.distance_to(_start) > 8.0
			if _moved:
				pan_by(event.position - _touches[event.index])
			_touches[event.index] = event.position
		else:
			var keys := _touches.keys()
			var a: Vector2 = _touches[keys[0]]
			var b: Vector2 = _touches[keys[1]]
			_touches[event.index] = event.position
			var c: Vector2 = _touches[keys[0]]
			var d: Vector2 = _touches[keys[1]]
			if a.distance_to(b) > 1.0:
				zoom_at(c.distance_to(d) / a.distance_to(b), (a + b) / 2)
			pan_by((c + d - a - b) / 2)
	elif event is InputEventMagnifyGesture:
		zoom_at(event.factor, event.position)
	elif event is InputEventPanGesture:
		pan_by(-event.delta * 20.0)
	accept_event()
