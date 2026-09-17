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
	HeadlessGuard.guard_mesh(n)
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
		"moss_badger":
			_build_badger(bob)
		"cedar_stag":
			_build_stag(bob)
		"pine_fox":
			_build_fox(bob)
		"oak_hare":
			_build_hare(bob)
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


static func _build_badger(bob: Node3D) -> void:
	## Chunky mossy badger — low body, stripe, soft snout (no tusks).
	var body := _mi(_capsule(0.32, 0.85), Vector3(0, 0.48, 0), bob, "Body")
	body.rotation_degrees = Vector3(0, 0, 90)
	_mi(_sphere(0.26), Vector3(0, 0.52, 0.48), bob, "Head")
	_mi(_sphere(0.1), Vector3(0, 0.48, 0.7), bob, "Snout")
	# Vertical face stripe (accent colorized), kept on the front of the snout.
	_mi(_box(Vector3(0.12, 0.32, 0.06)), Vector3(0, 0.62, 0.69), bob, "Stripe")
	# Short rounded ears
	_mi(_sphere(0.08), Vector3(-0.14, 0.72, 0.4), bob, "EarL")
	_mi(_sphere(0.08), Vector3(0.14, 0.72, 0.4), bob, "EarR")
	# Four sturdy legs
	for info in [
		["FL", Vector3(-0.2, 0.26, 0.26)],
		["FR", Vector3(0.2, 0.26, 0.26)],
		["BL", Vector3(-0.2, 0.26, -0.26)],
		["BR", Vector3(0.2, 0.26, -0.26)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.08, 0.28), Vector3(0, -0.04, 0), leg, "Thigh")
		_mi(_box(Vector3(0.13, 0.07, 0.16)), Vector3(0, -0.24, 0.02), leg, "Paw")
	# Moss tufts on back
	_mi(_sphere(0.12), Vector3(0.05, 0.72, -0.05), bob, "Moss1")
	_mi(_sphere(0.1), Vector3(-0.08, 0.7, -0.15), bob, "Moss2")


static func _build_stag(bob: Node3D) -> void:
	## Tall cedar-grove stag — long neck, branching antlers, four legs (wholesome).
	var body := _mi(_capsule(0.28, 1.05), Vector3(0, 0.78, 0), bob, "Body")
	body.rotation_degrees = Vector3(0, 0, 90)
	var neck := _mi(_cyl(0.10, 0.14, 0.55), Vector3(0, 1.05, 0.42), bob, "Neck")
	neck.rotation_degrees = Vector3(28, 0, 0)
	_mi(_sphere(0.20), Vector3(0, 1.28, 0.70), bob, "Head")
	_mi(_sphere(0.08), Vector3(0, 1.22, 0.88), bob, "Snout")
	_mi(_box(Vector3(0.08, 0.12, 0.22)), Vector3(0, 0.78, -0.55), bob, "Tail")
	# Branching antlers
	var ant_l := Node3D.new()
	ant_l.name = "AntlerL"
	ant_l.position = Vector3(-0.10, 1.46, 0.62)
	ant_l.rotation_degrees = Vector3(12, 0, -18)
	bob.add_child(ant_l)
	_mi(_cyl(0.025, 0.035, 0.42), Vector3(0, 0.18, 0), ant_l, "Beam")
	_mi(_cyl(0.02, 0.025, 0.22), Vector3(-0.08, 0.32, 0.04), ant_l, "TineA")
	_mi(_cyl(0.018, 0.022, 0.16), Vector3(0.06, 0.38, -0.02), ant_l, "TineB")
	var ant_r := Node3D.new()
	ant_r.name = "AntlerR"
	ant_r.position = Vector3(0.10, 1.46, 0.62)
	ant_r.rotation_degrees = Vector3(12, 0, 18)
	bob.add_child(ant_r)
	_mi(_cyl(0.025, 0.035, 0.42), Vector3(0, 0.18, 0), ant_r, "Beam")
	_mi(_cyl(0.02, 0.025, 0.22), Vector3(0.08, 0.32, 0.04), ant_r, "TineA")
	_mi(_cyl(0.018, 0.022, 0.16), Vector3(-0.06, 0.38, -0.02), ant_r, "TineB")
	# Ears
	_mi(_sphere(0.07, 0.12), Vector3(-0.12, 1.38, 0.58), bob, "EarL")
	_mi(_sphere(0.07, 0.12), Vector3(0.12, 1.38, 0.58), bob, "EarR")
	# Four long legs
	for info in [
		["FL", Vector3(-0.16, 0.48, 0.32)],
		["FR", Vector3(0.16, 0.48, 0.32)],
		["BL", Vector3(-0.16, 0.48, -0.32)],
		["BR", Vector3(0.16, 0.48, -0.32)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.06, 0.42), Vector3(0, -0.12, 0), leg, "Thigh")
		_mi(_box(Vector3(0.10, 0.06, 0.14)), Vector3(0, -0.36, 0.02), leg, "Hoof")

static func _build_fox(bob: Node3D) -> void:
	## Slender pine-wilds fox — pointed ears, bushy tail (distinct from badger/stag).
	var body := _mi(_capsule(0.22, 0.78), Vector3(0, 0.52, 0), bob, "Body")
	body.rotation_degrees = Vector3(0, 0, 90)
	_mi(_sphere(0.18), Vector3(0, 0.58, 0.42), bob, "Head")
	_mi(_sphere(0.07), Vector3(0, 0.52, 0.58), bob, "Snout")
	# Pointed ears
	var el := _mi(_cyl(0.01, 0.06, 0.18), Vector3(-0.08, 0.78, 0.38), bob, "EarL")
	el.rotation_degrees = Vector3(12, 0, -18)
	var er := _mi(_cyl(0.01, 0.06, 0.18), Vector3(0.08, 0.78, 0.38), bob, "EarR")
	er.rotation_degrees = Vector3(12, 0, 18)
	# Bushy tail (curled up)
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.58, -0.42)
	tail.rotation_degrees = Vector3(-35, 0, 0)
	bob.add_child(tail)
	_mi(_capsule(0.10, 0.55), Vector3(0, 0.12, -0.08), tail, "TailMain")
	_mi(_sphere(0.12), Vector3(0, 0.28, -0.28), tail, "TailTip")
	# Four light legs
	for info in [
		["FL", Vector3(-0.12, 0.30, 0.22)],
		["FR", Vector3(0.12, 0.30, 0.22)],
		["BL", Vector3(-0.12, 0.30, -0.22)],
		["BR", Vector3(0.12, 0.30, -0.22)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.05, 0.30), Vector3(0, -0.06, 0), leg, "Thigh")
		_mi(_box(Vector3(0.09, 0.05, 0.12)), Vector3(0, -0.26, 0.02), leg, "Paw")


static func _build_hare(bob: Node3D) -> void:
	## Soft oak-wilds hare — long ears, compact hop body (distinct from fox/badger/stag).
	var body := _mi(_capsule(0.20, 0.62), Vector3(0, 0.42, 0), bob, "Body")
	body.rotation_degrees = Vector3(0, 0, 90)
	_mi(_sphere(0.16), Vector3(0, 0.50, 0.34), bob, "Head")
	_mi(_sphere(0.06), Vector3(0, 0.46, 0.48), bob, "Snout")
	# Long upright ears
	var el := _mi(_cyl(0.015, 0.045, 0.32), Vector3(-0.06, 0.78, 0.30), bob, "EarL")
	el.rotation_degrees = Vector3(8, 0, -12)
	var er := _mi(_cyl(0.015, 0.045, 0.32), Vector3(0.06, 0.78, 0.30), bob, "EarR")
	er.rotation_degrees = Vector3(8, 0, 12)
	# Soft cotton-tail puff
	_mi(_sphere(0.10), Vector3(0, 0.44, -0.36), bob, "Tail")
	# Four light hop legs
	for info in [
		["FL", Vector3(-0.10, 0.24, 0.18)],
		["FR", Vector3(0.10, 0.24, 0.18)],
		["BL", Vector3(-0.10, 0.24, -0.18)],
		["BR", Vector3(0.10, 0.24, -0.18)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.045, 0.26), Vector3(0, -0.04, 0), leg, "Thigh")
		_mi(_box(Vector3(0.08, 0.05, 0.11)), Vector3(0, -0.22, 0.02), leg, "Paw")
