# scripts/parallax_setup.gd
extends ParallaxBackground

const BACKGROUND_TEXTURE := preload("res://assets/sprites/kenney/Backgrounds/darkPurple.png")

const LAYER_CONFIGS := [
	{"speed": 15.0, "count": 35, "scale": 0.9, "modulate": Color(0.85, 0.9, 1, 0.35)},
	{"speed": 45.0, "count": 22, "scale": 1.2, "modulate": Color(0.9, 0.95, 1, 0.55)},
	{"speed": 85.0, "count": 12, "scale": 1.6, "modulate": Color(1, 1, 0.95, 0.85)},
]

var _star_textures: Array[ImageTexture] = []

var _speeds: Array = []

func _ready() -> void:
	if _star_textures.is_empty():
		_build_star_textures()
	_add_background_layer()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for config in LAYER_CONFIGS:
		var layer := ParallaxLayer.new()
		add_child(layer)
		_speeds.append(config["speed"])
		for i in range(config["count"]):
			layer.add_child(_create_star(config, rng))

func _build_star_textures() -> void:
	for size in [6, 8, 10, 12]:
		_star_textures.append(_make_glow_texture(size))

static func _make_glow_texture(size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size - 1, size - 1) * 0.5
	var radius := float(size) * 0.5
	for y in range(size):
		for x in range(size):
			var dist: float = Vector2(x, y).distance_to(center) / radius
			if dist > 1.0:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var core: float = clampf(1.0 - dist * 1.35, 0.0, 1.0)
			var glow: float = pow(clampf(1.0 - dist, 0.0, 1.0), 1.8)
			var alpha: float = glow * 0.95
			var tint: float = lerpf(0.88, 1.0, core)
			image.set_pixel(x, y, Color(tint, tint, 1.0, alpha))
	var texture := ImageTexture.create_from_image(image)
	return texture

func _create_star(config: Dictionary, rng: RandomNumberGenerator) -> Node2D:
	var star_root := Node2D.new()
	var texture: ImageTexture = _star_textures[rng.randi_range(0, _star_textures.size() - 1)]
	var scale: float = config["scale"] * rng.randf_range(0.85, 1.15)
	var halo := Sprite2D.new()
	halo.texture = texture
	halo.scale = Vector2.ONE * scale
	halo.modulate = config["modulate"]
	star_root.add_child(halo)
	if rng.randf() < 0.55:
		var core := Sprite2D.new()
		core.texture = _star_textures[rng.randi_range(0, _star_textures.size() - 1)]
		core.scale = Vector2.ONE * scale * rng.randf_range(0.22, 0.35)
		core.modulate = Color(1, 1, 0.98, config["modulate"].a * 1.2)
		star_root.add_child(core)
	star_root.position = Vector2(
		rng.randf_range(0, GameConstants.VIEWPORT_W),
		rng.randf_range(0, GameConstants.VIEWPORT_H)
	)
	star_root.rotation = rng.randf_range(0.0, TAU)
	return star_root

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
