extends Node3D
## Builds village + guild halls + NPCs + enemy spawns from world.json

const PlayerScene := preload("res://scenes/player/player.tscn")
const EnemyScene := preload("res://scenes/world/enemy.tscn")
const NpcScene := preload("res://scenes/world/npc.tscn")

@onready var entities: Node3D = $Entities
@onready var static_world: Node3D = $StaticWorld

var player: CharacterBody3D
var world_data: Dictionary = {}

signal npc_talk(npc: Node)

func _ready() -> void:
	var f: FileAccess = FileAccess.open("res://data/world.json", FileAccess.READ)
	if f:
		world_data = JSON.parse_string(f.get_as_text())
		f.close()
	_build_ground()
	_build_buildings()
	_build_trees()
	_build_fountain()
	_spawn_npcs()
	_spawn_enemies()
	_spawn_player()
	GameState.in_world = true

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(90, 90)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#3d6b3d")
	ground.material_override = mat
	ground.position.y = -0.01
	static_world.add_child(ground)
	# Path ring
	var path := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 14
	cyl.bottom_radius = 14
	cyl.height = 0.05
	path.mesh = cyl
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color("#8b7355")
	path.material_override = pmat
	path.position = Vector3(0, 0.02, 6)
	static_world.add_child(path)
	# Soft wild tint edges — darker grass patches via disks
	for i in 8:
		var patch := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 6
		pm.bottom_radius = 6
		pm.height = 0.02
		patch.mesh = pm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("#2a4a2a")
		patch.material_override = m
		var ang := i * TAU / 8.0
		patch.position = Vector3(cos(ang) * 34, 0.015, sin(ang) * 34)
		static_world.add_child(patch)

func _hex_color(h: String) -> Color:
	return Color(h)

func _build_buildings() -> void:
	for b in world_data.get("buildings", []):
		var body := StaticBody3D.new()
		body.position = Vector3(b["x"], 0, b["z"])
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(b["w"], b["h"], b["d"])
		mi.mesh = box
		mi.position.y = b["h"] / 2.0
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _hex_color(b["color"])
		mi.material_override = mat
		body.add_child(mi)
		# Roof
		var roof := MeshInstance3D.new()
		var rmesh := PrismMesh.new()
		rmesh.size = Vector3(b["w"] + 0.4, 1.5, b["d"] + 0.4)
		roof.mesh = rmesh
		roof.position.y = b["h"] + 0.6
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color("#4a3728")
		roof.material_override = rmat
		body.add_child(roof)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(b["w"], b["h"], b["d"])
		col.shape = shape
		col.position.y = b["h"] / 2.0
		body.add_child(col)
		var lbl := Label3D.new()
		lbl.text = b["label"]
		lbl.font_size = 64
		lbl.position = Vector3(0, b["h"] + 2.2, 0)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.outline_size = 6
		body.add_child(lbl)
		static_world.add_child(body)

func _build_trees() -> void:
	for t in world_data.get("trees", []):
		var body := StaticBody3D.new()
		body.position = Vector3(t[0], 0, t[1])
		var trunk := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.35
		cyl.height = 1.4
		trunk.mesh = cyl
		trunk.position.y = 0.7
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = Color("#5c4033")
		trunk.material_override = tmat
		body.add_child(trunk)
		var leaves := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.1
		sphere.height = 2.0
		leaves.mesh = sphere
		leaves.position.y = 2.0
		var lmat := StandardMaterial3D.new()
		lmat.albedo_color = Color("#2d6a4f")
		leaves.material_override = lmat
		body.add_child(leaves)
		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.6
		shape.height = 2.0
		col.shape = shape
		col.position.y = 1.0
		body.add_child(col)
		static_world.add_child(body)

func _build_fountain() -> void:
	var f: Dictionary = world_data.get("fountain", {"x":0,"z":8})
	var root := Node3D.new()
	root.position = Vector3(f["x"], 0, f["z"])
	var base := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.2
	cyl.bottom_radius = 2.4
	cyl.height = 0.4
	base.mesh = cyl
	base.position.y = 0.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#8a8a9a")
	base.material_override = mat
	root.add_child(base)
	var water := MeshInstance3D.new()
	var wc := CylinderMesh.new()
	wc.top_radius = 1.6
	wc.bottom_radius = 1.6
	wc.height = 0.15
	water.mesh = wc
	water.position.y = 0.35
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color("#4a90c8")
	wmat.roughness = 0.2
	water.material_override = wmat
	root.add_child(water)
	var pillar := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.25
	pc.bottom_radius = 0.35
	pc.height = 1.6
	pillar.mesh = pc
	pillar.position.y = 1.0
	pillar.material_override = mat
	root.add_child(pillar)
	var lbl := Label3D.new()
	lbl.text = "Fountain"
	lbl.font_size = 48
	lbl.position = Vector3(0, 2.4, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(lbl)
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
