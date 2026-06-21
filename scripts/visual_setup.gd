# scripts/visual_setup.gd
class_name VisualSetup
extends RefCounted

static func fit_collision_to_sprite(node: Area2D, sprite: Sprite2D, scale_factor: float = 0.55) -> void:
	var shape_node: CollisionShape2D = node.get_node_or_null("Shape")
	if shape_node == null or sprite.texture == null:
		return
	var tex_size: Vector2 = sprite.texture.get_size() * sprite.scale.abs()
	var rect := RectangleShape2D.new()
	rect.size = tex_size * scale_factor
	shape_node.shape = rect

static func configure_sprite(sprite: Sprite2D, texture: Texture2D, target_height: float) -> void:
	sprite.texture = texture
	if texture == null:
		return
	var scale_value: float = target_height / texture.get_size().y
	sprite.scale = Vector2(scale_value, scale_value)
	sprite.centered = true
