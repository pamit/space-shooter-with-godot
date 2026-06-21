# scripts/bomb_explosion.gd
extends Node2D

const EXPLOSION_SCENE := preload("res://scenes/effects/Explosion.tscn")

const BLAST_OFFSETS: Array[Vector2] = [
	Vector2.ZERO,
	Vector2(-70, -40),
	Vector2(70, -40),
	Vector2(-50, 30),
	Vector2(50, 30),
	Vector2(-90, 0),
	Vector2(90, 0),
	Vector2(0, -80),
	Vector2(0, 60),
]

func _ready() -> void:
	for i in BLAST_OFFSETS.size():
		if i > 0:
			await get_tree().create_timer(0.12).timeout
		var blast: Node2D = EXPLOSION_SCENE.instantiate()
		get_parent().add_child(blast)
		blast.global_position = global_position + BLAST_OFFSETS[i]
		blast.scale = Vector2(1.4, 1.4) if i == 0 else Vector2(1.1, 1.1)
	await get_tree().create_timer(1.2).timeout
	queue_free()
