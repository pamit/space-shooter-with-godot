# scripts/parallax_setup.gd
extends ParallaxBackground

const BACKGROUND_TEXTURE := preload("res://assets/sprites/kenney/Backgrounds/darkPurple.png")
const STAR_TEXTURE := preload("res://assets/sprites/kenney/PNG/Effects/star1.png")

const LAYER_CONFIGS := [
	{"speed": 15.0, "count": 35, "scale": 0.35, "modulate": Color(1, 1, 1, 0.35)},
	{"speed": 45.0, "count": 22, "scale": 0.5, "modulate": Color(1, 1, 1, 0.6)},
	{"speed": 85.0, "count": 12, "scale": 0.75, "modulate": Color(0.85, 0.95, 1, 0.9)},
]

var _speeds: Array = []

func _ready() -> void:
	_add_background_layer()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for config in LAYER_CONFIGS:
		var layer := ParallaxLayer.new()
		add_child(layer)
		_speeds.append(config["speed"])
		for i in range(config["count"]):
			var star := Sprite2D.new()
			star.texture = STAR_TEXTURE
			star.scale = Vector2.ONE * config["scale"]
			star.modulate = config["modulate"]
			star.position = Vector2(
				rng.randf_range(0, GameConstants.VIEWPORT_W),
				rng.randf_range(0, GameConstants.VIEWPORT_H)
			)
			layer.add_child(star)

func _add_background_layer() -> void:
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(0, 0)
	add_child(layer)
	move_child(layer, 0)
	var bg := Sprite2D.new()
	bg.texture = BACKGROUND_TEXTURE
	bg.centered = false
	bg.scale = Vector2(
		float(GameConstants.VIEWPORT_W) / BACKGROUND_TEXTURE.get_width(),
		float(GameConstants.VIEWPORT_H) / BACKGROUND_TEXTURE.get_height()
	)
	layer.add_child(bg)

func _process(delta: float) -> void:
	for i in range(1, get_child_count()):
		var layer := get_child(i) as ParallaxLayer
		layer.motion_offset.y += _speeds[i - 1] * delta
		if layer.motion_offset.y > GameConstants.VIEWPORT_H:
			layer.motion_offset.y = 0.0
