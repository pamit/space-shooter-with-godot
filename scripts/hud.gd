# scripts/hud.gd
extends Control

signal health_boost_pressed
signal rocket_summon_pressed
signal penta_shot_pressed
signal pause_restart_pressed
signal pause_quit_pressed

const LOW_HP_RATIO := 0.25
const FILL_STYLE_NORMAL := preload("res://assets/ui/progress_fill_normal.tres")
const FILL_STYLE_LOW := preload("res://assets/ui/progress_fill_low.tres")
const FILL_STYLE_BOSS := preload("res://assets/ui/progress_fill_boss.tres")
const ABILITY_ACTIVE_NORMAL := preload("res://assets/ui/ability_button_active.tres")
const ABILITY_ACTIVE_HOVER := preload("res://assets/ui/ability_button_active_hover.tres")
const ABILITY_ACTIVE_PRESSED := preload("res://assets/ui/ability_button_active_pressed.tres")
const ABILITY_DISABLED := preload("res://assets/ui/ability_button_disabled.tres")

const ABILITY_ACTIVE_COLOR := Color(0.95, 0.98, 1, 1)
const ABILITY_DISABLED_COLOR := Color(0.38, 0.42, 0.48, 0.55)
const HEALTH_PLUS_OFFSET_LEFT := 6

@onready var hp_bar: ProgressBar = $TopPanel/Margin/Row/HPBar
@onready var level_label: Label = $TopPanel/Margin/Row/LevelLabel
@onready var score_label: Label = $BottomPanel/Margin/BottomRow/ScoreGroup/ScoreLabel
@onready var score_title: Label = $BottomPanel/Margin/BottomRow/ScoreGroup/ScoreTitle
@onready var pause_overlay: Control = $PauseOverlay
@onready var confirm_overlay: Control = $ConfirmOverlay
@onready var boss_warning: Label = $BossWarning
@onready var boss_bar_panel: PanelContainer = $BossBarPanel
@onready var boss_hp_bar: ProgressBar = $BossBarPanel/Margin/BossRow/BossHPBar
@onready var health_boost_button: Button = $BottomPanel/Margin/BottomRow/ActionButtons/HealthBoostButton
@onready var rocket_summon_button: Button = $BottomPanel/Margin/BottomRow/ActionButtons/RocketSummonButton
@onready var penta_shot_button: Button = $BottomPanel/Margin/BottomRow/ActionButtons/PentaShotButton

var _confirm_yes_action: Callable = Callable()

func _ready() -> void:
	pause_overlay.visible = false
	confirm_overlay.visible = false
	boss_warning.visible = false
	boss_bar_panel.visible = false
	boss_hp_bar.add_theme_stylebox_override("fill", FILL_STYLE_BOSS)
	score_title.add_theme_constant_override("offset_top", -10)
	_style_ability_buttons()
	reset_level_abilities()

func _style_ability_buttons() -> void:
	health_boost_button.text = "+"
	health_boost_button.add_theme_font_size_override("font_size", 32)
	rocket_summon_button.text = "▲"
	rocket_summon_button.icon = null
	rocket_summon_button.add_theme_font_size_override("font_size", 28)
	penta_shot_button.text = "5"
	penta_shot_button.add_theme_font_size_override("font_size", 28)
	for button in [health_boost_button, rocket_summon_button, penta_shot_button]:
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("outline_size", 0)
		button.add_theme_constant_override("h_separation", 0)

func reset_level_abilities() -> void:
	health_boost_button.disabled = false
	rocket_summon_button.disabled = false
	penta_shot_button.disabled = false
	_apply_ability_button_style(health_boost_button, true, true)
	_apply_ability_button_style(rocket_summon_button, true, false)
	_apply_ability_button_style(penta_shot_button, true, false)

func disable_health_boost() -> void:
	health_boost_button.disabled = true
	_apply_ability_button_style(health_boost_button, false, true)

func disable_rocket_summon() -> void:
	rocket_summon_button.disabled = true
	_apply_ability_button_style(rocket_summon_button, false, false)

func disable_penta_shot() -> void:
	penta_shot_button.disabled = true
	_apply_ability_button_style(penta_shot_button, false, false)

func show_confirm(on_yes: Callable) -> void:
	_confirm_yes_action = on_yes
	confirm_overlay.visible = true

func hide_confirm() -> void:
	confirm_overlay.visible = false
	_confirm_yes_action = Callable()

func _apply_ability_button_style(button: Button, enabled: bool, shift_plus_right: bool) -> void:
	if enabled:
		button.add_theme_stylebox_override("normal", _ability_style(ABILITY_ACTIVE_NORMAL, shift_plus_right))
		button.add_theme_stylebox_override("hover", _ability_style(ABILITY_ACTIVE_HOVER, shift_plus_right))
		button.add_theme_stylebox_override("pressed", _ability_style(ABILITY_ACTIVE_PRESSED, shift_plus_right))
		button.add_theme_stylebox_override("focus", _ability_style(ABILITY_ACTIVE_NORMAL, shift_plus_right))
		button.add_theme_stylebox_override("disabled", ABILITY_DISABLED)
		button.add_theme_color_override("font_color", ABILITY_ACTIVE_COLOR)
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.82, 0.88, 0.96, 1))
	else:
		button.add_theme_stylebox_override("normal", ABILITY_DISABLED)
		button.add_theme_stylebox_override("hover", ABILITY_DISABLED)
		button.add_theme_stylebox_override("pressed", ABILITY_DISABLED)
		button.add_theme_stylebox_override("focus", ABILITY_DISABLED)
		button.add_theme_color_override("font_color", ABILITY_DISABLED_COLOR)
		button.add_theme_color_override("font_disabled_color", ABILITY_DISABLED_COLOR)

func _ability_style(base: StyleBoxFlat, shift_plus_right: bool) -> StyleBoxFlat:
	if not shift_plus_right:
		return base
	var style: StyleBoxFlat = base.duplicate()
	style.content_margin_left = HEALTH_PLUS_OFFSET_LEFT
	return style

func show_boss_warning() -> void:
	boss_warning.visible = true

func hide_boss_warning() -> void:
	boss_warning.visible = false

func show_boss_health(max_hp: float, current_hp: float) -> void:
	boss_bar_panel.visible = true
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = current_hp

func hide_boss_health() -> void:
	boss_bar_panel.visible = false

func _process(_delta: float) -> void:
	hp_bar.max_value = GameConstants.PLAYER_MAX_HP
	hp_bar.value = GameManager.player_hp
	level_label.text = "LEVEL %d" % GameManager.level
	score_label.text = "%d" % GameManager.score

	var hp_ratio: float = GameManager.player_hp / GameConstants.PLAYER_MAX_HP
	var fill_style: StyleBox = FILL_STYLE_LOW if hp_ratio <= LOW_HP_RATIO else FILL_STYLE_NORMAL
	if hp_bar.get_theme_stylebox("fill") != fill_style:
		hp_bar.add_theme_stylebox_override("fill", fill_style)

	if boss_bar_panel.visible:
		var boss: Node = get_tree().get_first_node_in_group("boss")
		if boss != null and boss.has_method("get_current_hp"):
			boss_hp_bar.max_value = boss.get_max_hp()
			boss_hp_bar.value = boss.get_current_hp()
		else:
			hide_boss_health()

	pause_overlay.visible = (
		get_tree().paused
		and not _is_level_complete_visible()
		and not _is_game_over_visible()
		and not confirm_overlay.visible
	)

func _is_game_over_visible() -> bool:
	var main := get_tree().current_scene
	if main == null:
		return false
	var panel := main.get_node_or_null("GameOverLayer/GameOverPanel")
	return panel != null and panel.visible

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event is InputEventKey or not event.pressed or event.keycode != KEY_SPACE:
		return
	if _is_level_complete_visible() or _is_game_over_visible() or confirm_overlay.visible:
		return
	get_tree().paused = not get_tree().paused
	get_viewport().set_input_as_handled()

func _is_level_complete_visible() -> bool:
	var main := get_tree().current_scene
	if main == null:
		return false
	var panel := main.get_node_or_null("LevelCompleteLayer/LevelCompletePanel")
	return panel != null and panel.visible

func _on_pause_pressed() -> void:
	if _is_level_complete_visible() or _is_game_over_visible():
		return
	get_tree().paused = not get_tree().paused

func _on_resume_pressed() -> void:
	get_tree().paused = false

func _on_health_boost_pressed() -> void:
	if health_boost_button.disabled:
		return
	health_boost_pressed.emit()

func _on_rocket_summon_pressed() -> void:
	if rocket_summon_button.disabled:
		return
	rocket_summon_pressed.emit()

func _on_penta_shot_pressed() -> void:
	if penta_shot_button.disabled:
		return
	penta_shot_pressed.emit()

func _on_pause_restart_pressed() -> void:
	show_confirm(_confirm_pause_restart)

func _on_pause_quit_pressed() -> void:
	show_confirm(_confirm_pause_quit)

func _confirm_pause_restart() -> void:
	pause_restart_pressed.emit()

func _confirm_pause_quit() -> void:
	pause_quit_pressed.emit()

func _on_confirm_yes_pressed() -> void:
	var action := _confirm_yes_action
	hide_confirm()
	if action.is_valid():
		action.call()

func _on_confirm_no_pressed() -> void:
	hide_confirm()
