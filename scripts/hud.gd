# scripts/hud.gd
extends Control

@onready var hp_bar: ProgressBar = $HPBar
@onready var level_label: Label = $LevelLabel
@onready var score_label: Label = $ScoreLabel

func _process(_delta: float) -> void:
	hp_bar.max_value = GameConstants.PLAYER_MAX_HP
	hp_bar.value = GameManager.player_hp
	level_label.text = "Level %d" % GameManager.level
	score_label.text = "Score %d" % GameManager.score

func _on_pause_pressed() -> void:
	get_tree().paused = not get_tree().paused
