# scripts/main_menu.gd
extends Control

@onready var high_score_label: Label = $HighScoreLabel
@onready var mute_button: CheckButton = $MuteButton

func _ready() -> void:
	high_score_label.text = "High Score: %d" % SaveManager.get_high_score()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_mute_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, toggled_on)
