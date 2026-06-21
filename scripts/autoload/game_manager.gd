# scripts/autoload/game_manager.gd
extends Node

signal player_died
signal level_advanced(new_level: int)

var level: int = 1
var score: int = 0
var kills: int = 0
var player_hp: float = GameConstants.PLAYER_MAX_HP
var session_active: bool = false

func begin_session(saved_level: int, saved_score: int) -> void:
	level = max(1, saved_level)
	score = max(0, saved_score)
	kills = 0
	player_hp = GameConstants.PLAYER_MAX_HP
	session_active = true

func start_run() -> void:
	begin_session(1, 0)

func add_kill() -> void:
	kills += 1
	score += GameConstants.SCORE_PER_KILL

func advance_level() -> void:
	level += 1
	score += GameConstants.SCORE_PER_LEVEL
	level_advanced.emit(level)

func damage_player(amount: float) -> void:
	player_hp = clamp(player_hp - amount, 0.0, GameConstants.PLAYER_MAX_HP)
	if player_hp <= 0.0:
		player_died.emit()

func is_player_dead() -> bool:
	return player_hp <= 0.0

func restart_current_level() -> void:
	player_hp = GameConstants.PLAYER_MAX_HP

func restore_player_hp() -> void:
	player_hp = GameConstants.PLAYER_MAX_HP
