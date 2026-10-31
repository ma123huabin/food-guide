extends SceneTree

var failures := 0
var gd: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1

func capture(filename: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("D:/软件安装位置/Codex/food-guide-build/draw-motion-" + filename + ".png")

func run() -> void:
	gd = root.get_node("GameData")
	gd.SAVE_PATH = "user://food-journey-draw-motion-qa.json"
	var had_save := FileAccess.file_exists(gd.SAVE_PATH)
	var old_save := FileAccess.get_file_as_string(gd.SAVE_PATH) if had_save else ""
	gd.lit_cities.clear()
	gd.lit_city_id = ""
	gd.checkins.clear()
	seed(8172)
	var main = load("res://scripts/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var home = main.home
	home.autoplay_enabled = false
	check(home._area.position == Vector2(0, 249) and home._area.size == Vector2(480, 350), "existing carousel layout unchanged")
	check(home._button.position == Vector2(82, 750) and home._thumbs.size() == 5, "existing button and five collection slots unchanged")
	await capture("idle")
	home._advance_carousel()
	home._tween.pause()
	home._tween.custom_step(0.18)
	var autoplay_x: float = home._track.position.x
	home._draw_city()
	check(is_equal_approx(home._track.position.x, autoplay_x), "drawing mid-autoplay preserves the visible position")
	var winner_id: String = home._draw_pool[home._selected].city_id
	var selected_slot: int = home._active_slot
	home._draw_city()
	check(home._active_slot == selected_slot and gd.lit_count() == 0, "repeated click cannot change in-flight winner")
	# Step the launch deterministically so font/import stalls cannot skew timing.
	home._tween.pause()
	var start_x: float = home._track.position.x
	home._tween.custom_step(0.1)
	var first_distance: float = start_x - home._track.position.x
	home._tween.custom_step(0.1)
	check(first_distance > 0 and start_x - home._track.position.x > first_distance * 2.5, "carousel accelerates from rest")
	home._tween.play()
	await capture("rolling")
	await create_timer(3.4).timeout
	check(home._cards[home._active_slot].highlighted and not is_instance_valid(home._drop_card), "winner reveals before collection flight")
	check(absf(home._track.position.x - (120 - home._active_slot * home.STEP)) < 0.01, "braking stops exactly at the selected city")
	check(home._cards[home._active_slot]._winner_effect.visible, "winner gold effect is active")
	var colours_unchanged := true
	for card in home._cards:
		colours_unchanged = colours_unchanged and card.modulate == Color.WHITE and card.self_modulate == Color.WHITE
	check(colours_unchanged and home.modulate == Color.WHITE and home._track.modulate == Color.WHITE, "side cards and background are never darkened")
	await capture("winner")
	await create_timer(0.72).timeout
	check(is_instance_valid(home._drop_card) and home._busy and gd.lit_count() == 0, "collection stays locked during the flight")
	var ghost := false
	for card in home._cards:
		if card.city.city_id == winner_id and card.visible:
			ghost = true
	check(not ghost, "winner leaves no faded duplicate in the carousel")
	check(home._drop_card.scale.x < 1 and home._drop_card.position.y > 261, "card shrinks along its downward path")
	await capture("flight")
	await create_timer(0.95).timeout
	check(not home._busy and gd.lit_cities == [winner_id], "landing saves exactly the drawn city and unlocks input")
	check(home._draw_pool.size() == gd.cities.size() - 1, "winner is removed from the live draw pool")
	check(not home._thumbs[0].disabled and not is_instance_valid(home._drop_card), "collection receives the card and temporary flight node is removed")
	await capture("collected")
	# Exercise consecutive draws, the one-city tail, and all-collected state.
	for city in gd.cities:
		if city.city_id != winner_id and gd.lit_cities.size() < gd.cities.size() - 3:
			gd.lit_cities.append(city.city_id)
	home._rebuild_draw_pool()
	home._rebuild_collection()
	home._refresh()
	for remaining in [3, 2, 1]:
		check(home._draw_pool.size() == remaining, "remaining pool size before draw: %d" % remaining)
		var previous: Array = gd.lit_cities.duplicate()
		home._draw_city()
		var next_id: String = home._draw_pool[home._selected].city_id
		check(not previous.has(next_id), "next draw excludes every collected city")
		await create_timer(5.2).timeout
		check(not home._busy and gd.lit_cities.size() == previous.size() + 1, "consecutive draw lands exactly one new city")
		check(home._draw_pool.size() == remaining - 1, "all copies of the drawn city leave the pool")
	check(home._button.disabled and home._draw_pool.is_empty(), "last-city draw ends in existing collection-complete state")
	home._draw_city()
	check(not home._busy, "empty pool cannot restart a draw")
	if had_save:
		var file := FileAccess.open(gd.SAVE_PATH, FileAccess.WRITE)
		file.store_string(old_save)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(gd.SAVE_PATH))
	print("DRAW_MOTION_QA failures=" + str(failures))
	quit(0 if failures == 0 else 1)
