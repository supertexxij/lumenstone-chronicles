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

	# Accessory (chest charm / belt pouch / lantern) — hidden until equipped
	var accessory := Node3D.new()
	accessory.name = "Accessory"
	accessory.visible = false
	accessory.position = Vector3(0.0, 1.05, 0.22)
	bob.add_child(accessory)
	var acc_body := _mi(_sphere(0.11), Vector3(0, 0, 0), accessory, "AccBody")
	var acc_glow := _mi(_sphere(0.06), Vector3(0, 0.08, 0.04), accessory, "AccGlow")
	var acc_strap := _mi(_box(Vector3(0.08, 0.22, 0.04)), Vector3(0, 0.16, -0.02), accessory, "AccStrap")

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
		"accessory": accessory,
		"acc_body": acc_body,
		"acc_glow": acc_glow,
		"acc_strap": acc_strap,
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


## Style accessory mesh from item id/name heuristics (lantern, pin, beads, pouch, scroll…).
static func style_accessory(parts: Dictionary, item: Dictionary) -> void:
	var root: Node3D = parts.get("accessory")
	if root == null:
		return
	var iid: String = str(item.get("id", "")).to_lower()
	var name: String = str(item.get("name", "")).to_lower()
	var col := Color(item.get("color", "#c9a227"))
	var body: MeshInstance3D = parts.get("acc_body")
	var glow: MeshInstance3D = parts.get("acc_glow")
	var strap: MeshInstance3D = parts.get("acc_strap")
	set_color(body, col)
	set_color(glow, col.lightened(0.35), 0.3)
	set_color(strap, col.darkened(0.25))
	if "lantern" in iid or "lantern" in name:
		root.position = Vector3(0.38, 0.85, 0.12)
		if body and body.mesh is SphereMesh:
			pass
		# Swap to box-ish lantern look via scale
		if body:
			body.scale = Vector3(0.7, 1.1, 0.7)
		if glow:
			glow.visible = true
			glow.scale = Vector3.ONE
	elif "bead" in iid or "prayer" in name:
		root.position = Vector3(0, 1.38, 0.18)
		if body:
			body.scale = Vector3(1.4, 0.45, 1.4)
		if glow:
			glow.visible = false
	elif "pin" in iid or "star" in name or "badge" in name:
		root.position = Vector3(0.18, 1.15, 0.18)
		if body:
			body.scale = Vector3(0.9, 0.35, 0.9)
		if glow:
			glow.visible = true
			glow.scale = Vector3(0.6, 0.6, 0.6)
	elif "scroll" in iid or "notebook" in name or "bookmark" in name or "map" in name:
		root.position = Vector3(-0.32, 0.95, 0.1)
		if body:
			body.scale = Vector3(0.55, 1.4, 0.35)
		if glow:
			glow.visible = false
	else:
		# Generic charm / purse at belt
		root.position = Vector3(0.28, 0.78, 0.14)
		if body:
			body.scale = Vector3(1.0, 0.9, 1.0)
		if glow:
			glow.visible = true
			glow.scale = Vector3(0.7, 0.7, 0.7)
	if strap:
		strap.visible = "lantern" in iid or "purse" in iid or "pouch" in name



## Rebuild weapon child meshes to match item mesh style (sword/axe/staff/bow/dagger/mallet).
static func style_weapon(parts: Dictionary, item: Dictionary) -> void:
	var weapon: Node3D = parts.get("weapon")
	if weapon == null:
		return
	# Clear prior mesh children
	for c in weapon.get_children():
		weapon.remove_child(c)
		c.free()
	var mesh_style: String = str(item.get("mesh", "sword")).to_lower()
	var iid: String = str(item.get("id", "")).to_lower()
	var name: String = str(item.get("name", "")).to_lower()
	if "axe" in mesh_style or "axe" in iid or "axe" in name:
		mesh_style = "axe"
	elif "staff" in mesh_style or "staff" in iid or "staff" in name:
		mesh_style = "staff"
	elif "bow" in mesh_style or "bow" in iid or "bow" in name:
		mesh_style = "bow"
	elif "dagger" in mesh_style or "dagger" in iid or "knife" in name:
		mesh_style = "dagger"
	elif "mallet" in mesh_style or "mallet" in iid or "hammer" in name:
		mesh_style = "mallet"
	else:
		mesh_style = "sword"

	var blade: MeshInstance3D
	var hilt: MeshInstance3D
	var pommel: MeshInstance3D
	match mesh_style:
		"axe":
			# Haft + axe head
			blade = _mi(_box(Vector3(0.10, 0.78, 0.10)), Vector3(0, 0.12, 0), weapon, "Blade")
			hilt = _mi(_box(Vector3(0.42, 0.22, 0.12)), Vector3(0.18, 0.42, 0), weapon, "Hilt")
			pommel = _mi(_sphere(0.07), Vector3(0, -0.30, 0), weapon, "Pommel")
			weapon.position = Vector3(0.42, 0.85, 0.05)
			weapon.rotation_degrees = Vector3(0, 0, -22)
		"staff":
			blade = _mi(_cyl(0.05, 0.06, 1.35), Vector3(0, 0.35, 0), weapon, "Blade")
			hilt = _mi(_sphere(0.09), Vector3(0, 1.0, 0), weapon, "Hilt")
			pommel = _mi(_cyl(0.07, 0.07, 0.08), Vector3(0, -0.28, 0), weapon, "Pommel")
			weapon.position = Vector3(0.38, 0.55, -0.05)
			weapon.rotation_degrees = Vector3(8, 0, -8)
		"bow":
			# Simple recurve silhouette (cosmetic)
			blade = _mi(_box(Vector3(0.06, 0.95, 0.08)), Vector3(0, 0.2, 0), weapon, "Blade")
			hilt = _mi(_box(Vector3(0.05, 0.55, 0.05)), Vector3(0.18, 0.2, 0), weapon, "Hilt")
			pommel = _mi(_box(Vector3(0.04, 0.04, 0.35)), Vector3(0.09, 0.55, 0), weapon, "Pommel")
			weapon.position = Vector3(0.36, 0.95, -0.08)
			weapon.rotation_degrees = Vector3(0, 15, -5)
		"dagger":
			blade = _mi(_box(Vector3(0.07, 0.38, 0.07)), Vector3(0, 0.05, 0), weapon, "Blade")
			hilt = _mi(_box(Vector3(0.16, 0.06, 0.07)), Vector3(0, -0.14, 0), weapon, "Hilt")
			pommel = _mi(_sphere(0.05), Vector3(0, -0.22, 0), weapon, "Pommel")
			weapon.position = Vector3(0.40, 0.88, 0.08)
			weapon.rotation_degrees = Vector3(0, 0, -25)
		"mallet":
			blade = _mi(_box(Vector3(0.12, 0.55, 0.12)), Vector3(0, 0.1, 0), weapon, "Blade")
			hilt = _mi(_box(Vector3(0.28, 0.22, 0.22)), Vector3(0, 0.42, 0), weapon, "Hilt")
			pommel = _mi(_sphere(0.07), Vector3(0, -0.22, 0), weapon, "Pommel")
			weapon.position = Vector3(0.42, 0.82, 0.06)
			weapon.rotation_degrees = Vector3(0, 0, -20)
		_:
			blade = _mi(_box(Vector3(0.08, 0.72, 0.08)), Vector3(0, 0.15, 0), weapon, "Blade")
			hilt = _mi(_box(Vector3(0.18, 0.08, 0.08)), Vector3(0, -0.22, 0), weapon, "Hilt")
			pommel = _mi(_sphere(0.06), Vector3(0, -0.32, 0), weapon, "Pommel")
			weapon.position = Vector3(0.42, 0.85, 0.05)
			weapon.rotation_degrees = Vector3(0, 0, -18)

	parts["blade"] = blade
	parts["hilt"] = hilt
	parts["pommel"] = pommel
	parts["weapon_mesh"] = mesh_style

	var col := Color(item.get("color", "#a67c52"))
	set_color(blade, col)
	set_color(hilt, col.darkened(0.25))
	set_color(pommel, col.lightened(0.15))
