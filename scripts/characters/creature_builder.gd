class_name CreatureBuilder
extends RefCounted
## Limb-aware creature meshes for wild enemies (chunky stylized).

static func _clear(root: Node3D) -> void:
	for c in root.get_children():
		root.remove_child(c)
		c.free()


static func _mi(mesh: Mesh, pos: Vector3, parent: Node3D, name: String, scale := Vector3.ONE) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = name
	n.mesh = mesh
	n.position = pos
	n.scale = scale
	parent.add_child(n)
	return n


static func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func _sphere(r: float, h: float = -1.0) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h if h > 0.0 else r * 2.0
	return m


static func _cyl(top_r: float, bot_r: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bot_r
	m.height = h
	return m


static func _capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	return m


static func colorize(root: Node3D, primary: Color, accent: Color) -> void:
	var i := 0
	for c in root.get_children():
		if c is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = accent if (i % 3 == 1) else primary
			mat.roughness = 0.7
			(c as MeshInstance3D).material_override = mat
			i += 1
		elif c is Node3D:
			for gc in c.get_children():
				if gc is MeshInstance3D:
					var mat2 := StandardMaterial3D.new()
					mat2.albedo_color = accent if (i % 3 == 1) else primary
					mat2.roughness = 0.7
					(gc as MeshInstance3D).material_override = mat2
					i += 1


## Returns bob root Node3D for idle animation.
static func build(kind: String, root: Node3D) -> Node3D:
	_clear(root)
	var bob := Node3D.new()
	bob.name = "CreatureBob"
	root.add_child(bob)
	match kind:
		"briar_boar":
			_build_boar(bob)
		"shadow_moth":
			_build_moth(bob)
		"dust_golem":
			_build_golem(bob)
		_:
			_build_wisp(bob)
	return bob


static func _build_wisp(bob: Node3D) -> void:
	# Soft glowing orb — intentionally simple
	_mi(_sphere(0.45), Vector3(0, 0.7, 0), bob, "Core")
	_mi(_sphere(0.22), Vector3(0.15, 1.05, 0.1), bob, "Spark1")
	_mi(_sphere(0.16), Vector3(-0.2, 0.95, -0.1), bob, "Spark2")


static func _build_moth(bob: Node3D) -> void:
	_mi(_sphere(0.28, 0.55), Vector3(0, 0.85, 0), bob, "Body")
	_mi(_sphere(0.18), Vector3(0, 1.15, 0.12), bob, "Head")
	# Wings
	var lw := _mi(_box(Vector3(0.7, 0.05, 0.55)), Vector3(-0.45, 0.95, 0), bob, "LWing")
	lw.rotation_degrees = Vector3(10, 0, 25)
	var rw := _mi(_box(Vector3(0.7, 0.05, 0.55)), Vector3(0.45, 0.95, 0), bob, "RWing")
	rw.rotation_degrees = Vector3(10, 0, -25)
	# Thin legs
	for i in 3:
		var x := -0.12 + i * 0.12
		_mi(_cyl(0.03, 0.03, 0.35), Vector3(x, 0.45, 0.08), bob, "Leg%d" % i)


static func _build_boar(bob: Node3D) -> void:
	# Body elongated
	var body := _mi(_capsule(0.35, 0.9), Vector3(0, 0.55, 0), bob, "Body")
	body.rotation_degrees = Vector3(0, 0, 90)
	_mi(_sphere(0.28), Vector3(0, 0.55, 0.55), bob, "Head")
	_mi(_cyl(0.04, 0.06, 0.18), Vector3(-0.12, 0.6, 0.78), bob, "TuskL")
	_mi(_cyl(0.04, 0.06, 0.18), Vector3(0.12, 0.6, 0.78), bob, "TuskR")
	# Four chunky legs
	for info in [
		["FL", Vector3(-0.22, 0.28, 0.28)],
		["FR", Vector3(0.22, 0.28, 0.28)],
		["BL", Vector3(-0.22, 0.28, -0.28)],
		["BR", Vector3(0.22, 0.28, -0.28)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.09, 0.32), Vector3(0, -0.05, 0), leg, "Thigh")
		_mi(_box(Vector3(0.14, 0.08, 0.18)), Vector3(0, -0.28, 0.02), leg, "Hoof")
	# Briar tufts
	_mi(_sphere(0.14), Vector3(0, 0.85, -0.1), bob, "Briar")


static func _build_golem(bob: Node3D) -> void:
	# Blocky humanoid dust golem with clear arms/legs
	_mi(_box(Vector3(0.7, 0.75, 0.45)), Vector3(0, 1.05, 0), bob, "Torso")
	_mi(_box(Vector3(0.42, 0.38, 0.42)), Vector3(0, 1.65, 0), bob, "Head")
	_mi(_box(Vector3(0.55, 0.28, 0.4)), Vector3(0, 0.58, 0), bob, "Pelvis")
	# Arms
	var la := Node3D.new()
	la.name = "LArm"
	la.position = Vector3(-0.48, 1.25, 0)
	bob.add_child(la)
	_mi(_box(Vector3(0.22, 0.55, 0.22)), Vector3(0, -0.2, 0), la, "LUpper")
	_mi(_box(Vector3(0.24, 0.2, 0.24)), Vector3(0, -0.55, 0), la, "LFist")
	var ra := Node3D.new()
	ra.name = "RArm"
	ra.position = Vector3(0.48, 1.25, 0)
	bob.add_child(ra)
	_mi(_box(Vector3(0.22, 0.55, 0.22)), Vector3(0, -0.2, 0), ra, "RUpper")
	_mi(_box(Vector3(0.24, 0.2, 0.24)), Vector3(0, -0.55, 0), ra, "RFist")
	# Legs
	var ll := Node3D.new()
	ll.name = "LLeg"
	ll.position = Vector3(-0.2, 0.45, 0)
	bob.add_child(ll)
	_mi(_box(Vector3(0.24, 0.5, 0.24)), Vector3(0, -0.15, 0), ll, "LThigh")
	_mi(_box(Vector3(0.26, 0.12, 0.32)), Vector3(0, -0.45, 0.04), ll, "LFoot")
	var rl := Node3D.new()
	rl.name = "RLeg"
	rl.position = Vector3(0.2, 0.45, 0)
	bob.add_child(rl)
	_mi(_box(Vector3(0.24, 0.5, 0.24)), Vector3(0, -0.15, 0), rl, "RThigh")
	_mi(_box(Vector3(0.26, 0.12, 0.32)), Vector3(0, -0.45, 0.04), rl, "RFoot")
