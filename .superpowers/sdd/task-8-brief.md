### Task 8: Boss scene — scaling single attack pattern

**Files:**
- Create: `scripts/boss.gd`
- Create: `scenes/Boss.tscn`

**Interfaces:**
- Consumes: `Difficulty.boss_hp_for_level`, `boss_bullet_count_for_level`, `boss_fire_interval_for_level` (Task 2), `EnemyBullet.tscn` (Task 7).
- Produces: `Boss` node (group `"enemy"`, also group `"boss"`) with method `set_level(level: int) -> void` (sets `hp` and internal fire params from `Difficulty`), signal `died`. Fires a radial spread of `boss_bullet_count_for_level(level)` bullets every `boss_fire_interval_for_level(level)` seconds.

- [ ] **Step 1: Write the boss script**

```gdscript
# scripts/boss.gd
extends Area2D

signal died

@export var enemy_bullet_scene: PackedScene
var hp: float = 100.0
var _bullet_count: int = 3
var _fire_interval: float = 1.5
var _fire_timer: float = 1.5
var _move_dir: float = 1.0

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")

func set_level(level: int) -> void:
	hp = Difficulty.boss_hp_for_level(level)
	_bullet_count = Difficulty.boss_bullet_count_for_level(level)
	_fire_interval = Difficulty.boss_fire_interval_for_level(level)
	_fire_timer = _fire_interval

func _physics_process(delta: float) -> void:
	position.x += _move_dir * 80.0 * delta
	if position.x < 80 or position.x > GameConstants.VIEWPORT_W - 80:
		_move_dir *= -1.0
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_spread()
		_fire_timer = _fire_interval

func _fire_spread() -> void:
	if enemy_bullet_scene == null:
		return
	var spread_angle := PI / 4.0
	for i in range(_bullet_count):
		var t := 0.0 if _bullet_count == 1 else float(i) / float(_bullet_count - 1)
		var angle := lerp(-spread_angle, spread_angle, t) + PI / 2.0
		var bullet = enemy_bullet_scene.instantiate()
		bullet.direction = Vector2.RIGHT.rotated(angle)
		get_parent().add_child(bullet)
		bullet.global_position = global_position + Vector2(0, 30)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		died.emit()
		GameManager.add_kill()
		queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player_bullet"):
		take_damage(area.damage)
		area.queue_free()
```

- [ ] **Step 2: Create the Boss scene**

```ini
# scenes/Boss.tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/boss.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/EnemyBullet.tscn" id="2"]

[node name="Boss" type="Area2D" groups=["enemy", "boss"]]
script = ExtResource("1")
enemy_bullet_scene = ExtResource("2")
collision_layer = 8
collision_mask = 4

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, 50, -60, -10, -30, -50, 30, -50, 60, -10)
color = Color(0.9, 0.1, 0.1, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

- [ ] **Step 3: Verify script parses cleanly**

Run: `godot --headless --check-only --script res://scripts/boss.gd`
Expected: no `Parse Error` output, exit code 0.

- [ ] **Step 4: Commit**

```bash
git add scripts/boss.gd scenes/Boss.tscn
git commit -m "feat: add boss with level-scaled radial bullet spread"
```

---

