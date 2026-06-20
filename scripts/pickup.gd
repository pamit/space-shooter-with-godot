# scripts/pickup.gd
extends Area2D

@export var kind: String = "weapon"
@export var fall_speed: float = 120.0

func _ready() -> void:
	add_to_group("pickup")

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y > GameConstants.VIEWPORT_H + 50:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if not area.is_in_group("player"):
		return
	match kind:
		"weapon":
			_apply_weapon_boost(area)
		"shield":
			_apply_shield(area)
		"speed":
			_apply_speed(area)
		"bomb":
			_apply_bomb()
	queue_free()

func _apply_weapon_boost(player: Node) -> void:
	var original: float = player.fire_rate
	player.fire_rate = original / 3.0
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.fire_rate = original
	)

func _apply_shield(player: Node) -> void:
	player.apply_shield(true)
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.apply_shield(false)
	)

func _apply_speed(player: Node) -> void:
	var original: float = player.speed_multiplier
	player.speed_multiplier = 1.6
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.speed_multiplier = original
	)

func _apply_bomb() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("take_damage"):
			enemy.take_damage(999.0)
