class_name HumanoidBuilder
extends RefCounted
## Chunky RuneScape-style humanoid from MeshInstance3D primitives.
## Kid-readable proportions: clear head, torso, arms, legs, feet.

static func make_mat(c: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = roughness
	return mat


static func set_color(mi: MeshInstance3D, c: Color, roughness: float = 0.85) -> void:
	if mi == null:
		return
	mi.material_override = make_mat(c, roughness)


static func _mi(mesh: Mesh, pos: Vector3, parent: Node3D, name: String) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = name
	n.mesh = mesh
	n.position = pos
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


## Clears visual children of root and builds a full humanoid.
## Returns named part refs for coloring / equipment / animation.
static func build(root: Node3D) -> Dictionary:
	for c in root.get_children():
		c.queue_free()
	# Wait a frame isn't possible here — free immediately for rebuilds in editor/runtime
	for c in root.get_children():
		root.remove_child(c)
		c.free()

	var bob := Node3D.new()
	bob.name = "BodyBob"
	root.add_child(bob)

	# --- Core ---
	var torso := _mi(_box(Vector3(0.52, 0.62, 0.32)), Vector3(0, 1.05, 0), bob, "Torso")
	var pelvis := _mi(_box(Vector3(0.48, 0.22, 0.30)), Vector3(0, 0.68, 0), bob, "Pelvis")
	var neck := _mi(_cyl(0.10, 0.12, 0.12), Vector3(0, 1.42, 0), bob, "Neck")
	var head := _mi(_sphere(0.28), Vector3(0, 1.62, 0), bob, "Head")
	var hair := _mi(_sphere(0.30, 0.42), Vector3(0, 1.78, -0.02), bob, "Hair")

	# Hat (explorer-style brim + crown) — hidden until equipped
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.visible = false
	hat.position = Vector3(0, 1.88, 0)
	bob.add_child(hat)
	var hat_crown := _mi(_cyl(0.22, 0.24, 0.22), Vector3(0, 0.08, 0), hat, "HatCrown")
	var hat_brim := _mi(_cyl(0.38, 0.38, 0.04), Vector3(0, -0.02, 0), hat, "HatBrim")

	# Cape on back
	var cape := _mi(_box(Vector3(0.62, 0.85, 0.08)), Vector3(0, 1.05, -0.22), bob, "Cape")

	# Belt around waist
	var belt := _mi(_box(Vector3(0.54, 0.10, 0.34)), Vector3(0, 0.72, 0), bob, "Belt")
	belt.visible = false

	# Weapon at right hip (sheathed look)
	var weapon := Node3D.new()
	weapon.name = "Weapon"
	weapon.visible = false
	weapon.position = Vector3(0.42, 0.85, 0.05)
	weapon.rotation_degrees = Vector3(0, 0, -18)
	bob.add_child(weapon)
	var blade := _mi(_box(Vector3(0.08, 0.72, 0.08)), Vector3(0, 0.15, 0), weapon, "Blade")
	var hilt := _mi(_box(Vector3(0.18, 0.08, 0.08)), Vector3(0, -0.22, 0), weapon, "Hilt")
	var pommel := _mi(_sphere(0.06), Vector3(0, -0.32, 0), weapon, "Pommel")

	# --- Arms (pivots at shoulders for swing) ---
	var l_arm := Node3D.new()
	l_arm.name = "LArm"
	l_arm.position = Vector3(-0.34, 1.28, 0)
	bob.add_child(l_arm)
	var l_upper := _mi(_capsule(0.09, 0.38), Vector3(-0.06, -0.16, 0), l_arm, "LUpperArm")
	var l_lower := _mi(_capsule(0.08, 0.34), Vector3(-0.08, -0.48, 0), l_arm, "LLowerArm")
	var l_hand := _mi(_sphere(0.09), Vector3(-0.08, -0.70, 0), l_arm, "LHand")

	var r_arm := Node3D.new()
	r_arm.name = "RArm"
	r_arm.position = Vector3(0.34, 1.28, 0)
	bob.add_child(r_arm)
	var r_upper := _mi(_capsule(0.09, 0.38), Vector3(0.06, -0.16, 0), r_arm, "RUpperArm")
	var r_lower := _mi(_capsule(0.08, 0.34), Vector3(0.08, -0.48, 0), r_arm, "RLowerArm")
	var r_hand := _mi(_sphere(0.09), Vector3(0.08, -0.70, 0), r_arm, "RHand")

	# --- Legs (pivots at hips) ---
	var l_leg := Node3D.new()
	l_leg.name = "LLeg"
	l_leg.position = Vector3(-0.14, 0.58, 0)
	bob.add_child(l_leg)
	var l_thigh := _mi(_capsule(0.11, 0.36), Vector3(0, -0.16, 0), l_leg, "LUpperLeg")
	var l_shin := _mi(_capsule(0.09, 0.32), Vector3(0, -0.48, 0), l_leg, "LLowerLeg")
	var l_foot := _mi(_box(Vector3(0.16, 0.10, 0.28)), Vector3(0, -0.68, 0.04), l_leg, "LFoot")

	var r_leg := Node3D.new()
	r_leg.name = "RLeg"
	r_leg.position = Vector3(0.14, 0.58, 0)
	bob.add_child(r_leg)
	var r_thigh := _mi(_capsule(0.11, 0.36), Vector3(0, -0.16, 0), r_leg, "RUpperLeg")
	var r_shin := _mi(_capsule(0.09, 0.32), Vector3(0, -0.48, 0), r_leg, "RLowerLeg")
	var r_foot := _mi(_box(Vector3(0.16, 0.10, 0.28)), Vector3(0, -0.68, 0.04), r_leg, "RFoot")

	return {
		"bob": bob,
		"torso": torso,
		"pelvis": pelvis,
		"neck": neck,
		"head": head,
		"hair": hair,
		"hat": hat,
		"hat_crown": hat_crown,
		"hat_brim": hat_brim,
		"cape": cape,
		"belt": belt,
		"weapon": weapon,
		"blade": blade,
		"hilt": hilt,
		"pommel": pommel,
		"l_arm": l_arm,
		"r_arm": r_arm,
		"l_leg": l_leg,
		"r_leg": r_leg,
		"l_hand": l_hand,
		"r_hand": r_hand,
		"l_foot": l_foot,
		"r_foot": r_foot,
		"l_upper": l_upper,
		"r_upper": r_upper,
		"l_lower": l_lower,
		"r_lower": r_lower,
		"l_thigh": l_thigh,
		"r_thigh": r_thigh,
		"l_shin": l_shin,
		"r_shin": r_shin,
	}


## Apply player-style colors: skin on exposed parts, outfit on clothes, etc.
static func apply_human_colors(parts: Dictionary, skin: Color, hair: Color, outfit: Color, cape_col: Color, shoe: Color = Color("#3b2f2f")) -> void:
	set_color(parts.get("head"), skin)
	set_color(parts.get("neck"), skin)
	set_color(parts.get("hair"), hair)
	set_color(parts.get("torso"), outfit)
	set_color(parts.get("pelvis"), outfit.darkened(0.08))
	# Arms: sleeves (outfit) + hands (skin)
	set_color(parts.get("l_upper"), outfit)
	set_color(parts.get("r_upper"), outfit)
	set_color(parts.get("l_lower"), outfit.lightened(0.05))
	set_color(parts.get("r_lower"), outfit.lightened(0.05))
	set_color(parts.get("l_hand"), skin)
	set_color(parts.get("r_hand"), skin)
	# Legs / feet
	set_color(parts.get("l_thigh"), outfit.darkened(0.12))
	set_color(parts.get("r_thigh"), outfit.darkened(0.12))
	set_color(parts.get("l_shin"), outfit.darkened(0.18))
	set_color(parts.get("r_shin"), outfit.darkened(0.18))
	set_color(parts.get("l_foot"), shoe)
	set_color(parts.get("r_foot"), shoe)
	set_color(parts.get("cape"), cape_col)


static func apply_npc_colors(parts: Dictionary, accent: Color, skin: Color = Color("#c68642")) -> void:
	var outfit := accent
	var hair := accent.darkened(0.35)
	apply_human_colors(parts, skin, hair, outfit, accent.darkened(0.2))
	# NPCs show a small cape stub in accent
	var cape: MeshInstance3D = parts.get("cape")
	if cape:
		cape.visible = true
