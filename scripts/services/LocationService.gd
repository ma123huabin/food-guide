extends Node

signal location_resolved(lat: float, lng: float)
signal location_failed(reason: String)

var _last_lat: float = NAN
var _last_lng: float = NAN
var _timer: Timer
var _busy: bool = false
var _deadline: int = 0
var _output_path: String = ""
var _token: String = ""
var _boundaries: Dictionary = {}

func _ready() -> void:
	var boundary_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/boundaries.json"))
	if boundary_data is Dictionary and boundary_data.get("cities") is Dictionary:
		_boundaries = boundary_data.cities
	_timer = Timer.new()
	_timer.wait_time = 0.3
	_timer.timeout.connect(_poll)
	add_child(_timer)

func request_location() -> void:
	if _busy:
		return
	_last_lat = NAN
	_last_lng = NAN
	_busy = true
	_token = str(Time.get_ticks_msec())
	_deadline = Time.get_ticks_msec() + 22000
	if OS.has_feature("web"):
		var js := """
		(function(){
		  const token = '%s';
		  window.__foodGeo = {token: token, done: false};
		  if (!navigator.geolocation) { window.__foodGeo = {token:token, done:true, error:'当前浏览器不支持定位'}; return; }
		  navigator.geolocation.getCurrentPosition(function(p){
		    if(window.__foodGeo.token === token) window.__foodGeo = {token:token, done:true, lat:p.coords.latitude, lng:p.coords.longitude, accuracy:p.coords.accuracy};
		  }, function(e){
		    if(window.__foodGeo.token === token) window.__foodGeo = {token:token, done:true, error:e.code === 1 ? '定位权限未开启，请允许浏览器使用位置后重试。' : '未能获得定位，请检查定位服务和网络后重试。'};
		  }, {enableHighAccuracy:true, timeout:15000, maximumAge:0});
		})();
		""" % _token
		JavaScriptBridge.eval(js, true)
	elif OS.get_name() == "Windows":
		_output_path = ProjectSettings.globalize_path("user://location-" + _token + ".json")
		var script_file := ProjectSettings.globalize_path("user://get-location.ps1")
		var f := FileAccess.open(script_file, FileAccess.WRITE)
		if f == null:
			_fail("无法启动定位，请检查应用数据目录权限。")
			return
		f.store_string("\uFEFF" + FileAccess.get_file_as_string("res://scripts/services/get-location.ps1"))
		f.close()
		var pid := OS.create_process("powershell.exe", PackedStringArray(["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass", "-File", script_file, "-OutputPath", _output_path]), false)
		if pid < 0:
			_fail("无法启动 Windows 定位服务。")
			return
	else:
		_fail("当前平台尚未接入定位，请使用 Windows 版或支持定位的浏览器版本。")
		return
	_timer.start()

func _poll() -> void:
	if not _busy:
		return
	if Time.get_ticks_msec() > _deadline:
		_fail("定位超时。请开启系统定位服务与位置权限后重试。")
		return
	var result: Dictionary = {}
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("JSON.stringify(window.__foodGeo || {})", true)
		var parsed = JSON.parse_string(str(raw))
		if parsed is Dictionary:
			result = parsed
		if not result.get("done", false):
			return
	elif FileAccess.file_exists(_output_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(_output_path))
		if not parsed is Dictionary:
			return
		result = parsed
		DirAccess.remove_absolute(_output_path)
	else:
		return
	if result.has("error"):
		_fail(str(result.error))
		return
	if not result.has("lat") or not result.has("lng"):
		_fail("定位数据不完整，请重试。")
		return
	var lat: float = float(result.lat)
	var lng: float = float(result.lng)
	if not is_finite(lat) or not is_finite(lng) or absf(lat) > 90 or absf(lng) > 180:
		_fail("定位坐标无效，请重试。")
		return
	if float(result.get("accuracy", 999999)) > 3000:
		_fail("当前定位精度不足（误差超过 3 公里），请开启精确位置后重试。")
		return
	_timer.stop()
	_busy = false
	_last_lat = lat
	_last_lng = lng
	location_resolved.emit(lat, lng)

func _fail(reason: String) -> void:
	_busy = false
	_timer.stop()
	location_failed.emit(reason)

func distance_to_city(city: CityData) -> float:
	if city == null or is_nan(_last_lat):
		return -1
	return haversine_km(_last_lat, _last_lng, city.center_lat, city.center_lng)

func is_within_city(city: CityData) -> bool:
	if city == null or is_nan(_last_lat) or is_nan(_last_lng):
		return false
	return contains_coordinate(city.city_id, _last_lat, _last_lng)

func contains_coordinate(city_id: String, lat: float, lng: float) -> bool:
	if not is_finite(lat) or not is_finite(lng) or absf(lat) > 90 or absf(lng) > 180:
		return false
	var point := Vector2(lng, lat)
	for polygon in _boundaries.get(city_id, []):
		if polygon.is_empty() or not _inside_ring(point, polygon[0]):
			continue
		var in_hole: bool = false
		for i in range(1, polygon.size()):
			if _inside_ring(point, polygon[i]):
				in_hole = true
				break
		if not in_hole:
			return true
	return false

func _inside_ring(point: Vector2, ring: Array) -> bool:
	var vertices := PackedVector2Array()
	for coordinate in ring:
		vertices.append(Vector2(float(coordinate[0]), float(coordinate[1])))
	return Geometry2D.is_point_in_polygon(point, vertices)

func haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
	var a: float = pow(sin(deg_to_rad(lat2 - lat1) / 2), 2) + cos(deg_to_rad(lat1)) * cos(deg_to_rad(lat2)) * pow(sin(deg_to_rad(lng2 - lng1) / 2), 2)
	return 6371.0 * 2.0 * atan2(sqrt(clampf(a, 0, 1)), sqrt(clampf(1 - a, 0, 1)))

func has_boundary(city_id: String) -> bool:
	return _boundaries.has(city_id)
