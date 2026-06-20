# scripts/difficulty.gd
class_name Difficulty
extends RefCounted

const C = preload("res://scripts/constants.gd")

static func enemy_count_for_level(level: int) -> int:
	return C.BASE_ENEMY_COUNT + (level - 1) * C.ENEMIES_PER_LEVEL

static func enemy_speed_multiplier(level: int) -> float:
	var mult := 1.0 + (level - 1) * C.SPEED_GROWTH_PER_LEVEL
	return min(mult, C.MAX_SPEED_MULTIPLIER)

static func boss_hp_for_level(level: int) -> float:
	return C.BASE_BOSS_HP * pow(C.BOSS_HP_GROWTH, level - 1)

static func boss_bullet_count_for_level(level: int) -> int:
	return int(C.BOSS_BULLET_COUNT_BASE + level * C.BOSS_BULLET_COUNT_PER_LEVEL)

static func boss_fire_interval_for_level(level: int) -> float:
	var interval := C.BOSS_FIRE_INTERVAL_BASE - (level - 1) * C.BOSS_FIRE_INTERVAL_DECAY
	return max(interval, C.BOSS_FIRE_INTERVAL_MIN)

static func is_boss_level(level: int) -> bool:
	return level % C.BOSS_LEVEL_INTERVAL == 0
