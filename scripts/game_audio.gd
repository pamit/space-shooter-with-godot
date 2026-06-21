# scripts/game_audio.gd
class_name GameAudio
extends RefCounted

const FIRE := preload("res://assets/audio/sfx_laser1.ogg")
const FIRE_ALT := preload("res://assets/audio/sfx_laser2.ogg")
const HIT := preload("res://assets/audio/sfx_zap.ogg")
const EXPLOSION := preload("res://assets/audio/sfx_twoTone.ogg")
const PICKUP := preload("res://assets/audio/sfx_shieldUp.ogg")
const SHIELD_DOWN := preload("res://assets/audio/sfx_shieldDown.ogg")
const GAME_OVER := preload("res://assets/audio/sfx_lose.ogg")
const MUSIC := preload("res://assets/audio/music/starshooter.ogg")

static func play_2d(player: AudioStreamPlayer2D, stream: AudioStream) -> void:
	if player == null or stream == null:
		return
	player.stream = stream
	player.play()

static func play_1d(player: AudioStreamPlayer, stream: AudioStream) -> void:
	if player == null or stream == null:
		return
	player.stream = stream
	player.play()

static func start_music(player: AudioStreamPlayer, volume_db: float = -10.0) -> void:
	if player == null or MUSIC == null:
		return
	var stream: AudioStream = MUSIC.duplicate()
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	player.stream = stream
	player.volume_db = volume_db
	if not player.playing:
		player.play()

static func stop_music(player: AudioStreamPlayer) -> void:
	if player != null and player.playing:
		player.stop()
