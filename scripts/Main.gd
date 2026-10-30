extends Control

@onready var home: HomeScreen = $HomeScreen
@onready var detail: CityDetailScreen = $CityDetailScreen

func _enter_tree() -> void:
	var app_theme := Theme.new()
	app_theme.default_font = load("res://assets/fonts/chinese.ttc")
	app_theme.default_font_size = 16
	theme = app_theme

func _ready() -> void:
	detail.visible = false
	EventBus.request_open_city.connect(_open_city)
	EventBus.request_home.connect(_go_home)

func _open_city(city_id: String) -> void:
	if not GameData.is_lit(city_id):
		return
	detail.load_city(city_id)
	detail.visible = true
	home.visible = false

func _go_home() -> void:
	home.visible = true
	detail.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and detail.visible:
		_go_home()
