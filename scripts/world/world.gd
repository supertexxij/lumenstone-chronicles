extends Node3D
## Builds village + guild halls + props + NPCs + enemy spawns from world.json
## Dense RuneScape-like green with performance-minded prop budgets (llvmpipe OK).

const PlayerScene := preload("res://scenes/player/player.tscn")
const EnemyScene := preload("res://scenes/world/enemy.tscn")
const NpcScene := preload("res://scenes/world/npc.tscn")

@onready var entities: Node3D = $Entities
@onready var static_world: Node3D = $StaticWorld

var player: CharacterBody3D
var world_data: Dictionary = {}

## Shared materials to cut draw-state churn on low-end / llvmpipe
var _mats: Dictionary = {}

## Day–night cycle (subtle; readable at night)
var _day_phase: float = 0.22  # start late morning
var _day_seconds: float = 360.0  # full day ~6 minutes
var _sun: DirectionalLight3D
var _env: Environment
var _interior_root: Node3D
var _outdoor_return: Vector3 = Vector3(0, 0, 10)
var _inside_hall: String = ""
var _door_cooldown: float = 0.0
var _weather_mode: int = 0  # 0 clear, 1 fog, 2 rain
var _weather_timer: float = 90.0
var _weather_auto: bool = true
var _rain: CPUParticles3D
var _fog_boost: float = 0.0
var _weather_label_cache: String = "Clear"

signal npc_talk(npc: Node)
signal weather_changed(mode: int, label: String)

func _ready() -> void:
	var f: FileAccess = FileAccess.open("res://data/world.json", FileAccess.READ)
	if f:
		world_data = JSON.parse_string(f.get_as_text())
		f.close()
	_init_mats()
	_build_ground()
	_build_paths()
	_build_buildings()
	_build_trees()
	_build_wilds()
	_build_fountain()
	_build_village_props()
	_spawn_npcs()
	_spawn_enemies()
	_spawn_player()
	_build_interiors()
	_build_lantern_glade()
	_build_pine_ridge()
	_build_prayer_garden()
	_build_lookout_rock()
	_build_mill_bridge()
	_setup_day_night()
	_setup_weather()
	_setup_outdoor_navigation()
	GameState.in_world = true
	AudioBus.start_ambient()

func _init_mats() -> void:
	_mats["grass"] = _mat(Color("#3d6b3d"))
	_mats["grass_dark"] = _mat(Color("#2a4a2a"))
	_mats["grass_light"] = _mat(Color("#4a7c4a"))
	_mats["dirt"] = _mat(Color("#8b7355"))
	_mats["dirt_trim"] = _mat(Color("#a08a6a"))
	_mats["stone"] = _mat(Color("#8a8a9a"))
	_mats["stone_dark"] = _mat(Color("#6a6a78"))
	_mats["wood"] = _mat(Color("#5c4033"))
	_mats["wood_light"] = _mat(Color("#7a5a40"))
	_mats["roof"] = _mat(Color("#4a3728"))
	_mats["water"] = _mat(Color("#4a90c8"), 0.2)
	_mats["leaf"] = _mat(Color("#2d6a4f"))
	_mats["leaf_alt"] = _mat(Color("#3d7a3f"))
	_mats["leaf_autumn"] = _mat(Color("#8a6a30"))
	_mats["barrel"] = _mat(Color("#6b4f2a"))
	_mats["iron"] = _mat(Color("#5a5a62"), 0.45)
	_mats["lantern"] = _mat(Color("#f4a261"), 0.35)
	_mats["lantern_glow"] = _mat(Color("#ffe08a"), 0.25)
	_mats["fence"] = _mat(Color("#6e5238"))
	_mats["bench"] = _mat(Color("#7a5c3a"))
	_mats["flower"] = _mat(Color("#c76b8a"))
	_mats["flower_y"] = _mat(Color("#d4a017"))
	_mats["rock"] = _mat(Color("#7a7a70"))
	_mats["bush"] = _mat(Color("#356b45"))

func _mat(c: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = roughness
	return m

func _hex_color(h: String) -> Color:
	return Color(h)

func _mi(mesh: Mesh, pos: Vector3, parent: Node, mat: Material, name: String = "") -> MeshInstance3D:
	var n := MeshInstance3D.new()
	if name != "":
		n.name = name
	n.mesh = mesh
	n.position = pos
	n.material_override = mat
	parent.add_child(n)
	return n

func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m

func _cyl(tr: float, br: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = tr
	m.bottom_radius = br
	m.height = h
	return m

func _sphere(r: float, h: float = -1.0) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h if h > 0.0 else r * 2.0
	return m

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	ground.mesh = plane
	ground.material_override = _mats["grass"]
	ground.position.y = -0.01
	static_world.add_child(ground)
	# Thin floor collider — outdoor click-to-move NavigationMesh bake + footing
	var floor_body := StaticBody3D.new()
	floor_body.name = "GroundBody"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(120, 0.2, 120)
	floor_col.shape = floor_shape
	floor_col.position = Vector3(0, -0.1, 0)
	floor_body.add_child(floor_col)
	static_world.add_child(floor_body)
	# Soft wild tint edges
	for i in 10:
		var patch := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 5.5 + (i % 3) * 0.8
		pm.bottom_radius = pm.top_radius
		pm.height = 0.02
		patch.mesh = pm
		patch.material_override = _mats["grass_dark"] if i % 2 == 0 else _mats["grass_light"]
		var ang := i * TAU / 10.0
		patch.position = Vector3(cos(ang) * 36.0, 0.015, sin(ang) * 36.0)
		static_world.add_child(patch)

func _build_paths() -> void:
	# Central plaza ring
	var path := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 14.5
	cyl.bottom_radius = 14.5
	cyl.height = 0.05
	path.mesh = cyl
	path.material_override = _mats["dirt"]
	path.position = Vector3(0, 0.02, 6)
	static_world.add_child(path)
	# Inner trim ring
	var trim := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = 15.3
	tc.bottom_radius = 15.3
	tc.height = 0.03
	trim.mesh = tc
	trim.material_override = _mats["dirt_trim"]
	trim.position = Vector3(0, 0.018, 6)
	static_world.add_child(trim)
	# Spokes toward guild halls
	var spokes := [
		Vector3(18, 0, 2), Vector3(-18, 0, 2), Vector3(0, 0, -14),
		Vector3(0, 0, 18), Vector3(0, 0, 0)
	]
	for s in spokes:
		var plank := MeshInstance3D.new()
		var box := BoxMesh.new()
		var dx: float = s.x
		var dz: float = s.z
		var length: float = maxf(8.0, Vector2(dx, dz).length() + 4.0)
		var ang: float = atan2(dx, dz)
		box.size = Vector3(2.4, 0.04, length)
		plank.mesh = box
		plank.material_override = _mats["dirt"]
		plank.position = Vector3(dx * 0.45, 0.025, 6.0 + dz * 0.45)
		plank.rotation.y = ang
		static_world.add_child(plank)

func _build_buildings() -> void:
	for b in world_data.get("buildings", []):
		var body := StaticBody3D.new()
		body.position = Vector3(b["x"], 0, b["z"])
		var w: float = float(b["w"])
		var d: float = float(b["d"])
		var h: float = float(b["h"])
		var guild_col := _hex_color(b["color"])
		var wall_mat := _mat(guild_col.lightened(0.08))
		var trim_mat := _mat(guild_col.darkened(0.25))
		# Main hall body
		_mi(_box(Vector3(w, h, d)), Vector3(0, h * 0.5, 0), body, wall_mat, "Hall")
		# Front porch / steps
		_mi(_box(Vector3(w * 0.55, 0.25, 1.2)), Vector3(0, 0.12, d * 0.5 + 0.4), body, _mats["stone"], "Steps")
		_mi(_box(Vector3(w * 0.5, 0.18, 0.9)), Vector3(0, 0.32, d * 0.5 + 0.25), body, _mats["stone_dark"], "Landing")
		# Door frame recess (darker panel)
		_mi(_box(Vector3(1.1, 2.0, 0.12)), Vector3(0, 1.1, d * 0.5 + 0.02), body, trim_mat, "Door")
		# Side buttress pillars
		_mi(_cyl(0.28, 0.32, h * 0.85), Vector3(-w * 0.5 - 0.15, h * 0.42, d * 0.35), body, _mats["stone"], "PillarL")
		_mi(_cyl(0.28, 0.32, h * 0.85), Vector3(w * 0.5 + 0.15, h * 0.42, d * 0.35), body, _mats["stone"], "PillarR")
		# Banner strip under eaves
		_mi(_box(Vector3(w * 0.7, 0.35, 0.08)), Vector3(0, h - 0.4, d * 0.5 + 0.06), body, trim_mat, "Banner")
		# Roof prism
		var roof := MeshInstance3D.new()
		var rmesh := PrismMesh.new()
		rmesh.size = Vector3(w + 0.6, 1.8, d + 0.6)
		roof.mesh = rmesh
		roof.position.y = h + 0.75
		roof.material_override = _mats["roof"]
		body.add_child(roof)
		# Chimney
		_mi(_box(Vector3(0.55, 1.4, 0.55)), Vector3(w * 0.28, h + 1.4, -d * 0.15), body, _mats["stone_dark"], "Chimney")
		# Collision for main box only
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(w, h, d)
		col.shape = shape
		col.position.y = h * 0.5
		body.add_child(col)
		var lbl := Label3D.new()
		lbl.text = b["label"]
		lbl.font_size = 64
		lbl.position = Vector3(0, h + 2.6, 0)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.outline_size = 6
		body.add_child(lbl)
		# Small lantern by door
		_add_lantern(body, Vector3(-1.0, 2.2, d * 0.5 + 0.35))
		static_world.add_child(body)

func _build_trees() -> void:
	for t in world_data.get("trees", []):
		_add_tree(Vector3(t[0], 0, t[1]), 0)

func _build_wilds() -> void:
	## Extra edge variety: rocks, bushes, alternate trees — capped for performance
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var placed := 0
	var attempts := 0
	while placed < 22 and attempts < 80:
		attempts += 1
		var ang := rng.randf() * TAU
		var rad := rng.randf_range(30.0, 44.0)
		var p := Vector3(cos(ang) * rad, 0, sin(ang) * rad)
		if _in_travel_corridor(p):
			continue
		match placed % 4:
			0:
				_add_tree(p, 1 if placed % 8 == 0 else 0)
			1:
				_add_rock_cluster(p, rng)
			2:
				_add_bush(p, rng)
			_:
				_add_bush(p + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5)), rng)
		placed += 1

func _near_segment_xz(pos: Vector3, a: Vector3, b: Vector3, half_w: float) -> bool:
	## Distance from point to segment on XZ plane (y ignored).
	var p := Vector2(pos.x, pos.z)
	var aa := Vector2(a.x, a.z)
	var bb := Vector2(b.x, b.z)
	var ab := bb - aa
	var len2 := ab.length_squared()
	if len2 < 0.0001:
		return p.distance_to(aa) < half_w
	var t := clampf((p - aa).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(aa + ab * t) < half_w

func _in_travel_corridor(pos: Vector3) -> bool:
	## Keep soft-travel routes walkable: north glade spur, west ridge spur, east garden spur.
	# North path to Lantern Glade (around x=0.5)
	if abs(pos.x - 0.5) < 3.2 and pos.z < -16.0 and pos.z > -52.0:
		return true
	# West path Glade → Pine Ridge (around z=-48)
	if abs(pos.z + 48.0) < 3.0 and pos.x < -2.0 and pos.x > -30.0:
		return true
	# East path to Prayer Garden
	if abs(pos.z - 18.0) < 3.0 and pos.x > 12.0 and pos.x < 36.0:
		return true
	# Village plaza keep-clear near fountain soft-travel
	if abs(pos.x) < 4.0 and abs(pos.z - 12.0) < 3.0:
		return true
	# Southeast diagonal path to Lookout Rock (v1.6 bugfix: was only z≈34 band)
	if _near_segment_xz(pos, Vector3(10, 0, 14), Vector3(40, 0, 34), 3.4):
		return true
	# Lookout plaza keep-clear
	if abs(pos.x - 40.0) < 4.0 and abs(pos.z - 34.0) < 4.0:
		return true
	# Southwest path to Mill Bridge
	if _near_segment_xz(pos, Vector3(-8, 0, 14), Vector3(-36, 0, 30), 3.4):
		return true
	# Mill Bridge plaza keep-clear
	if abs(pos.x + 36.0) < 5.0 and abs(pos.z - 30.0) < 5.0:
		return true
	return false

func _add_tree(pos: Vector3, style: int = 0) -> void:
	if _in_travel_corridor(pos):
		return
	var body := StaticBody3D.new()
	body.position = pos
	var trunk_h := 1.4 if style == 0 else 1.8
	_mi(_cyl(0.22, 0.34, trunk_h), Vector3(0, trunk_h * 0.5, 0), body, _mats["wood"], "Trunk")
	var leaf_mat: Material = _mats["leaf"] if style == 0 else _mats["leaf_autumn"]
	_mi(_sphere(1.05 if style == 0 else 0.95, 2.0), Vector3(0, trunk_h + 0.55, 0), body, leaf_mat, "Leaves")
	if style == 1:
		_mi(_sphere(0.7, 1.3), Vector3(0.35, trunk_h + 0.2, 0.1), body, _mats["leaf_alt"], "Leaves2")
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.32
	shape.height = 2.0
	col.shape = shape
	col.position.y = 1.0
	body.add_child(col)
	static_world.add_child(body)

func _add_rock_cluster(pos: Vector3, rng: RandomNumberGenerator) -> void:
	if _in_travel_corridor(pos):
		return
	var root := Node3D.new()
	root.position = pos
	for i in rng.randi_range(2, 4):
		var rock := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(0.25, 0.55)
		sm.height = sm.radius * rng.randf_range(1.2, 1.8)
		rock.mesh = sm
		rock.material_override = _mats["rock"]
		rock.position = Vector3(rng.randf_range(-0.6, 0.6), sm.height * 0.35, rng.randf_range(-0.6, 0.6))
		rock.scale = Vector3(rng.randf_range(0.8, 1.3), rng.randf_range(0.6, 1.0), rng.randf_range(0.8, 1.2))
		root.add_child(rock)
	static_world.add_child(root)

func _add_bush(pos: Vector3, rng: RandomNumberGenerator) -> void:
	if _in_travel_corridor(pos):
		return
	var root := Node3D.new()
	root.position = pos
	_mi(_sphere(rng.randf_range(0.45, 0.7), rng.randf_range(0.7, 1.1)), Vector3(0, 0.35, 0), root, _mats["bush"], "Bush")
	static_world.add_child(root)

func _build_fountain() -> void:
	var f: Dictionary = world_data.get("fountain", {"x": 0, "z": 8})
	var root := Node3D.new()
	root.position = Vector3(f["x"], 0, f["z"])
	_mi(_cyl(2.35, 2.55, 0.4), Vector3(0, 0.2, 0), root, _mats["stone"], "Base")
	_mi(_cyl(1.65, 1.65, 0.15), Vector3(0, 0.35, 0), root, _mats["water"], "Water")
	_mi(_cyl(0.28, 0.38, 1.6), Vector3(0, 1.0, 0), root, _mats["stone"], "Pillar")
	_mi(_cyl(0.9, 0.95, 0.2), Vector3(0, 1.75, 0), root, _mats["stone_dark"], "Bowl")
	_mi(_cyl(0.55, 0.55, 0.08), Vector3(0, 1.82, 0), root, _mats["water"], "UpperWater")
	# Ring of low posts
	for i in 6:
		var ang := i * TAU / 6.0
		_mi(_cyl(0.12, 0.14, 0.55), Vector3(cos(ang) * 2.7, 0.28, sin(ang) * 2.7), root, _mats["stone"], "Post%d" % i)
	var lbl := Label3D.new()
	lbl.text = "Fountain"
	lbl.font_size = 48
	lbl.position = Vector3(0, 2.5, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(lbl)
	# Soft pantry refill when walking near the fountain
	var refill := Area3D.new()
	refill.name = "PantryRefill"
	refill.monitoring = true
	refill.collision_layer = 0
	refill.collision_mask = 2
	refill.position = Vector3(0, 1.0, 0)
	var rcol := CollisionShape3D.new()
	var rbox := CylinderShape3D.new()
	rbox.radius = 3.2
	rbox.height = 2.4
	rcol.shape = rbox
	refill.add_child(rcol)
	refill.body_entered.connect(func(body: Node):
		if body.is_in_group("player") and GameState.has_method("refill_pantry"):
			GameState.refill_pantry(true)
	)
	root.add_child(refill)
	static_world.add_child(root)

func _build_village_props() -> void:
	## Barrels, fences, lantern posts, benches around plaza — budget ~50 pieces
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	# Fence arcs near plaza edges
	_fence_arc(Vector3(10, 0, 14), 4, 0.0)
	_fence_arc(Vector3(-10, 0, 14), 4, PI)
	_fence_arc(Vector3(12, 0, -2), 3, -0.4)
	_fence_arc(Vector3(-12, 0, -2), 3, 0.4 + PI)
	# Benches facing fountain
	_add_bench(Vector3(5.5, 0, 11.5), -0.6)
	_add_bench(Vector3(-5.5, 0, 11.5), 0.6)
	_add_bench(Vector3(4.0, 0, 3.5), 0.2)
	_add_bench(Vector3(-4.0, 0, 3.5), -0.2)
	# Barrel clusters near halls
	var barrel_spots := [
		Vector3(16, 0, 2), Vector3(17.2, 0, 2.8), Vector3(-16, 0, 2),
		Vector3(-17, 0, 1.4), Vector3(2.5, 0, -16), Vector3(-2.2, 0, -15.5),
		Vector3(2.0, 0, 20), Vector3(-1.5, 0, 19.5), Vector3(3.5, 0, -3.5)
	]
	for p in barrel_spots:
		_add_barrel(p, rng.randf() * TAU)
	# Lantern posts along path
	var lantern_spots := [
		Vector3(8, 0, 8), Vector3(-8, 0, 8), Vector3(0, 0, 14),
		Vector3(14, 0, 4), Vector3(-14, 0, 4), Vector3(0, 0, -10),
		Vector3(6, 0, 0), Vector3(-6, 0, 0)
	]
	for p in lantern_spots:
		_add_lantern_post(p)
	# Flower patches
	for i in 10:
		var ang := i * TAU / 10.0
		_add_flowers(Vector3(cos(ang) * 11.0, 0, 6.0 + sin(ang) * 9.0), rng)
	# Market crates near Builder hall
	_add_crate(Vector3(15.5, 0, 5.5))
	_add_crate(Vector3(16.3, 0, 5.0))
	_add_crate(Vector3(-15.2, 0, 5.2))

func _fence_arc(origin: Vector3, posts: int, yaw: float) -> void:
	var root := Node3D.new()
	root.position = origin
	root.rotation.y = yaw
	for i in posts:
		var x := float(i) * 1.35
		_mi(_box(Vector3(0.12, 1.0, 0.12)), Vector3(x, 0.5, 0), root, _mats["fence"], "Post")
		if i < posts - 1:
			_mi(_box(Vector3(1.25, 0.1, 0.08)), Vector3(x + 0.65, 0.7, 0), root, _mats["fence"], "Rail")
			_mi(_box(Vector3(1.25, 0.1, 0.08)), Vector3(x + 0.65, 0.35, 0), root, _mats["fence"], "RailLo")
	static_world.add_child(root)

func _add_bench(pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	_mi(_box(Vector3(1.6, 0.12, 0.45)), Vector3(0, 0.45, 0), root, _mats["bench"], "Seat")
	_mi(_box(Vector3(1.6, 0.45, 0.1)), Vector3(0, 0.7, -0.2), root, _mats["bench"], "Back")
	_mi(_box(Vector3(0.12, 0.45, 0.4)), Vector3(-0.7, 0.22, 0), root, _mats["wood"], "LegL")
	_mi(_box(Vector3(0.12, 0.45, 0.4)), Vector3(0.7, 0.22, 0), root, _mats["wood"], "LegR")
	static_world.add_child(root)

func _add_barrel(pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	_mi(_cyl(0.35, 0.38, 0.85), Vector3(0, 0.42, 0), root, _mats["barrel"], "Barrel")
	_mi(_cyl(0.36, 0.36, 0.06), Vector3(0, 0.55, 0), root, _mats["iron"], "Band")
	_mi(_cyl(0.36, 0.36, 0.06), Vector3(0, 0.28, 0), root, _mats["iron"], "Band2")
	static_world.add_child(root)

func _add_lantern_post(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	_mi(_cyl(0.08, 0.1, 2.2), Vector3(0, 1.1, 0), root, _mats["wood"], "Post")
	_add_lantern(root, Vector3(0.25, 2.0, 0))
	static_world.add_child(root)

func _add_lantern(parent: Node, pos: Vector3, with_light: bool = false) -> void:
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)
	_mi(_box(Vector3(0.22, 0.28, 0.22)), Vector3(0, 0, 0), holder, _mats["iron"], "Cage")
	_mi(_sphere(0.1), Vector3(0, 0, 0), holder, _mats["lantern_glow"], "Glow")
	_mi(_cyl(0.04, 0.06, 0.12), Vector3(0, 0.2, 0), holder, _mats["lantern"], "Cap")
	if with_light:
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.88, 0.62)
		light.light_energy = 1.35
		light.omni_range = 7.5
		light.omni_attenuation = 1.2
		light.shadow_enabled = false
		holder.add_child(light)

func _add_flowers(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var root := Node3D.new()
	root.position = pos
	for i in rng.randi_range(3, 5):
		var mat: Material = _mats["flower"] if i % 2 == 0 else _mats["flower_y"]
		_mi(_sphere(0.08, 0.12), Vector3(rng.randf_range(-0.4, 0.4), 0.15, rng.randf_range(-0.4, 0.4)), root, mat, "Fl")
	static_world.add_child(root)

func _add_crate(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	_mi(_box(Vector3(0.7, 0.55, 0.7)), Vector3(0, 0.28, 0), root, _mats["wood_light"], "Crate")
	static_world.add_child(root)

func _spawn_npcs() -> void:
	for n in world_data.get("npcs", []):
		var npc: Node = NpcScene.instantiate()
		npc.npc_id = n["id"]
		npc.npc_name = n["name"]
		npc.title = n["title"]
		npc.guild = n["guild"]
		npc.quest_ids = PackedStringArray(n["quest_ids"])
		npc.accent = _hex_color(n["color"])
		npc.position = Vector3(n["x"], 0, n["z"])
		npc.talk_requested.connect(func(p): npc_talk.emit(p))
		entities.add_child(npc)

func _spawn_enemies() -> void:
	for s in EnemyDB.spawns:
		var e: Node = EnemyScene.instantiate()
		e.kind = s["kind"]
		e.spawn_id = s["id"]
		e.position = Vector3(s["x"], 0, s["z"])
		entities.add_child(e)

func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	entities.add_child(player)
	player.global_position = Vector3(GameState.position_xz.x, 0, GameState.position_xz.y)


func _process(delta: float) -> void:
	if _door_cooldown > 0.0:
		_door_cooldown -= delta
	_update_day_night(delta)
	_update_weather(delta)
	_update_quest_desk_highlights()

func _setup_day_night() -> void:
	_sun = get_node_or_null("Sun") as DirectionalLight3D
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we:
		_env = we.environment
	_update_day_night(0.0)

func _update_day_night(delta: float) -> void:
	_day_phase = fmod(_day_phase + delta / _day_seconds, 1.0)
	# Smooth day curve: bright midday, soft dusk, readable night (never pitch black)
	var ang := _day_phase * TAU
	var dayness := clampf(0.55 + 0.45 * sin(ang - 0.2), 0.28, 1.0)
	if _inside_hall != "":
		dayness = 0.75  # indoor lamps feel steady
	if _sun:
		_sun.light_energy = lerpf(0.35, 1.2, dayness)
		var warm := Color(1.0, 0.92, 0.78)
		var cool := Color(0.75, 0.82, 1.0)
		_sun.light_color = warm.lerp(cool, 1.0 - dayness)
		# Orbit sun a bit
		var elev := lerpf(18.0, 55.0, dayness)
		var az := _day_phase * 360.0
		_sun.rotation_degrees = Vector3(-elev, az, 0)
	if _env:
		var day_sky := Color(0.45, 0.70, 0.90)
		var dusk_sky := Color(0.55, 0.40, 0.55)
		var night_sky := Color(0.12, 0.16, 0.28)
		var sky: Color
		if dayness > 0.65:
			sky = day_sky
		elif dayness > 0.4:
			sky = day_sky.lerp(dusk_sky, (0.65 - dayness) / 0.25)
		else:
			sky = dusk_sky.lerp(night_sky, (0.4 - dayness) / 0.4)
		_env.background_color = sky
		_env.ambient_light_color = Color(0.85, 0.88, 0.95).lerp(Color(0.45, 0.55, 0.75), 1.0 - dayness)
		_env.ambient_light_energy = lerpf(0.35, 0.6, dayness)
		_env.fog_light_color = sky.lightened(0.1)
		var base_fog := lerpf(0.0022, 0.0012, dayness)
		if _inside_hall != "":
			_env.fog_density = 0.0004
		else:
			_env.fog_density = base_fog + _fog_boost

func _build_interiors() -> void:
	## Simple enterable guild-hall volumes: walk into the door, teleport to a cozy interior.
	_interior_root = Node3D.new()
	_interior_root.name = "Interiors"
	_interior_root.position = Vector3(120, 0, 0)
	add_child(_interior_root)
	var halls: Array = world_data.get("buildings", [])
	for i in halls.size():
		var b: Dictionary = halls[i]
		_add_door_volume(b)
		_add_interior_room(b, i)

func _add_door_volume(b: Dictionary) -> void:
	var area := Area3D.new()
	area.name = "Door_%s" % b.get("id", "hall")
	area.monitoring = true
	area.monitorable = false
	area.collision_layer = 0
	area.collision_mask = 2  # player layer
	var d: float = float(b.get("d", 5))
	area.position = Vector3(float(b["x"]), 1.0, float(b["z"]) + d * 0.5 + 0.7)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 2.2, 1.4)
	col.shape = box
	area.add_child(col)
	# Visible soft door marker
	var mat := _mat(Color(0.95, 0.9, 0.55, 0.35), 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mi(_box(Vector3(1.2, 2.0, 0.15)), Vector3(0, 0.1, 0), area, mat, "DoorGlow")
	var tip := Label3D.new()
	tip.text = "Enter"
	tip.font_size = 36
	tip.position = Vector3(0, 1.5, 0)
	tip.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	area.add_child(tip)
	area.body_entered.connect(func(body: Node):
		if body.is_in_group("player"):
			_enter_hall(str(b.get("id", "")), str(b.get("label", "Hall")), body)
	)
	static_world.add_child(area)

func _add_interior_room(b: Dictionary, index: int) -> void:
	var room := Node3D.new()
	room.name = "Interior_%s" % b.get("id", index)
	room.position = Vector3(float(index) * 28.0, 0, 0)
	room.set_meta("hall_id", str(b.get("id", "")))
	room.set_meta("hall_label", str(b.get("label", "Hall")))
	room.set_meta("guild", str(b.get("guild", "")))
	_interior_root.add_child(room)
	var col := Color(b.get("color", "#888888"))
	var wall := _mat(col.lightened(0.15))
	var floor_m: Material = _mats["stone"]
	var rug := _mat(col.darkened(0.15))
	# Floor / walls / ceiling with collision shells
	_mi(_box(Vector3(12, 0.2, 12)), Vector3(0, 0.1, 0), room, floor_m, "Floor")
	_add_wall_col(room, Vector3(12, 3.6, 0.35), Vector3(0, 1.85, -6))
	_add_wall_col(room, Vector3(12, 3.6, 0.35), Vector3(0, 1.85, 6))
	_add_wall_col(room, Vector3(0.35, 3.6, 12), Vector3(-6, 1.85, 0))
	_add_wall_col(room, Vector3(0.35, 3.6, 12), Vector3(6, 1.85, 0))
	_mi(_box(Vector3(12, 3.5, 0.3)), Vector3(0, 1.8, -6), room, wall, "WallN")
	_mi(_box(Vector3(12, 3.5, 0.3)), Vector3(0, 1.8, 6), room, wall, "WallS")
	_mi(_box(Vector3(0.3, 3.5, 12)), Vector3(-6, 1.8, 0), room, wall, "WallW")
	_mi(_box(Vector3(0.3, 3.5, 12)), Vector3(6, 1.8, 0), room, wall, "WallE")
	_mi(_box(Vector3(12.2, 0.25, 12.2)), Vector3(0, 3.7, 0), room, _mats["roof"], "Ceiling")
	# Rug
	_mi(_box(Vector3(4.5, 0.04, 3.2)), Vector3(0, 0.22, 0.5), room, rug, "Rug")
	# Quest desk (center-north) — interactable
	_add_quest_desk(room, Vector3(0, 0, -3.2), col, str(b.get("guild", "")), str(b.get("label", "Hall")))
	# Side study tables + chairs
	_add_study_table(room, Vector3(-3.4, 0, -1.0), 0.2)
	_add_study_table(room, Vector3(3.4, 0, -1.0), -0.2)
	_add_chair(room, Vector3(-3.4, 0, 0.3), PI)
	_add_chair(room, Vector3(3.4, 0, 0.3), PI)
	# Bookshelves / scroll racks
	_add_bookshelf(room, Vector3(-5.2, 0, -3.5), col)
	_add_bookshelf(room, Vector3(5.2, 0, -3.5), col)
	_add_bookshelf(room, Vector3(-5.2, 0, 2.0), col)
	_add_bookshelf(room, Vector3(5.2, 0, 2.0), col)  # denser east wall
	# Extra study nook + desk-side chair
	_add_study_table(room, Vector3(0.0, 0, 2.4), 0.0)
	_add_chair(room, Vector3(0.0, 0, 3.4), 0.0)
	_add_chair(room, Vector3(-0.9, 0, -2.2), 0.4)  # seat at quest desk
	# Wall plaque near desk
	_mi(_box(Vector3(1.1, 0.7, 0.06)), Vector3(-2.2, 1.8, -5.7), room, _mat(col.darkened(0.25)), "Plaque")
	var plaque := Label3D.new()
	plaque.text = "Mastery Desk"
	plaque.font_size = 26
	plaque.position = Vector3(-2.2, 2.35, -5.5)
	plaque.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	room.add_child(plaque)
	# Benches along walls
	_mi(_box(Vector3(2.2, 0.45, 0.5)), Vector3(-2.5, 0.55, 4.2), room, _mats["bench"], "BenchL")
	_mi(_box(Vector3(2.2, 0.45, 0.5)), Vector3(2.5, 0.55, 4.2), room, _mats["bench"], "BenchR")
	# Barrel + crate + notice board
	var bar := Node3D.new()
	bar.position = Vector3(-4.5, 0, 3.5)
	room.add_child(bar)
	_mi(_cyl(0.32, 0.35, 0.8), Vector3(0, 0.4, 0), bar, _mats["barrel"], "Barrel")
	_mi(_box(Vector3(0.65, 0.5, 0.65)), Vector3(4.4, 0.28, 3.4), room, _mats["wood_light"], "Crate")
	_mi(_box(Vector3(1.6, 1.1, 0.08)), Vector3(0, 1.6, 5.5), room, _mat(col.darkened(0.35)), "NoticeBoard")
	var notice := Label3D.new()
	notice.text = "Notices"
	notice.font_size = 28
	notice.position = Vector3(0, 2.3, 5.5)
	notice.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	room.add_child(notice)
	# Warm indoor lanterns + real omni lights (stronger, cozy halls)
	_add_lantern(room, Vector3(-3.5, 2.6, -4.0), true)
	_add_lantern(room, Vector3(3.5, 2.6, -4.0), true)
	_add_lantern(room, Vector3(-3.5, 2.6, 3.5), true)
	_add_lantern(room, Vector3(3.5, 2.6, 3.5), true)
	_add_lantern(room, Vector3(0, 2.8, 0.2), true)  # center fill
	_mi(_box(Vector3(2.8, 1.1, 0.08)), Vector3(0, 2.5, -5.7), room, _mat(col.darkened(0.2)), "Banner")
	_add_guild_theme_props(room, str(b.get("guild", "")), col)
	var lbl := Label3D.new()
	lbl.text = "%s Hall" % b.get("label", "Guild")
	lbl.font_size = 56
	lbl.position = Vector3(0, 3.15, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	room.add_child(lbl)
	# Indoor attendant NPC (same quests as outdoor mentor)
	_spawn_indoor_attendant(room, b)
	# Exit volume near south wall
	var exit_area := Area3D.new()
	exit_area.name = "Exit"
	exit_area.monitoring = true
	exit_area.collision_layer = 0
	exit_area.collision_mask = 2
	exit_area.position = Vector3(0, 1.0, 5.0)
	var ecol := CollisionShape3D.new()
	var ebox := BoxShape3D.new()
	ebox.size = Vector3(2.2, 2.2, 1.3)
	ecol.shape = ebox
	exit_area.add_child(ecol)
	var emat := _mat(Color(0.6, 0.85, 0.95, 0.4), 0.5)
	emat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mi(_box(Vector3(1.5, 2.0, 0.12)), Vector3(0, 0.1, 0), exit_area, emat, "ExitGlow")
	var elbl := Label3D.new()
	elbl.text = "Exit to green"
	elbl.font_size = 32
	elbl.position = Vector3(0, 1.4, 0)
	elbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	exit_area.add_child(elbl)
	exit_area.body_entered.connect(func(body: Node):
		if body.is_in_group("player"):
			_exit_hall(body)
	)
	room.add_child(exit_area)

func _add_wall_col(room: Node3D, size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	room.add_child(body)

func _add_quest_desk(room: Node3D, pos: Vector3, guild_col: Color, guild: String, label: String) -> void:
	var root := Node3D.new()
	root.position = pos
	room.add_child(root)
	_mi(_box(Vector3(2.8, 0.85, 1.2)), Vector3(0, 0.55, 0), root, _mats["wood"], "Desk")
	_mi(_box(Vector3(2.9, 0.08, 1.3)), Vector3(0, 1.0, 0), root, _mats["wood_light"], "DeskTop")
	_mi(_box(Vector3(0.45, 0.12, 0.55)), Vector3(-0.7, 1.1, 0.1), root, _mat(guild_col), "Book")
	_mi(_box(Vector3(0.35, 0.08, 0.45)), Vector3(0.6, 1.08, -0.15), root, _mats["iron"], "Inkwell")
	_mi(_box(Vector3(0.4, 0.05, 0.5)), Vector3(0.05, 1.08, 0.25), root, _mat(Color("#f4e4bc")), "Scroll")
	_mi(_cyl(0.05, 0.06, 0.28), Vector3(0.95, 1.22, 0.25), root, _mat(Color("#f4e4bc")), "DeskCandle")
	_mi(_sphere(0.045), Vector3(0.95, 1.4, 0.25), root, _mats["lantern_glow"], "DeskFlame")
	_mi(_cyl(0.16, 0.14, 0.22), Vector3(-1.05, 1.18, -0.25), root, _mats["barrel"], "DeskPot")
	_mi(_sphere(0.18, 0.28), Vector3(-1.05, 1.42, -0.25), root, _mats["leaf"], "DeskPlant")
	# Interactable volume — opens outdoor mentor for this guild
	var area := Area3D.new()
	area.name = "QuestDesk"
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = Vector3(0, 1.0, 1.1)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.0, 1.6)
	col.shape = box
	area.add_child(col)
	var tip := Label3D.new()
	tip.name = "DeskTip"
	tip.text = "Quest Desk (F)"
	tip.font_size = 30
	tip.position = Vector3(0, 1.5, 0)
	tip.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tip.modulate = Color(1, 1, 1, 0.55)
	area.add_child(tip)
	var glow_mat := _mat(Color(guild_col.r, guild_col.g, guild_col.b, 0.18), 0.5)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var glow_mi := _mi(_box(Vector3(2.0, 0.05, 1.2)), Vector3(0, -0.7, 0), area, glow_mat, "DeskGlow")
	var ring_mat := _mat(Color(guild_col.r, guild_col.g, guild_col.b, 0.0), 0.5)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ring := _mi(_cyl(1.15, 1.15, 0.04), Vector3(0, -0.85, 0), area, ring_mat, "DeskHighlight")
	area.set_meta("guild", guild)
	area.set_meta("glow_mi", glow_mi)
	area.set_meta("ring_mi", ring)
	area.set_meta("tip", tip)
	area.set_meta("guild_col", guild_col)
	area.set_meta("player_near", false)
	area.add_to_group("quest_desks")
	area.body_entered.connect(func(body: Node):
		if body.is_in_group("player") and guild != "":
			body.set_meta("nearby_guild_desk", guild)
			area.set_meta("player_near", true)
			GameState.toast.emit("Quest desk — press F to speak with the hall mentor.")
	)
	area.body_exited.connect(func(body: Node):
		if body.is_in_group("player") and body.has_meta("nearby_guild_desk"):
			if str(body.get_meta("nearby_guild_desk")) == guild:
				body.remove_meta("nearby_guild_desk")
			area.set_meta("player_near", false)
	)
	root.add_child(area)

func _add_study_table(room: Node3D, pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	room.add_child(root)
	_mi(_box(Vector3(1.6, 0.7, 0.9)), Vector3(0, 0.45, 0), root, _mats["wood"], "Table")
	_mi(_cyl(0.06, 0.06, 0.7), Vector3(-0.6, 0.35, -0.3), root, _mats["wood_light"], "Leg1")
	_mi(_cyl(0.06, 0.06, 0.7), Vector3(0.6, 0.35, -0.3), root, _mats["wood_light"], "Leg2")
	_mi(_cyl(0.06, 0.06, 0.7), Vector3(-0.6, 0.35, 0.3), root, _mats["wood_light"], "Leg3")
	_mi(_cyl(0.06, 0.06, 0.7), Vector3(0.6, 0.35, 0.3), root, _mats["wood_light"], "Leg4")

func _add_chair(room: Node3D, pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	room.add_child(root)
	_mi(_box(Vector3(0.55, 0.12, 0.5)), Vector3(0, 0.45, 0), root, _mats["bench"], "Seat")
	_mi(_box(Vector3(0.55, 0.55, 0.08)), Vector3(0, 0.75, -0.22), root, _mats["bench"], "Back")
	_mi(_box(Vector3(0.08, 0.45, 0.08)), Vector3(-0.2, 0.22, 0.15), root, _mats["wood"], "Leg")
	_mi(_box(Vector3(0.08, 0.45, 0.08)), Vector3(0.2, 0.22, 0.15), root, _mats["wood"], "Leg2")

func _add_bookshelf(room: Node3D, pos: Vector3, guild_col: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	room.add_child(root)
	_mi(_box(Vector3(1.4, 2.2, 0.4)), Vector3(0, 1.15, 0), root, _mats["wood"], "Shelf")
	for i in 4:
		var y := 0.45 + float(i) * 0.45
		_mi(_box(Vector3(1.2, 0.08, 0.35)), Vector3(0, y, 0), root, _mats["wood_light"], "Plank")
		_mi(_box(Vector3(0.18, 0.32, 0.12)), Vector3(-0.35 + (i % 3) * 0.3, y + 0.2, 0.05), root, _mat(guild_col.lightened(0.1 * (i % 3))), "Book")

func _spawn_indoor_attendant(room: Node3D, b: Dictionary) -> void:
	## Quiet indoor attendant sharing the outdoor mentor's quest list.
	var guild: String = str(b.get("guild", ""))
	var outdoor: Dictionary = {}
	for n in world_data.get("npcs", []):
		if str(n.get("guild", "")) == guild:
			outdoor = n
			break
	if outdoor.is_empty():
		return
	var npc: Node = NpcScene.instantiate()
	npc.npc_id = str(outdoor.get("id", "")) + "-indoor"
	npc.npc_name = str(outdoor.get("name", "Mentor"))
	npc.title = "%s (Hall)" % outdoor.get("title", "Guild")
	npc.guild = guild
	npc.quest_ids = PackedStringArray(outdoor.get("quest_ids", []))
	npc.accent = _hex_color(str(outdoor.get("color", b.get("color", "#888"))))
	npc.position = Vector3(2.2, 0, -3.8)
	npc.talk_requested.connect(func(p): npc_talk.emit(p))
	room.add_child(npc)

func _open_guild_npc(guild: String) -> void:
	for n in get_tree().get_nodes_in_group("npcs"):
		if str(n.get("guild")) == guild and not str(n.get("npc_id")).ends_with("-indoor"):
			npc_talk.emit(n)
			return
	# Fallback: indoor attendant
	for n in get_tree().get_nodes_in_group("npcs"):
		if str(n.get("guild")) == guild:
			npc_talk.emit(n)
			return

func _enter_hall(hall_id: String, label: String, body: Node) -> void:
	if _inside_hall != "" or _door_cooldown > 0.0:
		return
	# Push return point clearly outside the door volume (south of front face)
	var door_z: float = body.global_position.z
	_outdoor_return = Vector3(body.global_position.x, 0, door_z + 2.8)
	_inside_hall = hall_id
	_door_cooldown = 0.8
	for room in _interior_root.get_children():
		if str(room.get_meta("hall_id", "")) == hall_id:
			body.global_position = room.global_position + Vector3(0, 0, 2.8)
			if "has_click_target" in body:
				body.has_click_target = false
			GameState.toast.emit("Entered %s Hall — desk for quests, blue glow to leave." % label)
			GameState.position_xz = Vector2(body.global_position.x, body.global_position.z)
			_apply_weather_visuals(false)
			return

func _exit_hall(body: Node) -> void:
	if _inside_hall == "":
		return
	_inside_hall = ""
	_door_cooldown = 1.2
	body.global_position = _outdoor_return
	if "has_click_target" in body:
		body.has_click_target = false
	GameState.toast.emit("Back on the village green.")
	GameState.position_xz = Vector2(body.global_position.x, body.global_position.z)
	_apply_weather_visuals(false)

func _build_lantern_glade() -> void:
	## Northern wilds spur — wider continuous dirt path + brook; corridor kept clear.
	var root := Node3D.new()
	root.name = "LanternGlade"
	static_world.add_child(root)
	# Continuous dirt ribbon north from village (overlap for no gaps)
	for i in 12:
		var z := -14.0 - float(i) * 3.0
		_mi(_box(Vector3(3.0, 0.04, 3.4)), Vector3(0.5, 0.025, z), root, _mats["dirt"], "Path")
	# Soft edge trim
	for i in 6:
		var z := -16.0 - float(i) * 5.5
		_mi(_box(Vector3(3.6, 0.02, 0.35)), Vector3(0.5, 0.03, z), root, _mats["dirt_trim"], "Trim")
	# Stepping stones across a tiny brook (centered on path)
	_mi(_cyl(2.8, 2.8, 0.08), Vector3(0.5, 0.02, -42), root, _mats["water"], "Brook")
	_mi(_cyl(1.6, 1.6, 0.06), Vector3(3.6, 0.02, -44.5), root, _mats["water"], "BrookPool")
	for i in 6:
		_mi(_sphere(0.32, 0.2), Vector3(-0.4 + float(i) * 0.55, 0.12, -42.0), root, _mats["rock"], "Step")
	# Signpost off the walk line
	var sign := Node3D.new()
	sign.position = Vector3(3.4, 0, -30)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 2.0), Vector3(0, 1.0, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.4, 0.7, 0.1)), Vector3(0, 1.8, 0), sign, _mats["wood_light"], "Board")
	var sl := Label3D.new()
	sl.text = "Lantern Glade"
	sl.font_size = 42
	sl.position = Vector3(0, 2.5, 0)
	sl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.add_child(sl)
	# Framing props kept outside corridor (side >= 4.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 12:
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(0.5 + side * rng.randf_range(5.0, 10.0), 0, -20.0 - float(i) * 2.6)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 1 if i > 6 else 0)
	# Lantern ring at glade end (outside path center)
	for i in 5:
		var ang := i * TAU / 5.0
		_add_lantern_post(Vector3(0.5 + cos(ang) * 5.0, 0, -48.0 + sin(ang) * 5.0))
	var glade_lbl := Label3D.new()
	glade_lbl.text = "Lantern Glade"
	glade_lbl.font_size = 56
	glade_lbl.position = Vector3(0.5, 3.2, -48)
	glade_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(glade_lbl)

func _setup_weather() -> void:
	_rain = CPUParticles3D.new()
	_rain.name = "Rain"
	_rain.emitting = false
	_rain.amount = 280
	_rain.lifetime = 1.1
	_rain.preprocess = 0.4
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(28, 0.2, 28)
	_rain.direction = Vector3(0.08, -1, 0.02)
	_rain.spread = 4.0
	_rain.initial_velocity_min = 8.0
	_rain.initial_velocity_max = 12.0
	_rain.gravity = Vector3(0, -2, 0)
	var rm := BoxMesh.new()
	rm.size = Vector3(0.03, 0.22, 0.03)
	_rain.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.65, 0.75, 0.9, 0.45)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rain.material_override = rmat
	_rain.position = Vector3(0, 14, 6)
	add_child(_rain)
	_apply_weather_visuals()

func _update_weather(delta: float) -> void:
	# Follow player outdoors so rain reads nearby; mute-friendly (no weather audio)
	if player and _rain:
		if _inside_hall == "":
			_rain.global_position = Vector3(player.global_position.x, 14, player.global_position.z)
			_rain.visible = true
		else:
			_rain.emitting = false
			_rain.visible = false
	if _weather_auto:
		_weather_timer -= delta
		if _weather_timer <= 0.0:
			cycle_weather(true)
			_weather_timer = [100.0, 70.0, 55.0][_weather_mode]

func cycle_weather(announce: bool = true) -> void:
	_weather_mode = (_weather_mode + 1) % 3
	_apply_weather_visuals(announce)

func set_weather(mode: int, announce: bool = false) -> void:
	_weather_mode = clampi(mode, 0, 2)
	_weather_auto = true
	_weather_timer = [100.0, 70.0, 55.0][_weather_mode]
	_apply_weather_visuals(announce)

func toggle_weather_auto() -> void:
	## Manual bump through clear → fog → rain; keeps auto-cycle on.
	cycle_weather(true)
	_weather_timer = [100.0, 70.0, 55.0][_weather_mode]

func get_weather_label() -> String:
	return _weather_label_cache

func _apply_weather_visuals(announce: bool = false) -> void:
	var rain_on := false
	var drip_on := false
	match _weather_mode:
		1:
			_weather_label_cache = "Fog"
			_fog_boost = 0.0045
			if _rain:
				_rain.emitting = false
		2:
			_weather_label_cache = "Rain"
			_fog_boost = 0.0025
			if _rain and _inside_hall == "":
				_rain.emitting = true
				rain_on = true
			elif _rain:
				_rain.emitting = false
				drip_on = true  # raining outdoors while player is indoors
		_:
			_weather_label_cache = "Clear"
			_fog_boost = 0.0
			if _rain:
				_rain.emitting = false
	if AudioBus.has_method("set_indoor_drip"):
		AudioBus.set_indoor_drip(drip_on)
	if AudioBus.has_method("set_rain_audio"):
		AudioBus.set_rain_audio(rain_on)
	weather_changed.emit(_weather_mode, _weather_label_cache)
	if announce:
		GameState.toast.emit("Weather: %s" % _weather_label_cache)


func _update_quest_desk_highlights() -> void:
	## Soft pulse when the player stands at a quest desk.
	for area in get_tree().get_nodes_in_group("quest_desks"):
		var near: bool = bool(area.get_meta("player_near", false))
		var tip: Label3D = area.get_meta("tip") if area.has_meta("tip") else null
		var glow_mi: MeshInstance3D = area.get_meta("glow_mi") if area.has_meta("glow_mi") else null
		var ring_mi: MeshInstance3D = area.get_meta("ring_mi") if area.has_meta("ring_mi") else null
		var gc: Color = area.get_meta("guild_col") if area.has_meta("guild_col") else Color(1, 0.9, 0.5)
		var pulse: float = 0.35 + 0.35 * abs(sin(Time.get_ticks_msec() * 0.004))
		if tip:
			tip.modulate = Color(1, 1, 0.85, 0.95 if near else 0.5)
			tip.font_size = 36 if near else 30
		if glow_mi and glow_mi.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = glow_mi.material_override
			m.albedo_color = Color(gc.r, gc.g, gc.b, (0.45 * pulse) if near else 0.14)
		if ring_mi:
			ring_mi.visible = near
			if near and ring_mi.material_override is StandardMaterial3D:
				var rm: StandardMaterial3D = ring_mi.material_override
				rm.albedo_color = Color(gc.r, gc.g, gc.b, 0.25 + 0.35 * pulse)
				var s: float = 0.95 + 0.12 * pulse
				ring_mi.scale = Vector3(s, 1.0, s)

func _add_guild_theme_props(room: Node3D, guild: String, col: Color) -> void:
	## Light per-guild prop flavor — keeps halls distinct without heavy budgets.
	match guild:
		"math":
			# Counting blocks + abacus bar
			for i in 5:
				var c := Color("#d4a017").lightened(0.05 * i)
				_mi(_box(Vector3(0.28, 0.28, 0.28)), Vector3(-4.2 + float(i) * 0.35, 0.35, 1.8), room, _mat(c), "Block")
			_mi(_box(Vector3(1.4, 0.08, 0.12)), Vector3(4.0, 1.2, -2.0), room, _mats["wood"], "AbacusBar")
			for i in 6:
				_mi(_sphere(0.08), Vector3(3.5 + float(i) * 0.18, 1.35, -2.0), room, _mat(Color("#c9a227")), "Bead")
		"la":
			# Scroll racks + ink pots
			for i in 4:
				_mi(_cyl(0.08, 0.08, 0.7), Vector3(-4.0 + float(i) * 0.35, 0.9, 1.5), room, _mats["wood_light"], "Scroll")
				_mi(_cyl(0.1, 0.1, 0.06), Vector3(-4.0 + float(i) * 0.35, 1.25, 1.5), room, _mat(col), "ScrollCap")
			_mi(_cyl(0.12, 0.14, 0.2), Vector3(4.2, 1.15, -2.2), room, _mats["iron"], "Ink")
			_mi(_box(Vector3(0.5, 0.04, 0.7)), Vector3(3.6, 1.08, -2.0), room, _mat(Color("#f4e4bc")), "Parchment")
		"science":
			# Potted plants + observation tray
			_mi(_cyl(0.22, 0.18, 0.35), Vector3(-4.3, 0.35, 1.6), room, _mats["barrel"], "Pot")
			_mi(_sphere(0.35, 0.55), Vector3(-4.3, 0.85, 1.6), room, _mats["leaf"], "Plant")
			_mi(_cyl(0.2, 0.16, 0.3), Vector3(4.2, 0.3, 1.4), room, _mats["stone"], "Pot2")
			_mi(_sphere(0.28, 0.45), Vector3(4.2, 0.75, 1.4), room, _mats["leaf_alt"], "Plant2")
			_mi(_box(Vector3(1.1, 0.08, 0.7)), Vector3(3.5, 1.08, -2.1), room, _mats["stone_dark"], "Tray")
			_mi(_sphere(0.12), Vector3(3.3, 1.2, -2.1), room, _mats["rock"], "Sample")
			_mi(_sphere(0.1, 0.14), Vector3(3.7, 1.18, -2.0), room, _mat(Color("#6aaa6a")), "LeafSample")
		"history":
			# Map table + timeline posts
			_mi(_box(Vector3(1.8, 0.7, 1.1)), Vector3(-3.8, 0.45, 1.5), room, _mats["wood"], "MapTable")
			_mi(_box(Vector3(1.5, 0.04, 0.9)), Vector3(-3.8, 0.85, 1.5), room, _mat(Color("#c2b280")), "Map")
			for i in 4:
				_mi(_cyl(0.06, 0.06, 1.1), Vector3(3.6 + float(i) * 0.35, 0.7, 1.8), room, _mats["wood"], "Post")
				_mi(_box(Vector3(0.2, 0.15, 0.05)), Vector3(3.6 + float(i) * 0.35, 1.2, 1.8), room, _mat(col.lightened(0.1 * i)), "Flag")
		"bible":
			# Simple lectern + quiet candles
			_mi(_box(Vector3(0.7, 1.1, 0.5)), Vector3(-3.8, 0.7, 1.4), room, _mats["wood"], "Lectern")
			_mi(_box(Vector3(0.55, 0.08, 0.45)), Vector3(-3.8, 1.3, 1.55), room, _mats["wood_light"], "LecternTop")
			_mi(_box(Vector3(0.35, 0.1, 0.28)), Vector3(-3.8, 1.4, 1.55), room, _mat(Color("#f4e4bc")), "OpenWord")
			for i in 3:
				var cx := 3.5 + float(i) * 0.4
				_mi(_cyl(0.06, 0.07, 0.35), Vector3(cx, 1.2, -2.0), room, _mat(Color("#f4e4bc")), "Candle")
				_mi(_sphere(0.05), Vector3(cx, 1.42, -2.0), room, _mats["lantern_glow"], "Flame")
		_:
			pass

func _build_pine_ridge() -> void:
	## Western spur beyond Lantern Glade — continuous ford path + pine stand.
	var root := Node3D.new()
	root.name = "PineRidge"
	static_world.add_child(root)
	# Continuous path west from glade brook toward ridge
	for i in 9:
		var x := -2.0 - float(i) * 2.8
		_mi(_box(Vector3(3.2, 0.04, 2.6)), Vector3(x, 0.025, -48.0), root, _mats["dirt"], "RidgePath")
	# Creek ford (shallow crossing) with centered stepping stones
	_mi(_cyl(3.2, 3.2, 0.07), Vector3(-18, 0.015, -48), root, _mats["water"], "Creek")
	_mi(_cyl(1.4, 1.4, 0.05), Vector3(-20.5, 0.015, -50.5), root, _mats["water"], "CreekBend")
	for i in 5:
		_mi(_sphere(0.3, 0.18), Vector3(-16.2 - float(i) * 0.75, 0.12, -48.0), root, _mats["rock"], "FordStone")
	var sign := Node3D.new()
	sign.position = Vector3(-12, 0, -45.2)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.9), Vector3(0, 0.95, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.5, 0.65, 0.1)), Vector3(0, 1.7, 0), sign, _mats["wood_light"], "Board")
	var sl := Label3D.new()
	sl.text = "Pine Ridge"
	sl.font_size = 40
	sl.position = Vector3(0, 2.4, 0)
	sl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.add_child(sl)
	# Pines kept off the ford corridor
	var rng := RandomNumberGenerator.new()
	rng.seed = 113
	for i in 14:
		var ang := rng.randf() * TAU
		var rad := rng.randf_range(4.0, 10.0)
		var p := Vector3(-24.0 + cos(ang) * rad, 0, -54.0 + sin(ang) * rad * 0.75)
		if _in_travel_corridor(p):
			continue
		_add_pine(p, rng)
	for i in 4:
		_add_rock_cluster(Vector3(-26.0 + float(i) * 2.2, 0, -58.0 - (i % 2)), rng)
	var ridge_lbl := Label3D.new()
	ridge_lbl.text = "Pine Ridge"
	ridge_lbl.font_size = 52
	ridge_lbl.position = Vector3(-24, 3.4, -54)
	ridge_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(ridge_lbl)

func _add_pine(pos: Vector3, rng: RandomNumberGenerator) -> void:
	if _in_travel_corridor(pos):
		return
	var body := StaticBody3D.new()
	body.position = pos
	var trunk_h := rng.randf_range(1.6, 2.2)
	_mi(_cyl(0.14, 0.22, trunk_h), Vector3(0, trunk_h * 0.5, 0), body, _mats["wood"], "Trunk")
	var pine := _mat(Color("#1f4d32"))
	for j in 3:
		var y := trunk_h * 0.45 + float(j) * 0.55
		var r := 0.95 - float(j) * 0.22
		var cone := CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = r
		cone.height = 0.85
		_mi(cone, Vector3(0, y, 0), body, pine, "Pine%d" % j)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.28
	shape.height = 2.2
	col.shape = shape
	col.position.y = 1.1
	body.add_child(col)
	static_world.add_child(body)


func _build_prayer_garden() -> void:
	## Quiet eastern landmark — soft travel (G). Simple benches + stone marker.
	var root := Node3D.new()
	root.name = "PrayerGarden"
	static_world.add_child(root)
	# Path east from plaza
	for i in 7:
		var x := 14.0 + float(i) * 2.6
		_mi(_box(Vector3(2.8, 0.04, 2.4)), Vector3(x, 0.025, 18.0), root, _mats["dirt"], "GardenPath")
	# Garden circle
	_mi(_cyl(5.5, 5.5, 0.04), Vector3(30, 0.02, 18), root, _mats["grass_light"], "Lawn")
	_mi(_cyl(1.2, 1.3, 0.35), Vector3(30, 0.2, 18), root, _mats["stone"], "MarkerBase")
	_mi(_box(Vector3(0.28, 1.8, 0.18)), Vector3(30, 1.2, 18), root, _mats["stone_dark"], "Marker")
	_mi(_box(Vector3(0.9, 0.22, 0.16)), Vector3(30, 1.55, 18), root, _mats["stone"], "MarkerArm")
	# Quiet benches
	_add_bench(Vector3(27.5, 0, 20.5), 0.8)
	_add_bench(Vector3(32.5, 0, 20.5), -0.8)
	_add_bench(Vector3(30, 0, 14.8), 0.0)
	# Flower ring
	var rng := RandomNumberGenerator.new()
	rng.seed = 131
	for i in 8:
		var ang := i * TAU / 8.0
		_add_flowers(Vector3(30.0 + cos(ang) * 3.8, 0, 18.0 + sin(ang) * 3.8), rng)
	_add_lantern_post(Vector3(26.5, 0, 15.5))
	_add_lantern_post(Vector3(33.5, 0, 15.5))
	var sign := Node3D.new()
	sign.position = Vector3(26.2, 0, 18.0)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.8), Vector3(0, 0.9, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.5, 0.6, 0.1)), Vector3(0, 1.6, 0), sign, _mats["wood_light"], "Board")
	var sl := Label3D.new()
	sl.text = "Prayer Garden"
	sl.font_size = 40
	sl.position = Vector3(0, 2.3, 0)
	sl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.add_child(sl)
	var lbl := Label3D.new()
	lbl.text = "Prayer Garden"
	lbl.font_size = 52
	lbl.position = Vector3(30, 3.2, 18)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(lbl)



func _build_lookout_rock() -> void:
	## Southeast landmark — soft travel (L). Rocky overlook with a short dirt spur.
	var root := Node3D.new()
	root.name = "LookoutRock"
	static_world.add_child(root)
	# Path southeast from plaza toward lookout
	for i in 8:
		var t := float(i) / 7.0
		var x := 10.0 + t * 28.0
		var z := 14.0 + t * 20.0
		_mi(_box(Vector3(2.6, 0.04, 2.4)), Vector3(x, 0.025, z), root, _mats["dirt"], "LookoutPath")
	# Rocky outcrop
	_mi(_cyl(4.2, 4.5, 0.35), Vector3(40, 0.18, 34), root, _mats["stone"], "LookoutBase")
	_mi(_box(Vector3(3.2, 1.6, 2.4)), Vector3(40, 1.0, 34), root, _mats["stone_dark"], "LookoutMass")
	_mi(_box(Vector3(1.4, 0.9, 1.2)), Vector3(41.2, 1.85, 33.2), root, _mats["stone"], "LookoutCap")
	_mi(_cyl(0.35, 0.4, 1.4), Vector3(39.0, 1.9, 35.0), root, _mats["wood"], "LookoutPost")
	_mi(_box(Vector3(1.1, 0.08, 0.7)), Vector3(39.0, 2.65, 35.0), root, _mats["wood_light"], "LookoutRail")
	_add_bench(Vector3(37.5, 0, 36.2), -0.6)
	_add_lantern_post(Vector3(37.0, 0, 32.0))
	_add_lantern_post(Vector3(42.5, 0, 36.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = 211
	for i in 6:
		var ang := i * TAU / 6.0
		_add_flowers(Vector3(40.0 + cos(ang) * 5.0, 0, 34.0 + sin(ang) * 5.0), rng)
	var sign := Node3D.new()
	sign.position = Vector3(36.5, 0, 34.0)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.8), Vector3(0, 0.9, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.6, 0.6, 0.1)), Vector3(0, 1.6, 0), sign, _mats["wood_light"], "Board")
	var sl := Label3D.new()
	sl.text = "Lookout Rock"
	sl.font_size = 40
	sl.position = Vector3(0, 2.3, 0)
	sl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.add_child(sl)
	var lbl := Label3D.new()
	lbl.text = "Lookout Rock"
	lbl.font_size = 52
	lbl.position = Vector3(40, 3.6, 34)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(lbl)

func get_minimap_markers() -> Dictionary:
	## Data for HUD minimap / compass
	var halls: Array = []
	for b in world_data.get("buildings", []):
		halls.append({"x": float(b["x"]), "z": float(b["z"]), "label": str(b.get("label", "")), "color": str(b.get("color", "#888"))})
	# Landmarks for wilds spurs
	halls.append({"x": 0.5, "z": -48.0, "label": "Glade", "color": "#4a90c8"})
	halls.append({"x": -24.0, "z": -54.0, "label": "Pine", "color": "#1f4d32"})
	halls.append({"x": 30.0, "z": 18.0, "label": "Garden", "color": "#c9b037"})
	halls.append({"x": 40.0, "z": 34.0, "label": "Lookout", "color": "#8a8a9a"})
	halls.append({"x": -36.0, "z": 30.0, "label": "Mill", "color": "#7a5a40"})
	halls.append({"x": 0.0, "z": 8.0, "label": "Fountain", "color": "#4a90c8"})
	var npcs: Array = []
	for n in get_tree().get_nodes_in_group("npcs"):
		# Hide indoor duplicates on minimap (keep outdoor mentors)
		if str(n.get("npc_id")).ends_with("-indoor"):
			continue
		npcs.append({"x": n.global_position.x, "z": n.global_position.z})
	var foes: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("is_alive") and e.is_alive() and e.visible:
			foes.append({"x": e.global_position.x, "z": e.global_position.z})
	var px := 0.0
	var pz := 0.0
	var yaw := 0.0
	if player:
		px = player.global_position.x
		pz = player.global_position.z
		yaw = float(player.get("cam_yaw"))
	return {
		"player": {"x": px, "z": pz, "yaw": yaw},
		"halls": halls,
		"npcs": npcs,
		"foes": foes,
		"inside": _inside_hall,
		"day": _day_phase,
		"weather": _weather_label_cache,
	}

func _build_mill_bridge() -> void:
	## Southwest landmark — soft travel (K). Wooden mill + creek bridge spur.
	var root := Node3D.new()
	root.name = "MillBridge"
	static_world.add_child(root)
	# Dirt spur southwest from plaza
	for i in 8:
		var t := float(i) / 7.0
		var x := -8.0 + t * (-28.0)
		var z := 14.0 + t * 16.0
		_mi(_box(Vector3(2.6, 0.04, 2.4)), Vector3(x, 0.025, z), root, _mats["dirt"], "MillPath")
	# Creek under the bridge
	_mi(_cyl(3.4, 3.4, 0.08), Vector3(-36.0, 0.015, 30.0), root, _mats["water"], "MillCreek")
	_mi(_cyl(1.5, 1.5, 0.05), Vector3(-39.0, 0.015, 32.5), root, _mats["water"], "MillCreekBend")
	# Bridge planks
	_mi(_box(Vector3(5.2, 0.12, 1.8)), Vector3(-36.0, 0.35, 30.0), root, _mats["wood"], "BridgeDeck")
	_mi(_box(Vector3(5.2, 0.35, 0.12)), Vector3(-36.0, 0.65, 29.0), root, _mats["wood_light"], "RailS")
	_mi(_box(Vector3(5.2, 0.35, 0.12)), Vector3(-36.0, 0.65, 31.0), root, _mats["wood_light"], "RailN")
	for i in 5:
		var px := -38.0 + float(i) * 1.0
		_mi(_cyl(0.08, 0.1, 0.7), Vector3(px, 0.2, 29.0), root, _mats["wood"], "PillarS")
		_mi(_cyl(0.08, 0.1, 0.7), Vector3(px, 0.2, 31.0), root, _mats["wood"], "PillarN")
	# Small mill house + water wheel
	_mi(_box(Vector3(3.2, 2.4, 2.8)), Vector3(-40.5, 1.2, 27.0), root, _mats["wood"], "MillHouse")
	_mi(_box(Vector3(3.6, 0.2, 3.2)), Vector3(-40.5, 2.5, 27.0), root, _mats["roof"], "MillRoof")
	_mi(_cyl(1.1, 1.1, 0.22), Vector3(-38.2, 1.3, 28.6), root, _mats["wood_light"], "Wheel")
	for i in 6:
		var ang := float(i) * TAU / 6.0
		var bx := -38.2 + cos(ang) * 1.05
		var by := 1.3 + sin(ang) * 1.05
		_mi(_box(Vector3(0.12, 0.7, 0.08)), Vector3(bx, by, 28.6), root, _mats["wood"], "Blade")
	_mi(_cyl(0.12, 0.14, 1.6), Vector3(-38.2, 1.3, 27.8), root, _mats["iron"], "Axle")
	_add_lantern_post(Vector3(-33.5, 0, 28.0))
	_add_lantern_post(Vector3(-33.5, 0, 32.0))
	_add_bench(Vector3(-34.0, 0, 33.5), 0.3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 307
	for i in 5:
		var ang := i * TAU / 5.0
		_add_flowers(Vector3(-36.0 + cos(ang) * 5.5, 0, 30.0 + sin(ang) * 5.5), rng)
	var sign := Node3D.new()
	sign.position = Vector3(-32.5, 0, 30.0)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.8), Vector3(0, 0.9, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.7, 0.6, 0.1)), Vector3(0, 1.6, 0), sign, _mats["wood_light"], "Board")
	var sl := Label3D.new()
	sl.text = "Mill Bridge"
	sl.font_size = 40
	sl.position = Vector3(0, 2.3, 0)
	sl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.add_child(sl)
	var lbl := Label3D.new()
	lbl.text = "Mill Bridge"
	lbl.font_size = 52
	lbl.position = Vector3(-36.0, 3.4, 30.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(lbl)

func _setup_outdoor_navigation() -> void:
	## Lightweight outdoor NavigationRegion3D bake (static colliders + ground).
	## Skips guild-hall interiors (x >= 90). Falls back gracefully if bake is empty.
	var region := NavigationRegion3D.new()
	region.name = "OutdoorNavRegion"
	add_child(region)
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.5
	nm.agent_height = 1.5
	nm.agent_max_climb = 0.5
	nm.agent_max_slope = 45.0
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.filter_baking_aabb = AABB(Vector3(-54, -1, -64), Vector3(108, 5, 118))
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, source, static_world)
	NavigationServer3D.bake_from_source_geometry_data(nm, source)
	region.navigation_mesh = nm
	if player and player.has_method("set_navigation_ready"):
		player.set_navigation_ready(true)

