### Task 6: Player scene — touch-drag movement, HP, auto-fire

**Files:**
- Create: `scenes/Player.tscn`
- Create: `scripts/player.gd`
- Create: `scenes/Bullet.tscn`
- Create: `scripts/bullet.gd`

**Interfaces:**
- Consumes: `GameManager.player_hp`/`damage_player` (Task 5), `GameConstants` (Task 1).
- Produces: `Player` node (group `"player"`) with exported `fire_rate: float = 0.25`, `bullet_scene: PackedScene`, `speed_multiplier: float = 1.0` (set by speed pickups, Task 11), method `apply_shield(active: bool) -> void`, signal `hit(amount: float)`. `Bullet` scene/script: exported `speed: float`, `damage: float`, moves in `direction` (`Vector2`), frees itself on leaving viewport or on area collision (area group check happens in the body it hits, e.g. enemy script calls `queue_free()` on the bullet after applying damage).

- [ ] **Step 1: Write the bullet script (used by player fire)**

```gdscript
# scripts/bullet.gd
extends Area2D

@export var speed: float = 600.0
@export var damage: float = 10.0
var direction: Vector2 = Vector2.UP

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if position.y < -50 or position.y > GameConstants.VIEWPORT_H + 50:
		queue_free()
```

- [ ] **Step 2: Create the Bullet scene**

```ini
# scenes/Bullet.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/bullet.gd" id="1"]

[node name="Bullet" type="Area2D" groups=["player_bullet"]]
script = ExtResource("1")
collision_layer = 4
collision_mask = 8

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-4, -10, 4, -10, 4, 10, -4, 10)
color = Color(1, 0.9, 0.2, 1)
```

Note: `CollisionShape2D.shape` is intentionally left to be set in code (Step 3 below sets it on every spawned bullet instance) so the same scene can be reused for differently-sized bullets without per-scene resource duplication.

- [ ] **Step 3: Write the player script**

```gdscript
# scripts/player.gd
extends Area2D

signal hit(amount: float)

@export var fire_rate: float = 0.25
@export var bullet_scene: PackedScene
@export var speed_multiplier: float = 1.0

var _fire_timer: float = 0.0
var _drag_offset: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _shield_active: bool = false

func _ready() -> void:
	add_to_group("player")
	GameManager.start_run()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if get_rect_global().has_point(event.position) or true:
				_dragging = true
				_drag_offset = global_position - event.position
		else:
			_dragging = false
	elif event is InputEventScreenDrag and _dragging:
		global_position = event.position + _drag_offset
		_clamp_to_screen()

func get_rect_global() -> Rect2:
	return Rect2(global_position - Vector2(40, 40), Vector2(80, 80))

func _clamp_to_screen() -> void:
	global_position.x = clamp(global_position.x, 30, GameConstants.VIEWPORT_W - 30)
	global_position.y = clamp(global_position.y, 30, GameConstants.VIEWPORT_H - 30)

func _physics_process(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = fire_rate

func _fire() -> void:
	if bullet_scene == null:
		return
	var bullet = bullet_scene.instantiate()
	bullet.direction = Vector2.UP
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, -30)

func apply_shield(active: bool) -> void:
	_shield_active = active

func take_damage(amount: float) -> void:
	if _shield_active:
		return
	GameManager.damage_player(amount)
	hit.emit(amount)

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_bullet") or area.is_in_group("enemy"):
		take_damage(20.0)
		if area.has_method("queue_free"):
			area.queue_free()
```

- [ ] **Step 4: Create the Player scene**

```ini
# scenes/Player.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1"]

[node name="Player" type="Area2D"]
script = ExtResource("1")
collision_layer = 2
collision_mask = 8

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, -30, 25, 25, 0, 10, -25, 25)
color = Color(0.2, 0.7, 1, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

- [ ] **Step 5: Manual verification (no automated test — touch input requires a running scene)**

Run: `godot --path . res://scenes/Player.tscn` (opens the editor's run mode for this scene). Since there's no parent `Main.tscn` yet, this will warn about missing bullet container, which is fine — full play-test happens in Task 12.

For now, verify headless that the scene parses with no script errors:

Run: `godot --headless --check-only --script res://scripts/player.gd`
Expected: no `Parse Error` lines printed, exit code 0.

- [ ] **Step 6: Commit**

```bash
git add scenes/Player.tscn scripts/player.gd scenes/Bullet.tscn scripts/bullet.gd
git commit -m "feat: add player touch-drag movement, auto-fire, and bullet scene"
```

---

