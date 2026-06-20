# scripts/pickup.gd
extends Area2D

@export var kind: String = "weapon"
@export var fall_speed: float = 120.0

@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSFX

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
	if pickup_sfx.stream != null:
		pickup_sfx.play()
		await get_tree().create_timer(0.2).timeout
	queue_free()

func _apply_weapon_boost(player: Node) -> void:
	player.add_weapon_boost()
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.remove_weapon_boost()
	)

func _apply_shield(player: Node) -> void:
	player.add_shield()
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.remove_shield()
	)

func _apply_speed(player: Node) -> void:
	player.add_speed_boost()
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.remove_speed_boost()
	)

func _apply_bomb() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("take_damage"):
			enemy.take_damage(999.0)
