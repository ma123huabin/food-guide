class_name CityDetailScreen
extends Control

var _city: CityData
var _dynamic: Control
var _modal: Control
var _check_button: Button
var _pending_city: String = ""
var _food_scroll: ScrollContainer
var _food_pressing: bool = false
var _food_moved: bool = false
var _food_start_x: float = 0.0
var _food_scroll_start: int = 0

func _ready() -> void:
	GuideUI.background(self)
	_dynamic = Control.new()
	_dynamic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dynamic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dynamic)
	LocationService.location_resolved.connect(_on_location)
	LocationService.location_failed.connect(_on_failed)

func load_city(city_id: String) -> void:
	_close_modal()
	for child in _dynamic.get_children():
		_dynamic.remove_child(child)
		child.queue_free()
	_city = GameData.get_city(city_id)
	_food_pressing = false
	if _city == null:
		return
	GuideUI.button(_dynamic, "‹  返回", Rect2(20, 24, 80, 34), func() -> void: EventBus.request_home.emit())
	GuideUI.label(_dynamic, "%s · 寻味地图" % _city.display_name, Rect2(107, 24, 267, 34), 22, GuideUI.INK, true)
	GuideUI.label(_dynamic, "已点亮", Rect2(387, 26, 75, 30), 13, GuideUI.RED, true)
	GuideUI.panel(_dynamic, Rect2(18, 80, 444, 240), Color("fff8f2"), 22, Color("fffdf2"), 2)
	var title := GuideUI.label(_dynamic, "推荐美食点", Rect2(0, 89, 480, 40), 28, Color("b34723"), true)
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color("ffe7bc"))
	GuideUI.label(_dynamic, "舌尖上的%s  ·  左右滑动发现更多" % _city.display_name, Rect2(0, 126, 480, 20), 11, Color("a47d68"), true)
	var scroll := ScrollContainer.new()
	_food_scroll = scroll
	scroll.position = Vector2(29, 154)
	scroll.size = Vector2(422, 154)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_dynamic.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	scroll.add_child(row)
	for i in range(_city.popular_foods.size()):
		var food: PopularFoodData = _city.popular_foods[i]
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(126, 148)
		row.add_child(holder)
		var card := GuideUI.button(holder, "", Rect2(0, 0, 126, 145), _show_food.bind(i))
		GuideUI.food_art(card, _city, i, Rect2(8, 4, 110, 83))
		GuideUI.label(card, food.name, Rect2(0, 88, 126, 26), 17, GuideUI.INK, true)
		GuideUI.panel(card, Rect2(16, 118, 94, 20), Color("f5d0a5"), 10)
		GuideUI.label(card, food.district, Rect2(0, 116, 126, 23), 11, Color("924b29"), true)
	# A dedicated gesture area gives mouse and touch the same horizontal swipe behavior.
	var gesture := Control.new()
	gesture.position = Vector2(29, 154)
	gesture.size = Vector2(422, 154)
	gesture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gesture.gui_input.connect(_on_food_input)
	_dynamic.add_child(gesture)
	GuideUI.label(_dynamic, "%s风味地图" % _city.display_name, Rect2(26, 334, 280, 30), 21)
	GuideUI.label(_dynamic, "● 美食点  ·  点击探索", Rect2(292, 338, 162, 24), 12, GuideUI.RED, true)
	var map_panel := GuideUI.panel(_dynamic, Rect2(20, 376, 440, 330), Color("fffae9"), 22, GuideUI.GOLD, 2)
	map_panel.clip_contents = true
	# Atlas map quadrants remain distinct for each city; no geography is shared.
	var map_texture: Texture2D = _city.map_texture if _city.map_texture != null else GuideUI.atlas("res://assets/art/maps.png", GameData.city_index(city_id))
	var map_rect := Rect2(6, 6, 428, 318)
	if _city.map_texture != null:
		var map_height := 428.0 * map_texture.get_height() / map_texture.get_width()
		map_rect = Rect2(6, (330 - map_height) / 2, 428, map_height)
	var map_image := GuideUI.picture(map_panel, map_texture, map_rect)
	map_image.stretch_mode = TextureRect.STRETCH_SCALE
	if _city.map_texture == null:
		GuideUI.panel(map_panel, Rect2(12, 12, 134, 27), Color(1, 0.98, 0.9, 0.94), 12)
		GuideUI.label(map_panel, "风味手绘 · 探索版", Rect2(12, 12, 134, 27), 11, GuideUI.INK, true)
		GuideUI.label(map_panel, "N\n✧", Rect2(392, 10, 30, 53), 15, Color("355e6a"), true)
	for i in range(_city.food_spots.size()):
		var spot: FoodSpotData = _city.food_spots[i]
		var p := Vector2(22 + spot.pos_x * 390, 22 + spot.pos_y * 274)
		if _city.map_texture != null:
			p = map_rect.position + Vector2(spot.pos_x, spot.pos_y) * map_rect.size
		var pin := GuideUI.button(map_panel, "●", Rect2(p.x - 17, p.y - 17, 34, 34), _show_spot.bind(i))
		pin.add_theme_stylebox_override("normal", GuideUI.box(Color("e84035"), 17, Color("fff5ce"), 3))
		pin.add_theme_color_override("font_color", Color("ffcf73"))
		pin.add_theme_font_size_override("font_size", 14)
		pin.tooltip_text = spot.name + " · " + spot.district
		GuideUI.panel(map_panel, Rect2(clampf(p.x - 42, 4, 350), p.y + 20, 84, 22), Color(1, 0.97, 0.85, 0.95), 9)
		GuideUI.label(map_panel, spot.name, Rect2(clampf(p.x - 42, 4, 350), p.y + 20, 84, 22), 11, GuideUI.INK, true)
	GuideUI.label(_dynamic, "手绘点位为风味示意，非实时导航地图", Rect2(0, 711, 480, 23), 11, Color("977967"), true)
	_check_button = GuideUI.button(_dynamic, "", Rect2(28, 748, 424, 61), _check_in, true)
	_refresh_button()
	GuideUI.label(_dynamic, "需授权真实定位 · 在本机按城市行政区边界核验", Rect2(0, 817, 480, 24), 11, Color("98715f"), true)

func _refresh_button() -> void:
	if _check_button == null or _city == null:
		return
	_check_button.disabled = not _pending_city.is_empty() or GameData.checkins.has(_city.city_id)
	_check_button.text = "✓  已留下美食足迹" if GameData.checkins.has(_city.city_id) else ("正在核验定位…" if not _pending_city.is_empty() else "我要打卡")

func _on_food_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_food_pressing = true
			_food_moved = false
			_food_start_x = event.position.x
			_food_scroll_start = _food_scroll.scroll_horizontal
		elif _food_pressing:
			_food_pressing = false
			if not _food_moved:
				var index: int = floori((event.position.x + _food_scroll.scroll_horizontal) / 136.0)
				if index >= 0 and index < _city.popular_foods.size():
					_show_food(index)
	elif event is InputEventMouseMotion and _food_pressing:
		var delta: float = event.position.x - _food_start_x
		if absf(delta) > 8:
			_food_moved = true
		_food_scroll.scroll_horizontal = _food_scroll_start - roundi(delta)

func _show_food(index: int) -> void:
	var food: PopularFoodData = _city.popular_foods[index]
	var description: String = "在%s，慢慢发现这座城市的烟火滋味。" % food.district
	for spot in _city.food_spots:
		if spot.name == food.name:
			description = spot.desc
	_message(food.name + " · " + food.district, description, index)

func _show_spot(index: int) -> void:
	var spot: FoodSpotData = _city.food_spots[index]
	var food_index: int = -1
	for i in range(_city.popular_foods.size()):
		if _city.popular_foods[i].name == spot.name:
			food_index = i
	_message(spot.name + " · " + spot.district, spot.desc, food_index)

func _message(title: String, body: String, food_index: int = -1) -> void:
	_close_modal()
	_modal = Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_modal)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.2, 0.1, 0.08, 0.40)
	_modal.add_child(shade)
	GuideUI.panel(_modal, Rect2(34, 252, 412, 318), GuideUI.CREAM, 25, GuideUI.GOLD, 2)
	if food_index >= 0:
		GuideUI.food_art(_modal, _city, food_index, Rect2(189, 267, 102, 92))
	else:
		GuideUI.label(_modal, "✦", Rect2(0, 268, 480, 80), 44, GuideUI.GOLD, true)
	GuideUI.label(_modal, title, Rect2(54, 364, 372, 40), 23, GuideUI.INK, true)
	var copy := GuideUI.label(_modal, body, Rect2(65, 410, 350, 78), 16, Color("98735d"), true)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GuideUI.button(_modal, "知道了", Rect2(122, 505, 236, 45), _close_modal, true)

func _close_modal() -> void:
	if is_instance_valid(_modal):
		remove_child(_modal)
		_modal.queue_free()
	_modal = null

func _check_in() -> void:
	if not _pending_city.is_empty() or _city == null:
		return
	_pending_city = _city.city_id
	_refresh_button()
	LocationService.request_location()

func _on_location(_lat: float, _lng: float) -> void:
	if _pending_city.is_empty():
		return
	var requested := GameData.get_city(_pending_city)
	_pending_city = ""
	var distance: float = LocationService.distance_to_city(requested)
	if LocationService.is_within_city(requested):
		GameData.record_checkin(requested.city_id)
		_message("打卡成功 · " + requested.display_name, "你已在核验范围内！\n这一次的城市美食足迹，已为你珍藏。")
	else:
		_message("还未到达" + requested.display_name, "当前位置不在该城市行政区范围内，\n距市中心约 %.0f 公里，到达后再来打卡吧。" % distance)
	_refresh_button()

func _on_failed(reason: String) -> void:
	if _pending_city.is_empty():
		return
	_pending_city = ""
	_message("暂时无法完成打卡", reason)
	_refresh_button()
