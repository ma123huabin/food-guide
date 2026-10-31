extends Node

var ACTIVE_CITY_COUNT: int = 0
var cities: Array[CityData] = []
var lit_city_id: String = ""
var lit_cities: Array[String] = []
var checkins: Dictionary = {}
var SAVE_PATH = "user://food-journey-v1.json"

func _ready() -> void:
	_build_cities()
	_load_progress()

func _build_cities() -> void:
	cities.clear()
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/cities.json"))
	if not data is Dictionary or not data.get("cities") is Array:
		push_error("城市数据表格式错误")
		return
	for row in data.cities:
		if not row.get("enabled", true):
			continue
		var city := CityData.new()
		city.city_id = row.id
		city.display_name = row.name
		city.tagline = row.get("tagline", "")
		city.cover_texture = _image(row.get("cover_image", {}))
		city.map_texture = _image(row.get("flat_map_image", {}))
		city.food_atlas_index = int(row.get("food_atlas_index", -1))
		city.center_lat = float(row.get("center_lat", 0))
		city.center_lng = float(row.get("center_lng", 0))
		for item in row.get("foods", []):
			var food := _pack_food(item.name, item.get("district", "城市特色"))
			food.image_texture = _image(item.get("image", {}))
			food.urban_district = item.get("urban_district", "")
			city.popular_foods.append(food)
			# Only mapped foods get a pin; do not invent central coordinates for new foods.
			var p: Array = item.get("map_position", [])
			if p.size() == 2:
				city.food_spots.append(_pack_spot(item.name, item.get("urban_district", item.get("district", "城市特色")), float(p[0]), float(p[1]), item.get("description", "")))
		cities.append(city)
	ACTIVE_CITY_COUNT = cities.size()

func _image(spec: Dictionary) -> Texture2D:
	var path: String = spec.get("path", "")
	if path.is_empty():
		return null
	var texture := load(path) as Texture2D
	if texture == null or not spec.has("index"):
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	var columns: int = int(spec.get("columns", 1))
	var rows: int = int(spec.get("rows", 1))
	var index: int = int(spec.index)
	var cell := texture.get_size() / Vector2(columns, rows)
	atlas.region = Rect2(Vector2(index % columns, index / columns) * cell, cell)
	return atlas

func get_city(city_id: String) -> CityData:
	for c: CityData in cities:
		if c.city_id == city_id:
			return c
	return null

func get_lit_city() -> CityData:
	if lit_city_id.is_empty():
		return null
	return get_city(lit_city_id)

func set_lit(city_id: String) -> void:
	if get_city(city_id) == null or get_city(city_id).locked:
		return
	lit_city_id = city_id
	if not lit_cities.has(city_id):
		lit_cities.append(city_id)
	_save_progress()

func _pack_food(name: String, district: String) -> PopularFoodData:
	var f := PopularFoodData.new()
	f.name = name
	f.district = district
	return f

func _pack_spot(name: String, district: String, x: float, y: float, desc: String) -> FoodSpotData:
	var s := FoodSpotData.new()
	s.name = name
	s.district = district
	s.pos_x = x
	s.pos_y = y
	s.desc = desc
	return s

func city_index(city_id: String) -> int:
	for i in range(cities.size()):
		if cities[i].city_id == city_id:
			return i
	return 0

func is_lit(city_id: String) -> bool:
	return lit_cities.has(city_id)

func lit_count() -> int:
	return lit_cities.size()

func record_checkin(city_id: String) -> void:
	if not is_lit(city_id):
		return
	if not checkins.has(city_id):
		checkins[city_id] = Time.get_datetime_string_from_system()
	_save_progress()

func _save_progress() -> void:
	var f := FileAccess.open(SAVE_PATH + ".pending", FileAccess.WRITE)
	if f == null:
		push_warning("无法保存城市足迹")
		return
	f.store_string(JSON.stringify({"lit": lit_cities, "last": lit_city_id, "checkins": checkins}))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".pending"), ProjectSettings.globalize_path(SAVE_PATH))

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary:
		return
	var saved_lit = data.get("lit", [])
	if saved_lit is Array:
		for id in saved_lit:
			if id is String and get_city(id) != null and not get_city(id).locked and not lit_cities.has(id):
				lit_cities.append(id)
	var last = data.get("last", "")
	if last is String and lit_cities.has(last):
		lit_city_id = last
	var saved_checkins = data.get("checkins", {})
	if saved_checkins is Dictionary:
		for id in saved_checkins:
			if lit_cities.has(id) and saved_checkins[id] is String:
				checkins[id] = saved_checkins[id]
