extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func run() -> void:
	var rows = JSON.parse_string(FileAccess.get_file_as_string("res://img/界面组件/组件映射.json"))
	check(rows.size() == 13, "all approved components have stable mappings")
	for row in rows:
		var texture := GuideUI.component(row.id)
		check(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "component loads: " + row.id)
	var main = load("res://scripts/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.home.hide()
	main.detail.show()
	var gd := root.get_node("GameData")
	for city in gd.cities:
		main.detail.load_city(city.city_id)
		await process_frame
		check(main.detail._food_scroll.size == Vector2(416, 128), "food viewport unchanged: " + city.city_id)
		check(main.detail._check_button.position == Vector2(28, 756), "action position unchanged: " + city.city_id)
		main.detail._show_food(0)
		var popup: Control = main.detail._modal.get_node("FoodPopup")
		var label: Label = popup.get_node("FoodName")
		check(label.clip_text and label.size.x <= popup.size.x, "variable food text stays in popup: " + city.city_id)
		main.detail._close_modal()
	print("COMPONENTS_QA cities=" + str(gd.cities.size()) + " assets=" + str(rows.size()) + " failures=" + str(failures))
	quit(failures)
