extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1

func covered(view: MapViewport) -> bool:
	var extent := view._world.size * view._world.scale
	return view._world.position.x <= 0.01 and view._world.position.y <= 0.01 and view._world.position.x + extent.x >= view.size.x - 0.01 and view._world.position.y + extent.y >= view.size.y - 0.01

func run() -> void:
	var main = load("res://scripts/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.home.visible = false
	main.detail.visible = true
	for id in ["yichang", "chengdu", "chongqing", "guangzhou", "quanzhou"]:
		main.detail.load_city(id)
		await process_frame
		var view: MapViewport = main.detail._map_view
		check(view.size == Vector2(main.size.x, 748) and covered(view), id + " map covers its clipped page area")
		var tray: Control = main.detail._dynamic.get_node("FoodTray")
		check(tray.position == Vector2(18, 550) and main.detail._check_button.position == Vector2(28, 756), "overlay positions remain fixed")
		for factor in [1.5, 2.0, 100.0, 0.02]:
			view.zoom_at(factor, Vector2(180, 280))
			for delta in [Vector2(100000, 100000), Vector2(-100000, -100000), Vector2(100000, -100000), Vector2(-100000, 100000)]:
				view.pan_by(delta)
				check(covered(view), "pan and zoom never expose blank pixels")
		check(is_equal_approx(view._zoom, 1.0), "zoom out stops at screen-cover scale")
		view._fit()
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = Vector2(160, 250)
		touch.pressed = true
		view._gui_input(touch)
		var second := InputEventScreenTouch.new()
		second.index = 1
		second.position = Vector2(260, 250)
		second.pressed = true
		view._gui_input(second)
		var drag := InputEventScreenDrag.new()
		drag.index = 1
		drag.position = Vector2(360, 250)
		view._gui_input(drag)
		check(view._zoom > 1.0 and covered(view), "two-finger pinch zooms while preserving coverage")
		second.pressed = false
		view._gui_input(second)
		touch.pressed = false
		view._gui_input(touch)
		check(not is_instance_valid(main.detail._modal), "pinch does not accidentally open a food modal")
		view.size = Vector2(854, 480)
		view._fit()
		check(covered(view), "resized landscape viewport also stays covered")
	print("MAP_QA failures=" + str(failures))
	quit(0 if failures == 0 else 1)
