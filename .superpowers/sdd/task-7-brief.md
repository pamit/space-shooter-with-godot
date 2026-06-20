### Task 7: Enemy base + 3 movement-pattern types

**Files:**
- Create: `scripts/enemy_base.gd`
- Create: `scripts/enemy_straight.gd`
- Create: `scripts/enemy_zigzag.gd`
- Create: `scripts/enemy_shooter.gd`
- Create: `scenes/EnemyStraight.tscn`, `scenes/EnemyZigzag.tscn`, `scenes/EnemyShooter.tscn`
- Create: `scenes/EnemyBullet.tscn` (reuses `scripts/bullet.gd` with `direction = Vector2.DOWN`)

**Interfaces:**
- Consumes: `Difficulty.enemy_speed_multiplier` (Task 2), `GameManager.add_kill` (Task 5).
- Produces: `EnemyBase` (extended by all 3 types) with exported `base_speed: float`, `hp: float = 20.0`, method `set_level(level: int) -> void` (applies `Difficulty.enemy_speed_multiplier(level)` to its movement speed), signal `died`. Each type adds to group `"enemy"`. On `hp <= 0`: emits `died`, calls `GameManager.add_kill()`, `queue_free()`.

- [ ] **Step 1: Write the enemy base script**

```gdscript
# scripts/enemy_base.gd
extends Area2D
class_name EnemyBase

signal died

@export var base_speed: float = 100.0
@export var hp: float = 20.0

var _speed: float = 100.0

func _ready() -> void:
	add_to_group("enemy")

func set_level(level: int) -> void:
	_speed = base_speed * Difficulty.enemy_speed_multiplier(level)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		died.emit()
		GameManager.add_kill()
		queue_free()

func _physics_process(_delta: float) -> void:
	if position.y > GameConstants.VIEWPORT_H + 60:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player_bullet"):
		take_damage(area.damage)
		area.queue_free()
```

- [ ] **Step 2: Write the 3 movement-pattern subclasses**

```gdscript
# scripts/enemy_straight.gd
extends "res://scripts/enemy_base.gd"

func _physics_process(delta: float) -> void:
	position.y += _speed * delta
	super._physics_process(delta)
```

```gdscript
# scripts/enemy_zigzag.gd
extends "res://scripts/enemy_base.gd"

var _t: float = 0.0
var _origin_x: float = 0.0
var _initialized: bool = false

func _physics_process(delta: float) -> void:
	if not _initialized:
		_origin_x = position.x
		_initialized = true
	_t += delta
	position.y += _speed * delta
	position.x = _origin_x + sin(_t * 3.0) * 60.0
	super._physics_process(delta)
```

```gdscript
# scripts/enemy_shooter.gd
extends "res://scripts/enemy_base.gd"

@export var enemy_bullet_scene: PackedScene
var _fire_timer: float = 1.0

func _physics_process(delta: float) -> void:
	position.y += _speed * 0.5 * delta
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = 1.5
	super._physics_process(delta)

func _fire() -> void:
	if enemy_bullet_scene == null:
		return
	var bullet = enemy_bullet_scene.instantiate()
	bullet.direction = Vector2.DOWN
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, 20)
```

- [ ] **Step 3: Create EnemyBullet scene (reuses bullet.gd, marked as enemy_bullet group)**

```ini
# scenes/EnemyBullet.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/bullet.gd" id="1"]

[node name="EnemyBullet" type="Area2D" groups=["enemy_bullet"]]
script = ExtResource("1")
speed = 350.0
damage = 20.0
collision_layer = 8
collision_mask = 2

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-3, -8, 3, -8, 3, 8, -3, 8)
color = Color(1, 0.3, 0.3, 1)
```

- [ ] **Step 4: Create the 3 enemy scenes**

```ini
# scenes/EnemyStraight.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_straight.gd" id="1"]

[node name="EnemyStraight" type="Area2D" groups=["enemy"]]
script = ExtResource("1")
base_speed = 100.0
hp = 20.0
collision_layer = 8
collision_mask = 4

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, 20, -20, -15, 20, -15)
color = Color(0.8, 0.2, 0.2, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

```ini
# scenes/EnemyZigzag.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_zigzag.gd" id="1"]

[node name="EnemyZigzag" type="Area2D" groups=["enemy"]]
script = ExtResource("1")
base_speed = 90.0
hp = 15.0
collision_layer = 8
collision_mask = 4

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, 20, -18, 0, 0, -20, 18, 0)
color = Color(0.8, 0.6, 0.1, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

```ini
# scenes/EnemyShooter.tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/enemy_shooter.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/EnemyBullet.tscn" id="2"]

[node name="EnemyShooter" type="Area2D" groups=["enemy"]]
script = ExtResource("1")
base_speed = 60.0
hp = 30.0
enemy_bullet_scene = ExtResource("2")
collision_layer = 8
collision_mask = 4

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, 22, -22, -10, 0, -22, 22, -10)
color = Color(0.6, 0.1, 0.7, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

- [ ] **Step 5: Verify scripts parse cleanly**

Run: `godot --headless --check-only --script res://scripts/enemy_base.gd && godot --headless --check-only --script res://scripts/enemy_straight.gd && godot --headless --check-only --script res://scripts/enemy_zigzag.gd && godot --headless --check-only --script res://scripts/enemy_shooter.gd`
Expected: no `Parse Error` output for any of the four, exit code 0 each.

- [ ] **Step 6: Commit**

```bash
git add scripts/enemy_base.gd scripts/enemy_straight.gd scripts/enemy_zigzag.gd scripts/enemy_shooter.gd scenes/EnemyStraight.tscn scenes/EnemyZigzag.tscn scenes/EnemyShooter.tscn scenes/EnemyBullet.tscn
git commit -m "feat: add 3 enemy types with distinct movement patterns"
```

---

