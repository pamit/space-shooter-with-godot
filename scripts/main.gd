# scripts/main.gd
extends Node2D

@onready var wave_spawner: Node2D = $WaveSpawner
@onready var hud: Control = $HUD
@onready var game_over_panel: Control = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/FinalScoreLabel

func _ready() -> void:
	game_over_panel.visible = false
	GameManager.player_died.connect(_on_player_died)
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.start_level(GameManager.level)

func _on_wave_cleared() -> void:
	GameManager.advance_level()
	wave_spawner.start_level(GameManager.level)

func _on_player_died() -> void:
	get_tree().paused = true
	SaveManager.report_run_result(GameManager.score, GameManager.kills)
	final_score_label.text = "Score: %d" % GameManager.score
	game_over_panel.visible = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	game_over_panel.visible = false
	GameManager.restart_current_level()
	wave_spawner.start_level(GameManager.level)

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
