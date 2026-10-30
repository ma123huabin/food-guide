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
	print("QA viewport=" + str(root.size) + " logical=" + str(main.size))
	await click_at(Vector2(240, 778))
	check(home._busy, "real button starts carousel")
	await click_at(Vector2(240, 778))
	check(_gd.lit_count() == 0, "drawing cannot be completed by rapid double click")
	await create_timer(3.9).timeout
	check(_gd.lit_count() == 1, "animation lights exactly one city")
	check(not home._busy, "carousel unlocks after animation")
	await capture("home-lit.png")
	await click_at(Vector2(240, 411))
	check(main.detail.visible and not home.visible, "click lit center card opens detail")
	var detail = main.detail
	for city in _gd.cities:
		if not city.locked:
			check(_loc.contains_coordinate(city.city_id, city.center_lat, city.center_lng), "city center is within administrative boundary: " + city.city_id)
	check(_loc.contains_coordinate("yichang", 30.825, 110.976), "Yichang includes Zigui beyond center radius")
	check(_loc.contains_coordinate("chengdu", 31.0036, 103.6186), "Chengdu includes Dujiangyan beyond center radius")
	check(not _loc.contains_coordinate("chengdu", 29.56, 106.55), "Chongqing is outside Chengdu boundary")
	await click_at(Vector2(85, 205))
	check(is_instance_valid(detail._modal), "food card opens introduction")
	detail._close_modal()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(350, 205)
	root.push_input(press, true)
	var swipe := InputEventMouseMotion.new()
	swipe.position = Vector2(120, 205)
	swipe.relative = Vector2(-230, 0)
	swipe.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(swipe, true)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = Vector2(120, 205)
	root.push_input(release, true)
	await process_frame
	check(detail._food_scroll.scroll_horizontal > 0 and not is_instance_valid(detail._modal), "food swipe scrolls without accidental popup")
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
	await click_at(Vector2(128, 464))
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
	check(_gd.checkins.has("yichang") and _gd.lit_count() == 4, "progress survives save and reload without duplicate cities")
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
