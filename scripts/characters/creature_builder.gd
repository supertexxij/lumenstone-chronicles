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
		"olive_owl":
			_build_owl(bob)
		"palm_pika":
			_build_pika(bob)
		"lemon_lemming":
			_build_lemming(bob)
		"cherry_chinchilla":
			_build_chinchilla(bob)
		"plum_porcupine":
			_build_porcupine(bob)
		"peach_puffin":
			_build_puffin(bob)
		"fig_finch":
			_build_finch(bob)
		"grape_gecko":
			_build_gecko(bob)
		"apricot_armadillo":
			_build_armadillo(bob)
		"blueberry_bunny":
			_build_bunny(bob)
		"cranberry_capybara":
			_build_capybara(bob)
		"raspberry_ram":
			_build_ram(bob)
		"strawberry_stoat":
			_build_stoat(bob)
		"blackberry_bear":
			_build_bear(bob)
		"guava_goat":
			_build_goat(bob)
		"kiwi_koala":
			_build_koala(bob)
		"mango_mongoose":
			_build_mongoose(bob)
		"papaya_panda":
			_build_panda(bob)
		"coconut_crab":
			_build_crab(bob)
		"lime_llama":
			_build_llama(bob)
		"melon_moose":
			_build_moose(bob)
		"quince_quokka":
			_build_quokka(bob)
		"watermelon_wallaby":
			_build_wallaby(bob)
		"honeydew_hamster":
			_build_hamster(bob)
		"party_unicorn":
			_build_party_unicorn(bob)
		_:
			_build_wisp(bob)
	return bob


static func _build_party_unicorn(bob: Node3D) -> void:
	## My-Little-Pony-inspired party unicorn — slim soft pony facing +Z,
	## big shiny eyes, flowing hair locks, cute short legs.
	# Barrel along Z (nose→tail), NOT along X — earlier Z-roll made them look sideways-wide.
	var body := _mi(_soft_capsule(0.14, 0.86), Vector3(0, 0.58, 0.0), bob, "Body")
	body.rotation_degrees = Vector3(90, 0, 0)
	_mi(_soft_sphere(0.10, 0.095), Vector3(0, 0.46, 0.02), bob, "Belly")
	# Soft short neck toward +Z
	var neck := _mi(_soft_cyl(0.08, 0.10, 0.26), Vector3(0, 0.78, 0.32), bob, "Neck")
	neck.rotation_degrees = Vector3(18, 0, 0)
	# Cute head + tiny muzzle (still MLP-round, but not oversized)
	_mi(_soft_sphere(0.17, 0.18), Vector3(0, 0.98, 0.50), bob, "Head")
	_mi(_soft_sphere(0.075, 0.085), Vector3(0, 0.92, 0.66), bob, "Muzzle")
	_mi(_soft_sphere(0.026, 0.020), Vector3(0, 0.90, 0.74), bob, "Nose")
	# Big shiny cartoon eyes
	_mi(_soft_sphere(0.052, 0.055), Vector3(-0.075, 1.02, 0.60), bob, "EyeWhiteL")
	_mi(_soft_sphere(0.052, 0.055), Vector3(0.075, 1.02, 0.60), bob, "EyeWhiteR")
	_mi(_soft_sphere(0.034), Vector3(-0.075, 1.02, 0.64), bob, "IrisL")
	_mi(_soft_sphere(0.034), Vector3(0.075, 1.02, 0.64), bob, "IrisR")
	_mi(_soft_sphere(0.016), Vector3(-0.075, 1.02, 0.67), bob, "PupilL")
	_mi(_soft_sphere(0.016), Vector3(0.075, 1.02, 0.67), bob, "PupilR")
	_mi(_soft_sphere(0.011), Vector3(-0.06, 1.04, 0.675), bob, "ShineL")
	_mi(_soft_sphere(0.011), Vector3(0.09, 1.04, 0.675), bob, "ShineR")
	# Soft blush
	_mi(_soft_sphere(0.034, 0.022), Vector3(-0.11, 0.94, 0.56), bob, "BlushL")
	_mi(_soft_sphere(0.034, 0.022), Vector3(0.11, 0.94, 0.56), bob, "BlushR")
	# Soft rounded ears
	var ear_l := _mi(_soft_cyl(0.011, 0.036, 0.10), Vector3(-0.09, 1.14, 0.44), bob, "EarL")
	ear_l.rotation_degrees = Vector3(8, 0, -22)
	var ear_r := _mi(_soft_cyl(0.011, 0.036, 0.10), Vector3(0.09, 1.14, 0.44), bob, "EarR")
	ear_r.rotation_degrees = Vector3(8, 0, 22)
	# Elegant pearl horn
	var horn_root := Node3D.new()
	horn_root.name = "Horn"
	horn_root.position = Vector3(0, 1.14, 0.46)
	horn_root.rotation_degrees = Vector3(-10, 0, 0)
	bob.add_child(horn_root)
	_mi(_soft_cyl(0.032, 0.022, 0.10), Vector3(0, 0.04, 0), horn_root, "HornBase")
	_mi(_soft_cyl(0.022, 0.012, 0.12), Vector3(0, 0.13, 0), horn_root, "HornMid")
	_mi(_soft_cyl(0.012, 0.003, 0.10), Vector3(0, 0.22, 0), horn_root, "HornTip")
	# Flowing hair locks — keep close to the spine (not flared wide)
	var mane := Node3D.new()
	mane.name = "Mane"
	mane.position = Vector3(0, 0.88, 0.14)
	bob.add_child(mane)
	var lock_specs := [
		["Forelock", Vector3(0.0, 0.22, 0.32), Vector3(-48, 0, 0), 0.05, 0.26],
		["ManeA", Vector3(0.05, 0.16, 0.14), Vector3(-18, 18, 12), 0.055, 0.36],
		["ManeB", Vector3(-0.05, 0.12, 0.06), Vector3(-12, -20, -12), 0.052, 0.38],
		["ManeC", Vector3(0.06, -0.02, -0.06), Vector3(8, 14, 14), 0.05, 0.40],
		["ManeD", Vector3(-0.05, -0.08, -0.14), Vector3(14, -12, -10), 0.048, 0.38],
		["ManeE", Vector3(0.01, -0.16, -0.22), Vector3(22, 4, 2), 0.046, 0.34],
	]
	for spec in lock_specs:
		var lock := _mi(_soft_capsule(float(spec[3]), float(spec[4])), spec[1], mane, str(spec[0]))
		lock.rotation_degrees = spec[2]
	# Soft flowing tail
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.62, -0.42)
	bob.add_child(tail)
	var t1 := _mi(_soft_capsule(0.048, 0.34), Vector3(0.01, 0.02, -0.10), tail, "TailA")
	t1.rotation_degrees = Vector3(42, 8, 0)
	var t2 := _mi(_soft_capsule(0.045, 0.32), Vector3(-0.03, -0.02, -0.26), tail, "TailB")
	t2.rotation_degrees = Vector3(52, -10, 4)
	var t3 := _mi(_soft_capsule(0.042, 0.28), Vector3(0.03, -0.05, -0.40), tail, "TailC")
	t3.rotation_degrees = Vector3(60, 6, -3)
	# Cute short pony legs — narrow stance under slim barrel
	for info in [
		["FL", Vector3(-0.07, 0.34, 0.26)],
		["FR", Vector3(0.07, 0.34, 0.26)],
		["BL", Vector3(-0.07, 0.34, -0.26)],
		["BR", Vector3(0.07, 0.34, -0.26)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_soft_cyl(0.028, 0.032, 0.16), Vector3(0, -0.02, 0), leg, "Thigh")
		_mi(_soft_cyl(0.024, 0.026, 0.12), Vector3(0, -0.14, 0), leg, "Shin")
		_mi(_soft_sphere(0.034, 0.028), Vector3(0, -0.23, 0.01), leg, "Hoof")


static func _soft_sphere(r: float, h: float = -1.0) -> SphereMesh:
	var m := _sphere(r, h)
	m.radial_segments = 24
	m.rings = 12
	return m


static func _soft_capsule(r: float, h: float) -> CapsuleMesh:
	var m := _capsule(r, h)
	m.radial_segments = 24
	m.rings = 8
	return m


static func _soft_cyl(top_r: float, bot_r: float, h: float) -> CylinderMesh:
	var m := _cyl(top_r, bot_r, h)
	m.radial_segments = 20
	return m


static func colorize_party_unicorn(root: Node3D, coat: Color, mane: Color) -> void:
	## Soft MLP materials — glossy coat, vivid mane, pearl horn, big shiny eyes.
	var dark := Color(0.12, 0.08, 0.16)
	var white := Color(0.98, 0.98, 1.0)
	var hoof_c := coat.darkened(0.22)
	var nose_c := coat.darkened(0.12)
	var iris := mane.darkened(0.05).lerp(Color(0.35, 0.55, 0.95), 0.35)
	var blush := Color(1.0, 0.55, 0.65, 1.0)
	var horn_c := Color(1.0, 0.92, 0.55).lerp(mane.lightened(0.2), 0.25)
	_colorize_named_meshes(root, func(n: String) -> Dictionary:
		var low := n.to_lower()
		if "eyewhite" in low or "shine" in low:
			return {"color": white, "roughness": 0.25, "metallic": 0.0, "emission": Color(0, 0, 0, 0)}
		if "pupil" in low:
			return {"color": dark, "roughness": 0.35, "metallic": 0.0, "emission": Color(0, 0, 0, 0)}
		if "iris" in low:
			return {"color": iris, "roughness": 0.3, "metallic": 0.0, "emission": Color(0, 0, 0, 0)}
		if "hoof" in low:
			return {"color": hoof_c, "roughness": 0.55, "metallic": 0.0, "emission": Color(0, 0, 0, 0)}
		if "nose" in low:
			return {"color": nose_c, "roughness": 0.5, "metallic": 0.0, "emission": Color(0, 0, 0, 0)}
		if "blush" in low:
			return {"color": blush, "roughness": 0.45, "metallic": 0.0, "emission": Color(0, 0, 0, 0)}
		if "horn" in low:
			return {"color": horn_c, "roughness": 0.22, "metallic": 0.55, "emission": Color(horn_c.r, horn_c.g, horn_c.b) * 0.15}
		if "mane" in low or "forelock" in low or "tail" in low:
			return {"color": mane, "roughness": 0.4, "metallic": 0.0, "emission": Color(0, 0, 0, 0)}
		if "ear" in low:
			return {"color": coat.darkened(0.04), "roughness": 0.42, "metallic": 0.0, "emission": Color(0, 0, 0, 0)}
		if "belly" in low or "muzzle" in low:
			return {"color": coat.lightened(0.14), "roughness": 0.38, "metallic": 0.0, "emission": Color(0, 0, 0, 0)}
		# Soft glossy coat
		return {"color": coat, "roughness": 0.36, "metallic": 0.0, "emission": Color(0, 0, 0, 0)}
	)


static func _colorize_named_meshes(root: Node3D, pick: Callable) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var spec: Variant = pick.call(str(n.name))
			var mat := StandardMaterial3D.new()
			if typeof(spec) == TYPE_DICTIONARY:
				var d: Dictionary = spec
				mat.albedo_color = d.get("color", Color.WHITE)
				mat.roughness = float(d.get("roughness", 0.5))
				mat.metallic = float(d.get("metallic", 0.0))
				var em: Color = d.get("emission", Color(0, 0, 0, 0))
				if em.r + em.g + em.b > 0.001:
					mat.emission_enabled = true
					mat.emission = em
					mat.emission_energy_multiplier = 1.2
			else:
				mat.albedo_color = spec
				mat.roughness = 0.45
			(n as MeshInstance3D).material_override = mat
		for c in n.get_children():
			stack.append(c)


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

static func _build_owl(bob: Node3D) -> void:
	## Soft olive-wilds owl — round body, big eyes, ear tufts, short hooked beak (distinct from Juniper Jay / Willow Wren / Poplar Dove / Rowan Robin / Ash Sparrow).
	# Round plump body
	_mi(_sphere(0.22, 0.26), Vector3(0, 0.42, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.12, 0.16), Vector3(0, 0.34, 0.06), bob, "Belly")
	# Round head (large relative to birds)
	_mi(_sphere(0.16), Vector3(0, 0.66, 0.04), bob, "Head")
	# Ear tufts (signature)
	var tl := _mi(_box(Vector3(0.04, 0.10, 0.035)), Vector3(-0.07, 0.82, -0.01), bob, "TuftL")
	tl.rotation_degrees = Vector3(-18, 0, -12)
	var tr := _mi(_box(Vector3(0.04, 0.10, 0.035)), Vector3(0.07, 0.82, -0.01), bob, "TuftR")
	tr.rotation_degrees = Vector3(-18, 0, 12)
	# Big wholesome eyes
	_mi(_sphere(0.055), Vector3(-0.06, 0.68, 0.14), bob, "EyeL")
	_mi(_sphere(0.055), Vector3(0.06, 0.68, 0.14), bob, "EyeR")
	_mi(_sphere(0.022), Vector3(-0.06, 0.685, 0.175), bob, "PupilL")
	_mi(_sphere(0.022), Vector3(0.06, 0.685, 0.175), bob, "PupilR")
	# Short hooked beak
	_mi(_box(Vector3(0.035, 0.03, 0.055)), Vector3(0, 0.62, 0.18), bob, "Beak")
	# Folded soft wings
	var lw := _mi(_box(Vector3(0.26, 0.035, 0.16)), Vector3(-0.16, 0.44, -0.02), bob, "LWing")
	lw.rotation_degrees = Vector3(6, 0, 18)
	var rw := _mi(_box(Vector3(0.26, 0.035, 0.16)), Vector3(0.16, 0.44, -0.02), bob, "RWing")
	rw.rotation_degrees = Vector3(6, 0, -18)
	# Short fan tail
	var tail := _mi(_box(Vector3(0.12, 0.03, 0.12)), Vector3(0, 0.40, -0.22), bob, "Tail")
	tail.rotation_degrees = Vector3(-10, 0, 0)
	# Perchy feet
	for info in [
		["FL", Vector3(-0.05, 0.18, 0.04)],
		["FR", Vector3(0.05, 0.18, 0.04)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.012, 0.014, 0.11), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.04, 0.012, 0.05)), Vector3(0, -0.08, 0.01), leg, "Foot")

static func _build_pika(bob: Node3D) -> void:
	## Soft palm-wilds pika — round body, big round ears, short snout, cotton puff tail (distinct from Maple Mouse / Hazel Hedgehog / Oak Hare / Beech Chipmunk / Olive Owl).
	# Round plump body
	_mi(_sphere(0.18, 0.22), Vector3(0, 0.32, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.10, 0.12), Vector3(0, 0.26, 0.06), bob, "Belly")
	# Round head
	_mi(_sphere(0.13), Vector3(0, 0.48, 0.06), bob, "Head")
	# Big round ears (signature)
	_mi(_sphere(0.055, 0.02), Vector3(-0.09, 0.60, -0.01), bob, "EarL")
	_mi(_sphere(0.055, 0.02), Vector3(0.09, 0.60, -0.01), bob, "EarR")
	_mi(_sphere(0.028, 0.012), Vector3(-0.09, 0.60, 0.01), bob, "EarInnerL")
	_mi(_sphere(0.028, 0.012), Vector3(0.09, 0.60, 0.01), bob, "EarInnerR")
	# Soft eyes
	_mi(_sphere(0.028), Vector3(-0.045, 0.50, 0.15), bob, "EyeL")
	_mi(_sphere(0.028), Vector3(0.045, 0.50, 0.15), bob, "EyeR")
	_mi(_sphere(0.012), Vector3(-0.045, 0.505, 0.17), bob, "PupilL")
	_mi(_sphere(0.012), Vector3(0.045, 0.505, 0.17), bob, "PupilR")
	# Short snout
	_mi(_sphere(0.04, 0.035), Vector3(0, 0.44, 0.16), bob, "Snout")
	# Tiny cotton puff tail
	_mi(_sphere(0.06), Vector3(0, 0.30, -0.18), bob, "TailPuff")
	# Short legs
	for info in [
		["FL", Vector3(-0.06, 0.14, 0.06)],
		["FR", Vector3(0.06, 0.14, 0.06)],
		["BL", Vector3(-0.06, 0.14, -0.06)],
		["BR", Vector3(0.06, 0.14, -0.06)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.014, 0.016, 0.10), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.035, 0.012, 0.04)), Vector3(0, -0.07, 0.01), leg, "Foot")

static func _build_lemming(bob: Node3D) -> void:
	## Soft lemon-wilds lemming — plump oval body, tiny rounded ears, short blunt snout, stubby tufted tail (distinct from Palm Pika / Maple Mouse / Spruce Mole / Oak Hare / Beech Chipmunk).
	# Plump oval body
	_mi(_sphere(0.20, 0.16), Vector3(0, 0.30, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.11, 0.09), Vector3(0, 0.24, 0.05), bob, "Belly")
	# Rounded head
	_mi(_sphere(0.12), Vector3(0, 0.42, 0.08), bob, "Head")
	# Tiny rounded ears (signature — smaller than Palm Pika)
	_mi(_sphere(0.032, 0.016), Vector3(-0.07, 0.52, 0.0), bob, "EarL")
	_mi(_sphere(0.032, 0.016), Vector3(0.07, 0.52, 0.0), bob, "EarR")
	# Soft eyes
	_mi(_sphere(0.024), Vector3(-0.04, 0.44, 0.16), bob, "EyeL")
	_mi(_sphere(0.024), Vector3(0.04, 0.44, 0.16), bob, "EyeR")
	_mi(_sphere(0.010), Vector3(-0.04, 0.445, 0.175), bob, "PupilL")
	_mi(_sphere(0.010), Vector3(0.04, 0.445, 0.175), bob, "PupilR")
	# Short blunt snout
	_mi(_sphere(0.035, 0.03), Vector3(0, 0.39, 0.17), bob, "Snout")
	# Stubby tufted tail (signature — short vs puff / bush)
	_mi(_cyl(0.025, 0.03, 0.08), Vector3(0, 0.28, -0.16), bob, "TailBase")
	_mi(_sphere(0.045), Vector3(0, 0.28, -0.22), bob, "TailTuft")
	# Short stocky legs
	for info in [
		["FL", Vector3(-0.07, 0.12, 0.06)],
		["FR", Vector3(0.07, 0.12, 0.06)],
		["BL", Vector3(-0.07, 0.12, -0.05)],
		["BR", Vector3(0.07, 0.12, -0.05)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.016, 0.018, 0.09), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.038, 0.012, 0.042)), Vector3(0, -0.065, 0.01), leg, "Foot")


static func _build_chinchilla(bob: Node3D) -> void:
	## Soft cherry-wilds chinchilla — plump body, oversized round ears, short snout, fluffy bushy tail (distinct from Lemon Lemming / Palm Pika / Maple Mouse / Birch Squirrel / Beech Chipmunk).
	# Plump rounded body
	_mi(_sphere(0.19, 0.20), Vector3(0, 0.34, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.11, 0.10), Vector3(0, 0.28, 0.06), bob, "Belly")
	# Round head
	_mi(_sphere(0.13), Vector3(0, 0.50, 0.05), bob, "Head")
	# Oversized round ears (signature — bigger than Palm Pika)
	_mi(_sphere(0.07, 0.022), Vector3(-0.11, 0.64, -0.02), bob, "EarL")
	_mi(_sphere(0.07, 0.022), Vector3(0.11, 0.64, -0.02), bob, "EarR")
	_mi(_sphere(0.035, 0.012), Vector3(-0.11, 0.64, 0.01), bob, "EarInnerL")
	_mi(_sphere(0.035, 0.012), Vector3(0.11, 0.64, 0.01), bob, "EarInnerR")
	# Soft eyes
	_mi(_sphere(0.026), Vector3(-0.045, 0.52, 0.14), bob, "EyeL")
	_mi(_sphere(0.026), Vector3(0.045, 0.52, 0.14), bob, "EyeR")
	_mi(_sphere(0.011), Vector3(-0.045, 0.525, 0.155), bob, "PupilL")
	_mi(_sphere(0.011), Vector3(0.045, 0.525, 0.155), bob, "PupilR")
	# Short blunt snout
	_mi(_sphere(0.038, 0.032), Vector3(0, 0.46, 0.15), bob, "Snout")
	# Fluffy bushy tail (signature — fuller than lemming tuft / pika puff)
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.32, -0.14)
	bob.add_child(tail)
	_mi(_cyl(0.04, 0.055, 0.14), Vector3(0, 0.0, -0.06), tail, "TailBase")
	_mi(_sphere(0.09, 0.11), Vector3(0, 0.02, -0.16), tail, "TailFluff")
	_mi(_sphere(0.05), Vector3(0, 0.04, -0.22), tail, "TailTip")
	# Short soft legs
	for info in [
		["FL", Vector3(-0.07, 0.14, 0.06)],
		["FR", Vector3(0.07, 0.14, 0.06)],
		["BL", Vector3(-0.07, 0.14, -0.05)],
		["BR", Vector3(0.07, 0.14, -0.05)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.015, 0.017, 0.10), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.036, 0.012, 0.04)), Vector3(0, -0.07, 0.01), leg, "Foot")

static func _build_porcupine(bob: Node3D) -> void:
	## Soft plum-wilds porcupine — plump body, short rounded snout, soft quill crest, stubby tail (distinct from Cherry Chinchilla / Hazel Hedgehog / Chestnut Toad / Magnolia Beaver).
	# Plump rounded body
	_mi(_sphere(0.20, 0.18), Vector3(0, 0.36, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.11, 0.09), Vector3(0, 0.28, 0.06), bob, "Belly")
	# Round head
	_mi(_sphere(0.12), Vector3(0, 0.48, 0.08), bob, "Head")
	# Small rounded ears
	_mi(_sphere(0.04, 0.018), Vector3(-0.09, 0.58, -0.01), bob, "EarL")
	_mi(_sphere(0.04, 0.018), Vector3(0.09, 0.58, -0.01), bob, "EarR")
	# Soft eyes
	_mi(_sphere(0.024), Vector3(-0.04, 0.50, 0.16), bob, "EyeL")
	_mi(_sphere(0.024), Vector3(0.04, 0.50, 0.16), bob, "EyeR")
	_mi(_sphere(0.01), Vector3(-0.04, 0.505, 0.175), bob, "PupilL")
	_mi(_sphere(0.01), Vector3(0.04, 0.505, 0.175), bob, "PupilR")
	# Short blunt snout
	_mi(_sphere(0.035, 0.028), Vector3(0, 0.44, 0.17), bob, "Snout")
	# Soft quill crest (signature — chunky spines, not hedgehog nubs)
	var quills := Node3D.new()
	quills.name = "Quills"
	quills.position = Vector3(0, 0.42, -0.02)
	bob.add_child(quills)
	for i in 7:
		var ang := (float(i) / 6.0 - 0.5) * 0.9
		var q := _mi(_cyl(0.018, 0.012, 0.22), Vector3(ang * 0.12, 0.08, -0.04 - abs(ang) * 0.04), quills, "Quill%d" % i)
		q.rotation_degrees = Vector3(-35 - abs(ang) * 20.0, ang * 40.0, ang * 15.0)
	# Soft rear fluff / stubby tail
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.30, -0.16)
	bob.add_child(tail)
	_mi(_sphere(0.06, 0.05), Vector3(0, 0.0, -0.04), tail, "TailPuff")
	# Short soft legs
	for info in [
		["FL", Vector3(-0.08, 0.14, 0.07)],
		["FR", Vector3(0.08, 0.14, 0.07)],
		["BL", Vector3(-0.08, 0.14, -0.06)],
		["BR", Vector3(0.08, 0.14, -0.06)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.016, 0.018, 0.10), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.038, 0.012, 0.042)), Vector3(0, -0.07, 0.01), leg, "Foot")

static func _build_puffin(bob: Node3D) -> void:
	## Soft peach-wilds puffin — plump body, chunky striped beak, upright stance, short stubby wings, paddle feet (distinct from Poplar Dove / Rowan Robin / Willow Wren / Alder Duck / Olive Owl / Ash Sparrow / Hickory Quail / Juniper Jay).
	# Plump upright body
	_mi(_sphere(0.17, 0.24), Vector3(0, 0.42, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.10, 0.14), Vector3(0, 0.38, 0.08), bob, "Belly")
	# Round head
	_mi(_sphere(0.12), Vector3(0, 0.64, 0.06), bob, "Head")
	# Soft eyes
	_mi(_sphere(0.024), Vector3(-0.045, 0.66, 0.14), bob, "EyeL")
	_mi(_sphere(0.024), Vector3(0.045, 0.66, 0.14), bob, "EyeR")
	_mi(_sphere(0.01), Vector3(-0.045, 0.665, 0.155), bob, "PupilL")
	_mi(_sphere(0.01), Vector3(0.045, 0.665, 0.155), bob, "PupilR")
	# Chunky striped beak (signature — wider/taller than dove/robin beaks)
	var beak := Node3D.new()
	beak.name = "Beak"
	beak.position = Vector3(0, 0.60, 0.18)
	bob.add_child(beak)
	_mi(_box(Vector3(0.10, 0.055, 0.14)), Vector3(0, 0.01, 0.04), beak, "BeakBase")
	_mi(_box(Vector3(0.08, 0.03, 0.06)), Vector3(0, 0.04, 0.10), beak, "BeakTip")
	_mi(_box(Vector3(0.09, 0.012, 0.10)), Vector3(0, -0.01, 0.05), beak, "BeakStripe")
	# Short stubby folded wings
	var lw := _mi(_box(Vector3(0.16, 0.04, 0.18)), Vector3(-0.14, 0.44, -0.02), bob, "LWing")
	lw.rotation_degrees = Vector3(10, 0, 28)
	var rw := _mi(_box(Vector3(0.16, 0.04, 0.18)), Vector3(0.14, 0.44, -0.02), bob, "RWing")
	rw.rotation_degrees = Vector3(10, 0, -28)
	# Short upright tail tuft
	var tail := _mi(_box(Vector3(0.08, 0.04, 0.10)), Vector3(0, 0.48, -0.16), bob, "Tail")
	tail.rotation_degrees = Vector3(-40, 0, 0)
	# Paddle feet (signature — broader than songbird perch feet)
	for info in [
		["FL", Vector3(-0.05, 0.18, 0.04)],
		["FR", Vector3(0.05, 0.18, 0.04)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.014, 0.018, 0.10), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.07, 0.014, 0.08)), Vector3(0, -0.08, 0.02), leg, "Paddle")

static func _build_finch(bob: Node3D) -> void:
	## Soft fig-wilds finch — plump oval body, tiny cone beak, short rounded wings, slender perch legs (distinct from Willow Wren / Rowan Robin / Ash Sparrow / Poplar Dove / Hickory Quail / Juniper Jay / Peach Puffin / Olive Owl / Alder Duck).
	# Plump oval body (more horizontal than upright puffin)
	_mi(_sphere(0.15, 0.13), Vector3(0, 0.38, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.09, 0.08), Vector3(0, 0.34, 0.07), bob, "Belly")
	# Round head
	_mi(_sphere(0.10), Vector3(0, 0.52, 0.08), bob, "Head")
	# Soft eyes
	_mi(_sphere(0.02), Vector3(-0.038, 0.54, 0.15), bob, "EyeL")
	_mi(_sphere(0.02), Vector3(0.038, 0.54, 0.15), bob, "EyeR")
	_mi(_sphere(0.008), Vector3(-0.038, 0.545, 0.165), bob, "PupilL")
	_mi(_sphere(0.008), Vector3(0.038, 0.545, 0.165), bob, "PupilR")
	# Tiny cone beak (signature — smaller/sharper than puffin striped beak)
	var beak := Node3D.new()
	beak.name = "Beak"
	beak.position = Vector3(0, 0.50, 0.16)
	bob.add_child(beak)
	_mi(_box(Vector3(0.04, 0.028, 0.07)), Vector3(0, 0.0, 0.03), beak, "BeakCone")
	# Soft fig-tone cheek patch
	_mi(_sphere(0.03), Vector3(-0.07, 0.50, 0.06), bob, "CheekL")
	_mi(_sphere(0.03), Vector3(0.07, 0.50, 0.06), bob, "CheekR")
	# Short rounded folded wings
	var lw := _mi(_box(Vector3(0.12, 0.03, 0.14)), Vector3(-0.12, 0.40, -0.02), bob, "LWing")
	lw.rotation_degrees = Vector3(8, 0, 22)
	var rw := _mi(_box(Vector3(0.12, 0.03, 0.14)), Vector3(0.12, 0.40, -0.02), bob, "RWing")
	rw.rotation_degrees = Vector3(8, 0, -22)
	# Short notched tail
	var tail := _mi(_box(Vector3(0.07, 0.025, 0.09)), Vector3(0, 0.40, -0.14), bob, "Tail")
	tail.rotation_degrees = Vector3(-28, 0, 0)
	# Slender perch legs (signature — thinner than paddle puffin feet)
	for info in [
		["FL", Vector3(-0.04, 0.22, 0.03)],
		["FR", Vector3(0.04, 0.22, 0.03)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.01, 0.012, 0.12), Vector3(0, -0.03, 0), leg, "Shin")
		_mi(_box(Vector3(0.035, 0.01, 0.04)), Vector3(0, -0.09, 0.01), leg, "Perch")

static func _build_gecko(bob: Node3D) -> void:
	## Soft grape-wilds gecko — plump low body, big soft eyes, sticky toe pads, short plump tail (distinct from Sycamore Skink / Fir Frog / Cypress Turtle / Chestnut Toad).
	# Plump low oval body (chunkier / shorter than skink capsule)
	var body := _mi(_sphere(0.16, 0.22), Vector3(0, 0.26, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.09, 0.12), Vector3(0, 0.20, 0.04), bob, "Belly")
	# Round head with big soft eyes (signature vs skink tiny beads)
	_mi(_sphere(0.11), Vector3(0, 0.32, 0.28), bob, "Head")
	_mi(_sphere(0.045), Vector3(-0.05, 0.36, 0.36), bob, "EyeL")
	_mi(_sphere(0.045), Vector3(0.05, 0.36, 0.36), bob, "EyeR")
	_mi(_sphere(0.018), Vector3(-0.05, 0.365, 0.39), bob, "PupilL")
	_mi(_sphere(0.018), Vector3(0.05, 0.365, 0.39), bob, "PupilR")
	# Soft blunt snout
	_mi(_box(Vector3(0.05, 0.035, 0.06)), Vector3(0, 0.30, 0.40), bob, "Snout")
	# Soft grape-tone cheek patch
	_mi(_sphere(0.035), Vector3(-0.08, 0.30, 0.22), bob, "CheekL")
	_mi(_sphere(0.035), Vector3(0.08, 0.30, 0.22), bob, "CheekR")
	# Short sturdy legs with sticky toe pads (signature)
	for info in [
		["FL", Vector3(-0.09, 0.12, 0.14)],
		["FR", Vector3(0.09, 0.12, 0.14)],
		["BL", Vector3(-0.09, 0.12, -0.12)],
		["BR", Vector3(0.09, 0.12, -0.12)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.016, 0.018, 0.09), Vector3(0, -0.015, 0), leg, "Shin")
		_mi(_box(Vector3(0.055, 0.014, 0.07)), Vector3(0, -0.07, 0.015), leg, "Pad")
	# Short plump tail (signature — shorter than skink taper)
	var tail := _mi(_cyl(0.055, 0.02, 0.28), Vector3(0, 0.24, -0.28), bob, "Tail")
	tail.rotation_degrees = Vector3(70, 0, 0)
	_mi(_sphere(0.035), Vector3(0, 0.18, -0.48), bob, "TailTip")

static func _build_armadillo(bob: Node3D) -> void:
	## Soft apricot-wilds armadillo — plump low body, banded shell plates, short snout, stubby legs, tiny rounded ears (distinct from Moss Badger / Pecan Possum / Walnut Weasel / Lemon Lemming / Cherry Chinchilla).
	# Plump oval body
	var body := _mi(_sphere(0.18, 0.26), Vector3(0, 0.28, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.10, 0.14), Vector3(0, 0.20, 0.05), bob, "Belly")
	# Banded shell plates (signature armor crest)
	var shell := Node3D.new()
	shell.name = "Shell"
	shell.position = Vector3(0, 0.38, -0.02)
	bob.add_child(shell)
	_mi(_box(Vector3(0.34, 0.06, 0.22)), Vector3(0, 0.0, 0.06), shell, "Plate1")
	_mi(_box(Vector3(0.36, 0.055, 0.20)), Vector3(0, 0.05, -0.02), shell, "Plate2")
	_mi(_box(Vector3(0.32, 0.05, 0.18)), Vector3(0, 0.09, -0.10), shell, "Plate3")
	# Soft apricot cheek tones on shell edges
	_mi(_sphere(0.06, 0.05), Vector3(-0.16, 0.02, 0.0), shell, "ShellEdgeL")
	_mi(_sphere(0.06, 0.05), Vector3(0.16, 0.02, 0.0), shell, "ShellEdgeR")
	# Round head + tiny ears + short soft snout
	_mi(_sphere(0.11), Vector3(0, 0.34, 0.30), bob, "Head")
	_mi(_sphere(0.04, 0.05), Vector3(-0.07, 0.42, 0.28), bob, "EarL")
	_mi(_sphere(0.04, 0.05), Vector3(0.07, 0.42, 0.28), bob, "EarR")
	_mi(_box(Vector3(0.055, 0.04, 0.08)), Vector3(0, 0.30, 0.42), bob, "Snout")
	_mi(_sphere(0.025), Vector3(-0.04, 0.36, 0.38), bob, "EyeL")
	_mi(_sphere(0.025), Vector3(0.04, 0.36, 0.38), bob, "EyeR")
	# Stubby legs
	for info in [
		["FL", Vector3(-0.10, 0.14, 0.14)],
		["FR", Vector3(0.10, 0.14, 0.14)],
		["BL", Vector3(-0.10, 0.14, -0.14)],
		["BR", Vector3(0.10, 0.14, -0.14)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.025, 0.03, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.06, 0.02, 0.07)), Vector3(0, -0.09, 0.01), leg, "Foot")
	# Soft tapered tail
	var tail := _mi(_cyl(0.04, 0.018, 0.26), Vector3(0, 0.24, -0.30), bob, "Tail")
	tail.rotation_degrees = Vector3(55, 0, 0)
	_mi(_sphere(0.028), Vector3(0, 0.16, -0.48), bob, "TailTip")

static func _build_bunny(bob: Node3D) -> void:
	## Soft blueberry-wilds bunny — plump round body, long soft ears, tiny puff tail, short hop legs (distinct from Oak Hare / Cherry Chinchilla / Lemon Lemming / Maple Mouse).
	# Plump round body
	_mi(_sphere(0.20, 0.28), Vector3(0, 0.32, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.11, 0.14), Vector3(0, 0.24, 0.06), bob, "Belly")
	# Round head + long soft ears (signature) + tiny nose
	_mi(_sphere(0.12), Vector3(0, 0.48, 0.22), bob, "Head")
	var ear_l := _mi(_cyl(0.035, 0.045, 0.28), Vector3(-0.06, 0.72, 0.18), bob, "EarL")
	ear_l.rotation_degrees = Vector3(8, 0, -12)
	var ear_r := _mi(_cyl(0.035, 0.045, 0.28), Vector3(0.06, 0.72, 0.18), bob, "EarR")
	ear_r.rotation_degrees = Vector3(8, 0, 12)
	_mi(_sphere(0.03), Vector3(-0.06, 0.86, 0.18), bob, "EarTipL")
	_mi(_sphere(0.03), Vector3(0.06, 0.86, 0.18), bob, "EarTipR")
	_mi(_sphere(0.03), Vector3(0, 0.46, 0.34), bob, "Nose")
	_mi(_sphere(0.025), Vector3(-0.045, 0.50, 0.30), bob, "EyeL")
	_mi(_sphere(0.025), Vector3(0.045, 0.50, 0.30), bob, "EyeR")
	# Short hop legs
	for info in [
		["FL", Vector3(-0.09, 0.16, 0.12)],
		["FR", Vector3(0.09, 0.16, 0.12)],
		["BL", Vector3(-0.10, 0.16, -0.12)],
		["BR", Vector3(0.10, 0.16, -0.12)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.028, 0.032, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.06, 0.02, 0.08)), Vector3(0, -0.09, 0.01), leg, "Foot")
	# Tiny puff tail
	_mi(_sphere(0.07), Vector3(0, 0.30, -0.26), bob, "Tail")


static func _build_capybara(bob: Node3D) -> void:
	## Soft cranberry-wilds capybara — plump barrel body, blunt snout, tiny rounded ears, stubby legs, soft blunt tail (distinct from Magnolia Beaver / Aspen Otter / Moss Badger / Blueberry Bunny / Lemon Lemming).
	# Plump barrel body
	var body := _mi(_sphere(0.22, 0.32), Vector3(0, 0.34, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.12, 0.16), Vector3(0, 0.24, 0.06), bob, "Belly")
	# Round head + blunt snout + tiny rounded ears
	_mi(_sphere(0.13), Vector3(0, 0.42, 0.30), bob, "Head")
	_mi(_sphere(0.045, 0.05), Vector3(-0.08, 0.52, 0.28), bob, "EarL")
	_mi(_sphere(0.045, 0.05), Vector3(0.08, 0.52, 0.28), bob, "EarR")
	_mi(_box(Vector3(0.07, 0.05, 0.10)), Vector3(0, 0.36, 0.44), bob, "Snout")
	_mi(_sphere(0.028), Vector3(0, 0.35, 0.50), bob, "Nose")
	_mi(_sphere(0.025), Vector3(-0.045, 0.44, 0.40), bob, "EyeL")
	_mi(_sphere(0.025), Vector3(0.045, 0.44, 0.40), bob, "EyeR")
	# Soft cheek tufts (cranberry blush)
	_mi(_sphere(0.04, 0.035), Vector3(-0.12, 0.38, 0.28), bob, "CheekL")
	_mi(_sphere(0.04, 0.035), Vector3(0.12, 0.38, 0.28), bob, "CheekR")
	# Stubby lounge legs
	for info in [
		["FL", Vector3(-0.11, 0.16, 0.14)],
		["FR", Vector3(0.11, 0.16, 0.14)],
		["BL", Vector3(-0.12, 0.16, -0.14)],
		["BR", Vector3(0.12, 0.16, -0.14)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.032, 0.036, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.07, 0.02, 0.09)), Vector3(0, -0.09, 0.01), leg, "Foot")
	# Soft blunt tail
	var tail := _mi(_cyl(0.045, 0.028, 0.16), Vector3(0, 0.28, -0.30), bob, "Tail")
	tail.rotation_degrees = Vector3(40, 0, 0)
	_mi(_sphere(0.04), Vector3(0, 0.22, -0.42), bob, "TailTip")

static func _build_ram(bob: Node3D) -> void:
	## Soft raspberry-wilds ram — plump woolly body, curled spiral horns, short sturdy legs, soft fluff tuft (distinct from Cedar Stag / Magnolia Beaver / Cranberry Capybara / Blueberry Bunny).
	# Plump woolly barrel
	_mi(_sphere(0.24, 0.34), Vector3(0, 0.38, 0.0), bob, "Body")
	# Soft cream belly
	_mi(_sphere(0.13, 0.17), Vector3(0, 0.26, 0.06), bob, "Belly")
	# Round head + soft ears + blunt muzzle
	_mi(_sphere(0.14), Vector3(0, 0.48, 0.32), bob, "Head")
	_mi(_sphere(0.05, 0.06), Vector3(-0.09, 0.58, 0.28), bob, "EarL")
	_mi(_sphere(0.05, 0.06), Vector3(0.09, 0.58, 0.28), bob, "EarR")
	_mi(_box(Vector3(0.08, 0.06, 0.11)), Vector3(0, 0.42, 0.46), bob, "Snout")
	_mi(_sphere(0.03), Vector3(0, 0.41, 0.53), bob, "Nose")
	_mi(_sphere(0.026), Vector3(-0.05, 0.50, 0.42), bob, "EyeL")
	_mi(_sphere(0.026), Vector3(0.05, 0.50, 0.42), bob, "EyeR")
	# Curled spiral horns (signature — not branching antlers)
	var horn_l := Node3D.new()
	horn_l.name = "HornL"
	horn_l.position = Vector3(-0.10, 0.58, 0.26)
	horn_l.rotation_degrees = Vector3(15, -25, -35)
	bob.add_child(horn_l)
	_mi(_cyl(0.035, 0.028, 0.16), Vector3(0, 0.06, 0), horn_l, "CurlA")
	_mi(_cyl(0.028, 0.022, 0.12), Vector3(-0.04, 0.14, -0.02), horn_l, "CurlB")
	_mi(_sphere(0.03), Vector3(-0.06, 0.20, -0.04), horn_l, "HornTip")
	var horn_r := Node3D.new()
	horn_r.name = "HornR"
	horn_r.position = Vector3(0.10, 0.58, 0.26)
	horn_r.rotation_degrees = Vector3(15, 25, 35)
	bob.add_child(horn_r)
	_mi(_cyl(0.035, 0.028, 0.16), Vector3(0, 0.06, 0), horn_r, "CurlA")
	_mi(_cyl(0.028, 0.022, 0.12), Vector3(0.04, 0.14, -0.02), horn_r, "CurlB")
	_mi(_sphere(0.03), Vector3(0.06, 0.20, -0.04), horn_r, "HornTip")
	# Soft wool cheek tufts (raspberry blush)
	_mi(_sphere(0.045, 0.04), Vector3(-0.13, 0.44, 0.28), bob, "WoolL")
	_mi(_sphere(0.045, 0.04), Vector3(0.13, 0.44, 0.28), bob, "WoolR")
	# Short sturdy legs
	for info in [
		["FL", Vector3(-0.12, 0.18, 0.14)],
		["FR", Vector3(0.12, 0.18, 0.14)],
		["BL", Vector3(-0.13, 0.18, -0.14)],
		["BR", Vector3(0.13, 0.18, -0.14)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.036, 0.04, 0.14), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.08, 0.025, 0.10)), Vector3(0, -0.10, 0.01), leg, "Hoof")
	# Soft fluff tuft tail
	_mi(_sphere(0.08), Vector3(0, 0.34, -0.30), bob, "Tail")

static func _build_stoat(bob: Node3D) -> void:
	## Soft strawberry-wilds stoat — slender body, pointed snout, short rounded ears, long soft tail with dark tip tuft (distinct from Walnut Weasel / Pine Fox / Raspberry Ram / Blueberry Bunny).
	# Slender low body
	_mi(_sphere(0.13, 0.36), Vector3(0, 0.32, 0.02), bob, "Body")
	# Cream-strawberry belly
	_mi(_sphere(0.07, 0.22), Vector3(0, 0.24, 0.05), bob, "Belly")
	# Pointed head + soft rounded ears + blunt-pink snout
	_mi(_sphere(0.10, 0.12), Vector3(0, 0.38, 0.26), bob, "Head")
	_mi(_sphere(0.032, 0.04), Vector3(-0.05, 0.48, 0.24), bob, "EarL")
	_mi(_sphere(0.032, 0.04), Vector3(0.05, 0.48, 0.24), bob, "EarR")
	_mi(_box(Vector3(0.045, 0.035, 0.09)), Vector3(0, 0.34, 0.38), bob, "Snout")
	_mi(_sphere(0.022), Vector3(0, 0.33, 0.44), bob, "Nose")
	_mi(_sphere(0.022), Vector3(-0.04, 0.42, 0.32), bob, "EyeL")
	_mi(_sphere(0.022), Vector3(0.04, 0.42, 0.32), bob, "EyeR")
	# Soft cheek blush tufts (strawberry pink)
	_mi(_sphere(0.035, 0.03), Vector3(-0.10, 0.34, 0.24), bob, "BlushL")
	_mi(_sphere(0.035, 0.03), Vector3(0.10, 0.34, 0.24), bob, "BlushR")
	# Short dainty legs
	for info in [
		["FL", Vector3(-0.07, 0.14, 0.14)],
		["FR", Vector3(0.07, 0.14, 0.14)],
		["BL", Vector3(-0.07, 0.14, -0.12)],
		["BR", Vector3(0.07, 0.14, -0.12)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.014, 0.016, 0.10), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.04, 0.012, 0.05)), Vector3(0, -0.08, 0.01), leg, "Foot")
	# Long soft tail with dark tip tuft (stoat signature — not weasel bushy taper alone)
	var tail := _mi(_cyl(0.045, 0.022, 0.42), Vector3(0, 0.32, -0.34), bob, "Tail")
	tail.rotation_degrees = Vector3(48, 0, 0)
	_mi(_sphere(0.055, 0.07), Vector3(0, 0.38, -0.55), bob, "TailTip")

static func _build_bear(bob: Node3D) -> void:
	## Soft blackberry-wilds bear cub — plump round body, rounded ears, short snout, stubby fluff tail (distinct from Magnolia Beaver / Raspberry Ram / Strawberry Stoat / Blueberry Bunny).
	# Plump low body
	_mi(_sphere(0.22, 0.28), Vector3(0, 0.36, 0.0), bob, "Body")
	# Soft cream-lavender belly
	_mi(_sphere(0.12, 0.16), Vector3(0, 0.28, 0.06), bob, "Belly")
	# Round head + soft rounded ears + blunt snout
	_mi(_sphere(0.14, 0.15), Vector3(0, 0.58, 0.18), bob, "Head")
	_mi(_sphere(0.045, 0.05), Vector3(-0.09, 0.72, 0.14), bob, "EarL")
	_mi(_sphere(0.045, 0.05), Vector3(0.09, 0.72, 0.14), bob, "EarR")
	_mi(_box(Vector3(0.07, 0.05, 0.08)), Vector3(0, 0.52, 0.32), bob, "Snout")
	_mi(_sphere(0.028), Vector3(0, 0.51, 0.38), bob, "Nose")
	_mi(_sphere(0.028), Vector3(-0.05, 0.62, 0.26), bob, "EyeL")
	_mi(_sphere(0.028), Vector3(0.05, 0.62, 0.26), bob, "EyeR")
	# Soft cheek tufts (blackberry blush)
	_mi(_sphere(0.04, 0.035), Vector3(-0.13, 0.52, 0.16), bob, "BlushL")
	_mi(_sphere(0.04, 0.035), Vector3(0.13, 0.52, 0.16), bob, "BlushR")
	# Short sturdy cub legs
	for info in [
		["FL", Vector3(-0.10, 0.16, 0.12)],
		["FR", Vector3(0.10, 0.16, 0.12)],
		["BL", Vector3(-0.10, 0.16, -0.10)],
		["BR", Vector3(0.10, 0.16, -0.10)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.028, 0.032, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.06, 0.018, 0.07)), Vector3(0, -0.09, 0.01), leg, "Foot")
	# Stubby fluff tail
	_mi(_sphere(0.07, 0.08), Vector3(0, 0.34, -0.26), bob, "Tail")

static func _build_goat(bob: Node3D) -> void:
	## Soft guava-wilds goat — lean body, upswept horns, chin beard tuft, short upright tail fluff (distinct from Raspberry Ram / Blackberry Bear / Strawberry Stoat / Cranberry Capybara).
	# Lean body + soft cream belly
	_mi(_sphere(0.18, 0.26), Vector3(0, 0.40, 0.0), bob, "Body")
	_mi(_sphere(0.10, 0.14), Vector3(0, 0.30, 0.05), bob, "Belly")
	# Longish head + soft ears + blunt muzzle
	_mi(_sphere(0.11, 0.13), Vector3(0, 0.58, 0.22), bob, "Head")
	_mi(_sphere(0.035, 0.05), Vector3(-0.08, 0.68, 0.18), bob, "EarL")
	_mi(_sphere(0.035, 0.05), Vector3(0.08, 0.68, 0.18), bob, "EarR")
	_mi(_box(Vector3(0.06, 0.05, 0.10)), Vector3(0, 0.52, 0.36), bob, "Snout")
	_mi(_sphere(0.025), Vector3(0, 0.51, 0.42), bob, "Nose")
	_mi(_sphere(0.024), Vector3(-0.04, 0.62, 0.30), bob, "EyeL")
	_mi(_sphere(0.024), Vector3(0.04, 0.62, 0.30), bob, "EyeR")
	# Upswept horns (straight-ish — not ram spirals)
	var horn_l := _mi(_cyl(0.018, 0.012, 0.16), Vector3(-0.06, 0.74, 0.16), bob, "HornL")
	horn_l.rotation_degrees = Vector3(18, 0, -22)
	var horn_r := _mi(_cyl(0.018, 0.012, 0.16), Vector3(0.06, 0.74, 0.16), bob, "HornR")
	horn_r.rotation_degrees = Vector3(18, 0, 22)
	# Chin beard tuft (goat signature)
	_mi(_sphere(0.04, 0.06), Vector3(0, 0.44, 0.34), bob, "Beard")
	# Soft guava cheek blush
	_mi(_sphere(0.035, 0.03), Vector3(-0.11, 0.54, 0.18), bob, "BlushL")
	_mi(_sphere(0.035, 0.03), Vector3(0.11, 0.54, 0.18), bob, "BlushR")
	# Short sturdy legs
	for info in [
		["FL", Vector3(-0.09, 0.18, 0.12)],
		["FR", Vector3(0.09, 0.18, 0.12)],
		["BL", Vector3(-0.09, 0.18, -0.10)],
		["BR", Vector3(0.09, 0.18, -0.10)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.022, 0.026, 0.14), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.05, 0.016, 0.06)), Vector3(0, -0.10, 0.01), leg, "Foot")
	# Short upright fluff tail
	var tail := _mi(_cyl(0.03, 0.02, 0.12), Vector3(0, 0.42, -0.22), bob, "Tail")
	tail.rotation_degrees = Vector3(-35, 0, 0)
	_mi(_sphere(0.045, 0.05), Vector3(0, 0.50, -0.28), bob, "TailFluff")

static func _build_koala(bob: Node3D) -> void:
	## Soft kiwi-wilds koala — round plump body, big round ears, large soft nose, stubby limbs, cheek blush (distinct from Guava Goat / Blackberry Bear / Blueberry Bunny).
	# Plump round body + soft cream belly
	_mi(_sphere(0.22, 0.28), Vector3(0, 0.38, 0.0), bob, "Body")
	_mi(_sphere(0.12, 0.14), Vector3(0, 0.28, 0.06), bob, "Belly")
	# Round head + oversized round ears (koala signature)
	_mi(_sphere(0.14, 0.15), Vector3(0, 0.62, 0.12), bob, "Head")
	_mi(_sphere(0.07, 0.08), Vector3(-0.12, 0.74, 0.10), bob, "EarL")
	_mi(_sphere(0.07, 0.08), Vector3(0.12, 0.74, 0.10), bob, "EarR")
	_mi(_sphere(0.04, 0.045), Vector3(-0.12, 0.74, 0.12), bob, "EarInL")
	_mi(_sphere(0.04, 0.045), Vector3(0.12, 0.74, 0.12), bob, "EarInR")
	# Large soft nose (koala signature)
	_mi(_sphere(0.055, 0.045), Vector3(0, 0.58, 0.26), bob, "Nose")
	_mi(_sphere(0.022), Vector3(-0.045, 0.66, 0.22), bob, "EyeL")
	_mi(_sphere(0.022), Vector3(0.045, 0.66, 0.22), bob, "EyeR")
	# Soft kiwi cheek blush
	_mi(_sphere(0.04, 0.03), Vector3(-0.12, 0.56, 0.14), bob, "BlushL")
	_mi(_sphere(0.04, 0.03), Vector3(0.12, 0.56, 0.14), bob, "BlushR")
	# Stubby limbs
	for info in [
		["FL", Vector3(-0.10, 0.16, 0.10)],
		["FR", Vector3(0.10, 0.16, 0.10)],
		["BL", Vector3(-0.10, 0.16, -0.10)],
		["BR", Vector3(0.10, 0.16, -0.10)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.028, 0.032, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.06, 0.018, 0.07)), Vector3(0, -0.09, 0.01), leg, "Foot")
	# Soft fluff rump tuft (no long tail)
	_mi(_sphere(0.08, 0.09), Vector3(0, 0.36, -0.22), bob, "RumpTuft")

static func _build_mongoose(bob: Node3D) -> void:
	## Soft mango-wilds mongoose — long lean body, pointed snout, small rounded ears, long bushy tail, cheek blush (distinct from Kiwi Koala / Guava Goat / Strawberry Stoat / Walnut Weasel / Pine Fox).
	# Long lean body + soft cream belly
	_mi(_sphere(0.14, 0.32), Vector3(0, 0.34, 0.0), bob, "Body")
	_mi(_sphere(0.09, 0.12), Vector3(0, 0.28, 0.04), bob, "Belly")
	# Small head + pointed snout (mongoose signature)
	_mi(_sphere(0.10, 0.11), Vector3(0, 0.48, 0.22), bob, "Head")
	_mi(_sphere(0.05, 0.08), Vector3(0, 0.44, 0.34), bob, "Snout")
	_mi(_sphere(0.025, 0.02), Vector3(0, 0.44, 0.42), bob, "Nose")
	# Small rounded ears
	_mi(_sphere(0.035, 0.04), Vector3(-0.08, 0.56, 0.20), bob, "EarL")
	_mi(_sphere(0.035, 0.04), Vector3(0.08, 0.56, 0.20), bob, "EarR")
	_mi(_sphere(0.018), Vector3(-0.035, 0.52, 0.30), bob, "EyeL")
	_mi(_sphere(0.018), Vector3(0.035, 0.52, 0.30), bob, "EyeR")
	# Soft mango cheek blush
	_mi(_sphere(0.03, 0.025), Vector3(-0.09, 0.44, 0.24), bob, "BlushL")
	_mi(_sphere(0.03, 0.025), Vector3(0.09, 0.44, 0.24), bob, "BlushR")
	# Short sturdy legs
	for info in [
		["FL", Vector3(-0.08, 0.14, 0.12)],
		["FR", Vector3(0.08, 0.14, 0.12)],
		["BL", Vector3(-0.08, 0.14, -0.12)],
		["BR", Vector3(0.08, 0.14, -0.12)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.02, 0.024, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.045, 0.014, 0.055)), Vector3(0, -0.09, 0.01), leg, "Foot")
	# Long bushy tail (mongoose signature)
	var tail := _mi(_cyl(0.035, 0.018, 0.28), Vector3(0, 0.38, -0.28), bob, "Tail")
	tail.rotation_degrees = Vector3(55, 0, 0)
	_mi(_sphere(0.06, 0.07), Vector3(0, 0.52, -0.48), bob, "TailFluff")

static func _build_panda(bob: Node3D) -> void:
	## Soft papaya-wilds panda — plump round body, round ears, dark eye patches, short blunt snout, stubby limbs, cheek blush (distinct from Kiwi Koala / Blackberry Bear / Mango Mongoose / Cranberry Capybara).
	# Plump round body + soft cream belly
	_mi(_sphere(0.20, 0.26), Vector3(0, 0.36, 0.0), bob, "Body")
	_mi(_sphere(0.11, 0.13), Vector3(0, 0.26, 0.05), bob, "Belly")
	# Round head + medium round ears (panda signature — not oversized like koala)
	_mi(_sphere(0.13, 0.14), Vector3(0, 0.58, 0.10), bob, "Head")
	_mi(_sphere(0.055, 0.06), Vector3(-0.11, 0.70, 0.08), bob, "EarL")
	_mi(_sphere(0.055, 0.06), Vector3(0.11, 0.70, 0.08), bob, "EarR")
	# Dark eye patches (panda signature)
	_mi(_sphere(0.045, 0.035), Vector3(-0.055, 0.60, 0.20), bob, "PatchL")
	_mi(_sphere(0.045, 0.035), Vector3(0.055, 0.60, 0.20), bob, "PatchR")
	_mi(_sphere(0.020), Vector3(-0.05, 0.61, 0.24), bob, "EyeL")
	_mi(_sphere(0.020), Vector3(0.05, 0.61, 0.24), bob, "EyeR")
	# Short blunt snout
	_mi(_sphere(0.05, 0.045), Vector3(0, 0.52, 0.22), bob, "Snout")
	_mi(_sphere(0.022, 0.018), Vector3(0, 0.52, 0.28), bob, "Nose")
	# Soft papaya cheek blush
	_mi(_sphere(0.035, 0.028), Vector3(-0.11, 0.52, 0.12), bob, "BlushL")
	_mi(_sphere(0.035, 0.028), Vector3(0.11, 0.52, 0.12), bob, "BlushR")
	# Stubby limbs
	for info in [
		["FL", Vector3(-0.10, 0.15, 0.10)],
		["FR", Vector3(0.10, 0.15, 0.10)],
		["BL", Vector3(-0.10, 0.15, -0.10)],
		["BR", Vector3(0.10, 0.15, -0.10)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.026, 0.030, 0.11), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.055, 0.016, 0.065)), Vector3(0, -0.085, 0.01), leg, "Foot")
	# Soft fluff rump tuft
	_mi(_sphere(0.07, 0.08), Vector3(0, 0.34, -0.20), bob, "RumpTuft")

static func _build_crab(bob: Node3D) -> void:
	## Soft coconut-wilds crab — round coconut shell, stalk eyes, big soft claws, stubby walking legs, cheek blush (distinct from Cypress Turtle / Chestnut Toad / Grape Gecko / Sycamore Skink / Apricot Armadillo / Magnolia Beaver / Papaya Panda).
	# Round coconut shell body (signature)
	_mi(_sphere(0.22, 0.20), Vector3(0, 0.32, 0.0), bob, "Shell")
	_mi(_sphere(0.14, 0.10), Vector3(0, 0.28, 0.02), bob, "Belly")
	# Soft shell tuft / husk ridge
	_mi(_box(Vector3(0.16, 0.04, 0.10)), Vector3(0, 0.44, 0.0), bob, "HuskRidge")
	# Round head peeking forward
	_mi(_sphere(0.10, 0.09), Vector3(0, 0.36, 0.20), bob, "Head")
	# Stalk eyes (crab signature)
	var stalk_l := Node3D.new()
	stalk_l.name = "StalkL"
	stalk_l.position = Vector3(-0.06, 0.44, 0.22)
	bob.add_child(stalk_l)
	_mi(_cyl(0.012, 0.014, 0.10), Vector3(0, 0.04, 0), stalk_l, "StemL")
	_mi(_sphere(0.028), Vector3(0, 0.10, 0.01), stalk_l, "EyeL")
	var stalk_r := Node3D.new()
	stalk_r.name = "StalkR"
	stalk_r.position = Vector3(0.06, 0.44, 0.22)
	bob.add_child(stalk_r)
	_mi(_cyl(0.012, 0.014, 0.10), Vector3(0, 0.04, 0), stalk_r, "StemR")
	_mi(_sphere(0.028), Vector3(0, 0.10, 0.01), stalk_r, "EyeR")
	# Soft coconut cheek blush
	_mi(_sphere(0.03, 0.025), Vector3(-0.09, 0.32, 0.18), bob, "BlushL")
	_mi(_sphere(0.03, 0.025), Vector3(0.09, 0.32, 0.18), bob, "BlushR")
	# Big soft claws (signature — not combat-y)
	var claw_l := Node3D.new()
	claw_l.name = "ClawL"
	claw_l.position = Vector3(-0.22, 0.28, 0.14)
	bob.add_child(claw_l)
	_mi(_cyl(0.035, 0.04, 0.14), Vector3(0, 0, 0.02), claw_l, "ArmL")
	_mi(_box(Vector3(0.10, 0.06, 0.12)), Vector3(-0.02, 0.0, 0.12), claw_l, "PincerL")
	var claw_r := Node3D.new()
	claw_r.name = "ClawR"
	claw_r.position = Vector3(0.22, 0.28, 0.14)
	bob.add_child(claw_r)
	_mi(_cyl(0.035, 0.04, 0.14), Vector3(0, 0, 0.02), claw_r, "ArmR")
	_mi(_box(Vector3(0.10, 0.06, 0.12)), Vector3(0.02, 0.0, 0.12), claw_r, "PincerR")
	# Four stubby walking legs
	for info in [
		["FL", Vector3(-0.12, 0.16, 0.08)],
		["FR", Vector3(0.12, 0.16, 0.08)],
		["ML", Vector3(-0.14, 0.16, -0.02)],
		["MR", Vector3(0.14, 0.16, -0.02)],
		["BL", Vector3(-0.10, 0.16, -0.12)],
		["BR", Vector3(0.10, 0.16, -0.12)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.018, 0.022, 0.10), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.04, 0.014, 0.05)), Vector3(0, -0.08, 0.01), leg, "Foot")
	# Soft little tail flap
	_mi(_box(Vector3(0.10, 0.03, 0.08)), Vector3(0, 0.22, -0.22), bob, "TailFlap")

static func _build_llama(bob: Node3D) -> void:
	## Soft lime-wilds llama — long neck, banana ears, soft snout, fluffy chest, stubby legs, cheek blush (distinct from Guava Goat / Raspberry Ram / Coconut Crab / Papaya Panda / Kiwi Koala / Cranberry Capybara).
	# Plump body + soft cream belly
	_mi(_sphere(0.20, 0.28), Vector3(0, 0.42, 0.0), bob, "Body")
	_mi(_sphere(0.12, 0.16), Vector3(0, 0.32, 0.04), bob, "Belly")
	# Long neck (llama signature)
	var neck := _mi(_cyl(0.06, 0.055, 0.28), Vector3(0, 0.68, 0.10), bob, "Neck")
	neck.rotation_degrees = Vector3(18, 0, 0)
	# Oval head + banana ears + soft snout
	_mi(_sphere(0.11, 0.13), Vector3(0, 0.92, 0.22), bob, "Head")
	var ear_l := _mi(_box(Vector3(0.04, 0.10, 0.03)), Vector3(-0.10, 1.02, 0.18), bob, "EarL")
	ear_l.rotation_degrees = Vector3(10, 0, -25)
	var ear_r := _mi(_box(Vector3(0.04, 0.10, 0.03)), Vector3(0.10, 1.02, 0.18), bob, "EarR")
	ear_r.rotation_degrees = Vector3(10, 0, 25)
	_mi(_box(Vector3(0.07, 0.05, 0.10)), Vector3(0, 0.88, 0.34), bob, "Snout")
	_mi(_sphere(0.022), Vector3(0, 0.88, 0.40), bob, "Nose")
	_mi(_sphere(0.022), Vector3(-0.04, 0.96, 0.30), bob, "EyeL")
	_mi(_sphere(0.022), Vector3(0.04, 0.96, 0.30), bob, "EyeR")
	# Soft lime cheek blush
	_mi(_sphere(0.035, 0.03), Vector3(-0.11, 0.88, 0.20), bob, "BlushL")
	_mi(_sphere(0.035, 0.03), Vector3(0.11, 0.88, 0.20), bob, "BlushR")
	# Fluffy chest tuft
	_mi(_sphere(0.08, 0.09), Vector3(0, 0.50, 0.18), bob, "ChestFluff")
	# Four stubby legs
	for info in [
		["FL", Vector3(-0.10, 0.18, 0.12)],
		["FR", Vector3(0.10, 0.18, 0.12)],
		["BL", Vector3(-0.10, 0.18, -0.12)],
		["BR", Vector3(0.10, 0.18, -0.12)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.024, 0.028, 0.14), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.05, 0.016, 0.06)), Vector3(0, -0.10, 0.01), leg, "Foot")
	# Soft little fluff tail
	var tail := _mi(_cyl(0.03, 0.02, 0.10), Vector3(0, 0.44, -0.24), bob, "Tail")
	tail.rotation_degrees = Vector3(-40, 0, 0)
	_mi(_sphere(0.05, 0.055), Vector3(0, 0.50, -0.30), bob, "TailFluff")

static func _build_moose(bob: Node3D) -> void:
	## Soft melon-wilds moose — bulky body, long snout, palmate antlers, dewlap, stubby legs, cheek blush (distinct from Cedar Stag / Raspberry Ram / Guava Goat / Lime Llama / Blackberry Bear).
	# Bulky body + soft cream belly
	_mi(_sphere(0.26, 0.32), Vector3(0, 0.48, 0.0), bob, "Body")
	_mi(_sphere(0.14, 0.18), Vector3(0, 0.36, 0.06), bob, "Belly")
	# Thick neck + oval head + long soft snout
	var neck := _mi(_cyl(0.08, 0.07, 0.22), Vector3(0, 0.72, 0.14), bob, "Neck")
	neck.rotation_degrees = Vector3(22, 0, 0)
	_mi(_sphere(0.13, 0.14), Vector3(0, 0.92, 0.28), bob, "Head")
	_mi(_box(Vector3(0.09, 0.07, 0.16)), Vector3(0, 0.86, 0.42), bob, "Snout")
	_mi(_sphere(0.028), Vector3(0, 0.86, 0.52), bob, "Nose")
	_mi(_sphere(0.024), Vector3(-0.05, 0.96, 0.34), bob, "EyeL")
	_mi(_sphere(0.024), Vector3(0.05, 0.96, 0.34), bob, "EyeR")
	# Soft rounded ears
	var ear_l := _mi(_sphere(0.05, 0.06), Vector3(-0.12, 1.02, 0.24), bob, "EarL")
	ear_l.rotation_degrees = Vector3(0, 0, -18)
	var ear_r := _mi(_sphere(0.05, 0.06), Vector3(0.12, 1.02, 0.24), bob, "EarR")
	ear_r.rotation_degrees = Vector3(0, 0, 18)
	# Soft melon cheek blush
	_mi(_sphere(0.04, 0.032), Vector3(-0.12, 0.88, 0.26), bob, "BlushL")
	_mi(_sphere(0.04, 0.032), Vector3(0.12, 0.88, 0.26), bob, "BlushR")
	# Palmate antlers (moose signature — broader than Cedar Stag points)
	var ant_l := _mi(_box(Vector3(0.18, 0.04, 0.10)), Vector3(-0.16, 1.10, 0.22), bob, "AntlerL")
	ant_l.rotation_degrees = Vector3(8, 15, -20)
	_mi(_box(Vector3(0.06, 0.03, 0.08)), Vector3(-0.24, 1.14, 0.18), bob, "PalmL")
	var ant_r := _mi(_box(Vector3(0.18, 0.04, 0.10)), Vector3(0.16, 1.10, 0.22), bob, "AntlerR")
	ant_r.rotation_degrees = Vector3(8, -15, 20)
	_mi(_box(Vector3(0.06, 0.03, 0.08)), Vector3(0.24, 1.14, 0.18), bob, "PalmR")
	# Soft dewlap under chin
	_mi(_sphere(0.06, 0.08), Vector3(0, 0.72, 0.28), bob, "Dewlap")
	# Four sturdy stubby legs
	for info in [
		["FL", Vector3(-0.12, 0.22, 0.14)],
		["FR", Vector3(0.12, 0.22, 0.14)],
		["BL", Vector3(-0.12, 0.22, -0.14)],
		["BR", Vector3(0.12, 0.22, -0.14)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.032, 0.036, 0.18), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.06, 0.02, 0.08)), Vector3(0, -0.12, 0.01), leg, "Hoof")
	# Soft little fluff tail
	var tail := _mi(_cyl(0.035, 0.025, 0.10), Vector3(0, 0.50, -0.28), bob, "Tail")
	tail.rotation_degrees = Vector3(-35, 0, 0)
	_mi(_sphere(0.055, 0.06), Vector3(0, 0.56, -0.34), bob, "TailFluff")

static func _build_quokka(bob: Node3D) -> void:
	## Soft quince-wilds quokka — plump round body, short thick tail, small rounded ears, blunt snout, stubby legs, cheek blush (distinct from Kiwi Koala / Palm Pika / Blueberry Bunny / Lemon Lemming / Cherry Chinchilla / Melon Moose).
	# Plump round body + soft cream belly
	_mi(_sphere(0.20, 0.24), Vector3(0, 0.34, 0.0), bob, "Body")
	_mi(_sphere(0.11, 0.13), Vector3(0, 0.26, 0.05), bob, "Belly")
	# Round head + small rounded ears (quokka signature — smaller than koala)
	_mi(_sphere(0.12, 0.13), Vector3(0, 0.56, 0.12), bob, "Head")
	_mi(_sphere(0.045, 0.05), Vector3(-0.10, 0.66, 0.10), bob, "EarL")
	_mi(_sphere(0.045, 0.05), Vector3(0.10, 0.66, 0.10), bob, "EarR")
	# Soft blunt snout (quokka smile silhouette)
	_mi(_sphere(0.055, 0.06), Vector3(0, 0.52, 0.24), bob, "Snout")
	_mi(_sphere(0.022, 0.018), Vector3(0, 0.52, 0.30), bob, "Nose")
	_mi(_sphere(0.02), Vector3(-0.04, 0.60, 0.22), bob, "EyeL")
	_mi(_sphere(0.02), Vector3(0.04, 0.60, 0.22), bob, "EyeR")
	# Soft quince cheek blush
	_mi(_sphere(0.035, 0.028), Vector3(-0.10, 0.50, 0.16), bob, "BlushL")
	_mi(_sphere(0.035, 0.028), Vector3(0.10, 0.50, 0.16), bob, "BlushR")
	# Stubby legs
	for info in [
		["FL", Vector3(-0.09, 0.14, 0.10)],
		["FR", Vector3(0.09, 0.14, 0.10)],
		["BL", Vector3(-0.09, 0.14, -0.10)],
		["BR", Vector3(0.09, 0.14, -0.10)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.026, 0.03, 0.12), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.055, 0.016, 0.065)), Vector3(0, -0.09, 0.01), leg, "Foot")
	# Short thick quokka tail (signature — not a long bushy mongoose tail)
	var tail := _mi(_cyl(0.04, 0.03, 0.12), Vector3(0, 0.32, -0.22), bob, "Tail")
	tail.rotation_degrees = Vector3(25, 0, 0)
	_mi(_sphere(0.05, 0.055), Vector3(0, 0.34, -0.30), bob, "TailTip")

static func _build_wallaby(bob: Node3D) -> void:
	## Soft watermelon-wilds wallaby — upright oval body, long powerful hind legs, short forepaws, pointed upright ears, long tapering tail, cheek blush (distinct from Quince Quokka / Kiwi Koala / Palm Pika / Blueberry Bunny / Lemon Lemming / Melon Moose).
	# Upright oval body + soft pink-cream belly (watermelon flesh hint)
	_mi(_sphere(0.16, 0.28), Vector3(0, 0.42, 0.0), bob, "Body")
	_mi(_sphere(0.09, 0.14), Vector3(0, 0.34, 0.06), bob, "Belly")
	# Round head + pointed upright ears (wallaby signature — taller than quokka)
	_mi(_sphere(0.11, 0.12), Vector3(0, 0.68, 0.10), bob, "Head")
	var ear_l := _mi(_cyl(0.025, 0.018, 0.12), Vector3(-0.08, 0.82, 0.08), bob, "EarL")
	ear_l.rotation_degrees = Vector3(12, 0, -18)
	var ear_r := _mi(_cyl(0.025, 0.018, 0.12), Vector3(0.08, 0.82, 0.08), bob, "EarR")
	ear_r.rotation_degrees = Vector3(12, 0, 18)
	# Soft blunt snout
	_mi(_sphere(0.05, 0.055), Vector3(0, 0.64, 0.22), bob, "Snout")
	_mi(_sphere(0.02, 0.016), Vector3(0, 0.64, 0.28), bob, "Nose")
	_mi(_sphere(0.018), Vector3(-0.035, 0.72, 0.18), bob, "EyeL")
	_mi(_sphere(0.018), Vector3(0.035, 0.72, 0.18), bob, "EyeR")
	# Soft watermelon cheek blush
	_mi(_sphere(0.032, 0.026), Vector3(-0.09, 0.62, 0.14), bob, "BlushL")
	_mi(_sphere(0.032, 0.026), Vector3(0.09, 0.62, 0.14), bob, "BlushR")
	# Short forepaws
	for info in [
		["FL", Vector3(-0.08, 0.36, 0.10)],
		["FR", Vector3(0.08, 0.36, 0.10)],
	]:
		var paw := Node3D.new()
		paw.name = "Leg" + str(info[0])
		paw.position = info[1]
		bob.add_child(paw)
		_mi(_cyl(0.022, 0.026, 0.10), Vector3(0, -0.02, 0), paw, "Shin")
		_mi(_box(Vector3(0.045, 0.014, 0.05)), Vector3(0, -0.08, 0.01), paw, "Foot")
	# Long powerful hind legs (wallaby signature hoppers)
	for info in [
		["BL", Vector3(-0.09, 0.28, -0.06)],
		["BR", Vector3(0.09, 0.28, -0.06)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.035, 0.04, 0.22), Vector3(0, -0.06, 0.02), leg, "Thigh")
		_mi(_cyl(0.028, 0.032, 0.16), Vector3(0, -0.20, 0.04), leg, "Shin")
		_mi(_box(Vector3(0.07, 0.02, 0.10)), Vector3(0, -0.30, 0.06), leg, "Foot")
	# Long tapering wallaby tail (signature — not short quokka stub)
	var tail := _mi(_cyl(0.045, 0.02, 0.36), Vector3(0, 0.30, -0.28), bob, "Tail")
	tail.rotation_degrees = Vector3(40, 0, 0)
	_mi(_sphere(0.03, 0.035), Vector3(0, 0.18, -0.48), bob, "TailTip")

static func _build_hamster(bob: Node3D) -> void:
	## Soft honeydew-wilds hamster — plump round body, full cheek pouches, small rounded ears, stubby tail, soft paws, cheek blush (distinct from Maple Mouse / Lemon Lemming / Cherry Chinchilla / Palm Pika / Blueberry Bunny / Quince Quokka / Watermelon Wallaby).
	# Plump round body + soft cream belly (honeydew flesh hint)
	_mi(_sphere(0.17, 0.18), Vector3(0, 0.32, 0.0), bob, "Body")
	_mi(_sphere(0.10, 0.09), Vector3(0, 0.26, 0.06), bob, "Belly")
	# Round head + small rounded ears (hamster signature — not oversized chinchilla ears)
	_mi(_sphere(0.12), Vector3(0, 0.48, 0.06), bob, "Head")
	_mi(_sphere(0.045, 0.02), Vector3(-0.09, 0.58, -0.01), bob, "EarL")
	_mi(_sphere(0.045, 0.02), Vector3(0.09, 0.58, -0.01), bob, "EarR")
	_mi(_sphere(0.022, 0.01), Vector3(-0.09, 0.58, 0.01), bob, "EarInnerL")
	_mi(_sphere(0.022, 0.01), Vector3(0.09, 0.58, 0.01), bob, "EarInnerR")
	# Soft eyes
	_mi(_sphere(0.022), Vector3(-0.04, 0.50, 0.15), bob, "EyeL")
	_mi(_sphere(0.022), Vector3(0.04, 0.50, 0.15), bob, "EyeR")
	_mi(_sphere(0.009), Vector3(-0.04, 0.505, 0.165), bob, "PupilL")
	_mi(_sphere(0.009), Vector3(0.04, 0.505, 0.165), bob, "PupilR")
	# Short blunt snout
	_mi(_sphere(0.035, 0.028), Vector3(0, 0.44, 0.16), bob, "Snout")
	_mi(_sphere(0.012, 0.01), Vector3(0, 0.445, 0.19), bob, "Nose")
	# Full cheek pouches (hamster signature)
	_mi(_sphere(0.055, 0.048), Vector3(-0.11, 0.44, 0.08), bob, "CheekL")
	_mi(_sphere(0.055, 0.048), Vector3(0.11, 0.44, 0.08), bob, "CheekR")
	# Soft honeydew cheek blush
	_mi(_sphere(0.028, 0.022), Vector3(-0.10, 0.40, 0.12), bob, "BlushL")
	_mi(_sphere(0.028, 0.022), Vector3(0.10, 0.40, 0.12), bob, "BlushR")
	# Soft stubby paws
	for info in [
		["FL", Vector3(-0.07, 0.14, 0.07)],
		["FR", Vector3(0.07, 0.14, 0.07)],
		["BL", Vector3(-0.07, 0.14, -0.05)],
		["BR", Vector3(0.07, 0.14, -0.05)],
	]:
		var leg := Node3D.new()
		leg.name = "Leg" + str(info[0])
		leg.position = info[1]
		bob.add_child(leg)
		_mi(_cyl(0.016, 0.018, 0.09), Vector3(0, -0.02, 0), leg, "Shin")
		_mi(_box(Vector3(0.034, 0.012, 0.038)), Vector3(0, -0.065, 0.01), leg, "Foot")
	# Stubby hamster tail (signature — short, not bushy / not long wallaby)
	var tail := _mi(_cyl(0.025, 0.012, 0.08), Vector3(0, 0.28, -0.14), bob, "Tail")
	tail.rotation_degrees = Vector3(55, 0, 0)
	_mi(_sphere(0.02), Vector3(0, 0.22, -0.20), bob, "TailTip")

