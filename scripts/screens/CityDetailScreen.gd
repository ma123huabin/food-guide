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
var _food_tray: Panel
var _tray_collapsed := false
var _tray_toggle: Button
var _tray_tween: Tween

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
	_tray_collapsed = false
	if _tray_tween:
		_tray_tween.kill()
	if _city == null:
		return
	var back := GuideUI.button(_dynamic, "‹  返回", Rect2(20, 24, 80, 34), func() -> void: EventBus.request_home.emit())
	back.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed"]:
		back.add_theme_stylebox_override(state, GuideUI.box(GuideUI.CREAM, 15, Color("b58c46"), 2))
	var header := GuideUI.label(_dynamic, "%s · 寻味地图" % _city.display_name, Rect2(107, 24, 267, 34), 22, GuideUI.INK, true)
	var title_frame := ReferenceFrame.new()
	title_frame.kind = "title"
	title_frame.position = header.position
	title_frame.size = header.size
	_dynamic.add_child(title_frame)
	_dynamic.move_child(title_frame, header.get_index())
	header.add_theme_font_override("font", load("res://assets/fonts/行楷.ttf"))
	header.add_theme_constant_override("outline_size", 0)
	header.add_theme_color_override("font_outline_color", GuideUI.CREAM)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var map_texture: Texture2D = _city.map_texture
	_map_view = null
	if map_texture != null:
		_map_view = MapViewport.new()
		_map_view.name = "CityMap"
		_dynamic.add_child(_map_view)
		_map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_map_view.anchor_right = 0.0
		_map_view.offset_right = get_viewport_rect().size.x
		_map_view.anchor_bottom = 0.0
		_map_view.offset_bottom = 748.0
		_dynamic.move_child(_map_view, 0)
		_map_view.configure(map_texture, _city.food_spots)
		_map_view.spot_pressed.connect(_show_spot)
		var fade := ColorRect.new()
		fade.name = "MapPageFade"
		fade.position = Vector2(0, 670)
		fade.size = Vector2(480, 78)
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fade_shader := Shader.new()
		fade_shader.code = """shader_type canvas_item;
uniform sampler2D paper : source_color;
void fragment() {
 vec2 page_uv = vec2(UV.x, (670.0 + UV.y * 78.0) / 854.0);
 vec4 background = texture(paper, page_uv);
 COLOR = vec4(background.rgb, smoothstep(0.0, 1.0, UV.y));
}"""
		var fade_material := ShaderMaterial.new()
		fade_material.shader = fade_shader
		fade_material.set_shader_parameter("paper", load("res://img/界面皮肤/首页精确背景.png"))
		fade.material = fade_material
		_dynamic.add_child(fade)
	else:
		GuideUI.label(_dynamic, "✧", Rect2(0, 168, 480, 80), 48, GuideUI.GOLD, true)
		GuideUI.label(_dynamic, _city.display_name + "美食地图绘制中", Rect2(0, 263, 480, 40), 23, Color("6b2615"), true)
		GuideUI.label(_dynamic, "从下方美食卡片，认识这座城市的味道", Rect2(0, 320, 480, 30), 13, Color("80583c"), true)
	var map_note := GuideUI.label(_dynamic, "手绘点位为风味示意，非实时导航地图" if map_texture != null else "城市美食地图与城市封面图独立制作", Rect2(0, 520, 480, 20), 10, Color("6b2615"), true)
	map_note.add_theme_constant_override("outline_size", 3)
	map_note.add_theme_color_override("font_outline_color", GuideUI.CREAM)
	# Fixed overlay: map moves underneath while the food tray stays in place.
	var tray := GuideUI.panel(_dynamic, Rect2(18, 550, 444, 180), Color("fff5df"), 24)
	GuideUI.skin_frame(tray, 0.12)
	tray.name = "FoodTray"
	_food_tray = tray
	tray.clip_contents = true
	tray.mouse_filter = Control.MOUSE_FILTER_STOP
	var tray_style := tray.get_theme_stylebox("panel") as StyleBoxFlat
	tray_style.shadow_color = Color(0.0, 0.12, 0.20, 0.25)
	tray_style.shadow_size = 14
	tray_style.shadow_offset = Vector2(0, 6)
	var tray_title := GuideUI.label(tray, "推荐美食点", Rect2(40, 6, 364, 30), 23, Color("7e210c"), true)
	tray_title.add_theme_font_override("font", load("res://assets/fonts/行楷.ttf"))
	GuideUI.label(tray, "舌尖上的%s" % _city.display_name, Rect2(40, 36, 364, 18), 11, Color("85674d"), true)
	var heading := GuideUI.button(tray, "", Rect2(0, 0, 392, 54), _toggle_food_tray)
	for state in ["normal", "hover", "pressed", "focus"]:
		heading.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_tray_toggle = GuideUI.button(tray, "⌄", Rect2(394, 8, 36, 32), _toggle_food_tray)
	_tray_toggle.name = "TrayToggle"
	_tray_toggle.tooltip_text = "收起推荐美食"
	var scroll := ScrollContainer.new()
	_food_scroll = scroll
	scroll.position = Vector2(11, 58)
	scroll.size = Vector2(422, 116)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tray.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	scroll.add_child(row)
	for i in range(_city.popular_foods.size()):
		var food: PopularFoodData = _city.popular_foods[i]
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(112, 114)
		row.add_child(holder)
		var card := GuideUI.button(holder, "", Rect2(0, 0, 112, 112), _show_food.bind(i))
		GuideUI.skin_frame(card, 0.06)
		card.name = "FoodCard%d" % i
		GuideUI.food_art(card, _city, i, Rect2(7, 5, 98, 62))
		var food_title := GuideUI.label(card, food.name, Rect2(3, 67, 106, 23), 16, GuideUI.INK, true)
		food_title.add_theme_font_override("font", load("res://assets/fonts/行楷.ttf"))
		GuideUI.panel(card, Rect2(7, 92, 98, 16), Color("dce5c7"), 8)
		GuideUI.label(card, food.district, Rect2(7, 91, 98, 18), 10, Color("526344"), true)
	var gesture := Control.new()
	gesture.position = scroll.position
	gesture.size = scroll.size
	gesture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gesture.gui_input.connect(_on_food_input)
	tray.add_child(gesture)
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

func _toggle_food_tray() -> void:
	_tray_collapsed = not _tray_collapsed
	_food_pressing = false
	_tray_toggle.text = "⌃" if _tray_collapsed else "⌄"
	_tray_toggle.tooltip_text = "展开推荐美食" if _tray_collapsed else "收起推荐美食"
	if _tray_tween:
		_tray_tween.kill()
	_tray_tween = create_tween().set_parallel(true)
	_tray_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tray_tween.tween_property(_food_tray, "position:y", 676.0 if _tray_collapsed else 550.0, 0.25)
	_tray_tween.tween_property(_food_tray, "size:y", 54.0 if _tray_collapsed else 180.0, 0.25)

func _on_food_input(event: InputEvent) -> void:
	var is_pointer: bool = event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	if is_pointer:
		if event.pressed:
			_food_pressing = true
			_food_moved = false
			_food_start_x = event.position.x
			_food_scroll_start = _food_scroll.scroll_horizontal
		elif _food_pressing:
			_food_pressing = false
			if not _food_moved:
				var x: float = event.position.x + _food_scroll.scroll_horizontal
				var index := floori(x / 122.0)
				if fmod(x, 122.0) < 112.0 and index >= 0 and index < _city.popular_foods.size():
					_show_food(index)
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and _food_pressing:
		var delta: float = event.position.x - _food_start_x
		if absf(delta) > 8:
			_food_moved = true
		if _food_moved:
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
	var food: PopularFoodData = _city.popular_foods[index]
	var panel := _popup_shell()
	panel.name = "FoodPopup"
	var width := panel.size.x
	var scale_factor := width / 542.0
	var image_height := 400.0 * scale_factor
	if food.image_texture != null:
		var picture := GuideUI.picture(panel, food.image_texture, Rect2(18 * scale_factor, 80 * scale_factor, width - 36 * scale_factor, image_height))
		picture.name = "FoodImage"
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		GuideUI.panel(panel, Rect2(18 * scale_factor, 80 * scale_factor, width - 36 * scale_factor, image_height), Color("f1e4cb"), 18)
		GuideUI.label(panel, "美食图片待补充", Rect2(18 * scale_factor, 80 * scale_factor, width - 36 * scale_factor, image_height), 19, Color("85674d"), true)
	var food_name := GuideUI.label(panel, food.name, Rect2(18, 486 * scale_factor, width - 36, 77 * scale_factor), roundi(56 * scale_factor), GuideUI.INK, true)
	food_name.name = "FoodName"
	food_name.add_theme_font_override("font", load("res://assets/fonts/行楷.ttf"))
	food_name.add_theme_color_override("font_color", Color("650b04"))
	var district := food.urban_district
	if district.is_empty() and (food.district.ends_with("区") or food.district.ends_with("市") or food.district.ends_with("县")):
		district = food.district
	var district_text := "所在城区 · " + district if not district.is_empty() else "所在城区 · 待补充"
	var area := GuideUI.label(panel, district_text, Rect2(18, 572 * scale_factor, width - 36, 38 * scale_factor), roundi(23 * scale_factor), Color("85674d"), true)
	area.name = "FoodDistrict"
	var acknowledge := GuideUI.button(panel, "知道了", Rect2(90 * scale_factor, 630 * scale_factor, 362 * scale_factor, 82 * scale_factor), _close_modal, true)
	acknowledge.add_theme_font_size_override("font_size", roundi(43 * scale_factor))
	(acknowledge as TravelButton).use_popup_reference()

func _message(title: String, body: String, food_index: int = -1) -> void:
	var panel := _popup_shell()
	panel.name = "MessagePopup"
	var k := panel.size.x / 542.0
	if food_index >= 0:
		GuideUI.food_art(panel, _city, food_index, Rect2(100 * k, 80 * k, 342 * k, 240 * k))
	else:
		GuideUI.label(panel, "✦", Rect2(0, 80 * k, panel.size.x, 160 * k), roundi(76 * k), GuideUI.GOLD, true)
	var headline := GuideUI.label(panel, title, Rect2(25 * k, 300 * k, panel.size.x - 50 * k, 95 * k), roundi(43 * k), Color("650b04"), true)
	headline.add_theme_font_override("font", load("res://assets/fonts/行楷.ttf"))
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var copy := GuideUI.label(panel, body, Rect2(40 * k, 410 * k, panel.size.x - 80 * k, 180 * k), roundi(25 * k), Color("85674d"), true)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var acknowledge := GuideUI.button(panel, "知道了", Rect2(90 * k, 630 * k, 362 * k, 82 * k), _close_modal, true)
	(acknowledge as TravelButton).use_popup_reference()

func _popup_shell() -> Panel:
	_close_modal()
	_modal = Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_modal)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.10, 0.065, 0.025, 0.72)
	_modal.add_child(shade)
	var width := minf(320.0, minf(size.x - 48.0, (size.y - 72.0) * 542.0 / 742.0))
	var extent := Vector2(width, width * 742.0 / 542.0)
	var panel := Panel.new()
	panel.position = (size - extent) / 2
	panel.size = extent
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_modal.add_child(panel)
	var skin := FoodPopupSkin.new()
	panel.add_child(skin)
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel

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
