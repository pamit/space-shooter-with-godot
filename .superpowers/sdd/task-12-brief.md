### Task 12: HUD, Main Menu, and Main scene wiring

**Files:**
- Create: `scripts/hud.gd`, `scenes/HUD.tscn`
- Create: `scripts/main_menu.gd`, `scenes/MainMenu.tscn`
- Create: `scripts/main.gd`, `scenes/Main.tscn`

**Interfaces:**
- Consumes: every prior task's scenes/scripts and signals.
- Produces: `MainMenu` (Play button -> loads `Main.tscn`; displays `SaveManager.get_high_score()`; mute toggle sets `AudioServer.set_bus_mute(0, muted)`); `HUD` (progress-bar HP from `GameManager.player_hp`, label for `GameManager.level`, label for `GameManager.score`, pause button toggling `get_tree().paused`); `Main` (instances `Player`, `WaveSpawner`, `HUD`, `ParallaxBackground`; on `wave_cleared` calls `GameManager.advance_level()` then `wave_spawner.start_level(GameManager.level)`; on `GameManager.player_died` shows game-over overlay, calls `SaveManager.report_run_result(...)`, and on confirm calls `GameManager.restart_current_level()` + `wave_spawner.start_level(GameManager.level)`).

- [ ] **Step 1: Write the HUD script and scene**

```gdscript
# scripts/hud.gd
extends Control

@onready var hp_bar: ProgressBar = $HPBar
@onready var level_label: Label = $LevelLabel
@onready var score_label: Label = $ScoreLabel

func _process(_delta: float) -> void:
	hp_bar.max_value = GameConstants.PLAYER_MAX_HP
	hp_bar.value = GameManager.player_hp
	level_label.text = "Level %d" % GameManager.level
	score_label.text = "Score %d" % GameManager.score

func _on_pause_pressed() -> void:
	get_tree().paused = not get_tree().paused
```

```ini
# scenes/HUD.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/hud.gd" id="1"]

[node name="HUD" type="Control"]
script = ExtResource("1")
anchors_preset = 15
process_mode = 3

[node name="HPBar" type="ProgressBar" parent="."]
offset_left = 20.0
offset_top = 20.0
offset_right = 220.0
offset_bottom = 44.0

[node name="LevelLabel" type="Label" parent="."]
offset_left = 20.0
offset_top = 50.0
text = "Level 1"

[node name="ScoreLabel" type="Label" parent="."]
offset_left = 20.0
offset_top = 80.0
text = "Score 0"

[node name="PauseButton" type="Button" parent="."]
offset_left = 620.0
offset_top = 20.0
offset_right = 700.0
offset_bottom = 60.0
text = "||"

[connection signal="pressed" from="PauseButton" to="." method="_on_pause_pressed"]
```

- [ ] **Step 2: Write the Main Menu script and scene**

```gdscript
# scripts/main_menu.gd
extends Control

@onready var high_score_label: Label = $HighScoreLabel
@onready var mute_button: CheckButton = $MuteButton

func _ready() -> void:
	high_score_label.text = "High Score: %d" % SaveManager.get_high_score()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_mute_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, toggled_on)
```

```ini
# scenes/MainMenu.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/main_menu.gd" id="1"]

[node name="MainMenu" type="Control"]
script = ExtResource("1")
anchors_preset = 15

[node name="Title" type="Label" parent="."]
offset_left = 240.0
offset_top = 300.0
text = "SPACE SHOOTER"

[node name="HighScoreLabel" type="Label" parent="."]
offset_left = 270.0
offset_top = 360.0
text = "High Score: 0"

[node name="PlayButton" type="Button" parent="."]
offset_left = 300.0
offset_top = 420.0
offset_right = 420.0
offset_bottom = 460.0
text = "PLAY"

[node name="MuteButton" type="CheckButton" parent="."]
offset_left = 300.0
offset_top = 480.0
text = "Mute"

[connection signal="pressed" from="PlayButton" to="." method="_on_play_pressed"]
[connection signal="toggled" from="MuteButton" to="." method="_on_mute_toggled"]
```

- [ ] **Step 3: Write the Main script**

```gdscript
# scripts/main.gd
extends Node2D

@onready var wave_spawner: Node2D = $WaveSpawner
@onready var hud: Control = $HUD
@onready var game_over_panel: Control = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/FinalScoreLabel

func _ready() -> void:
	game_over_panel.visible = false
	GameManager.player_died.connect(_on_player_died)
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.start_level(GameManager.level)

func _on_wave_cleared() -> void:
	GameManager.advance_level()
	wave_spawner.start_level(GameManager.level)

func _on_player_died() -> void:
	get_tree().paused = true
	SaveManager.report_run_result(GameManager.score, GameManager.kills)
	final_score_label.text = "Score: %d" % GameManager.score
	game_over_panel.visible = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	game_over_panel.visible = false
	GameManager.restart_current_level()
	wave_spawner.start_level(GameManager.level)

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
```

- [ ] **Step 4: Create the Main scene wiring every node together**

```ini
# scenes/Main.tscn
[gd_scene load_steps=8 format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1"]
[ext_resource type="Script" path="res://scripts/parallax_setup.gd" id="2"]
[ext_resource type="PackedScene" path="res://scenes/Player.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/Bullet.tscn" id="4"]
[ext_resource type="Script" path="res://scripts/wave_spawner.gd" id="5"]
[ext_resource type="PackedScene" path="res://scenes/Boss.tscn" id="6"]
[ext_resource type="PackedScene" path="res://scenes/Pickup.tscn" id="7"]
[ext_resource type="PackedScene" path="res://scenes/HUD.tscn" id="8"]
[ext_resource type="PackedScene" path="res://scenes/EnemyStraight.tscn" id="9"]
[ext_resource type="PackedScene" path="res://scenes/EnemyZigzag.tscn" id="10"]
[ext_resource type="PackedScene" path="res://scenes/EnemyShooter.tscn" id="11"]

[node name="Main" type="Node2D"]
script = ExtResource("1")

[node name="Parallax" type="ParallaxBackground" parent="."]
script = ExtResource("2")

[node name="Player" parent="." instance=ExtResource("3")]
position = Vector2(360, 1100)
bullet_scene = ExtResource("4")

[node name="WaveSpawner" type="Node2D" parent="."]
script = ExtResource("5")
boss_scene = ExtResource("6")
pickup_scene = ExtResource("7")
enemy_scenes = {
"straight": ExtResource("9"),
"zigzag": ExtResource("10"),
"shooter": ExtResource("11")
}

[node name="HUD" parent="." instance=ExtResource("8")]

[node name="GameOverPanel" type="Control" parent="."]
anchors_preset = 15
visible = false

[node name="FinalScoreLabel" type="Label" parent="GameOverPanel"]
offset_left = 270.0
offset_top = 500.0
text = "Score: 0"

[node name="RetryButton" type="Button" parent="GameOverPanel"]
offset_left = 280.0
offset_top = 560.0
offset_right = 440.0
offset_bottom = 600.0
text = "RETRY LEVEL"

[node name="QuitButton" type="Button" parent="GameOverPanel"]
offset_left = 300.0
offset_top = 610.0
offset_right = 420.0
offset_bottom = 650.0
text = "QUIT"

[connection signal="pressed" from="GameOverPanel/RetryButton" to="." method="_on_retry_pressed"]
[connection signal="pressed" from="GameOverPanel/QuitButton" to="." method="_on_quit_pressed"]
```

- [ ] **Step 5: Verify all scripts parse cleanly**

Run: `for f in scripts/hud.gd scripts/main_menu.gd scripts/main.gd; do godot --headless --check-only --script res://$f || echo "FAILED $f"; done`
Expected: no `FAILED` lines printed.

- [ ] **Step 6: Manual play-test (requires the Godot editor — this is the first point the full loop is playable)**

Open the project in the Godot editor (`godot --path .`), press F5 (or set `MainMenu.tscn` as run scene, already done in Task 1's `run/main_scene`), and verify:
1. Main menu shows "High Score: 0", Play button works.
2. Dragging anywhere moves the ship to follow your finger/cursor (mouse emulates touch in editor).
3. Ship auto-fires upward continuously.
4. Enemies spawn from the top in 3 distinct movement patterns (straight, zigzag, shooting).
5. Killing all enemies in a wave advances to the next level (HUD level label increments) and a new, larger wave spawns.
6. Reaching level 5 spawns a boss instead of a wave; killing it advances past level 5 to level 6 (a normal wave).
7. Taking enemy/boss bullet hits decreases the HP bar; HP reaching 0 shows the Game Over panel with final score.
8. Clicking "RETRY LEVEL" resets HP and re-spawns the same level's wave; "QUIT" returns to the main menu.
9. Occasionally a colored square (pickup) drops from a killed enemy; picking it up changes behavior (faster fire, brief invincibility, etc.) for a few seconds.

- [ ] **Step 7: Commit**

```bash
git add scripts/hud.gd scenes/HUD.tscn scripts/main_menu.gd scenes/MainMenu.tscn scripts/main.gd scenes/Main.tscn
git commit -m "feat: wire HUD, main menu, and main scene into a playable level loop"
```

---

