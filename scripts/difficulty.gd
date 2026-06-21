# scripts/difficulty.gd
class_name Difficulty
extends RefCounted

const C = preload("res://scripts/constants.gd")

static func level_multiplier(level: int) -> float:
	return pow(C.LEVEL_DIFFICULTY_GROWTH, level - 1)

static func enemy_count_for_level(level: int) -> int:
	return int(round(C.BASE_ENEMY_COUNT * level_multiplier(level)))

static func enemy_speed_multiplier(level: int) -> float:
	return min(level_multiplier(level), C.MAX_SPEED_MULTIPLIER)

static func enemy_hp_multiplier(level: int) -> float:
	return level_multiplier(level)

static func boss_hp_for_level(level: int) -> float:
	return C.BASE_BOSS_HP * level_multiplier(level)

static func boss_bullet_count_for_level(level: int) -> int:
	return int(C.BOSS_BULLET_COUNT_BASE + level * C.BOSS_BULLET_COUNT_PER_LEVEL)

static func boss_fire_interval_for_level(level: int) -> float:
	var interval := C.BOSS_FIRE_INTERVAL_BASE - (level - 1) * C.BOSS_FIRE_INTERVAL_DECAY
	return max(interval, C.BOSS_FIRE_INTERVAL_MIN)

static func is_boss_level(_level: int) -> bool:
	return true
