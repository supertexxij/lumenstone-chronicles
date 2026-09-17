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
		"birch_squirrel":
			_build_squirrel(bob)
		"aspen_otter":
			_build_otter(bob)
		"elm_raccoon":
			_build_raccoon(bob)
		"hazel_hedgehog":
			_build_hedgehog(bob)
		"willow_wren":
			_build_wren(bob)
		"maple_mouse":
			_build_mouse(bob)
		"spruce_mole":
			_build_mole(bob)
		"beech_chipmunk":
			_build_chipmunk(bob)
		"alder_duck":
			_build_duck(bob)
		"fir_frog":
			_build_frog(bob)
		"cypress_turtle":
			_build_turtle(bob)
		"poplar_dove":
			_build_dove(bob)
		"rowan_robin":
			_build_robin(bob)
		"ash_sparrow":
			_build_sparrow(bob)
		"hickory_quail":
			_build_quail(bob)
		"juniper_jay":
			_build_jay(bob)
		"sycamore_skink":
			_build_skink(bob)
		"chestnut_toad":
			_build_toad(bob)
		"walnut_weasel":
			_build_weasel(bob)
		"pecan_possum":
			_build_possum(bob)
		"magnolia_beaver":
			_build_beaver(bob)
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


static func _build_squirrel(bob: Node3D) -> void:
	## Quick birch-wilds squirrel — tuft ears, bushy upright tail (distinct from hare/fox).
	var body := _mi(_capsule(0.16, 0.48), Vector3(0, 0.38, 0), bob, "Body")
	body.rotation_degrees = Vector3(0, 0, 90)
	_mi(_sphere(0.14), Vector3(0, 0.48, 0.28), bob, "Head")
	_mi(_sphere(0.05), Vector3(0, 0.44, 0.40), bob, "Snout")
	# Soft cheek puffs
	_mi(_sphere(0.06), Vector3(-0.10, 0.44, 0.30), bob, "CheekL")
	_mi(_sphere(0.06), Vector3(0.10, 0.44, 0.30), bob, "CheekR")
	# Small tufted ears
	var el := _mi(_cyl(0.01, 0.045, 0.14), Vector3(-0.07, 0.66, 0.24), bob, "EarL")
	el.rotation_degrees = Vector3(10, 0, -16)
	var er := _mi(_cyl(0.01, 0.045, 0.14), Vector3(0.07, 0.66, 0.24), bob, "EarR")
	er.rotation_degrees = Vector3(10, 0, 16)
	# Bushy upright curl tail
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.42, -0.28)
	tail.rotation_degrees = Vector3(-55, 0, 0)
	bob.add_child(tail)
	_mi(_capsule(0.09, 0.48), Vector3(0, 0.18, -0.06), tail, "TailMain")
	_mi(_sphere(0.11), Vector3(0, 0.38, -0.18), tail, "TailTip")
	# Four light legs
	for info in [
		["FL", Vector3(-0.09, 0.22, 0.14)],
		["FR", Vector3(0.09, 0.22, 0.14)],
		["BL", Vector3(-0.09, 0.22, -0.14)],
		["BR", Vector3(0.09, 0.22, -0.14)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.04, 0.22), Vector3(0, -0.04, 0), leg, "Thigh")
		_mi(_box(Vector3(0.07, 0.04, 0.09)), Vector3(0, -0.18, 0.02), leg, "Paw")

static func _build_otter(bob: Node3D) -> void:
	## Sleek aspen-wilds otter — long body, flat paddle tail (distinct from squirrel/hare/fox).
	var body := _mi(_capsule(0.17, 0.72), Vector3(0, 0.36, 0), bob, "Body")
	body.rotation_degrees = Vector3(0, 0, 90)
	_mi(_sphere(0.15), Vector3(0, 0.42, 0.40), bob, "Head")
	_mi(_sphere(0.07), Vector3(0, 0.38, 0.54), bob, "Snout")
	# Soft cheek whisker pads
	_mi(_sphere(0.05), Vector3(-0.10, 0.40, 0.44), bob, "CheekL")
	_mi(_sphere(0.05), Vector3(0.10, 0.40, 0.44), bob, "CheekR")
	# Small rounded ears
	var el := _mi(_sphere(0.05), Vector3(-0.09, 0.54, 0.34), bob, "EarL")
	var er := _mi(_sphere(0.05), Vector3(0.09, 0.54, 0.34), bob, "EarR")
	# Flat paddle tail
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.34, -0.40)
	tail.rotation_degrees = Vector3(-18, 0, 0)
	bob.add_child(tail)
	_mi(_box(Vector3(0.18, 0.05, 0.42)), Vector3(0, 0.02, -0.16), tail, "TailMain")
	_mi(_box(Vector3(0.22, 0.04, 0.16)), Vector3(0, 0.0, -0.38), tail, "TailTip")
	# Four short legs
	for info in [
		["FL", Vector3(-0.11, 0.20, 0.20)],
		["FR", Vector3(0.11, 0.20, 0.20)],
		["BL", Vector3(-0.11, 0.20, -0.18)],
		["BR", Vector3(0.11, 0.20, -0.18)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.045, 0.20), Vector3(0, -0.03, 0), leg, "Thigh")
		_mi(_box(Vector3(0.08, 0.04, 0.12)), Vector3(0, -0.16, 0.02), leg, "Paw")

static func _build_raccoon(bob: Node3D) -> void:
	## Masked elm-wilds raccoon — face stripe mask, ringed bushy tail (distinct from otter/squirrel/fox).
	var body := _mi(_capsule(0.18, 0.62), Vector3(0, 0.40, 0), bob, "Body")
	body.rotation_degrees = Vector3(0, 0, 90)
	_mi(_sphere(0.16), Vector3(0, 0.46, 0.36), bob, "Head")
	_mi(_sphere(0.07), Vector3(0, 0.42, 0.50), bob, "Snout")
	# Soft cheek pads
	_mi(_sphere(0.055), Vector3(-0.10, 0.44, 0.38), bob, "CheekL")
	_mi(_sphere(0.055), Vector3(0.10, 0.44, 0.38), bob, "CheekR")
	# Dark face mask band (accent-colored)
	_mi(_box(Vector3(0.28, 0.10, 0.06)), Vector3(0, 0.50, 0.48), bob, "Mask")
	# Rounded ears
	_mi(_sphere(0.06), Vector3(-0.10, 0.60, 0.30), bob, "EarL")
	_mi(_sphere(0.06), Vector3(0.10, 0.60, 0.30), bob, "EarR")
	# Ringed bushy tail
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.42, -0.34)
	tail.rotation_degrees = Vector3(-28, 0, 0)
	bob.add_child(tail)
	_mi(_capsule(0.09, 0.42), Vector3(0, 0.10, -0.10), tail, "TailMain")
	_mi(_sphere(0.10), Vector3(0, 0.18, -0.30), tail, "Ring1")
	_mi(_sphere(0.085), Vector3(0, 0.14, -0.42), tail, "Ring2")
	_mi(_sphere(0.07), Vector3(0, 0.10, -0.52), tail, "TailTip")
	# Four short legs
	for info in [
		["FL", Vector3(-0.11, 0.22, 0.18)],
		["FR", Vector3(0.11, 0.22, 0.18)],
		["BL", Vector3(-0.11, 0.22, -0.16)],
		["BR", Vector3(0.11, 0.22, -0.16)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.045, 0.22), Vector3(0, -0.04, 0), leg, "Thigh")
		_mi(_box(Vector3(0.08, 0.04, 0.11)), Vector3(0, -0.18, 0.02), leg, "Paw")

static func _build_hedgehog(bob: Node3D) -> void:
	## Prickly hazel-wilds hedgehog — round body, soft snout, spine tufts (distinct from raccoon/otter/squirrel).
	_mi(_sphere(0.28, 0.42), Vector3(0, 0.38, 0), bob, "Body")
	_mi(_sphere(0.16), Vector3(0, 0.42, 0.28), bob, "Head")
	_mi(_sphere(0.07), Vector3(0, 0.38, 0.40), bob, "Snout")
	# Soft rounded ears
	_mi(_sphere(0.05), Vector3(-0.10, 0.52, 0.22), bob, "EarL")
	_mi(_sphere(0.05), Vector3(0.10, 0.52, 0.22), bob, "EarR")
	# Soft face tip (accent)
	_mi(_sphere(0.04), Vector3(0, 0.40, 0.46), bob, "Nose")
	# Spine tufts on back (chunky wholesome prickles)
	for i in 7:
		var ang := float(i) / 7.0 * TAU
		var r := 0.16
		var sx := cos(ang) * r
		var sz := sin(ang) * r * 0.7 - 0.04
		var sp := _mi(_cyl(0.01, 0.035, 0.22), Vector3(sx, 0.58, sz), bob, "Spine%d" % i)
		sp.rotation_degrees = Vector3(-18 + (i % 3) * 6, float(i) * 40.0, (i % 2) * 10 - 5)
	_mi(_cyl(0.012, 0.04, 0.26), Vector3(0, 0.66, -0.02), bob, "SpineTop")
	# Four stubby legs
	for info in [
		["FL", Vector3(-0.12, 0.18, 0.14)],
		["FR", Vector3(0.12, 0.18, 0.14)],
		["BL", Vector3(-0.12, 0.18, -0.12)],
		["BR", Vector3(0.12, 0.18, -0.12)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.04, 0.16), Vector3(0, -0.02, 0), leg, "Thigh")
		_mi(_box(Vector3(0.07, 0.035, 0.09)), Vector3(0, -0.14, 0.02), leg, "Paw")

static func _build_wren(bob: Node3D) -> void:
	## Soft willow-wilds wren — tiny round body, quick wings, stubby tail (distinct from moth + all mammal foes).
	_mi(_sphere(0.14, 0.22), Vector3(0, 0.72, 0), bob, "Body")
	_mi(_sphere(0.10), Vector3(0, 0.82, 0.14), bob, "Head")
	_mi(_sphere(0.035), Vector3(0, 0.80, 0.22), bob, "Beak")
	# Soft cheek fluff
	_mi(_sphere(0.04), Vector3(-0.06, 0.80, 0.12), bob, "CheekL")
	_mi(_sphere(0.04), Vector3(0.06, 0.80, 0.12), bob, "CheekR")
	# Wings (flapped in idle)
	var lw := _mi(_box(Vector3(0.32, 0.03, 0.22)), Vector3(-0.20, 0.74, 0), bob, "LWing")
	lw.rotation_degrees = Vector3(8, 0, 28)
	var rw := _mi(_box(Vector3(0.32, 0.03, 0.22)), Vector3(0.20, 0.74, 0), bob, "RWing")
	rw.rotation_degrees = Vector3(8, 0, -28)
	# Soft upright stubby tail
	var tail := _mi(_box(Vector3(0.08, 0.04, 0.18)), Vector3(0, 0.70, -0.16), bob, "Tail")
	tail.rotation_degrees = Vector3(-25, 0, 0)
	# Tiny stick legs
	_mi(_cyl(0.015, 0.015, 0.18), Vector3(-0.04, 0.55, 0.02), bob, "LegL")
	_mi(_cyl(0.015, 0.015, 0.18), Vector3(0.04, 0.55, 0.02), bob, "LegR")

static func _build_mouse(bob: Node3D) -> void:
	## Soft maple-wilds mouse — round body, big round ears, long thin tail (distinct from hare/squirrel/wren).
	_mi(_sphere(0.16, 0.22), Vector3(0, 0.38, 0), bob, "Body")
	_mi(_sphere(0.12), Vector3(0, 0.48, 0.18), bob, "Head")
	_mi(_sphere(0.045), Vector3(0, 0.44, 0.28), bob, "Snout")
	# Big round ears (accent-friendly)
	_mi(_sphere(0.07), Vector3(-0.10, 0.60, 0.14), bob, "EarL")
	_mi(_sphere(0.07), Vector3(0.10, 0.60, 0.14), bob, "EarR")
	_mi(_sphere(0.035), Vector3(-0.10, 0.60, 0.14), bob, "EarInnerL")
	_mi(_sphere(0.035), Vector3(0.10, 0.60, 0.14), bob, "EarInnerR")
	# Soft whisker dots
	_mi(_sphere(0.02), Vector3(-0.06, 0.44, 0.30), bob, "WhiskerL")
	_mi(_sphere(0.02), Vector3(0.06, 0.44, 0.30), bob, "WhiskerR")
	# Long thin curling tail
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.36, -0.18)
	tail.rotation_degrees = Vector3(-20, 0, 0)
	bob.add_child(tail)
	_mi(_cyl(0.018, 0.012, 0.42), Vector3(0, 0.02, -0.18), tail, "TailMain")
	_mi(_sphere(0.03), Vector3(0, 0.04, -0.40), tail, "TailTip")
	# Four tiny paws
	for info in [
		["FL", Vector3(-0.08, 0.16, 0.10)],
		["FR", Vector3(0.08, 0.16, 0.10)],
		["BL", Vector3(-0.08, 0.16, -0.10)],
		["BR", Vector3(0.08, 0.16, -0.10)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.03, 0.12), Vector3(0, -0.02, 0), leg, "Thigh")
		_mi(_box(Vector3(0.055, 0.03, 0.07)), Vector3(0, -0.10, 0.02), leg, "Paw")

static func _build_mole(bob: Node3D) -> void:
	## Soft spruce-wilds mole — low round body, pointed snout, tiny eyes, stubby paws (distinct from mouse/hare/hedgehog).
	_mi(_sphere(0.18, 0.26), Vector3(0, 0.28, 0), bob, "Body")
	_mi(_sphere(0.12, 0.16), Vector3(0, 0.30, 0.22), bob, "Head")
	# Pointed digging snout (longer than mouse)
	var snout := _mi(_cyl(0.04, 0.02, 0.16), Vector3(0, 0.28, 0.36), bob, "Snout")
	snout.rotation_degrees = Vector3(90, 0, 0)
	_mi(_sphere(0.035), Vector3(0, 0.28, 0.44), bob, "Nose")
	# Tiny near-hidden eyes
	_mi(_sphere(0.02), Vector3(-0.05, 0.34, 0.28), bob, "EyeL")
	_mi(_sphere(0.02), Vector3(0.05, 0.34, 0.28), bob, "EyeR")
	# Soft digging-paw frills (accent-friendly)
	_mi(_box(Vector3(0.14, 0.03, 0.08)), Vector3(-0.16, 0.18, 0.16), bob, "PawFrillL")
	_mi(_box(Vector3(0.14, 0.03, 0.08)), Vector3(0.16, 0.18, 0.16), bob, "PawFrillR")
	# Short stubby tail nub (not a long mouse tail)
	_mi(_sphere(0.05), Vector3(0, 0.26, -0.18), bob, "TailNub")
	# Four stubby burrow paws
	for info in [
		["FL", Vector3(-0.10, 0.12, 0.12)],
		["FR", Vector3(0.10, 0.12, 0.12)],
		["BL", Vector3(-0.10, 0.12, -0.10)],
		["BR", Vector3(0.10, 0.12, -0.10)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.035, 0.10), Vector3(0, -0.01, 0), leg, "Thigh")
		_mi(_box(Vector3(0.07, 0.025, 0.09)), Vector3(0, -0.08, 0.02), leg, "Paw")

static func _build_chipmunk(bob: Node3D) -> void:
	## Soft beech-wilds chipmunk — round body, cheek pouches, stripe line, short bushy tail (distinct from squirrel/mouse/mole).
	_mi(_sphere(0.17, 0.24), Vector3(0, 0.40, 0), bob, "Body")
	_mi(_sphere(0.13), Vector3(0, 0.50, 0.20), bob, "Head")
	# Soft cheek pouches (signature vs squirrel)
	_mi(_sphere(0.07), Vector3(-0.10, 0.46, 0.22), bob, "CheekL")
	_mi(_sphere(0.07), Vector3(0.10, 0.46, 0.22), bob, "CheekR")
	_mi(_sphere(0.04), Vector3(0, 0.46, 0.30), bob, "Snout")
	# Small upright ears
	_mi(_sphere(0.045), Vector3(-0.07, 0.62, 0.16), bob, "EarL")
	_mi(_sphere(0.045), Vector3(0.07, 0.62, 0.16), bob, "EarR")
	# Back stripe (accent-friendly dark line)
	_mi(_box(Vector3(0.04, 0.02, 0.28)), Vector3(0, 0.52, -0.02), bob, "Stripe")
	_mi(_box(Vector3(0.025, 0.015, 0.22)), Vector3(-0.06, 0.50, -0.02), bob, "StripeL")
	_mi(_box(Vector3(0.025, 0.015, 0.22)), Vector3(0.06, 0.50, -0.02), bob, "StripeR")
	# Short bushy upright tail (not squirrel-tall)
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.42, -0.18)
	tail.rotation_degrees = Vector3(-35, 0, 0)
	bob.add_child(tail)
	_mi(_sphere(0.09, 0.14), Vector3(0, 0.08, -0.06), tail, "TailBush")
	_mi(_sphere(0.05), Vector3(0, 0.16, -0.10), tail, "TailTip")
	# Four small paws
	for info in [
		["FL", Vector3(-0.08, 0.16, 0.10)],
		["FR", Vector3(0.08, 0.16, 0.10)],
		["BL", Vector3(-0.08, 0.16, -0.10)],
		["BR", Vector3(0.08, 0.16, -0.10)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.03, 0.11), Vector3(0, -0.02, 0), leg, "Thigh")
		_mi(_box(Vector3(0.055, 0.03, 0.07)), Vector3(0, -0.09, 0.02), leg, "Paw")


static func _build_duck(bob: Node3D) -> void:
	## Soft alder-wilds duck — plump body, flat bill, short wings, stubby paddle feet (distinct from wren/otter/chipmunk).
	_mi(_sphere(0.22, 0.28), Vector3(0, 0.38, 0), bob, "Body")
	_mi(_sphere(0.12), Vector3(0, 0.52, 0.22), bob, "Head")
	# Flat bill (signature)
	var bill := _mi(_box(Vector3(0.08, 0.035, 0.16)), Vector3(0, 0.48, 0.36), bob, "Bill")
	bill.rotation_degrees = Vector3(8, 0, 0)
	# Soft cheek
	_mi(_sphere(0.05), Vector3(-0.08, 0.50, 0.22), bob, "CheekL")
	_mi(_sphere(0.05), Vector3(0.08, 0.50, 0.22), bob, "CheekR")
	# Compact folded wings
	var lw := _mi(_box(Vector3(0.06, 0.04, 0.18)), Vector3(-0.18, 0.40, -0.02), bob, "LWing")
	lw.rotation_degrees = Vector3(0, 0, 18)
	var rw := _mi(_box(Vector3(0.06, 0.04, 0.18)), Vector3(0.18, 0.40, -0.02), bob, "RWing")
	rw.rotation_degrees = Vector3(0, 0, -18)
	# Short stubby tail feathers
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.40, -0.22)
	tail.rotation_degrees = Vector3(-25, 0, 0)
	bob.add_child(tail)
	_mi(_box(Vector3(0.12, 0.03, 0.1)), Vector3(0, 0.02, -0.04), tail, "TailFan")
	# Two stubby paddle feet
	for info in [
		["L", Vector3(-0.08, 0.14, 0.06)],
		["R", Vector3(0.08, 0.14, 0.06)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.025, 0.03, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.08, 0.025, 0.1)), Vector3(0, -0.09, 0.03), leg, "Paddle")

static func _build_frog(bob: Node3D) -> void:
	## Soft fir-wilds frog — plump body, bulging eyes, short hop legs, tiny toe pads (distinct from duck/mole/chipmunk).
	_mi(_sphere(0.22, 0.26), Vector3(0, 0.36, 0), bob, "Body")
	_mi(_sphere(0.14), Vector3(0, 0.48, 0.16), bob, "Head")
	# Bulging eyes (signature)
	_mi(_sphere(0.055), Vector3(-0.08, 0.58, 0.18), bob, "EyeL")
	_mi(_sphere(0.055), Vector3(0.08, 0.58, 0.18), bob, "EyeR")
	_mi(_sphere(0.025), Vector3(-0.08, 0.60, 0.22), bob, "PupilL")
	_mi(_sphere(0.025), Vector3(0.08, 0.60, 0.22), bob, "PupilR")
	# Soft cream throat pouch
	_mi(_sphere(0.08, 0.1), Vector3(0, 0.40, 0.24), bob, "Throat")
	# Tiny smile ridge
	_mi(_box(Vector3(0.1, 0.02, 0.03)), Vector3(0, 0.44, 0.30), bob, "Smile")
	# Folded hop legs (hind) + short front toes
	for info in [
		["FL", Vector3(-0.10, 0.16, 0.10)],
		["FR", Vector3(0.10, 0.16, 0.10)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.03, 0.10), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.07, 0.025, 0.08)), Vector3(0, -0.08, 0.02), leg, "Toe")
	for info in [
		["BL", Vector3(-0.12, 0.18, -0.08)],
		["BR", Vector3(0.12, 0.18, -0.08)],
	]:
		var leg2 := Node3D.new()
		leg2.name = "Leg" + str(info[0])
		leg2.position = info[1]
		bob.add_child(leg2)
		_mi(_capsule(0.045, 0.14), Vector3(0, -0.02, 0), leg2, "Thigh")
		_mi(_box(Vector3(0.1, 0.03, 0.12)), Vector3(0, -0.12, 0.04), leg2, "Pad")
	# Soft stubby tail nub
	_mi(_sphere(0.05), Vector3(0, 0.34, -0.20), bob, "Nub")

static func _build_turtle(bob: Node3D) -> void:
	## Soft cypress-wilds turtle — dome shell, gentle head, stubby legs, short tail (distinct from frog/duck/mole).
	# Domed shell (signature)
	_mi(_sphere(0.32, 0.22), Vector3(0, 0.42, 0), bob, "Shell")
	_mi(_box(Vector3(0.42, 0.06, 0.36)), Vector3(0, 0.30, 0), bob, "Plastron")
	# Soft shell scute ridges
	_mi(_box(Vector3(0.18, 0.04, 0.22)), Vector3(0, 0.52, 0.02), bob, "Scute")
	# Gentle head peeking out
	_mi(_sphere(0.11), Vector3(0, 0.38, 0.28), bob, "Head")
	_mi(_sphere(0.03), Vector3(-0.04, 0.42, 0.36), bob, "EyeL")
	_mi(_sphere(0.03), Vector3(0.04, 0.42, 0.36), bob, "EyeR")
	# Beak nub
	_mi(_box(Vector3(0.06, 0.03, 0.05)), Vector3(0, 0.36, 0.38), bob, "Beak")
	# Four stubby legs
	for info in [
		["FL", Vector3(-0.16, 0.18, 0.14)],
		["FR", Vector3(0.16, 0.18, 0.14)],
		["BL", Vector3(-0.16, 0.18, -0.14)],
		["BR", Vector3(0.16, 0.18, -0.14)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.045, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.09, 0.03, 0.1)), Vector3(0, -0.10, 0.02), leg, "Foot")
	# Short stubby tail
	_mi(_sphere(0.06, 0.08), Vector3(0, 0.28, -0.28), bob, "Tail")

static func _build_dove(bob: Node3D) -> void:
	## Soft poplar-wilds dove — plump body, soft wings, round head, short beak, fan tail (distinct from wren/duck/turtle).
	_mi(_sphere(0.18, 0.22), Vector3(0, 0.48, 0), bob, "Body")
	_mi(_sphere(0.12), Vector3(0, 0.62, 0.14), bob, "Head")
	# Soft cream eye rings
	_mi(_sphere(0.025), Vector3(-0.05, 0.66, 0.22), bob, "EyeL")
	_mi(_sphere(0.025), Vector3(0.05, 0.66, 0.22), bob, "EyeR")
	# Short gentle beak
	_mi(_box(Vector3(0.04, 0.025, 0.07)), Vector3(0, 0.60, 0.26), bob, "Beak")
	# Soft folded wings (signature — will flutter gently)
	var lw := _mi(_box(Vector3(0.28, 0.04, 0.22)), Vector3(-0.18, 0.50, -0.02), bob, "LWing")
	lw.rotation_degrees = Vector3(8, 0, 22)
	var rw := _mi(_box(Vector3(0.28, 0.04, 0.22)), Vector3(0.18, 0.50, -0.02), bob, "RWing")
	rw.rotation_degrees = Vector3(8, 0, -22)
	# Fan tail
	var tail := _mi(_box(Vector3(0.16, 0.03, 0.18)), Vector3(0, 0.46, -0.22), bob, "Tail")
	tail.rotation_degrees = Vector3(-28, 0, 0)
	# Tiny perch feet
	for info in [
		["FL", Vector3(-0.06, 0.22, 0.04)],
		["FR", Vector3(0.06, 0.22, 0.04)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.015, 0.02, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.05, 0.015, 0.06)), Vector3(0, -0.09, 0.01), leg, "Foot")
	# Soft chest fluff
	_mi(_sphere(0.1, 0.12), Vector3(0, 0.44, 0.10), bob, "Fluff")

static func _build_robin(bob: Node3D) -> void:
	## Soft rowan-wilds robin — plump body, red breast, short beak, perky tail (distinct from dove/wren/duck).
	_mi(_sphere(0.16, 0.20), Vector3(0, 0.46, 0), bob, "Body")
	# Signature warm red breast (accent-tinted via colorize)
	_mi(_sphere(0.11, 0.13), Vector3(0, 0.42, 0.10), bob, "Breast")
	_mi(_sphere(0.11), Vector3(0, 0.60, 0.12), bob, "Head")
	# Bright eye beads
	_mi(_sphere(0.022), Vector3(-0.045, 0.64, 0.20), bob, "EyeL")
	_mi(_sphere(0.022), Vector3(0.045, 0.64, 0.20), bob, "EyeR")
	# Short pointed beak
	_mi(_box(Vector3(0.035, 0.022, 0.06)), Vector3(0, 0.58, 0.23), bob, "Beak")
	# Compact wings (less fan than dove)
	var lw := _mi(_box(Vector3(0.22, 0.035, 0.16)), Vector3(-0.14, 0.48, -0.02), bob, "LWing")
	lw.rotation_degrees = Vector3(6, 0, 18)
	var rw := _mi(_box(Vector3(0.22, 0.035, 0.16)), Vector3(0.14, 0.48, -0.02), bob, "RWing")
	rw.rotation_degrees = Vector3(6, 0, -18)
	# Perky upright tail (signature vs dove fan)
	var tail := _mi(_box(Vector3(0.08, 0.03, 0.14)), Vector3(0, 0.50, -0.18), bob, "Tail")
	tail.rotation_degrees = Vector3(-42, 0, 0)
	# Tiny hop feet
	for info in [
		["FL", Vector3(-0.05, 0.20, 0.03)],
		["FR", Vector3(0.05, 0.20, 0.03)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.012, 0.015, 0.10), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.04, 0.012, 0.05)), Vector3(0, -0.08, 0.01), leg, "Foot")

static func _build_sparrow(bob: Node3D) -> void:
	## Soft ash-wilds sparrow — round body, cream bib, stubby beak, short barred tail (distinct from robin/dove/wren).
	_mi(_sphere(0.15, 0.18), Vector3(0, 0.44, 0), bob, "Body")
	# Soft cream bib (signature vs robin red breast)
	_mi(_sphere(0.09, 0.11), Vector3(0, 0.40, 0.09), bob, "Bib")
	_mi(_sphere(0.10), Vector3(0, 0.58, 0.10), bob, "Head")
	# Tiny eye beads
	_mi(_sphere(0.02), Vector3(-0.04, 0.61, 0.18), bob, "EyeL")
	_mi(_sphere(0.02), Vector3(0.04, 0.61, 0.18), bob, "EyeR")
	# Stubby cone beak (shorter than robin)
	_mi(_box(Vector3(0.03, 0.02, 0.045)), Vector3(0, 0.56, 0.20), bob, "Beak")
	# Compact wings folded close
	var lw := _mi(_box(Vector3(0.18, 0.03, 0.14)), Vector3(-0.12, 0.46, -0.02), bob, "LWing")
	lw.rotation_degrees = Vector3(5, 0, 14)
	var rw := _mi(_box(Vector3(0.18, 0.03, 0.14)), Vector3(0.12, 0.46, -0.02), bob, "RWing")
	rw.rotation_degrees = Vector3(5, 0, -14)
	# Short barred tail (lower angle than robin perky tail)
	var tail := _mi(_box(Vector3(0.07, 0.025, 0.11)), Vector3(0, 0.44, -0.16), bob, "Tail")
	tail.rotation_degrees = Vector3(-22, 0, 0)
	# Tiny hop feet
	for info in [
		["FL", Vector3(-0.045, 0.18, 0.03)],
		["FR", Vector3(0.045, 0.18, 0.03)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.01, 0.012, 0.09), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.035, 0.01, 0.045)), Vector3(0, -0.07, 0.01), leg, "Foot")

static func _build_quail(bob: Node3D) -> void:
	## Soft hickory-wilds quail — plump round body, short crest, warm flank patch (distinct from sparrow/robin/dove/wren).
	_mi(_sphere(0.20, 0.22), Vector3(0, 0.42, 0), bob, "Body")
	# Warm flank patch (accent-friendly signature)
	_mi(_sphere(0.11, 0.13), Vector3(0.08, 0.40, 0.06), bob, "Flank")
	_mi(_sphere(0.12), Vector3(0, 0.58, 0.08), bob, "Head")
	# Soft short crest (signature vs sparrow)
	var crest := _mi(_box(Vector3(0.04, 0.08, 0.06)), Vector3(0, 0.68, 0.02), bob, "Crest")
	crest.rotation_degrees = Vector3(-18, 0, 0)
	# Tiny eye beads
	_mi(_sphere(0.022), Vector3(-0.045, 0.61, 0.17), bob, "EyeL")
	_mi(_sphere(0.022), Vector3(0.045, 0.61, 0.17), bob, "EyeR")
	# Short stout beak
	_mi(_box(Vector3(0.035, 0.025, 0.05)), Vector3(0, 0.56, 0.19), bob, "Beak")
	# Compact wings folded close (plumper than sparrow)
	var lw := _mi(_box(Vector3(0.20, 0.035, 0.16)), Vector3(-0.14, 0.44, -0.02), bob, "LWing")
	lw.rotation_degrees = Vector3(6, 0, 12)
	var rw := _mi(_box(Vector3(0.20, 0.035, 0.16)), Vector3(0.14, 0.44, -0.02), bob, "RWing")
	rw.rotation_degrees = Vector3(6, 0, -12)
	# Short rounded tail
	var tail := _mi(_box(Vector3(0.09, 0.03, 0.10)), Vector3(0, 0.42, -0.18), bob, "Tail")
	tail.rotation_degrees = Vector3(-18, 0, 0)
	# Tiny ground-scurry feet
	for info in [
		["FL", Vector3(-0.05, 0.16, 0.04)],
		["FR", Vector3(0.05, 0.16, 0.04)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.012, 0.014, 0.08), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.04, 0.012, 0.05)), Vector3(0, -0.06, 0.012), leg, "Foot")

static func _build_jay(bob: Node3D) -> void:
	## Soft juniper-wilds jay — sleek body, tall crest, pale throat bib, longer tail (distinct from quail/sparrow/robin/dove/wren).
	_mi(_sphere(0.16, 0.20), Vector3(0, 0.48, 0), bob, "Body")
	# Pale throat bib (accent-friendly signature)
	_mi(_sphere(0.08, 0.09), Vector3(0, 0.46, 0.10), bob, "Bib")
	_mi(_sphere(0.11), Vector3(0, 0.66, 0.06), bob, "Head")
	# Tall jaunty crest (signature vs quail short crest)
	var crest := _mi(_box(Vector3(0.035, 0.12, 0.07)), Vector3(0, 0.78, -0.01), bob, "Crest")
	crest.rotation_degrees = Vector3(-28, 0, 0)
	# Tiny eye beads
	_mi(_sphere(0.02), Vector3(-0.04, 0.68, 0.14), bob, "EyeL")
	_mi(_sphere(0.02), Vector3(0.04, 0.68, 0.14), bob, "EyeR")
	# Pointed beak (longer than sparrow)
	_mi(_box(Vector3(0.03, 0.022, 0.06)), Vector3(0, 0.64, 0.18), bob, "Beak")
	# Folded wings with a hint of blue flare
	var lw := _mi(_box(Vector3(0.22, 0.03, 0.14)), Vector3(-0.13, 0.50, -0.02), bob, "LWing")
	lw.rotation_degrees = Vector3(8, 0, 16)
	var rw := _mi(_box(Vector3(0.22, 0.03, 0.14)), Vector3(0.13, 0.50, -0.02), bob, "RWing")
	rw.rotation_degrees = Vector3(8, 0, -16)
	# Longer fan tail
	var tail := _mi(_box(Vector3(0.10, 0.025, 0.16)), Vector3(0, 0.46, -0.20), bob, "Tail")
	tail.rotation_degrees = Vector3(-12, 0, 0)
	# Perchy feet
	for info in [
		["FL", Vector3(-0.045, 0.20, 0.03)],
		["FR", Vector3(0.045, 0.20, 0.03)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.01, 0.012, 0.10), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.035, 0.01, 0.045)), Vector3(0, -0.07, 0.01), leg, "Foot")

static func _build_skink(bob: Node3D) -> void:
	## Soft sycamore-wilds skink — sleek long body, short legs, tapering tail, tiny head (distinct from birds/mammals).
	# Elongated low body
	var body := _mi(_capsule(0.12, 0.55), Vector3(0, 0.28, 0), bob, "Body")
	body.rotation_degrees = Vector3(0, 0, 90)
	# Soft belly stripe (accent-friendly)
	_mi(_sphere(0.07, 0.09), Vector3(0, 0.22, 0.02), bob, "Belly")
	# Small pointed head
	_mi(_sphere(0.09), Vector3(0, 0.30, 0.38), bob, "Head")
	# Tiny eye beads
	_mi(_sphere(0.018), Vector3(-0.04, 0.34, 0.44), bob, "EyeL")
	_mi(_sphere(0.018), Vector3(0.04, 0.34, 0.44), bob, "EyeR")
	# Soft snout tip
	_mi(_box(Vector3(0.04, 0.03, 0.05)), Vector3(0, 0.28, 0.48), bob, "Snout")
	# Short scurrying legs
	for info in [
		["FL", Vector3(-0.08, 0.14, 0.18)],
		["FR", Vector3(0.08, 0.14, 0.18)],
		["BL", Vector3(-0.08, 0.14, -0.16)],
		["BR", Vector3(0.08, 0.14, -0.16)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.015, 0.018, 0.10), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.04, 0.012, 0.05)), Vector3(0, -0.08, 0.01), leg, "Foot")
	# Long tapering tail (signature)
	var tail := _mi(_cyl(0.06, 0.015, 0.42), Vector3(0, 0.26, -0.42), bob, "Tail")
	tail.rotation_degrees = Vector3(78, 0, 0)


static func _build_weasel(bob: Node3D) -> void:
	## Soft walnut-wilds weasel — long sleek body, pointed snout, short legs, bushy tapering tail (distinct from Pine Fox / Elm Raccoon / Oak Hare).
	# Long low body
	_mi(_sphere(0.14, 0.42), Vector3(0, 0.34, 0.02), bob, "Body")
	# Pointed head + snout
	_mi(_sphere(0.11, 0.14), Vector3(0, 0.40, 0.28), bob, "Head")
	_mi(_box(Vector3(0.05, 0.04, 0.10)), Vector3(0, 0.36, 0.40), bob, "Snout")
	# Soft ears
	_mi(_sphere(0.035, 0.05), Vector3(-0.05, 0.50, 0.26), bob, "EarL")
	_mi(_sphere(0.035, 0.05), Vector3(0.05, 0.50, 0.26), bob, "EarR")
	# Bright eyes
	_mi(_sphere(0.025), Vector3(-0.045, 0.44, 0.34), bob, "EyeL")
	_mi(_sphere(0.025), Vector3(0.045, 0.44, 0.34), bob, "EyeR")
	_mi(_sphere(0.012), Vector3(-0.045, 0.445, 0.36), bob, "PupilL")
	_mi(_sphere(0.012), Vector3(0.045, 0.445, 0.36), bob, "PupilR")
	# Cream belly stripe (accent-friendly)
	_mi(_sphere(0.08, 0.28), Vector3(0, 0.26, 0.04), bob, "Belly")
	# Short scurrying legs
	for info in [
		["FL", Vector3(-0.08, 0.16, 0.16)],
		["FR", Vector3(0.08, 0.16, 0.16)],
		["BL", Vector3(-0.08, 0.16, -0.14)],
		["BR", Vector3(0.08, 0.16, -0.14)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.016, 0.018, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.045, 0.014, 0.055)), Vector3(0, -0.09, 0.01), leg, "Foot")
	# Bushy tapering tail (signature)
	var tail := _mi(_cyl(0.07, 0.02, 0.48), Vector3(0, 0.36, -0.38), bob, "Tail")
	tail.rotation_degrees = Vector3(55, 0, 0)
	_mi(_sphere(0.06, 0.10), Vector3(0, 0.42, -0.58), bob, "TailTip")


static func _build_toad(bob: Node3D) -> void:
	## Soft chestnut-wilds toad — squat warty body, wide mouth, short hop legs, bumpy back (distinct from Fir Frog / Sycamore Skink).
	# Wide squat body (chunkier than frog)
	_mi(_sphere(0.26, 0.20), Vector3(0, 0.32, 0), bob, "Body")
	# Warty back bumps (signature vs smooth frog)
	_mi(_sphere(0.05), Vector3(-0.08, 0.44, -0.04), bob, "WartL")
	_mi(_sphere(0.045), Vector3(0.09, 0.43, 0.02), bob, "WartR")
	_mi(_sphere(0.04), Vector3(0.0, 0.46, -0.08), bob, "WartM")
	# Broad head + wide mouth ridge
	_mi(_sphere(0.15, 0.12), Vector3(0, 0.38, 0.18), bob, "Head")
	_mi(_box(Vector3(0.18, 0.03, 0.05)), Vector3(0, 0.34, 0.30), bob, "Mouth")
	# Soft side-set eyes (less bulging than frog)
	_mi(_sphere(0.04), Vector3(-0.09, 0.46, 0.22), bob, "EyeL")
	_mi(_sphere(0.04), Vector3(0.09, 0.46, 0.22), bob, "EyeR")
	_mi(_sphere(0.018), Vector3(-0.09, 0.47, 0.25), bob, "PupilL")
	_mi(_sphere(0.018), Vector3(0.09, 0.47, 0.25), bob, "PupilR")
	# Cream belly patch (accent-friendly)
	_mi(_sphere(0.12, 0.09), Vector3(0, 0.26, 0.08), bob, "Belly")
	# Short front toes + stout hind hop pads
	for info in [
		["FL", Vector3(-0.12, 0.14, 0.12)],
		["FR", Vector3(0.12, 0.14, 0.12)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_capsule(0.028, 0.08), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.07, 0.022, 0.07)), Vector3(0, -0.07, 0.02), leg, "Toe")
	for info in [
		["BL", Vector3(-0.14, 0.16, -0.10)],
		["BR", Vector3(0.14, 0.16, -0.10)],
	]:
		var leg2 := Node3D.new()
		leg2.name = "Leg" + str(info[0])
		leg2.position = info[1]
		bob.add_child(leg2)
		_mi(_capsule(0.05, 0.12), Vector3(0, -0.02, 0), leg2, "Thigh")
		_mi(_box(Vector3(0.11, 0.028, 0.10)), Vector3(0, -0.10, 0.03), leg2, "Pad")
	# Tiny stubby nub (no long skink tail)
	_mi(_sphere(0.04), Vector3(0, 0.28, -0.22), bob, "Nub")

static func _build_possum(bob: Node3D) -> void:
	## Soft pecan-wilds possum — round body, pointed snout, soft ears, curling prehensile tail (distinct from Walnut Weasel / Elm Raccoon / Pine Fox).
	# Plump rounded body (chunkier than weasel)
	_mi(_sphere(0.20, 0.28), Vector3(0, 0.36, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.12, 0.18), Vector3(0, 0.28, 0.06), bob, "Belly")
	# Pointed head + longish snout
	_mi(_sphere(0.12, 0.13), Vector3(0, 0.42, 0.26), bob, "Head")
	_mi(_box(Vector3(0.06, 0.045, 0.12)), Vector3(0, 0.38, 0.38), bob, "Snout")
	# Soft rounded ears (signature vs fox/weasel)
	_mi(_sphere(0.045, 0.055), Vector3(-0.07, 0.54, 0.24), bob, "EarL")
	_mi(_sphere(0.045, 0.055), Vector3(0.07, 0.54, 0.24), bob, "EarR")
	# Bright eyes
	_mi(_sphere(0.028), Vector3(-0.05, 0.46, 0.34), bob, "EyeL")
	_mi(_sphere(0.028), Vector3(0.05, 0.46, 0.34), bob, "EyeR")
	_mi(_sphere(0.012), Vector3(-0.05, 0.465, 0.36), bob, "PupilL")
	_mi(_sphere(0.012), Vector3(0.05, 0.465, 0.36), bob, "PupilR")
	# Short sturdy legs
	for info in [
		["FL", Vector3(-0.10, 0.16, 0.14)],
		["FR", Vector3(0.10, 0.16, 0.14)],
		["BL", Vector3(-0.10, 0.16, -0.12)],
		["BR", Vector3(0.10, 0.16, -0.12)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.018, 0.02, 0.13), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.05, 0.016, 0.06)), Vector3(0, -0.09, 0.01), leg, "Foot")
	# Curling prehensile tail (signature — coils upward unlike weasel bush)
	var tail := _mi(_cyl(0.05, 0.02, 0.38), Vector3(0, 0.34, -0.28), bob, "Tail")
	tail.rotation_degrees = Vector3(40, 0, 0)
	var curl := _mi(_cyl(0.035, 0.015, 0.22), Vector3(0, 0.48, -0.48), bob, "TailCurl")
	curl.rotation_degrees = Vector3(-55, 0, 0)
	_mi(_sphere(0.04), Vector3(0, 0.58, -0.55), bob, "TailTip")


static func _build_beaver(bob: Node3D) -> void:
	## Soft magnolia-wilds beaver — chunky body, flat paddle tail, buck teeth, soft ears (distinct from Pecan Possum / Walnut Weasel / Aspen Otter).
	# Chunky rounded body
	_mi(_sphere(0.22, 0.30), Vector3(0, 0.38, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.13, 0.20), Vector3(0, 0.28, 0.06), bob, "Belly")
	# Broad head
	_mi(_sphere(0.14, 0.13), Vector3(0, 0.44, 0.28), bob, "Head")
	# Soft rounded snout
	_mi(_box(Vector3(0.08, 0.05, 0.10)), Vector3(0, 0.40, 0.40), bob, "Snout")
	# Buck teeth (signature)
	_mi(_box(Vector3(0.018, 0.04, 0.012)), Vector3(-0.016, 0.37, 0.46), bob, "ToothL")
	_mi(_box(Vector3(0.018, 0.04, 0.012)), Vector3(0.016, 0.37, 0.46), bob, "ToothR")
	# Soft rounded ears
	_mi(_sphere(0.04, 0.05), Vector3(-0.08, 0.56, 0.24), bob, "EarL")
	_mi(_sphere(0.04, 0.05), Vector3(0.08, 0.56, 0.24), bob, "EarR")
	# Bright eyes
	_mi(_sphere(0.028), Vector3(-0.055, 0.48, 0.36), bob, "EyeL")
	_mi(_sphere(0.028), Vector3(0.055, 0.48, 0.36), bob, "EyeR")
	_mi(_sphere(0.012), Vector3(-0.055, 0.485, 0.38), bob, "PupilL")
	_mi(_sphere(0.012), Vector3(0.055, 0.485, 0.38), bob, "PupilR")
	# Short sturdy legs
	for info in [
		["FL", Vector3(-0.11, 0.16, 0.14)],
		["FR", Vector3(0.11, 0.16, 0.14)],
		["BL", Vector3(-0.11, 0.16, -0.12)],
		["BR", Vector3(0.11, 0.16, -0.12)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.022, 0.024, 0.14), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.055, 0.018, 0.07)), Vector3(0, -0.10, 0.01), leg, "Foot")
	# Flat paddle tail (signature — horizontal flat vs possum curl / weasel bush)
	var paddle := _mi(_box(Vector3(0.22, 0.035, 0.42)), Vector3(0, 0.30, -0.38), bob, "Paddle")
	paddle.rotation_degrees = Vector3(12, 0, 0)
	_mi(_box(Vector3(0.16, 0.028, 0.12)), Vector3(0, 0.28, -0.58), bob, "PaddleTip")

