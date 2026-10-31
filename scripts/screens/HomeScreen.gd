class_name HomeScreen
extends Control

const STEP = 260.0
const COLLECTION_VISIBLE = 5
const COLLECTION_CARD = Vector2(84, 116)
const COLLECTION_STEP = 93.0
const COLLECTION_TOP = 624.0
const COLLECTION_NAME_RECT = Rect2(20, 87, 44, 20)
@export_group("首页自动轮播")
@export var autoplay_enabled: bool = true
@export_range(0.2, 30.0, 0.1) var autoplay_interval: float = 2.0
@export_range(0.05, 3.0, 0.05) var autoplay_transition_duration: float = 0.45
@export_range(0.0, 30.0, 0.5) var autoplay_resume_delay: float = 6.0
@export_range(0.0, 30.0, 0.5) var autoplay_after_draw_delay: float = 1.0
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
var _collection_pressing: bool = false
var _collection_dragging: bool = false
var _collection_start: Vector2
var _collection_start_offset: float = 0.0
var _drop_card: CityCard
var _drop_tween: Tween
var _drop_origin: Vector2
var _drop_destination: Vector2
var _drop_scale: Vector2
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
	var title_art := GuideUI.picture(self, GuideUI.component("home_title"), Rect2(38, 68, 404, 164))
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
	_collection_view.position = Vector2(12, COLLECTION_TOP)
	_collection_view.size = Vector2(456, COLLECTION_CARD.y)
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
	if is_visible_in_tree() and not _busy and not _collection_hovered and not _collection_pressing and _collection_count > COLLECTION_VISIBLE:
		_collection_wait -= delta
		if _collection_wait <= 0.0:
			_collection_offset = fposmod(_collection_offset + collection_scroll_speed * delta, _collection_count * COLLECTION_STEP)
			_collection_track.position.x = -_collection_offset
	if not autoplay_enabled or not is_visible_in_tree() or _busy or _draw_pool.size() < 2:
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
		_collection_pressing = false
		_collection_dragging = false
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
			_start = event.position
			_pressing = true
		elif _pressing:
			_pressing = false
			var delta: float = event.position.x - _start.x
			if absf(delta) > 35:
				return
			elif event.position.x >= 120 and event.position.x <= 360:
				if GameData.is_lit(_draw_pool[_selected].city_id):
					EventBus.request_open_city.emit(_draw_pool[_selected].city_id)
				else:
					_hint.text = "这座城市还未点亮，试试下方「随机点亮」"

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _busy or _collection_count <= COLLECTION_VISIBLE:
		_collection_pressing = false
		_collection_dragging = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _collection_view.get_global_rect().has_point(event.position):
				_collection_pressing = true
				_collection_dragging = false
				_collection_start = event.position
				_collection_start_offset = _collection_offset
		elif _collection_pressing:
			_collection_pressing = false
			_collection_wait = autoplay_resume_delay
			if _collection_dragging:
				for child in _collection_track.get_children():
					if child is Button:
						child.button_pressed = false
				get_viewport().set_input_as_handled()
			_collection_dragging = false
	elif event is InputEventMouseMotion and _collection_pressing:
		var distance: float = event.position.x - _collection_start.x
		if absf(distance) > 10.0:
			_collection_dragging = true
		if _collection_dragging:
			_collection_offset = fposmod(_collection_start_offset - distance, _collection_count * COLLECTION_STEP)
			_collection_track.position.x = -_collection_offset
			get_viewport().set_input_as_handled()

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
	# Continue from the current visual position when autoplay is mid-transition.
	var visual_offset := _track.position.x - (120.0 - _active_slot * STEP)
	if _tween and _tween.is_running():
		_tween.kill()
	var start_slot := _draw_pool.size() + _selected
	_track.position.x = 120 - start_slot * STEP + visual_offset
	var pool: Array[int] = []
	for i in range(_draw_pool.size()):
		if not GameData.is_lit(_draw_pool[i].city_id):
			pool.append(i)
	if pool.is_empty():
		pool.assign(range(_draw_pool.size()))
	_selected = pool.pick_random()
	_active_slot = start_slot + _draw_pool.size() + posmod(_selected - start_slot, _draw_pool.size())
	for card in _cards:
		card.highlighted = false
	_set_roll_position(_track.position.x)
	var start_x := _track.position.x
	var end_x := 120.0 - _active_slot * STEP
	# Match velocity across all three phases, including the start of braking.
	var speed := (end_x - start_x) / (0.45 / 2.0 + 0.9 + 2.15 / 3.0)
	var accelerate_end := start_x + speed * 0.45 / 2.0
	var cruise_end := accelerate_end + speed * 0.9
	_tween = create_tween()
	_tween.tween_method(_set_roll_position, start_x, accelerate_end, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_method(_set_roll_position, accelerate_end, cruise_end, 0.9).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_method(_set_roll_position, cruise_end, end_x, 2.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_finish)

func _set_roll_position(value: float) -> void:
	_track.position.x = value
	for card in _cards:
		var distance := absf(card.position.x + value - 120.0)
		var focus := 1.0 - clampf(distance / STEP, 0.0, 1.0)
		card.scale = Vector2.ONE * lerpf(0.88, 1.0, focus * focus * (3.0 - 2.0 * focus))

func _finish() -> void:
	var card := _cards[_active_slot]
	card.play_winner(winner_highlight_duration)
	_hint.text = "✦ 抽中%s！" % _draw_pool[_selected].display_name
	_tween = create_tween()
	_tween.tween_property(card, "scale", Vector2(1.035, 1.035), winner_highlight_duration * 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(card, "scale", Vector2.ONE, winner_highlight_duration * 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(winner_highlight_duration * 0.4)
	_tween.tween_callback(_begin_drop)

func _begin_drop() -> void:
	# Keep input locked until the collected card actually lands.
	var city: CityData = _draw_pool[_selected]
	_hint.text = "✦ 抽中%s！正在收入城市收藏…" % city.display_name
	var is_new := not GameData.is_lit(city.city_id)
	_rebuild_collection(city.city_id if is_new else "")
	var slot := GameData.lit_cities.size() if is_new else GameData.lit_cities.find(city.city_id)
	_collection_offset = maxf(0.0, (slot - (COLLECTION_VISIBLE - 1)) * COLLECTION_STEP)
	_collection_track.position.x = -_collection_offset
	_drop_card = CityCard.new()
	_drop_card.city = city
	add_child(_drop_card)
	var source := _cards[_active_slot]
	_drop_origin = get_global_transform().affine_inverse() * source.global_position
	_drop_card.position = _drop_origin
	# The moving card is the sole visible copy of the collected city.
	for card in _cards:
		if card.city.city_id == city.city_id:
			card.hide()
	# Close the hole near the end of the flight, preserving the same neighbours.
	if _draw_pool.size() > 1:
		var take_previous := _selected == _draw_pool.size() - 1
		_tween = create_tween().set_parallel(true)
		for card in _cards:
			var distance := card.position.x + _track.position.x - 120.0
			if card.visible and absf(distance) <= STEP * 3.0 and ((take_previous and distance < 0.0) or (not take_previous and distance > 0.0)):
				var destination_x := card.position.x + (STEP if take_previous else -STEP)
				_tween.tween_property(card, "position:x", destination_x, collection_drop_duration * 0.45).set_delay(collection_drop_duration * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				var destination_scale := Vector2.ONE if absf(distance) < STEP * 1.1 else Vector2(0.88, 0.88)
				_tween.tween_property(card, "scale", destination_scale, collection_drop_duration * 0.45).set_delay(collection_drop_duration * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var target_scale := COLLECTION_CARD / Vector2(240, 320)
	_drop_scale = target_scale
	_drop_destination = _collection_view.position + Vector2(slot * COLLECTION_STEP - _collection_offset, 0) - _drop_card.pivot_offset * (Vector2.ONE - target_scale)
	_drop_tween = create_tween()
	_drop_tween.tween_method(_set_drop_progress, 0.0, 1.0, collection_drop_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_drop_tween.tween_callback(_complete_collection.bind(city.city_id, slot))

func _set_drop_progress(progress: float) -> void:
	if not is_instance_valid(_drop_card):
		return
	_drop_card.position = _drop_origin.lerp(_drop_destination, progress) + Vector2(0, -36.0 * sin(progress * PI))
	_drop_card.scale = Vector2.ONE.lerp(_drop_scale, progress)
	_drop_card.rotation = deg_to_rad(-2.0) * sin(progress * PI)

func _complete_collection(city_id: String, slot: int) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	GameData.set_lit(city_id)
	EventBus.city_lit.emit(city_id)
	if is_instance_valid(_drop_card):
		_drop_card.hide()
		_drop_card.queue_free()
	_drop_card = null
	_selected = mini(_selected, maxi(0, _draw_pool.size() - 2))
	_rebuild_draw_pool()
	_busy = false
	_autoplay_remaining = autoplay_after_draw_delay
	_rebuild_collection()
	_collection_offset = maxf(0.0, (slot - (COLLECTION_VISIBLE - 1)) * COLLECTION_STEP)
	_collection_track.position.x = -_collection_offset
	_collection_wait = collection_scroll_delay
	_refresh()
	_hint.text = "✦ 已收藏%s！点击小卡片查看攻略" % GameData.get_city(city_id).display_name
	var target := _thumbs[slot]
	var pulse := create_tween()
	pulse.tween_property(target, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse.tween_property(target, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _rebuild_collection(pending_id: String = "") -> void:
	for child in _collection_track.get_children():
		_collection_track.remove_child(child)
		child.queue_free()
	_thumbs.clear()
	_collection_count = GameData.lit_cities.size()
	var slots: int = maxi(COLLECTION_VISIBLE, _collection_count + (1 if not pending_id.is_empty() else 0))
	var copies := 2 if _collection_count > COLLECTION_VISIBLE else 1
	for copy in range(copies):
		for i in range(slots):
			var city_id: String = GameData.lit_cities[i] if i < _collection_count else ""
			var b := GuideUI.button(_collection_track, "", Rect2(Vector2((copy * slots + i) * COLLECTION_STEP, 0), COLLECTION_CARD), _open_collected.bind(city_id))
			b.pivot_offset = COLLECTION_CARD / 2
			if city_id.is_empty():
				b.disabled = true
				b.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
				var locked := GuideUI.picture(b, GuideUI.locked_art(), Rect2(Vector2.ZERO, COLLECTION_CARD))
				locked.stretch_mode = TextureRect.STRETCH_SCALE
			else:
				var city := GameData.get_city(city_id)
				for state in ["normal", "hover", "pressed", "focus"]:
					b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
				GuideUI.component_picture(b, "home_collected_card", Rect2(Vector2.ZERO, COLLECTION_CARD))
				GuideUI.rounded_picture(b, city.cover_texture, Rect2(7, 8, 70, 76), 9.0)
				var city_name := Label.new()
				city_name.name = "CollectionCityName"
				city_name.text = city.display_name
				city_name.clip_text = true
				city_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
				city_name.add_theme_font_override("font", load("res://assets/fonts/楷体.ttf"))
				city_name.add_theme_font_size_override("font_size", 13)
				city_name.add_theme_color_override("font_color", Color("fff7df"))
				city_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				city_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				city_name.scale = Vector2.ONE
				b.add_child(city_name)
				city_name.position = COLLECTION_NAME_RECT.position
				city_name.size = COLLECTION_NAME_RECT.size
				GuideUI.fit_label(city_name, 13, 1.0)
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
	_button.text = "随机点亮"
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
		if not city.locked and city.map_texture != null and not GameData.is_lit(city.city_id):
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
