extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main = load("res://scripts/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var data = root.get_node("GameData")
	var failures := 0
	var count := 0
	main.home.hide()
	main.detail.show()
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/cities.json"))
	for row in catalog.cities:
		var mapped := 0
		var seen := {}
		for item in row.foods:
			if seen.has(item.name): failures += 1
			seen[item.name] = true
			if item.has("map_position"): mapped += 1
			else:
				if item.get("sources", []).is_empty(): failures += 1
		if data.get_city(row.id).food_spots.size() != mapped: failures += 1
	if data.cities.size() != 25:
		failures += 1
	for city in data.cities:
		main.detail.load_city(city.city_id)
		await process_frame
		await process_frame
		if city.popular_foods.is_empty():
			failures += 1
		for food in city.popular_foods:
			count += 1
			if food.name.is_empty() or food.urban_district.is_empty():
				push_error("Missing food region: " + city.display_name + food.name)
				failures += 1
		for index in range(city.popular_foods.size()):
			main.detail._food_message(index)
			var popup = main.detail._modal.get_node("FoodPopup")
			if popup.get_node("FoodName").text != city.popular_foods[index].name or popup.get_node("FoodDistrict").text != "推荐区域 · " + city.popular_foods[index].urban_district:
				failures += 1
			main.detail._close_modal()
		var detail = main.detail
		var press := InputEventScreenTouch.new()
		press.pressed = true
		press.position = Vector2(360, 20)
		detail._on_food_input(press)
		var drag := InputEventScreenDrag.new()
		drag.position = Vector2(-10000, 20)
		detail._on_food_input(drag)
		press.pressed = false
		press.position = drag.position
		detail._on_food_input(press)
		if detail._food_scroll.scroll_horizontal <= 0 or is_instance_valid(detail._modal): failures += 1
		var last_x: float = (city.popular_foods.size() - 1) * 122 - detail._food_scroll.scroll_horizontal + 56
		if last_x < 0 or last_x > detail._food_scroll.size.x: failures += 1
		press.position = Vector2(last_x, 20)
		press.pressed = true
		detail._on_food_input(press)
		press.pressed = false
		detail._on_food_input(press)
		if not is_instance_valid(detail._modal):
			failures += 1
		elif detail._modal.get_node("FoodPopup/FoodName").text != city.popular_foods[-1].name:
			failures += 1
		detail._close_modal()
	print("FOOD REGIONS QA: %d cities, %d foods, %d failures" % [data.cities.size(), count, failures])
	quit(0 if failures == 0 else 1)
