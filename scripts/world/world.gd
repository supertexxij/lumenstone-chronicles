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

signal npc_talk(npc: Node)

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
	_setup_day_night()
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
	plane.size = Vector2(96, 96)
	ground.mesh = plane
	ground.material_override = _mats["grass"]
	ground.position.y = -0.01
	static_world.add_child(ground)
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
	for i in 18:
		var ang := rng.randf() * TAU
		var rad := rng.randf_range(30.0, 42.0)
		var p := Vector3(cos(ang) * rad, 0, sin(ang) * rad)
		match i % 4:
			0:
				_add_tree(p, 1 if i % 8 == 0 else 0)
			1:
				_add_rock_cluster(p, rng)
			2:
				_add_bush(p, rng)
			_:
				_add_bush(p + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5)), rng)

func _add_tree(pos: Vector3, style: int = 0) -> void:
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
	shape.radius = 0.55
	shape.height = 2.0
	col.shape = shape
	col.position.y = 1.0
	body.add_child(col)
	static_world.add_child(body)

func _add_rock_cluster(pos: Vector3, rng: RandomNumberGenerator) -> void:
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

func _add_lantern(parent: Node, pos: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)
	_mi(_box(Vector3(0.22, 0.28, 0.22)), Vector3(0, 0, 0), holder, _mats["iron"], "Cage")
	_mi(_sphere(0.1), Vector3(0, 0, 0), holder, _mats["lantern_glow"], "Glow")
	_mi(_cyl(0.04, 0.06, 0.12), Vector3(0, 0.2, 0), holder, _mats["lantern"], "Cap")

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
	_update_day_night(delta)

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
		_env.fog_density = lerpf(0.0022, 0.0012, dayness)

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
	_interior_root.add_child(room)
	var col := Color(b.get("color", "#888888"))
	var wall := _mat(col.lightened(0.15))
	var floor_m: Material = _mats["stone"]
	# Floor / walls / ceiling
	_mi(_box(Vector3(10, 0.2, 10)), Vector3(0, 0.1, 0), room, floor_m, "Floor")
	_mi(_box(Vector3(10, 3.5, 0.3)), Vector3(0, 1.8, -5), room, wall, "WallN")
	_mi(_box(Vector3(10, 3.5, 0.3)), Vector3(0, 1.8, 5), room, wall, "WallS")
	_mi(_box(Vector3(0.3, 3.5, 10)), Vector3(-5, 1.8, 0), room, wall, "WallW")
	_mi(_box(Vector3(0.3, 3.5, 10)), Vector3(5, 1.8, 0), room, wall, "WallE")
	_mi(_box(Vector3(10.2, 0.25, 10.2)), Vector3(0, 3.6, 0), room, _mats["roof"], "Ceiling")
	# Simple furniture
	_mi(_box(Vector3(2.2, 0.7, 1.0)), Vector3(0, 0.45, -2.5), room, _mats["wood"], "Table")
	_mi(_box(Vector3(1.4, 0.45, 0.45)), Vector3(-2.2, 0.55, 1.5), room, _mats["bench"], "Bench")
	_mi(_box(Vector3(1.4, 0.45, 0.45)), Vector3(2.2, 0.55, 1.5), room, _mats["bench"], "Bench2")
	_add_lantern(room, Vector3(-2.5, 2.4, -2.0))
	_add_lantern(room, Vector3(2.5, 2.4, -2.0))
	var banner := _mi(_box(Vector3(2.5, 1.0, 0.08)), Vector3(0, 2.4, -4.7), room, _mat(col.darkened(0.2)), "Banner")
	var lbl := Label3D.new()
	lbl.text = "%s Hall" % b.get("label", "Guild")
	lbl.font_size = 56
	lbl.position = Vector3(0, 3.0, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	room.add_child(lbl)
	# Exit volume near south wall
	var exit_area := Area3D.new()
	exit_area.name = "Exit"
	exit_area.monitoring = true
	exit_area.collision_layer = 0
	exit_area.collision_mask = 2
	exit_area.position = Vector3(0, 1.0, 4.2)
	var ecol := CollisionShape3D.new()
	var ebox := BoxShape3D.new()
	ebox.size = Vector3(2.0, 2.2, 1.2)
	ecol.shape = ebox
	exit_area.add_child(ecol)
	var emat := _mat(Color(0.6, 0.85, 0.95, 0.4), 0.5)
	emat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mi(_box(Vector3(1.4, 2.0, 0.12)), Vector3(0, 0.1, 0), exit_area, emat, "ExitGlow")
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

func _enter_hall(hall_id: String, label: String, body: Node) -> void:
	if _inside_hall != "":
		return
	_outdoor_return = body.global_position + Vector3(0, 0, 2.2)
	_inside_hall = hall_id
	# Find matching interior
	for room in _interior_root.get_children():
		if str(room.get_meta("hall_id", "")) == hall_id:
			body.global_position = room.global_position + Vector3(0, 0, 2.5)
			if body.has_method("_set_move_target"):
				body.has_click_target = false
			GameState.toast.emit("Entered %s Hall — walk the blue glow to leave." % label)
			GameState.position_xz = Vector2(body.global_position.x, body.global_position.z)
			return

func _exit_hall(body: Node) -> void:
	if _inside_hall == "":
		return
	_inside_hall = ""
	body.global_position = _outdoor_return
	if "has_click_target" in body:
		body.has_click_target = false
	GameState.toast.emit("Back on the village green.")
	GameState.position_xz = Vector2(body.global_position.x, body.global_position.z)

func get_minimap_markers() -> Dictionary:
	## Data for HUD minimap / compass
	var halls: Array = []
	for b in world_data.get("buildings", []):
		halls.append({"x": float(b["x"]), "z": float(b["z"]), "label": str(b.get("label", "")), "color": str(b.get("color", "#888"))})
	var npcs: Array = []
	for n in get_tree().get_nodes_in_group("npcs"):
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
	return {"player": {"x": px, "z": pz, "yaw": yaw}, "halls": halls, "npcs": npcs, "foes": foes, "inside": _inside_hall, "day": _day_phase}
