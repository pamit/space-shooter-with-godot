# scripts/main.gd
extends Node2D

@onready var wave_spawner: Node2D = $WaveSpawner
@onready var player: Area2D = $Player
@onready var hud: Control = $HUDLayer/HUD
@onready var game_over_panel: Control = $GameOverLayer/GameOverPanel
@onready var level_complete_panel: Control = $LevelCompleteLayer/LevelCompletePanel
@onready var final_score_label: Label = $GameOverLayer/GameOverPanel/Center/Panel/Margin/VBox/FinalScoreLabel
@onready var level_complete_label: Label = $LevelCompleteLayer/LevelCompletePanel/Center/Panel/Margin/VBox/CompleteLabel
@onready var game_over_sfx: AudioStreamPlayer = $GameOverLayer/GameOverSFX
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var _level_complete_pending: bool = false
var _health_boost_used: bool = false
var _rocket_summon_used: bool = false
var _penta_shot_used: bool = false

func _ready() -> void:
	get_tree().paused = false
	game_over_panel.visible = false
	level_complete_panel.visible = false
	game_over_sfx.stream = GameAudio.GAME_OVER
	GameAudio.start_music(music_player)
	GameManager.begin_session(SaveManager.get_saved_level(), SaveManager.get_saved_score())
	GameManager.player_died.connect(_on_player_died)
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.boss_warning.connect(_on_boss_warning)
	wave_spawner.boss_spawned.connect(_on_boss_spawned)
	hud.health_boost_pressed.connect(_on_health_boost_pressed)
	hud.rocket_summon_pressed.connect(_on_rocket_summon_pressed)
	hud.penta_shot_pressed.connect(_on_penta_shot_pressed)
	hud.pause_restart_pressed.connect(_on_pause_restart_pressed)
	hud.pause_quit_pressed.connect(_on_pause_quit_pressed)
	call_deferred("_start_level")

func _start_level() -> void:
	_health_boost_used = false
	_rocket_summon_used = false
	_penta_shot_used = false
	GameManager.restore_player_hp()
	if player.has_method("reset_powerups"):
		player.reset_powerups()
	if player.has_method("restore_ship"):
		player.restore_ship()
	else:
		player.set_can_fire(true)
	hud.hide_boss_health()
	hud.reset_level_abilities()
	wave_spawner.start_level(GameManager.level)

func _on_health_boost_pressed() -> void:
	if _health_boost_used or get_tree().paused:
		return
	_health_boost_used = true
	GameManager.restore_player_hp()
	hud.disable_health_boost()

func _on_rocket_summon_pressed() -> void:
	if _rocket_summon_used or get_tree().paused:
		return
	_rocket_summon_used = true
	HelperRockets.launch(self, GameManager.level)
	hud.disable_rocket_summon()

func _on_penta_shot_pressed() -> void:
	if _penta_shot_used or get_tree().paused:
		return
	_penta_shot_used = true
	if player.has_method("add_penta_shot"):
		player.add_penta_shot()
		get_tree().create_timer(GameConstants.PENTA_SHOT_DURATION).timeout.connect(
			func() -> void:
				if is_instance_valid(player) and player.has_method("remove_penta_shot"):
					player.remove_penta_shot()
		)
	hud.disable_penta_shot()

func _launch_helper_rockets(level: int) -> void:
	_run_helper_rocket_launch(level)

func _run_helper_rocket_launch(level: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var delay: float = rng.randf_range(
		GameConstants.HELPER_ROCKET_DELAY_MIN,
		GameConstants.HELPER_ROCKET_DELAY_MAX
	)
	await get_tree().create_timer(delay).timeout
	for i in range(GameConstants.HELPER_ROCKET_COUNT):
		if not is_inside_tree():
			return
		HelperRockets.spawn_one(self, level, i, rng)
		if i >= GameConstants.HELPER_ROCKET_COUNT - 1:
			continue
		delay = rng.randf_range(
			GameConstants.HELPER_ROCKET_DELAY_MIN,
			GameConstants.HELPER_ROCKET_DELAY_MAX
		)
		await get_tree().create_timer(delay).timeout

func _on_boss_warning() -> void:
	hud.show_boss_warning()

func _on_boss_spawned() -> void:
	hud.hide_boss_warning()
	var boss: Node = get_tree().get_first_node_in_group("boss")
	if boss != null and boss.has_method("get_max_hp"):
		hud.show_boss_health(boss.get_max_hp(), boss.get_current_hp())

func _on_wave_cleared(was_boss: bool, boss_position: Vector2) -> void:
	if not was_boss:
		return
	await _play_boss_defeat_cinematic(boss_position)
	_show_level_complete()

func _play_boss_defeat_cinematic(boss_position: Vector2) -> void:
	if _level_complete_pending:
		return
	_level_complete_pending = true
	player.set_can_fire(false)
	wave_spawner.clear_projectiles()
	hud.hide_boss_health()
	VisualEffects.spawn_boss_bombing(self, boss_position)
	await get_tree().create_timer(GameConstants.BOSS_DEFEAT_DELAY).timeout
	_level_complete_pending = false

func _show_level_complete() -> void:
	player.set_can_fire(false)
	wave_spawner.clear_projectiles()
	level_complete_label.text = (
		"CONGRATULATIONS, PILOT!\n\n"
		+ "LEVEL %d COMPLETE\n\n"
		+ "Score: %d"
	) % [GameManager.level, GameManager.score]
	level_complete_panel.visible = true
	get_tree().paused = true
	SaveManager.save_progress(GameManager.level + 1, GameManager.score, GameManager.kills)

func _on_player_died() -> void:
	if player.has_method("destroy_ship"):
		player.destroy_ship()
	else:
		player.set_can_fire(false)
	get_tree().paused = true
	hud.hide_boss_health()
	GameAudio.stop_music(music_player)
	SaveManager.report_run_result(GameManager.score, GameManager.kills)
	final_score_label.text = "Score: %d" % GameManager.score
	game_over_panel.visible = true
	GameAudio.play_1d(game_over_sfx, GameAudio.GAME_OVER)

func _on_retry_pressed() -> void:
	hud.show_confirm(_execute_retry)

func _execute_retry() -> void:
	get_tree().paused = false
	game_over_panel.visible = false
	GameManager.restart_current_level()
	_start_level()

func _on_pause_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.restart_current_level()
	_start_level()

func _on_pause_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_quit_pressed() -> void:
	hud.show_confirm(_execute_quit)

func _execute_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_next_level_pressed() -> void:
	get_tree().paused = false
	level_complete_panel.visible = false
	GameManager.advance_level()
	SaveManager.save_progress(GameManager.level, GameManager.score, GameManager.kills)
	_start_level()

func _on_level_complete_quit_pressed() -> void:
	SaveManager.save_progress(GameManager.level + 1, GameManager.score, GameManager.kills)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
