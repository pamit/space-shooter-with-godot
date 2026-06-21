# scripts/helper_rockets.gd
class_name HelperRockets
extends RefCounted

const ROCKET_SCENE := preload("res://scenes/HelperRocket.tscn")

static func launch(parent: Node, level: int) -> void:
	if parent == null or not parent.has_method("_launch_helper_rockets"):
		return
	parent.call_deferred("_launch_helper_rockets", level)

static func spawn_one(
	parent: Node,
	level: int,
	index: int,
	rng: RandomNumberGenerator = null
) -> void:
	if parent == null:
		return
	var tree: SceneTree = parent.get_tree()
	if tree == null:
		return
	var enemies: Array[Node] = []
	for node in tree.get_nodes_in_group("enemy"):
		if is_instance_valid(node) and node.has_method("take_damage"):
			enemies.append(node)
	if enemies.is_empty():
		return
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var base_speed: float = (
		GameConstants.BASE_ENEMY_SPEED
		* Difficulty.enemy_speed_multiplier(level)
		* GameConstants.HELPER_ROCKET_SPEED_MULT
	)
	var move_speed: float = base_speed * rng.randf_range(
		GameConstants.HELPER_ROCKET_SPEED_VARIANCE_MIN,
		GameConstants.HELPER_ROCKET_SPEED_VARIANCE_MAX
	)
	move_speed = snappedf(move_speed, 0.05)
	var spawn_pos: Vector2 = _pick_spawn_position(parent, index, rng)
	var rocket: Area2D = ROCKET_SCENE.instantiate()
	parent.add_child(rocket)
	if rocket.has_method("setup"):
		rocket.setup(spawn_pos.x, spawn_pos.y, move_speed)

static func _pick_spawn_position(parent: Node, index: int, rng: RandomNumberGenerator) -> Vector2:
	var margin := 90.0
	var base_y := GameConstants.VIEWPORT_H + 40.0 + float(index) * 22.0
	var slot_count := GameConstants.HELPER_ROCKET_COUNT
	var slot_width := (GameConstants.VIEWPORT_W - margin * 2.0) / float(slot_count)
	var min_sep := GameConstants.HELPER_ROCKET_MIN_SEPARATION
	for attempt in range(40):
		var slot := (index + attempt) % slot_count
		var spawn_x := margin + slot_width * (float(slot) + 0.5) + rng.randf_range(-slot_width * 0.2, slot_width * 0.2)
		var spawn_y := base_y + rng.randf_range(0.0, 18.0)
		if not _overlaps_active_rocket(parent, spawn_x, spawn_y, min_sep):
			return Vector2(spawn_x, spawn_y)
	return Vector2(
		margin + slot_width * (float(index) + 0.5),
		base_y + float(index) * 8.0
	)

static func _overlaps_active_rocket(parent: Node, spawn_x: float, spawn_y: float, min_sep: float) -> bool:
	var tree: SceneTree = parent.get_tree()
	if tree == null:
		return false
	var min_sep_sq := min_sep * min_sep
	for node in tree.get_nodes_in_group("helper_rocket"):
		if not is_instance_valid(node):
			continue
		var offset: Vector2 = node.global_position - Vector2(spawn_x, spawn_y)
		if offset.length_squared() < min_sep_sq:
			return true
	return false
