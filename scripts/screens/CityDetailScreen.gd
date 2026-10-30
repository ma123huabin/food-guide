class_name CityDetailScreen
extends Control

var _city: CityData
var _dynamic: Control
var _modal: Control
var _check_button: Button
var _pending_city: String = ""
var _map_view: MapViewport
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
	var header := GuideUI.label(_dynamic, "%s · 寻味地图" % _city.display_name, Rect2(107, 24, 267, 34), 22, GuideUI.INK, true)
	header.add_theme_constant_override("outline_size", 4)
	header.add_theme_color_override("font_outline_color", GuideUI.CREAM)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var map_texture: Texture2D = _city.map_texture
	_map_view = null
	if map_texture != null:
		_map_view = MapViewport.new()
		_map_view.name = "CityMap"
		_dynamic.add_child(_map_view)
		_map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_dynamic.move_child(_map_view, 0)
		_map_view.configure(map_texture, _city.food_spots)
		_map_view.spot_pressed.connect(_show_spot)
	else:
		GuideUI.label(_dynamic, "✧", Rect2(0, 168, 480, 80), 48, GuideUI.GOLD, true)
		GuideUI.label(_dynamic, _city.display_name + "美食地图绘制中", Rect2(0, 263, 480, 40), 23, Color("b1ebff"), true)
		GuideUI.label(_dynamic, "从下方美食卡片，认识这座城市的味道", Rect2(0, 320, 480, 30), 13, Color("a8d7e4"), true)
	var map_note := GuideUI.label(_dynamic, "手绘点位为风味示意，非实时导航地图" if map_texture != null else "城市美食地图与城市封面图独立制作", Rect2(0, 520, 480, 20), 10, Color("315f73"), true)
	map_note.add_theme_constant_override("outline_size", 3)
	map_note.add_theme_color_override("font_outline_color", GuideUI.CREAM)
	# Fixed overlay: map moves underneath while the food tray stays in place.
	var tray := GuideUI.panel(_dynamic, Rect2(18, 550, 444, 180), Color("e9faff"), 24)
	tray.name = "FoodTray"
	tray.mouse_filter = Control.MOUSE_FILTER_STOP
	var tray_style := tray.get_theme_stylebox("panel") as StyleBoxFlat
	tray_style.shadow_color = Color(0.0, 0.12, 0.20, 0.25)
	tray_style.shadow_size = 14
	tray_style.shadow_offset = Vector2(0, 6)
	GuideUI.label(_dynamic, "推荐美食点", Rect2(0, 556, 480, 30), 23, Color("12617d"), true)
	GuideUI.label(_dynamic, "舌尖上的%s" % _city.display_name, Rect2(0, 586, 480, 18), 11, Color("628e9d"), true)
	var scroll := ScrollContainer.new()
	_food_scroll = scroll
	scroll.position = Vector2(29, 608)
	scroll.size = Vector2(422, 116)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_dynamic.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	scroll.add_child(row)
	for i in range(_city.popular_foods.size()):
		var food: PopularFoodData = _city.popular_foods[i]
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(98, 114)
		row.add_child(holder)
		var card := GuideUI.button(holder, "", Rect2(0, 0, 98, 112), _show_food.bind(i))
		card.name = "FoodCard%d" % i
		GuideUI.food_art(card, _city, i, Rect2(7, 5, 84, 62))
		GuideUI.label(card, food.name, Rect2(3, 67, 92, 23), 13, GuideUI.INK, true)
		GuideUI.panel(card, Rect2(7, 92, 84, 16), Color("c7ecf6"), 8)
		GuideUI.label(card, food.district, Rect2(7, 91, 84, 18), 10, Color("23596e"), true)
	# Only longer future food lists need horizontal swipes; the current four fit fully.
	if _city.popular_foods.size() > 4:
		var gesture := Control.new()
		gesture.position = scroll.position
		gesture.size = scroll.size
		gesture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		gesture.gui_input.connect(_on_food_input)
		_dynamic.add_child(gesture)
	_check_button = GuideUI.button(_dynamic, "", Rect2(28, 756, 424, 61), _check_in, true)
	_refresh_button()

func _refresh_button() -> void:
	if _check_button == null or _city == null:
		return
	if not LocationService.has_boundary(_city.city_id):
		_check_button.disabled = true
		_check_button.text = "打卡核验筹备中"
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
				var index: int = floori((event.position.x + _food_scroll.scroll_horizontal) / 108.0)
				if index >= 0 and index < _city.popular_foods.size():
					_show_food(index)
	elif event is InputEventMouseMotion and _food_pressing:
		var delta: float = event.position.x - _food_start_x
		if absf(delta) > 8:
			_food_moved = true
		_food_scroll.scroll_horizontal = _food_scroll_start - roundi(delta)

func _show_food(index: int) -> void:
	_food_message(index)

func _show_spot(index: int) -> void:
	var spot: FoodSpotData = _city.food_spots[index]
	var food_index: int = -1
	for i in range(_city.popular_foods.size()):
		if _city.popular_foods[i].name == spot.name:
			food_index = i
	if food_index >= 0:
		_food_message(food_index)
	else:
		_message(spot.name, spot.district)

func _food_message(index: int) -> void:
	_close_modal()
	var food: PopularFoodData = _city.popular_foods[index]
	_modal = Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_modal)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.07, 0.11, 0.72)
	_modal.add_child(shade)
	var available := size - Vector2(48, 72)
	var width := minf(minf(320.0, available.x), available.y / 1.45)
	var image_height := width - 40.0
	if food.image_texture != null:
		image_height = (width - 40.0) * food.image_texture.get_height() / food.image_texture.get_width()
	image_height = clampf(image_height, maxf(120.0, width * 1.12 - 174.0), minf(340.0, available.y - 174.0))
	var height := maxf(width * 1.12, image_height + 174.0)
	var origin := (size - Vector2(width, height)) / 2
	var panel := GuideUI.panel(_modal, Rect2(origin, Vector2(width, height)), GuideUI.CREAM, 26, Color("8bddf5"), 2)
	panel.name = "FoodPopup"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if food.image_texture != null:
		var picture := GuideUI.picture(panel, food.image_texture, Rect2(20, 20, width - 40, image_height))
		picture.name = "FoodImage"
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		GuideUI.panel(panel, Rect2(20, 20, width - 40, image_height), Color("d2edf6"), 18)
		GuideUI.label(panel, "美食图片待补充", Rect2(20, 20, width - 40, image_height), 19, Color("46768a"), true)
	var food_name := GuideUI.label(panel, food.name, Rect2(18, image_height + 30, width - 36, 34), 25, GuideUI.INK, true)
	food_name.name = "FoodName"
	var district := food.urban_district
	if district.is_empty() and (food.district.ends_with("区") or food.district.ends_with("市") or food.district.ends_with("县")):
		district = food.district
	var district_text := "所在城区 · " + district if not district.is_empty() else "所在城区 · 待补充"
	var area := GuideUI.label(panel, district_text, Rect2(18, image_height + 70, width - 36, 26), 15, Color("547c8d"), true)
	area.name = "FoodDistrict"
	GuideUI.button(panel, "知道了", Rect2(38, image_height + 112, width - 76, 44), _close_modal, true)

func _message(title: String, body: String, food_index: int = -1) -> void:
	_close_modal()
	_modal = Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_modal)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.07, 0.11, 0.72)
	_modal.add_child(shade)
	GuideUI.panel(_modal, Rect2(34, 252, 412, 318), GuideUI.CREAM, 25, GuideUI.GOLD, 2)
	if food_index >= 0:
		GuideUI.food_art(_modal, _city, food_index, Rect2(189, 267, 102, 92))
	else:
		GuideUI.label(_modal, "✦", Rect2(0, 268, 480, 80), 44, GuideUI.GOLD, true)
	GuideUI.label(_modal, title, Rect2(54, 364, 372, 40), 23, GuideUI.INK, true)
	var copy := GuideUI.label(_modal, body, Rect2(65, 410, 350, 78), 16, Color("547c8d"), true)
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
