# tests/test_enemy_spawn.gd
extends SceneTree

var failures := 0

func check(name: String, condition: bool) -> void:
	if not condition:
		failures += 1
		print("FAIL %s" % name)

const SaveDataLib = preload("res://scripts/save_data.gd")
const SAVE_PATH := "user://savegame.json"

func _initialize() -> void:
	SaveDataLib.save_to(SAVE_PATH, SaveDataLib.default_data())

	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	var player: Node = main.get_node("Player")
	var spawner = main.get_node("WaveSpawner")
	spawner.pickup_drop_chance = 0.0
	if player.has_method("set_can_fire"):
		player.set_can_fire(false)
	player.global_position = Vector2(360.0, 2000.0)
	root.add_child(main)
	await process_frame
	await process_frame

	check("tree unpaused after main loads", not root.get_tree().paused)

	var hud: Control = main.get_node("HUDLayer/HUD")
	var level_label: Label = hud.get_node("TopPanel/Margin/Row/LevelLabel")
	var shield_label: Label = hud.get_node("TopPanel/Margin/Row/ShieldLabel")
	var pause_button: Button = hud.get_node("TopPanel/Margin/Row/PauseButton")
	check("hud single row shows level", level_label.visible and level_label.text.begins_with("LEVEL"))
	check("hud single row shows pause", pause_button.visible)
	check("shield and level share font size", shield_label.get_theme_font_size("font_size") == level_label.get_theme_font_size("font_size"))
	check("level 1 starts with wave not boss", get_nodes_in_group("boss").size() == 0)

	await root.get_tree().create_timer(0.5).timeout
	check("level 1 spawns enemies in rows", spawner.get_spawned_count() >= 9)
	check("visible enemy cap respected early", spawner.get_visible_enemy_count() <= GameConstants.MAX_ON_SCREEN_ENEMIES)

	var deadline_ms: int = Time.get_ticks_msec() + 360000
	while spawner.get_spawned_count() < 100 and Time.get_ticks_msec() < deadline_ms:
		check("visible enemy cap respected during wave", spawner.get_visible_enemy_count() <= GameConstants.MAX_ON_SCREEN_ENEMIES)
		await root.get_tree().process_frame
	check("level 1 spawns one hundred enemies", spawner.get_spawned_count() == 100)

	check("on screen enemy cap respected", spawner.get_visible_enemy_count() <= GameConstants.MAX_ON_SCREEN_ENEMIES)

	var enemies := get_nodes_in_group("enemy")
	var row_groups: Dictionary = {}
	for enemy in enemies:
		check("enemy script loaded", enemy.has_method("take_damage"))
		var row_key := snappedf(enemy.global_position.y, 0.5)
		row_groups[row_key] = row_groups.get(row_key, 0) + 1
	for row_key in row_groups:
		check("row has at most three enemies", row_groups[row_key] <= 3)

	root.get_tree().paused = true
	await process_frame
	check("enemies remain while paused", get_nodes_in_group("enemy").size() >= 1)
	root.get_tree().paused = false

	var boss_deadline_ms: int = Time.get_ticks_msec() + 360000
	while get_nodes_in_group("boss").size() == 0 and Time.get_ticks_msec() < boss_deadline_ms:
		for enemy in get_nodes_in_group("enemy"):
			if enemy.has_method("take_damage"):
				enemy.take_damage(999999.0)
		await root.get_tree().process_frame

	await root.get_tree().create_timer(1.0).timeout
	check("boss spawns after wave cleared", get_nodes_in_group("boss").size() == 1)
	var boss_bar_panel: CanvasItem = hud.get_node("BossBarPanel")
	check("boss health bar visible during fight", boss_bar_panel.visible)

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURES" % failures)
	quit(1 if failures > 0 else 0)
