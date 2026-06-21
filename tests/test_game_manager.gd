# tests/test_game_manager.gd
extends SceneTree

const GameManagerScript = preload("res://scripts/autoload/game_manager.gd")

var failures := 0

func check(name: String, actual, expected) -> void:
	if actual != expected:
		failures += 1
		print("FAIL %s: expected %s, got %s" % [name, expected, actual])

func _initialize() -> void:
	var gm = GameManagerScript.new()
	gm.start_run()
	check("initial level", gm.level, 1)
	check("initial score", gm.score, 0)
	check("initial hp", gm.player_hp, GameConstants.PLAYER_MAX_HP)

	gm.add_kill()
	gm.add_kill()
	check("score after 2 kills", gm.score, GameConstants.SCORE_PER_KILL * 2)
	check("kills after 2 kills", gm.kills, 2)

	gm.advance_level()
	check("level after advance", gm.level, 2)
	check("score after advance", gm.score, GameConstants.SCORE_PER_KILL * 2 + GameConstants.SCORE_PER_LEVEL)

	gm.restore_player_hp()
	check("hp restored on new level", gm.player_hp, GameConstants.PLAYER_MAX_HP)

	gm.damage_player(GameConstants.PLAYER_MAX_HP + 50)
	check("hp clamped to 0", gm.player_hp, 0.0)
	check("is_player_dead true", gm.is_player_dead(), true)

	gm.restart_current_level()
	check("hp reset after restart", gm.player_hp, GameConstants.PLAYER_MAX_HP)
	check("level unchanged after restart", gm.level, 2)
	check("score unchanged after restart", gm.score, GameConstants.SCORE_PER_KILL * 2 + GameConstants.SCORE_PER_LEVEL)

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURES" % failures)
	quit(1 if failures > 0 else 0)
