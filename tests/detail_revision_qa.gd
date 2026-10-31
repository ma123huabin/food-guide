extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("D:/软件安装位置/Codex/food-guide-build/" + name + ".png")
func run() -> void:
	var main = load("res://scripts/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.home.hide()
	main.detail.show()
	var detail = main.detail
	for id in ["beijing", "shanghai", "xian", "hangzhou"]:
		detail.load_city(id)
		check(detail._city.map_texture != null, id + " latest map loads")
	detail.load_city("chongqing")
	await process_frame
	await process_frame
	check(detail._food_scroll.get_child(0).get_child(0).size.x == 112, "initial viewport shows three and a half cards")
	await capture("revised-chongqing")
	detail._toggle_food_tray()
	await create_timer(0.3).timeout
	check(detail._food_tray.position.y == 676 and detail._food_tray.size.y == 54, "collapse moves tray down to its heading")
	await capture("revised-collapsed")
	detail._toggle_food_tray()
	await create_timer(0.3).timeout
	check(detail._food_tray.position.y == 550 and detail._food_tray.size.y == 180, "expand restores tray")
	var city = detail._city
	city.popular_foods.append(city.popular_foods[0])
	city.popular_foods.append(city.popular_foods[1])
	detail.load_city("chongqing")
	await process_frame
	await process_frame
	var press := InputEventScreenTouch.new()
	press.pressed = true
	press.position = Vector2(360, 20)
	detail._on_food_input(press)
	var drag := InputEventScreenDrag.new()
	drag.position = Vector2(50, 20)
	detail._on_food_input(drag)
	press.pressed = false
	press.position = drag.position
	detail._on_food_input(press)
	check(detail._food_scroll.scroll_horizontal > 0 and not is_instance_valid(detail._modal), "six foods swipe without opening modal")
	city.popular_foods.resize(4)
	detail.load_city("chengdu")
	detail._show_food(0)
	await process_frame
	await capture("revised-food-popup")
	check(detail._modal.get_node("FoodPopup/FoodImage").texture.get_height() == 303, "food crop uses actual row boundary")
	var food_extent: Vector2 = detail._modal.get_node("FoodPopup").size
	detail._message("暂时无法完成打卡", "定位服务暂不可用，请稍后再试。")
	check(detail._modal.get_node("MessagePopup").size == food_extent, "all popup types share reference dimensions")
	var popup: Control = detail._modal.get_node("MessagePopup")
	var ack: Button
	for child in popup.get_children():
		if child is Button: ack = child
	check(ack != null and ack.text == "知道了", "shared popup retains acknowledgement action")
	ack.pressed.emit()
	check(not is_instance_valid(detail._modal), "shared acknowledgement closes popup")
	check(detail._map_view.size.y == 748 and detail._dynamic.get_node("MapPageFade").position.y == 670, "map ends above bottom action with independent page fade")
	print("DETAIL_QA failures=" + str(failures))
	quit(failures)
