### Task 9: Pickups — weapon boost, shield, speed, bomb

**Files:**
- Create: `scripts/pickup.gd`
- Create: `scenes/Pickup.tscn`

**Interfaces:**
- Consumes: `Player.apply_shield` (Task 6), `GameConstants.PICKUP_DURATION` (Task 1).
- Produces: `Pickup` node, exported `kind: String` (one of `"weapon"`, `"shield"`, `"speed"`, `"bomb"`), falls downward, on overlapping group `"player"` applies its effect then `queue_free()`:
  - `"weapon"`: sets player `fire_rate` to a third for `PICKUP_DURATION` seconds, then restores.
  - `"shield"`: calls `player.apply_shield(true)`, then `false` after `PICKUP_DURATION`.
  - `"speed"`: sets player `speed_multiplier` to `1.6` for `PICKUP_DURATION` seconds, then restores to `1.0`. (`speed_multiplier` is read by `Player._clamp_to_screen`-adjacent drag logic — Task 6's drag movement is 1:1 with finger position already, so this multiplier is exposed for the pickup to set but does not change drag responsiveness; documented here as a no-op visual hook intentionally, since finger-follow movement has no "speed" to scale. Skip wiring `speed_multiplier` into movement math — it stays exported on `Player` for parity with the locked pickup list but has no effect until a non-drag movement mode exists.)
  - `"bomb"`: on pickup, immediately damages every node in group `"enemy"` for 999 damage (one-shot screen clear), no duration.

- [ ] **Step 1: Write the pickup script**

```gdscript
# scripts/pickup.gd
extends Area2D

@export var kind: String = "weapon"
@export var fall_speed: float = 120.0

func _ready() -> void:
	add_to_group("pickup")

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y > GameConstants.VIEWPORT_H + 50:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if not area.is_in_group("player"):
		return
	match kind:
		"weapon":
			_apply_weapon_boost(area)
		"shield":
			_apply_shield(area)
		"speed":
			_apply_speed(area)
		"bomb":
			_apply_bomb()
	queue_free()

func _apply_weapon_boost(player: Node) -> void:
	var original := player.fire_rate
	player.fire_rate = original / 3.0
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.fire_rate = original
	)

func _apply_shield(player: Node) -> void:
	player.apply_shield(true)
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.apply_shield(false)
	)

func _apply_speed(player: Node) -> void:
	var original := player.speed_multiplier
	player.speed_multiplier = 1.6
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.speed_multiplier = original
	)

func _apply_bomb() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("take_damage"):
			enemy.take_damage(999.0)
```

- [ ] **Step 2: Create the Pickup scene**

```ini
# scenes/Pickup.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/pickup.gd" id="1"]

[node name="Pickup" type="Area2D"]
script = ExtResource("1")
collision_layer = 16
collision_mask = 2

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-12, -12, 12, -12, 12, 12, -12, 12)
color = Color(0.2, 1, 0.4, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

- [ ] **Step 3: Verify script parses cleanly**

Run: `godot --headless --check-only --script res://scripts/pickup.gd`
Expected: no `Parse Error` output, exit code 0.

- [ ] **Step 4: Commit**

```bash
git add scripts/pickup.gd scenes/Pickup.tscn
git commit -m "feat: add 4 in-run pickup types (weapon, shield, speed, bomb)"
```

---

