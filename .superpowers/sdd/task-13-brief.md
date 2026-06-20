### Task 13: Audio hooks (structural — no bundled files)

**Files:**
- Modify: `scripts/player.gd` (add fire/hit `AudioStreamPlayer` calls)
- Modify: `scripts/enemy_base.gd`, `scripts/boss.gd` (add explosion `AudioStreamPlayer` calls)
- Modify: `scripts/pickup.gd` (add pickup `AudioStreamPlayer` call)
- Modify: `scenes/Player.tscn`, `scenes/EnemyStraight.tscn`, `scenes/EnemyZigzag.tscn`, `scenes/EnemyShooter.tscn`, `scenes/Boss.tscn`, `scenes/Pickup.tscn` (add child `AudioStreamPlayer`/`AudioStreamPlayer2D` nodes, `stream` left empty)
- Modify: `scenes/MainMenu.tscn`, `scenes/Main.tscn` (add a `MusicPlayer` `AudioStreamPlayer`, `stream` left empty, `autoplay` true, loop via code if a stream is later assigned)

**Interfaces:**
- Produces: a `play_sfx(player: AudioStreamPlayer2D) -> void` pattern repeated at each call site: `if player.stream != null: player.play()`. No new public API — purely additive nodes + guarded calls.

- [ ] **Step 1: Add a guarded SFX helper and call sites in player.gd**

```gdscript
# scripts/player.gd — add near the top, after existing @export lines
@onready var fire_sfx: AudioStreamPlayer2D = $FireSFX
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX

# inside _fire(), after instantiating + positioning the bullet, add:
	if fire_sfx.stream != null:
		fire_sfx.play()

# inside take_damage(), after hit.emit(amount), add:
	if hit_sfx.stream != null:
		hit_sfx.play()
```

- [ ] **Step 2: Add `AudioStreamPlayer2D` children to Player.tscn**

```ini
# add to scenes/Player.tscn, as new nodes under "Player"
[node name="FireSFX" type="AudioStreamPlayer2D" parent="."]

[node name="HitSFX" type="AudioStreamPlayer2D" parent="."]
```

- [ ] **Step 3: Add guarded explosion SFX in enemy_base.gd and boss.gd**

```gdscript
# scripts/enemy_base.gd — add @onready and guard inside take_damage(), before queue_free()
@onready var explosion_sfx: AudioStreamPlayer2D = $ExplosionSFX

# inside take_damage(), right before queue_free():
	if explosion_sfx.stream != null:
		explosion_sfx.play()
		await get_tree().create_timer(0.3).timeout
```

```gdscript
# scripts/boss.gd — identical pattern
@onready var explosion_sfx: AudioStreamPlayer2D = $ExplosionSFX

# inside take_damage(), right before queue_free():
	if explosion_sfx.stream != null:
		explosion_sfx.play()
		await get_tree().create_timer(0.3).timeout
```

Add to each of `EnemyStraight.tscn`, `EnemyZigzag.tscn`, `EnemyShooter.tscn`, `Boss.tscn`:

```ini
[node name="ExplosionSFX" type="AudioStreamPlayer2D" parent="."]
```

- [ ] **Step 4: Add guarded pickup SFX in pickup.gd**

```gdscript
# scripts/pickup.gd — add @onready and guard inside _on_area_entered(), before queue_free()
@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSFX

# at the end of _on_area_entered(), before the existing queue_free():
	if pickup_sfx.stream != null:
		pickup_sfx.play()
		await get_tree().create_timer(0.2).timeout
```

Add to `scenes/Pickup.tscn`:

```ini
[node name="PickupSFX" type="AudioStreamPlayer2D" parent="."]
```

- [ ] **Step 5: Add a music player to MainMenu and Main**

```ini
# add to scenes/MainMenu.tscn and scenes/Main.tscn
[node name="MusicPlayer" type="AudioStreamPlayer" parent="."]
autoplay = true
```

- [ ] **Step 6: Verify scripts still parse cleanly after edits**

Run: `for f in scripts/player.gd scripts/enemy_base.gd scripts/boss.gd scripts/pickup.gd; do godot --headless --check-only --script res://$f || echo "FAILED $f"; done`
Expected: no `FAILED` lines.

- [ ] **Step 7: Manual verification**

Re-run the Task 12 Step 6 play-test. Confirm no runtime errors appear in the Godot output panel related to `AudioStreamPlayer` nodes (silence is expected and correct — no streams are assigned yet).

- [ ] **Step 8: Commit**

```bash
git add scripts/player.gd scripts/enemy_base.gd scripts/boss.gd scripts/pickup.gd scenes/Player.tscn scenes/EnemyStraight.tscn scenes/EnemyZigzag.tscn scenes/EnemyShooter.tscn scenes/Boss.tscn scenes/Pickup.tscn scenes/MainMenu.tscn scenes/Main.tscn
git commit -m "feat: wire guarded audio hooks for fire, hit, explosion, pickup, and music"
```

---

## Follow-ups (explicitly out of scope for this plan)

- Swap placeholder `Polygon2D`/`ColorRect` shapes for real sprites (e.g. a Kenney-style asset pack you download and drop into `assets/sprites/`).
- Drop in royalty-free `.ogg`/`.wav` files and assign them to the `AudioStreamPlayer` `stream` properties added in Task 13.
- Android export presets / keystore signing (when ready to build an APK).
- v2 meta-progression: spending the already-tracked `total_kills`/`currency` save fields on permanent upgrades.
