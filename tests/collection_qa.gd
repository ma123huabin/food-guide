extends SceneTree

var failures := 0
var gd: Node
var old_save: String
var had_save: bool

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, text: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + text)
	if not ok:
		failures += 1

func capture(filename: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("D:/软件安装位置/Codex/food-guide-build/" + filename)

func run() -> void:
	gd = root.get_node("GameData")
	gd.SAVE_PATH = "user://food-journey-collection-qa.json"
	had_save = FileAccess.file_exists(gd.SAVE_PATH)
	if had_save:
		old_save = FileAccess.get_file_as_string(gd.SAVE_PATH)
	gd.lit_cities.clear()
	gd.checkins.clear()
	gd.lit_city_id = ""
	var main = load("res://scripts/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var home = main.home
	home.autoplay_enabled = false
	check(gd.cities.size() == 25, "five original cities plus twenty destinations")
	var ids: Array[String] = []
	for city in gd.cities:
		check(city.cover_texture != null and city.popular_foods.size() == 4 and not ids.has(city.city_id), "catalog and cover: " + city.display_name)
		ids.append(city.city_id)
		main.detail.load_city(city.city_id)
		if city.map_texture == null:
			check(main.detail._check_button.disabled, "new city does not fake location coverage: " + city.city_id)
	check(gd.get_city("quanzhou").cover_texture != gd.get_city("quanzhou").map_texture, "Quanzhou cover and map are separate assets")
	check(home._thumbs.size() == 7, "fresh collection has seven locked slots")
	for card in home._thumbs:
		var images: Array[Node] = card.find_children("*", "TextureRect", true, false)
		check(card.disabled and images.size() == 1 and images[0].texture is AtlasTexture and images[0].texture.atlas.resource_path == "res://img/界面皮肤/待解锁参考.png", "locked slot uses shared default instead of city cover")
	await capture("collection-empty.png")
	home._draw_city()
	await create_timer(3.65).timeout
	check(home._busy and home._cards[home._active_slot].highlighted and not is_instance_valid(home._drop_card), "gold border emphasis precedes drop")
	var winner_id: String = home._draw_pool[home._selected].city_id
	await create_timer(0.7).timeout
	check(home._busy and is_instance_valid(home._drop_card) and gd.lit_count() == 0, "winning card falls before collection unlocks")
	await capture("collection-drop.png")
	await create_timer(1.0).timeout
	check(not home._busy and gd.lit_count() == 1 and not home._thumbs[0].disabled, "landing lights one thumbnail")
	var has_cover := false
	for image in home._thumbs[0].find_children("*", "TextureRect", true, false):
		if image.texture == gd.get_city(winner_id).cover_texture: has_cover = true
	check(has_cover, "collected thumbnail shows its actual city cover")
	check(home._draw_pool.size() == 24, "collected city leaves big-card draw pool")
	var winner_present := false
	for card in home._cards:
		if card.city.city_id == winner_id:
			winner_present = true
	check(not winner_present, "all carousel copies of winning city are removed")
	await capture("collection-one.png")
	for i in range(8):
		gd.set_lit(gd.cities[i].city_id)
	home._rebuild_collection()
	home._collection_wait = 0.0
	var before: float = home._collection_track.position.x
	await create_timer(0.2).timeout
	check(home._collection_count > 7 and home._collection_track.position.x < before, "more than seven collected cities move right to left")
	home._collection_offset = home._collection_count * 66.0 - 0.1
	await create_timer(0.1).timeout
	check(home._collection_offset < 10.0, "collection loops continuously without blank tail")
	await capture("collection-many.png")
	home.visible = false
	before = home._collection_track.position.x
	await create_timer(0.1).timeout
	check(home._collection_track.position.x == before, "hidden collection pauses")
	home.visible = true
	home._open_collected(gd.lit_cities[0])
	check(main.detail.visible and not home.visible, "collected thumbnail opens its correct city detail")
	gd._load_progress()
	check(gd.lit_count() >= 8, "collected cities persist across reload")
	for city in gd.cities:
		gd.set_lit(city.city_id)
	home._rebuild_draw_pool()
	home._refresh()
	check(home._draw_pool.is_empty() and home._button.disabled, "all-collected state has no duplicate draws")
	if had_save:
		var f := FileAccess.open(gd.SAVE_PATH, FileAccess.WRITE)
		f.store_string(old_save)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(gd.SAVE_PATH))
	print("COLLECTION_QA failures=" + str(failures))
	quit(0 if failures == 0 else 1)
