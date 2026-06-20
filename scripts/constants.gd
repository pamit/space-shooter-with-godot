# scripts/constants.gd
class_name GameConstants
extends RefCounted

const VIEWPORT_W := 720
const VIEWPORT_H := 1280

# Enemy wave scaling
const BASE_ENEMY_COUNT := 5
const ENEMIES_PER_LEVEL := 2
const BASE_ENEMY_SPEED := 100.0
const SPEED_GROWTH_PER_LEVEL := 0.03
const MAX_SPEED_MULTIPLIER := 2.5

# Boss scaling
const BASE_BOSS_HP := 100.0
const BOSS_HP_GROWTH := 1.15
const BOSS_LEVEL_INTERVAL := 5
const BOSS_BULLET_COUNT_BASE := 3
const BOSS_BULLET_COUNT_PER_LEVEL := 0.4
const BOSS_FIRE_INTERVAL_BASE := 1.5
const BOSS_FIRE_INTERVAL_MIN := 0.4
const BOSS_FIRE_INTERVAL_DECAY := 0.05

# Player
const PLAYER_MAX_HP := 100.0

# Score
const SCORE_PER_KILL := 10
const SCORE_PER_LEVEL := 50

# Pickups
const PICKUP_DURATION := 6.0
