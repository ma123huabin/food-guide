extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1

func run() -> void:
	var data = root.get_node("GameData")
	var location = root.get_node("LocationService")
	data.SAVE_PATH = "user://location-flow-qa-%d.json" % Time.get_ticks_usec()
	data.checkins.clear()
	data.set_lit("yichang")
	var main = load("res://scripts/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.home.hide()
	main.detail.show()
	var detail = main.detail
	detail.load_city("yichang")
	detail._check_in()
	check(is_instance_valid(detail._modal) and detail._pending_city.is_empty() and not location._busy, "consent dialog opens without requesting location")
	check(detail._modal.get_node("LocationDialog/LocationPrimary").text == "同意并定位", "consent action explains next step")
	detail._close_modal()
	check(not data.checkins.has("yichang"), "dismissing consent does not check in")
	detail._pending_city = "yichang"
	location._last_lat = 0.0
	location._last_lng = 0.0
	detail._on_location(0.0, 0.0)
	check(not data.checkins.has("yichang") and detail._pending_city.is_empty(), "outside city rejects check-in and clears loading")
	check(detail._modal.get_node("LocationDialog/LocationPrimary").text == "重新定位", "outside-city result offers retry")
	detail._pending_city = "yichang"
	detail._on_failed("定位权限未开启")
	check(not data.checkins.has("yichang") and not detail._check_button.disabled, "permission failure allows retry without recording check-in")
	detail._pending_city = "yichang"
	location._last_lat = 30.69
	location._last_lng = 111.29
	detail._on_location(30.69, 111.29)
	check(data.checkins.has("yichang") and detail._check_button.disabled and detail._check_button.text == "✓  城市已点亮", "in-city result saves check-in and prevents duplicates")
	check(location.contains_coordinate("hangzhou", 30.2741, 120.1551), "Hangzhou center passes boundary verification")
	detail.load_city("hangzhou")
	detail._check_in()
	await process_frame
	check(detail._check_button.text == "点亮城市" and is_instance_valid(detail._modal), "Hangzhou can start the consent flow")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("D:/软件安装位置/Codex/food-guide-build/location-consent.png")
	detail._close_modal()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("D:/软件安装位置/Codex/food-guide-build/location-detail.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(data.SAVE_PATH))
	quit(failures)
