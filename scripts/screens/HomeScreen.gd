class_name HomeScreen
extends Control

const STEP = 260.0
var _area: Control
var _track: Control
var _cards: Array[CityCard] = []
var _button: Button
var _hint: Label
var _stats: Label
var _thumbs: Array[Button] = []
var _busy: bool = false
var _selected: int = 0
var _active_slot: int = 4
var _start: Vector2
var _pressing: bool = false
var _tween: Tween

func _ready() -> void:
	GuideUI.background(self)
	GuideUI.label(self, "城 市 寻 味  /  FOOD JOURNEY", Rect2(0, 28, 480, 25), 12, Color("a56c54"), true)
	var h1 := GuideUI.label(self, "一城一味，", Rect2(0, 68, 480, 68), 52, Color("d66b22"), true)
	var h2 := GuideUI.label(self, "今日点亮", Rect2(0, 129, 480, 76), 60, GuideUI.RED, true)
	for h in [h1, h2]:
		h.add_theme_constant_override("outline_size", 7)
		h.add_theme_color_override("font_outline_color", Color("fff7dc"))
	GuideUI.label(self, "让味蕾，决定下一站。", Rect2(0, 207, 480, 25), 15, Color("9b6852"), true)
	_area = Control.new()
	_area.position = Vector2(0, 249)
	_area.size = Vector2(480, 350)
	_area.clip_contents = true
	_area.gui_input.connect(_input_card)
	add_child(_area)
	_track = Control.new()
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(_track)
	for i in range(GameData.ACTIVE_CITY_COUNT * 7):
		var card := CityCard.new()
		card.city = GameData.cities[i % GameData.ACTIVE_CITY_COUNT]
		card.position = Vector2(i * STEP, 12)
		_track.add_child(card)
		_cards.append(card)
	_hint = GuideUI.label(self, "点击「随机点亮」，开启一场美食奇遇", Rect2(0, 598, 480, 24), 14, Color("a16850"), true)
	for i in range(GameData.cities.size()):
		var x := 12 + i * 66
		var b := GuideUI.button(self, "", Rect2(x, 637, 60, 87), _select_thumb.bind(i))
		if i < GameData.ACTIVE_CITY_COUNT:
			GuideUI.picture(b, GuideUI.city_art(GameData.cities[i]), Rect2(4, 4, 52, 54))
		else:
			GuideUI.label(b, "◇", Rect2(0, 5, 66, 51), 28, Color("a69491"), true)
		GuideUI.label(b, GameData.cities[i].display_name if i < GameData.ACTIVE_CITY_COUNT else "待解锁", Rect2(0, 59, 66, 21), 13, GuideUI.INK if i < GameData.ACTIVE_CITY_COUNT else Color("a69491"), true)
		_thumbs.append(b)
	_button = GuideUI.button(self, "随机点亮", Rect2(82, 750, 316, 62), _draw_city, true)
	_stats = GuideUI.label(self, "", Rect2(0, 819, 480, 24), 12, Color("9f7767"), true)
	EventBus.request_home.connect(_refresh)
	if not GameData.lit_city_id.is_empty():
		_selected = GameData.city_index(GameData.lit_city_id)
	_active_slot = GameData.ACTIVE_CITY_COUNT + _selected
	_track.position.x = 120 - _active_slot * STEP
	_refresh()

func _input_card(event: InputEvent) -> void:
	if _busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start = event.position
			_pressing = true
		elif _pressing:
			_pressing = false
			var delta: float = event.position.x - _start.x
			if absf(delta) > 35:
				_select_thumb(posmod(_selected - (1 if delta > 0 else -1), GameData.ACTIVE_CITY_COUNT))
			elif event.position.x >= 120 and event.position.x <= 360:
				if GameData.is_lit(GameData.cities[_selected].city_id):
					EventBus.request_open_city.emit(GameData.cities[_selected].city_id)
				else:
					_hint.text = "这座城市还未点亮，试试下方「随机点亮」"

func _select_thumb(index: int) -> void:
	if _busy:
		return
	if index >= GameData.ACTIVE_CITY_COUNT:
		_hint.text = "更多城市正在筹备，敬请期待"
		return
	_selected = index
	_active_slot = GameData.ACTIVE_CITY_COUNT + index
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_track, "position:x", 120 - _active_slot * STEP, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_refresh()

func _draw_city() -> void:
	if _busy:
		return
	_busy = true
	_button.disabled = true
	_button.text = "正在寻找下一站…"
	_hint.text = "城市飞驰中，下一口心动即将揭晓…"
	if _tween and _tween.is_running():
		_tween.kill()
	_track.position.x = 120 - (GameData.ACTIVE_CITY_COUNT + _selected) * STEP
	var pool: Array[int] = []
	for i in range(GameData.ACTIVE_CITY_COUNT):
		if not GameData.is_lit(GameData.cities[i].city_id):
			pool.append(i)
	if pool.is_empty():
		pool.assign(range(GameData.ACTIVE_CITY_COUNT))
	_selected = pool.pick_random()
	_active_slot = GameData.ACTIVE_CITY_COUNT * 5 + _selected
	for card in _cards:
		card.highlighted = false
		card.scale = Vector2(0.9, 0.9)
	_tween = create_tween()
	_tween.tween_property(_track, "position:x", 120 - _active_slot * STEP, 3.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_finish)

func _finish() -> void:
	_busy = false
	var city: CityData = GameData.cities[_selected]
	GameData.set_lit(city.city_id)
	EventBus.city_lit.emit(city.city_id)
	_refresh()
	_hint.text = "✦ 已点亮%s！再次点击中央卡片，出发寻味" % city.display_name
	var card := _cards[_active_slot]
	var pulse := create_tween()
	pulse.tween_property(card, "scale", Vector2(1.05, 1.05), 0.18)
	pulse.tween_property(card, "scale", Vector2.ONE, 0.24)

func _refresh() -> void:
	if _button == null:
		return
	_button.disabled = _busy
	_button.text = "再点亮一座城市" if GameData.lit_count() > 0 else "随机点亮"
	_stats.text = "已点亮 %d / %d 座城市   ·   已打卡 %d 座" % [GameData.lit_count(), GameData.ACTIVE_CITY_COUNT, GameData.checkins.size()]
	var lit: bool = GameData.is_lit(GameData.cities[_selected].city_id)
	_hint.text = "已点亮%s · 点击中央卡片进入攻略" % GameData.cities[_selected].display_name if lit else "点击「随机点亮」，开启一场美食奇遇"
	for i in range(_cards.size()):
		_cards[i].scale = Vector2.ONE if i == _active_slot else Vector2(0.88, 0.88)
		_cards[i].highlighted = lit and i == _active_slot
	for i in range(GameData.ACTIVE_CITY_COUNT):
		_thumbs[i].add_theme_stylebox_override("normal", GuideUI.box(GuideUI.CREAM, 14, GuideUI.GOLD if GameData.is_lit(GameData.cities[i].city_id) else Color("ddc9b7"), 3 if i == _selected else 1))
