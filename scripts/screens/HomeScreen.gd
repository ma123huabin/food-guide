class_name HomeScreen
extends Control

const STEP = 260.0
@export_group("首页自动轮播")
@export var autoplay_enabled: bool = true
@export_range(0.2, 30.0, 0.1) var autoplay_interval: float = 3.0
@export_range(0.05, 3.0, 0.05) var autoplay_transition_duration: float = 0.45
@export_range(0.0, 30.0, 0.5) var autoplay_resume_delay: float = 6.0
@export_enum("下一座:1", "上一座:-1") var autoplay_direction: int = 1

@export_group("抽中强调")
@export_range(0.2, 2.0, 0.1) var winner_highlight_duration: float = 0.7

@export_group("城市收集栏")
@export_range(0.2, 2.0, 0.05) var collection_drop_duration: float = 0.75
@export_range(5.0, 100.0, 1.0) var collection_scroll_speed: float = 22.0
@export_range(0.0, 10.0, 0.5) var collection_scroll_delay: float = 2.0

var _collection_view: Control
var _collection_track: Control
var _collection_offset: float = 0.0
var _collection_wait: float = 0.0
var _collection_count: int = 0
var _collection_hovered: bool = false
var _drop_card: CityCard
var _drop_tween: Tween
var _autoplay_remaining: float = 0.0
var _area: Control
var _track: Control
var _cards: Array[CityCard] = []
var _draw_pool: Array[CityData] = []
var _button: Button
var _hint: Label
var _thumbs: Array[Button] = []
var _busy: bool = false
var _selected: int = 0
var _active_slot: int = 4
var _start: Vector2
var _pressing: bool = false
var _tween: Tween

func _ready() -> void:
	GuideUI.background(self)
	var h1 := GuideUI.label(self, "一城一味，", Rect2(0, 68, 480, 68), 52, Color("bc3b0c"), true)
	var h2 := GuideUI.label(self, "今日点亮", Rect2(0, 129, 480, 76), 60, Color("ad210c"), true)
	for h in [h1, h2]:
		h.add_theme_font_override("font", load("res://assets/fonts/行楷.ttf"))
		h.add_theme_constant_override("outline_size", 2)
		h.add_theme_color_override("font_outline_color", Color("fff4dc"))
	h1.hide()
	h2.hide()
	var title_art := GuideUI.picture(self, load("res://img/界面皮肤/首页艺术标题.png"), Rect2(38, 68, 404, 164))
	title_art.name = "HomeTitleArt"
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_area = Control.new()
	_area.position = Vector2(0, 249)
	_area.size = Vector2(480, 350)
	_area.clip_contents = true
	_area.gui_input.connect(_input_card)
	add_child(_area)
	_track = Control.new()
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(_track)
	_rebuild_draw_pool()
	_hint = GuideUI.label(self, "点击「随机点亮」，开启一场美食奇遇", Rect2(0, 598, 480, 24), 14, Color("80583c"), true)
	_collection_view = Control.new()
	_collection_view.position = Vector2(12, 637)
	_collection_view.size = Vector2(456, 92)
	_collection_view.clip_contents = true
	_collection_view.mouse_entered.connect(func() -> void: _collection_hovered = true)
	_collection_view.mouse_exited.connect(func() -> void: _collection_hovered = false)
	add_child(_collection_view)
	_collection_track = Control.new()
	_collection_view.add_child(_collection_track)
	_rebuild_collection()
	_button = GuideUI.button(self, "随机点亮", Rect2(82, 750, 316, 62), _draw_city, true)
	EventBus.request_home.connect(_refresh)
	_refresh()
	_autoplay_remaining = autoplay_interval

func _process(delta: float) -> void:
	if is_visible_in_tree() and not _busy and not _collection_hovered and _collection_count > 7:
		_collection_wait -= delta
		if _collection_wait <= 0.0:
			_collection_offset = fposmod(_collection_offset + collection_scroll_speed * delta, _collection_count * 66.0)
			_collection_track.position.x = -_collection_offset
	if not autoplay_enabled or not is_visible_in_tree() or _busy or _pressing or _draw_pool.size() < 2:
		return
	if _tween and _tween.is_running():
		return
	_autoplay_remaining -= delta
	if _autoplay_remaining <= 0.0:
		_advance_carousel()

func _advance_carousel() -> void:
	var direction := 1 if autoplay_direction >= 0 else -1
	# Rebase onto an identical middle copy before crossing the wrap boundary.
	_active_slot = _draw_pool.size() + _selected
	_track.position.x = 120 - _active_slot * STEP
	_active_slot += direction
	_selected = posmod(_selected + direction, _draw_pool.size())
	_refresh()
	_tween = create_tween()
	_tween.tween_property(_track, "position:x", 120 - _active_slot * STEP, autoplay_transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_autoplay_remaining = autoplay_interval

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready():
		_pressing = false
		_autoplay_remaining = autoplay_interval
		_collection_wait = collection_scroll_delay
		if not _busy and _tween and _tween.is_running():
			_tween.kill()
			_track.position.x = 120 - _active_slot * STEP

func _input_card(event: InputEvent) -> void:
	if _busy or _draw_pool.is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_autoplay_remaining = autoplay_resume_delay
			if _tween and _tween.is_running():
				_tween.kill()
				_track.position.x = 120 - _active_slot * STEP
			_start = event.position
			_pressing = true
		elif _pressing:
			_pressing = false
			_autoplay_remaining = autoplay_resume_delay
			var delta: float = event.position.x - _start.x
			if absf(delta) > 35:
				_select_thumb(posmod(_selected - (1 if delta > 0 else -1), _draw_pool.size()))
			elif event.position.x >= 120 and event.position.x <= 360:
				if GameData.is_lit(_draw_pool[_selected].city_id):
					EventBus.request_open_city.emit(_draw_pool[_selected].city_id)
				else:
					_hint.text = "这座城市还未点亮，试试下方「随机点亮」"

func _select_thumb(index: int) -> void:
	if _busy:
		return
	_autoplay_remaining = autoplay_resume_delay
	if index >= _draw_pool.size():
		_hint.text = "更多城市正在筹备，敬请期待"
		return
	_selected = index
	_active_slot = _draw_pool.size() + index
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_track, "position:x", 120 - _active_slot * STEP, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_refresh()

func _draw_city() -> void:
	if _busy or _draw_pool.is_empty():
		return
	_busy = true
	_button.disabled = true
	_button.text = "正在寻找下一站…"
	_hint.text = "城市飞驰中，下一口心动即将揭晓…"
	if _tween and _tween.is_running():
		_tween.kill()
	_track.position.x = 120 - (_draw_pool.size() + _selected) * STEP
	var pool: Array[int] = []
	for i in range(_draw_pool.size()):
		if not GameData.is_lit(_draw_pool[i].city_id):
			pool.append(i)
	if pool.is_empty():
		pool.assign(range(_draw_pool.size()))
	_selected = pool.pick_random()
	_active_slot = _draw_pool.size() * 5 + _selected
	for card in _cards:
		card.highlighted = false
		card.scale = Vector2(0.9, 0.9)
	_tween = create_tween()
	_tween.tween_property(_track, "position:x", 120 - _active_slot * STEP, 3.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_finish)

func _finish() -> void:
	var card := _cards[_active_slot]
	card.highlighted = true
	_hint.text = "✦ 抽中%s！" % _draw_pool[_selected].display_name
	_tween = create_tween()
	_tween.tween_property(card, "scale", Vector2(1.06, 1.06), winner_highlight_duration * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(card, "scale", Vector2.ONE, winner_highlight_duration * 0.25)
	_tween.tween_interval(winner_highlight_duration * 0.4)
	_tween.tween_callback(_begin_drop)

func _begin_drop() -> void:
	# Keep input locked until the collected card actually lands.
	var city: CityData = _draw_pool[_selected]
	_hint.text = "✦ 抽中%s！正在收入城市收藏…" % city.display_name
	var is_new := not GameData.is_lit(city.city_id)
	_rebuild_collection(city.city_id if is_new else "")
	var slot := GameData.lit_cities.size() if is_new else GameData.lit_cities.find(city.city_id)
	_collection_offset = maxf(0.0, (slot - 6) * 66.0)
	_collection_track.position.x = -_collection_offset
	_drop_card = CityCard.new()
	_drop_card.city = city
	_drop_card.position = Vector2(120, 261)
	add_child(_drop_card)
	_cards[_active_slot].modulate.a = 0.25
	var destination := Vector2(12 + slot * 66 - _collection_offset - 90, 637 - 120)
	_drop_tween = create_tween().set_parallel(true)
	_drop_tween.tween_property(_drop_card, "position", destination, collection_drop_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_drop_tween.tween_property(_drop_card, "scale", Vector2(0.25, 0.25), collection_drop_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_drop_tween.chain().tween_callback(_complete_collection.bind(city.city_id, slot))

func _complete_collection(city_id: String, slot: int) -> void:
	GameData.set_lit(city_id)
	EventBus.city_lit.emit(city_id)
	if is_instance_valid(_drop_card):
		_drop_card.queue_free()
	_drop_card = null
	_selected = mini(_selected, maxi(0, _draw_pool.size() - 2))
	_rebuild_draw_pool()
	_busy = false
	_autoplay_remaining = autoplay_resume_delay
	_rebuild_collection()
	_collection_offset = maxf(0.0, (slot - 6) * 66.0)
	_collection_track.position.x = -_collection_offset
	_collection_wait = collection_scroll_delay
	_refresh()
	_hint.text = "✦ 已收藏%s！点击小卡片查看攻略" % GameData.get_city(city_id).display_name
	var target := _thumbs[slot]
	var pulse := create_tween()
	pulse.tween_property(target, "scale", Vector2(1.12, 1.12), 0.14)
	pulse.tween_property(target, "scale", Vector2.ONE, 0.2)

func _rebuild_collection(pending_id: String = "") -> void:
	for child in _collection_track.get_children():
		_collection_track.remove_child(child)
		child.queue_free()
	_thumbs.clear()
	_collection_count = GameData.lit_cities.size()
	var slots: int = maxi(7, _collection_count + (1 if not pending_id.is_empty() else 0))
	var copies := 2 if _collection_count > 7 else 1
	for copy in range(copies):
		for i in range(slots):
			var city_id: String = GameData.lit_cities[i] if i < _collection_count else ""
			var b := GuideUI.button(_collection_track, "", Rect2((copy * slots + i) * 66, 0, 60, 87), _open_collected.bind(city_id))
			b.pivot_offset = Vector2(30, 43)
			if city_id.is_empty():
				b.disabled = true
				b.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
				var locked := GuideUI.picture(b, GuideUI.locked_art(), Rect2(0, 0, 60, 87))
				locked.stretch_mode = TextureRect.STRETCH_SCALE
			else:
				var city := GameData.get_city(city_id)
				GuideUI.skin_frame(b, 0.045)
				GuideUI.picture(b, city.cover_texture, Rect2(4, 4, 52, 54))
				GuideUI.panel(b, Rect2(4, 58, 52, 25), Color("22683f"), 5, GuideUI.GOLD, 1)
				GuideUI.label(b, city.display_name, Rect2(1, 59, 50, 21), 13, Color("fff7df"), true)
				GuideUI.label(b, "♥", Rect2(48, 68, 9, 12), 9, GuideUI.GOLD, true)
				for x in [4, 49]:
					GuideUI.label(b, "♥", Rect2(x, 55, 8, 10), 8, GuideUI.GOLD, true)
			if copy == 0:
				_thumbs.append(b)
	_collection_offset = 0.0
	_collection_track.position.x = 0.0
	_collection_wait = collection_scroll_delay

func _open_collected(city_id: String) -> void:
	if _busy or city_id.is_empty() or not GameData.is_lit(city_id):
		return
	_collection_wait = autoplay_resume_delay
	EventBus.request_open_city.emit(city_id)

func _refresh() -> void:
	if _button == null:
		return
	_button.disabled = _busy or _draw_pool.is_empty()
	if _draw_pool.is_empty():
		_button.text = "全部城市已收藏"
		_hint.text = "城市收集完成 · 点击小卡片重温旅程"
		return
	_button.text = "再点亮一座城市" if GameData.lit_count() > 0 else "随机点亮"
	var lit: bool = GameData.is_lit(_draw_pool[_selected].city_id)
	_hint.text = "已点亮%s · 点击中央卡片进入攻略" % _draw_pool[_selected].display_name if lit else "点击「随机点亮」，开启一场美食奇遇"
	for i in range(_cards.size()):
		_cards[i].scale = Vector2.ONE if i == _active_slot else Vector2(0.88, 0.88)
		_cards[i].highlighted = lit and i == _active_slot

func _rebuild_draw_pool() -> void:
	for child in _track.get_children():
		_track.remove_child(child)
		child.queue_free()
	_cards.clear()
	_draw_pool.clear()
	for city in GameData.cities:
		if not city.locked and not GameData.is_lit(city.city_id):
			_draw_pool.append(city)
	if _draw_pool.is_empty():
		_track.position.x = 0.0
		GuideUI.panel(_track, Rect2(120, 12, 240, 320), GuideUI.CREAM, 22, GuideUI.GOLD, 4)
		GuideUI.label(_track, "✦", Rect2(120, 78, 240, 90), 55, GuideUI.GOLD, true)
		GuideUI.label(_track, "城市收藏已集齐", Rect2(120, 185, 240, 40), 22, GuideUI.INK, true)
		return
	_selected = clampi(_selected, 0, _draw_pool.size() - 1)
	for i in range(_draw_pool.size() * 7):
		var card := CityCard.new()
		card.city = _draw_pool[i % _draw_pool.size()]
		card.position = Vector2(i * STEP, 12)
		_track.add_child(card)
		_cards.append(card)
	_active_slot = _draw_pool.size() + _selected
	_track.position.x = 120 - _active_slot * STEP
