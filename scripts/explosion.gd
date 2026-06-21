# scripts/explosion.gd
# Adapted from GodotSimpleExplosionVFX (MIT) — https://github.com/drcd1/GodotSimpleExplosionVFX
extends Node2D

const SMOKE_SHEET := preload("res://assets/effects/explosion/smokesprite.png")
const FRAME_COLS := 8
const FRAME_ROWS := 8
const FRAME_SIZE := 256

static var _sprite_frames: SpriteFrames

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _sprite_frames == null:
		_sprite_frames = _build_sprite_frames()
	animated_sprite.sprite_frames = _sprite_frames
	animated_sprite.animation = "explode"
	scale = Vector2.ONE * randf_range(0.42, 0.58)
	animated_sprite.play()
	animated_sprite.animation_finished.connect(queue_free)

static func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"explode")
	frames.set_animation_speed(&"explode", 28.0)
	frames.set_animation_loop(&"explode", false)
	var frame_count := FRAME_COLS * FRAME_ROWS
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = SMOKE_SHEET
		var col := i % FRAME_COLS
		var row := int(i / FRAME_COLS)
		atlas.region = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(&"explode", atlas)
	return frames
