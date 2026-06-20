### Task 11: Parallax starfield background

**Files:**
- Create: `scripts/parallax_setup.gd`

**Interfaces:**
- Produces: `ParallaxSetup` script attached to a `ParallaxBackground` node in `Main.tscn` (Task 12); in `_ready()` builds 3 `ParallaxLayer` children procedurally (no external star sprite needed — uses `Polygon2D` dots drawn via `_draw()` on a `Node2D` per layer), each layer auto-scrolling downward at a different speed to fake forward motion, and wrapping via `ParallaxBackground.scroll_offset`.

- [ ] **Step 1: Write the parallax setup script**

```gdscript
# scripts/parallax_setup.gd
extends ParallaxBackground

const LAYER_CONFIGS := [
	{"speed": 20.0, "count": 40, "size": 1.0, "color": Color(1, 1, 1, 0.4)},
	{"speed": 50.0, "count": 25, "size": 1.5, "color": Color(1, 1, 1, 0.7)},
	{"speed": 90.0, "count": 12, "size": 2.0, "color": Color(1, 1, 1, 1.0)},
]

var _speeds: Array = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for config in LAYER_CONFIGS:
		var layer := ParallaxLayer.new()
		add_child(layer)
		_speeds.append(config["speed"])
		for i in range(config["count"]):
			var star := ColorRect.new()
			var s: float = config["size"]
			star.size = Vector2(s, s)
			star.color = config["color"]
			star.position = Vector2(
				rng.randf_range(0, GameConstants.VIEWPORT_W),
				rng.randf_range(0, GameConstants.VIEWPORT_H)
			)
			layer.add_child(star)

func _process(delta: float) -> void:
	for i in range(get_child_count()):
		var layer := get_child(i) as ParallaxLayer
		layer.motion_offset.y += _speeds[i] * delta
		if layer.motion_offset.y > GameConstants.VIEWPORT_H:
			layer.motion_offset.y = 0.0
```

- [ ] **Step 2: Verify script parses cleanly**

Run: `godot --headless --check-only --script res://scripts/parallax_setup.gd`
Expected: no `Parse Error` output, exit code 0.

- [ ] **Step 3: Commit**

```bash
git add scripts/parallax_setup.gd
git commit -m "feat: add procedural 3-layer parallax starfield"
```

---

