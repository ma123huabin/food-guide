extends SceneTree

var _had_save: bool
var _save: String
var _failures: int = 0
var _gd: Node
var _loc: Node

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		_failures += 1
		printerr("FAIL: " + message)
	else:
		print("PASS: " + message)

func click_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.position = point
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		root.push_input(e, true)
		await process_frame

func capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("D:/软件安装位置/Codex/food-guide-build/" + filename)

func _run() -> void:
	_gd = root.get_node("GameData")
	_gd.SAVE_PATH = "user://food-journey-qa.json"
	_loc = root.get_node("LocationService")
	_had_save = FileAccess.file_exists(_gd.SAVE_PATH)
	if _had_save:
		_save = FileAccess.get_file_as_string(_gd.SAVE_PATH)
	_gd.lit_cities.clear()
	_gd.checkins.clear()
	_gd.lit_city_id = ""
	var main = load("res://scripts/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await create_timer(0.5).timeout
	await capture("home.png")
	var home = main.home
	# Exercise timer-driven movement, wrapping, visibility pause and manual delay.
	var initial_lit: int = _gd.lit_count()
	home.autoplay_interval = 0.2
	home.autoplay_transition_duration = 0.05
	home._autoplay_remaining = 0.01
	var before: int = home._selected
	await create_timer(0.12).timeout
	check(home._selected == (before + 1) % _gd.ACTIVE_CITY_COUNT, "autoplay advances without a click")
	check(_gd.lit_count() == initial_lit, "autoplay never lights a city")
	home._select_thumb(_gd.ACTIVE_CITY_COUNT - 1)
	await create_timer(0.4).timeout
	home._autoplay_remaining = 0.01
	await create_timer(0.12).timeout
	check(home._selected == 0, "autoplay wraps from last city to first")
	home.autoplay_direction = -1
	home._autoplay_remaining = 0.01
	await create_timer(0.12).timeout
	check(home._selected == _gd.ACTIVE_CITY_COUNT - 1, "reverse autoplay wraps to last city")
	home.visible = false
	before = home._selected
	await create_timer(0.4).timeout
	check(home._selected == before, "autoplay pauses while home is hidden")
	home.visible = true
	home._select_thumb(0)
	await create_timer(0.7).timeout
	check(home._selected == 0, "manual selection pauses autoplay")
	home.autoplay_enabled = false
	home._autoplay_remaining = 0.01
	await create_timer(0.3).timeout
	check(home._selected == 0, "autoplay switch disables automatic movement")
	home.autoplay_enabled = true
	home.autoplay_direction = 1
	home.autoplay_interval = 3.0
	home.autoplay_transition_duration = 0.45
	home._autoplay_remaining = 3.0
	var removed_copy := ["城 市 寻 味  /  FOOD JOURNEY", "✧  一城一味 · 风物收藏  ✧", "已点亮 · 点击探索  →", "等待你的美食奇遇"]
	var removed_found := false
	for label in home.find_children("*", "Label", true, false):
		if label.text in removed_copy or label.text.begins_with("已点亮 0 /"):
			removed_found = true
	check(not removed_found, "red-box text removed from all carousel copies")
	print("QA viewport=" + str(root.size) + " logical=" + str(main.size))
	await click_at(Vector2(240, 778))
	check(home._busy, "real button starts carousel")
	await click_at(Vector2(240, 778))
	check(_gd.lit_count() == 0, "drawing cannot be completed by rapid double click")
	await create_timer(5.4).timeout
	check(_gd.lit_count() == 1, "animation lights exactly one city")
	check(not home._busy, "carousel unlocks after animation")
	await capture("home-lit.png")
	await click_at(Vector2(42, 680))
	check(main.detail.visible and not home.visible, "collected thumbnail opens detail after big card leaves list")
	var detail = main.detail
	for city in _gd.cities:
		if _loc.has_boundary(city.city_id):
			check(_loc.contains_coordinate(city.city_id, city.center_lat, city.center_lng), "city center is within administrative boundary: " + city.city_id)
	check(_loc.contains_coordinate("yichang", 30.825, 110.976), "Yichang includes Zigui beyond center radius")
	check(_loc.contains_coordinate("chengdu", 31.0036, 103.6186), "Chengdu includes Dujiangyan beyond center radius")
	check(not _loc.contains_coordinate("chengdu", 29.56, 106.55), "Chongqing is outside Chengdu boundary")
	await click_at(Vector2(78, 660))
	check(is_instance_valid(detail._modal), "food card opens introduction")
	var food_popup: Control = detail._modal.get_node("FoodPopup")
	check(food_popup.size.y > food_popup.size.x and food_popup.position.y >= 0 and food_popup.position.y + food_popup.size.y <= detail.size.y, "food popup is portrait and fits phone screen")
	check(food_popup.get_node("FoodName").position.y < food_popup.get_node("FoodDistrict").position.y, "food name appears before its urban district")
	var popup_buttons := food_popup.find_children("*", "Button", true, false)
	check(popup_buttons.size() == 1 and popup_buttons[0] is TravelButton, "food popup uses blue travel capsule button")
	detail._close_modal()
	await click_at(Vector2(400, 660))
	check(is_instance_valid(detail._modal), "fourth food card is fully visible and clickable")
	detail._close_modal()
	check(detail._food_scroll.get_h_scroll_bar().max_value <= detail._food_scroll.size.x, "four food cards fit without horizontal clipping")
	var map_host: Control = detail._map_view
	var food_tray: Control = detail._dynamic.get_node("FoodTray")
	check((map_host == null or (map_host is MapViewport and map_host.size == main.size)) and food_tray.position == Vector2(18, 550), "available full-screen map sits beneath fixed food tray")
	for city in _gd.cities:
		if city.locked:
			continue
		_gd.set_lit(city.city_id)
		detail.load_city(city.city_id)
		detail.visible = true
		home.visible = false
		await process_frame
		await capture("detail-" + city.city_id + ".png")
		check(detail._city.food_spots.size() >= 3, "food pins present: " + city.city_id)
	# Test location decisions with injected coordinates; never fabricate a live location.
	detail.load_city("yichang")
	await process_frame
	detail._map_view._pick(detail._map_view._world.position + detail._map_view._spots[0] * detail._map_view._world.scale)
	check(is_instance_valid(detail._modal), "map red pin opens introduction")
	detail._close_modal()
	detail._pending_city = "yichang"
	_loc._last_lat = 0.0
	_loc._last_lng = 0.0
	_loc.location_resolved.emit(0.0, 0.0)
	check(not _gd.checkins.has("yichang"), "out-of-city location rejects check-in")
	detail._close_modal()
	detail._pending_city = "yichang"
	_loc.location_failed.emit("测试权限拒绝")
	check(not _gd.checkins.has("yichang") and detail._pending_city.is_empty(), "permission failure resets state without check-in")
	detail._close_modal()
	detail._pending_city = "yichang"
	_loc._last_lat = 30.69
	_loc._last_lng = 111.29
	_loc.location_resolved.emit(30.69, 111.29)
	check(_gd.checkins.has("yichang"), "in-range location records check-in")
	await capture("checkin.png")
	_gd._load_progress()
	check(_gd.checkins.has("yichang") and _gd.lit_count() == _gd.ACTIVE_CITY_COUNT, "progress survives save and reload without duplicate cities")
	detail._close_modal()
	await click_at(Vector2(59, 40))
	check(home.visible and not detail.visible, "back button returns home")
	if _had_save:
		var f := FileAccess.open(_gd.SAVE_PATH, FileAccess.WRITE)
		f.store_string(_save)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_gd.SAVE_PATH))
	print("QA_COMPLETE failures=" + str(_failures))
	quit(0 if _failures == 0 else 1)
