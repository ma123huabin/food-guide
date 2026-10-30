extends Node

## 全局游戏数据：城市列表、当前点亮城市。
## 作为服务定位器提供跨场景数据，不含任何游戏玩法逻辑。

const ACTIVE_CITY_COUNT = 5
var cities: Array[CityData] = []
var lit_city_id: String = ""
var lit_cities: Array[String] = []
var checkins: Dictionary = {}
const SAVE_PATH = "user://food-journey-v1.json"

func _ready() -> void:
	_build_cities()
	_load_progress()

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

func _build_cities() -> void:
	cities.clear()

	# 宜昌：使用真实手绘地图素材
	var yichang := CityData.new()
	yichang.city_id = "yichang"
	yichang.display_name = "宜昌"
	yichang.emoji = "🏞️"
	yichang.theme_color = Color("#4A9E7F")
	yichang.center_lat = 30.69
	yichang.center_lng = 111.29
	yichang.radius_km = 30.0
	# All four new maps are selected from the map atlas in CityDetailScreen.
	yichang.popular_foods = [
		_pack_food("红油小面", "解放路"),
		_pack_food("萝卜饺子", "西陵"),
		_pack_food("肥鱼火锅", "滨江"),
		_pack_food("清江鱼糕", "夷陵"),
	]
	yichang.food_spots = [
		_pack_spot("红油小面", "解放路", 0.32, 0.40, "麻辣鲜香，风味独特"),
		_pack_spot("萝卜饺子", "西陵", 0.45, 0.55, "外皮焦脆，馅料鲜嫩"),
		_pack_spot("肥鱼火锅", "滨江", 0.60, 0.35, "江鲜美味，汤浓肉嫩"),
		_pack_spot("清江鱼糕", "夷陵", 0.55, 0.62, "鱼肉细腻，口感弹牙"),
		_pack_spot("炕土豆", "步行街", 0.40, 0.70, "焦黄软糯，香气扑鼻"),
	]
	cities.append(yichang)

	# 成都
	var cd := CityData.new()
	cd.city_id = "chengdu"
	cd.display_name = "成都"
	cd.emoji = "🐼"
	cd.theme_color = Color("#E8542A")
	cd.center_lat = 30.57
	cd.center_lng = 104.07
	cd.radius_km = 30.0
	cd.popular_foods = [
		_pack_food("火锅", "春熙路"),
		_pack_food("串串香", "玉林"),
		_pack_food("担担面", "宽窄巷子"),
		_pack_food("龙抄手", "锦江"),
	]
	cd.food_spots = [
		_pack_spot("火锅", "春熙路", 0.35, 0.45, "麻辣鲜香，红油翻滚"),
		_pack_spot("串串香", "玉林", 0.50, 0.60, "市井烟火，自选竹签"),
		_pack_spot("担担面", "宽窄巷子", 0.45, 0.35, "咸鲜微辣，麻香十足"),
	]
	cities.append(cd)

	# 重庆
	var cq := CityData.new()
	cq.city_id = "chongqing"
	cq.display_name = "重庆"
	cq.emoji = "🌶️"
	cq.theme_color = Color("#C0392B")
	cq.center_lat = 29.56
	cq.center_lng = 106.55
	cq.radius_km = 30.0
	cq.popular_foods = [
		_pack_food("重庆小面", "解放碑"),
		_pack_food("老火锅", "洪崖洞"),
		_pack_food("酸辣粉", "磁器口"),
		_pack_food("辣子鸡", "歌乐山"),
	]
	cq.food_spots = [
		_pack_spot("重庆小面", "解放碑", 0.40, 0.50, "麻辣鲜香，清晨一碗"),
		_pack_spot("老火锅", "洪崖洞", 0.55, 0.40, "牛油厚味，九宫格"),
		_pack_spot("酸辣粉", "磁器口", 0.45, 0.65, "酸辣开胃，红薯粉爽滑"),
	]
	cities.append(cq)

	# 广州
	var gz := CityData.new()
	gz.city_id = "guangzhou"
	gz.display_name = "广州"
	gz.emoji = "🍤"
	gz.theme_color = Color("#F0A030")
	gz.center_lat = 23.13
	gz.center_lng = 113.26
	gz.radius_km = 30.0
	gz.popular_foods = [
		_pack_food("早茶", "上下九"),
		_pack_food("烧腊", "北京路"),
		_pack_food("肠粉", "西关"),
		_pack_food("艇仔粥", "荔湾"),
	]
	gz.food_spots = [
		_pack_spot("早茶", "上下九", 0.40, 0.50, "一盅两件，慢享晨光"),
		_pack_spot("烧腊", "北京路", 0.55, 0.45, "油亮甘香，斩件拼盘"),
		_pack_spot("肠粉", "西关", 0.45, 0.65, "米浆滑爽，酱油点睛"),
	]
	cities.append(gz)

	# 泉州：独立山海手绘地图。
	var qz := CityData.new()
	qz.city_id = "quanzhou"
	qz.display_name = "泉州"
	qz.emoji = "🏯"
	qz.theme_color = Color("#358eaa")
	qz.center_lat = 24.874
	qz.center_lng = 118.675
	qz.map_texture = load("res://assets/maps/quanzhou.png")
	qz.popular_foods = [
		_pack_food("面线糊", "古城"),
		_pack_food("肉粽", "西街"),
		_pack_food("姜母鸭", "鲤城"),
		_pack_food("土笋冻", "晋江"),
	]
	qz.food_spots = [
		_pack_spot("面线糊", "古城", 0.60, 0.54, "细面线熬成糊，佐以海鲜、卤味与油条，是泉州街巷的熟悉滋味。"),
		_pack_spot("肉粽", "西街", 0.50, 0.49, "糯米包裹卤肉与香菇，搭配酱料，咸香软糯。"),
		_pack_spot("姜母鸭", "鲤城", 0.68, 0.63, "老姜与鸭肉在砂锅中慢煨，姜香浓郁。"),
		_pack_spot("土笋冻", "晋江", 0.52, 0.76, "闽南特色冷食，晶莹爽口，配蒜蓉与酱汁品尝。"),
	]
	cities.append(qz)

	# 待解锁城市（对应首页灰色小卡）
	var xa := CityData.new()
	xa.city_id = "xian"
	xa.display_name = "西安"
	xa.emoji = "🏯"
	xa.locked = true
	cities.append(xa)

	var wh := CityData.new()
	wh.city_id = "wuhan"
	wh.display_name = "武汉"
	wh.emoji = "🌉"
	wh.locked = true
	cities.append(wh)

	# Illustrated positions are schematic; spread targets so every food stays tappable.
	var map_positions: Array[Vector2] = [Vector2(0.22, 0.24), Vector2(0.18, 0.62), Vector2(0.75, 0.32), Vector2(0.75, 0.72), Vector2(0.38, 0.86)]
	for city in cities:
		if city.city_id == "quanzhou":
			continue
		for i in range(city.food_spots.size()):
			city.food_spots[i].pos_x = map_positions[i].x
			city.food_spots[i].pos_y = map_positions[i].y

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
