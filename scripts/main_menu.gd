# scripts/main_menu.gd
extends Control

@onready var high_score_label: Label = $CenterPanel/Panel/Margin/VBox/HighScoreLabel
@onready var mute_button: CheckButton = $CenterPanel/Panel/Margin/VBox/MuteButton
@onready var music_player: AudioStreamPlayer = $MusicPlayer

func _ready() -> void:
	var saved_level := SaveManager.get_saved_level()
	var level_text := "HIGH SCORE: %d" % SaveManager.get_high_score()
	if saved_level > 1:
		level_text += "  |  CONTINUE: LEVEL %d" % saved_level
	high_score_label.text = level_text
	GameAudio.start_music(music_player, -12.0)

func _on_play_pressed() -> void:
	get_tree().paused = false
	GameManager.begin_session(SaveManager.get_saved_level(), SaveManager.get_saved_score())
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_mute_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, toggled_on)
