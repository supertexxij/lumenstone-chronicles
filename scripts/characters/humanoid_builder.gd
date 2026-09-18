class_name HumanoidBuilder
extends RefCounted
## Chunky RuneScape-style humanoid from MeshInstance3D primitives.
## Kid-readable proportions: face, head, torso, shoulders, arms with elbows, legs with knees, feet.

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

	# --- Core (v1.80 world: chunky RS clothing silhouette that reads from the elevated camera) ---
	var torso := _mi(_box(Vector3(0.54, 0.58, 0.32)), Vector3(0, 1.16, 0), bob, "Torso")
	var pelvis := _mi(_box(Vector3(0.50, 0.20, 0.30)), Vector3(0, 0.80, 0), bob, "Pelvis")
	var hem := _mi(_box(Vector3(0.64, 0.18, 0.38)), Vector3(0, 0.74, 0.02), bob, "Hem")
	# Soft skirt overlay for girl silhouette — hidden until apply_gender("girl").
	var skirt := _mi(_cyl(0.22, 0.48, 0.46), Vector3(0, 0.52, 0.02), bob, "Skirt")
	skirt.visible = false
	var neck := _mi(_cyl(0.09, 0.11, 0.14), Vector3(0, 1.52, 0), bob, "Neck")
	var collar := _mi(_cyl(0.16, 0.18, 0.08), Vector3(0, 1.46, 0.02), bob, "Collar")
	var head := _mi(_sphere(0.23), Vector3(0, 1.72, 0.02), bob, "Head")
	# Hair sits back so the face stays visible from the RuneScape camera.
	var hair := _mi(_sphere(0.25, 0.34), Vector3(0, 1.86, -0.06), bob, "Hair")
	var bangs := _mi(_box(Vector3(0.30, 0.10, 0.08)), Vector3(0, 1.88, 0.14), bob, "Bangs")
	# Optional hair-style parts (toggled by apply_hair_style).
	var hair_long := _mi(_sphere(0.24, 0.62), Vector3(0, 1.48, -0.16), bob, "HairLong")
	hair_long.visible = false
	var hair_l_lock := _mi(_capsule(0.055, 0.38), Vector3(-0.20, 1.52, 0.08), bob, "HairLLock")
	hair_l_lock.rotation_degrees = Vector3(18, 0, 22)
	hair_l_lock.visible = false
	var hair_r_lock := _mi(_capsule(0.055, 0.38), Vector3(0.20, 1.52, 0.08), bob, "HairRLock")
	hair_r_lock.rotation_degrees = Vector3(18, 0, -22)
	hair_r_lock.visible = false
	var hair_wave_l := _mi(_sphere(0.12, 0.22), Vector3(-0.22, 1.78, 0.0), bob, "HairWaveL")
	hair_wave_l.visible = false
	var hair_wave_r := _mi(_sphere(0.12, 0.22), Vector3(0.22, 1.78, 0.0), bob, "HairWaveR")
	hair_wave_r.visible = false
	var hair_spike_l := _mi(_box(Vector3(0.08, 0.18, 0.08)), Vector3(-0.10, 2.02, -0.02), bob, "HairSpikeL")
	hair_spike_l.rotation_degrees = Vector3(0, 0, -18)
	hair_spike_l.visible = false
	var hair_spike_m := _mi(_box(Vector3(0.08, 0.22, 0.08)), Vector3(0.0, 2.06, -0.02), bob, "HairSpikeM")
	hair_spike_m.visible = false
	var hair_spike_r := _mi(_box(Vector3(0.08, 0.18, 0.08)), Vector3(0.10, 2.02, -0.02), bob, "HairSpikeR")
	hair_spike_r.rotation_degrees = Vector3(0, 0, 18)
	hair_spike_r.visible = false
	var hair_ponytail := _mi(_capsule(0.07, 0.42), Vector3(0.0, 1.55, -0.22), bob, "HairPonytail")
	hair_ponytail.rotation_degrees = Vector3(28, 0, 0)
	hair_ponytail.visible = false
	var hair_bun := _mi(_sphere(0.11), Vector3(0.0, 2.02, -0.08), bob, "HairBun")
	hair_bun.visible = false
	# Boy facial hair (toggled by apply_facial_hair; always hidden for girls).
	var face_stubble := _mi(_box(Vector3(0.18, 0.04, 0.05)), Vector3(0, 1.58, 0.20), bob, "FaceStubble")
	face_stubble.visible = false
	var face_mustache := _mi(_box(Vector3(0.14, 0.035, 0.05)), Vector3(0, 1.64, 0.22), bob, "FaceMustache")
	face_mustache.visible = false
	var face_goatee := _mi(_box(Vector3(0.08, 0.10, 0.06)), Vector3(0, 1.56, 0.21), bob, "FaceGoatee")
	face_goatee.visible = false
	var face_beard := _mi(_sphere(0.12, 0.18), Vector3(0, 1.52, 0.16), bob, "FaceBeard")
	face_beard.visible = false
	var l_shoulder := _mi(_box(Vector3(0.20, 0.17, 0.26)), Vector3(-0.34, 1.38, 0), bob, "LShoulder")
	var r_shoulder := _mi(_box(Vector3(0.20, 0.17, 0.26)), Vector3(0.34, 1.38, 0), bob, "RShoulder")
	# Face (eyes / brows / nose / mouth) — kid-readable, not a blank sphere.
	var l_eye := _mi(_sphere(0.055, 0.05), Vector3(-0.08, 1.74, 0.18), bob, "LEye")
	var r_eye := _mi(_sphere(0.055, 0.05), Vector3(0.08, 1.74, 0.18), bob, "REye")
	var l_pupil := _mi(_sphere(0.028, 0.03), Vector3(-0.08, 1.74, 0.22), bob, "LPupil")
	var r_pupil := _mi(_sphere(0.028, 0.03), Vector3(0.08, 1.74, 0.22), bob, "RPupil")
	var l_brow := _mi(_box(Vector3(0.10, 0.03, 0.04)), Vector3(-0.08, 1.82, 0.18), bob, "LBrow")
	var r_brow := _mi(_box(Vector3(0.10, 0.03, 0.04)), Vector3(0.08, 1.82, 0.18), bob, "RBrow")
	var nose := _mi(_box(Vector3(0.06, 0.07, 0.07)), Vector3(0, 1.68, 0.22), bob, "Nose")
	var mouth := _mi(_box(Vector3(0.10, 0.03, 0.04)), Vector3(0, 1.62, 0.21), bob, "Mouth")
	var l_ear := _mi(_sphere(0.06, 0.09), Vector3(-0.22, 1.72, 0.0), bob, "LEar")
	var r_ear := _mi(_sphere(0.06, 0.09), Vector3(0.22, 1.72, 0.0), bob, "REar")

	# Hat (explorer brim + crown; jewel for crownlets) — hidden until equipped
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.visible = false
	hat.position = Vector3(0, 1.94, 0)
	bob.add_child(hat)
	var hat_crown := _mi(_cyl(0.20, 0.22, 0.20), Vector3(0, 0.08, 0), hat, "HatCrown")
	var hat_brim := _mi(_cyl(0.36, 0.36, 0.04), Vector3(0, -0.02, 0), hat, "HatBrim")
	var hat_jewel := _mi(_sphere(0.06), Vector3(0, 0.22, 0), hat, "HatJewel")
	hat_jewel.visible = false

	# Cape drapes from the shoulders — narrower so arms still read from above.
	var cape := _mi(_box(Vector3(0.52, 0.88, 0.07)), Vector3(0, 1.04, -0.22), bob, "Cape")

	# Belt around waist — leather cord always on so the tunic/pants break reads from the camera
	var belt := _mi(_box(Vector3(0.52, 0.10, 0.32)), Vector3(0, 0.84, 0), bob, "Belt")
	belt.visible = true
	var buckle := _mi(_box(Vector3(0.10, 0.10, 0.08)), Vector3(0, 0.84, 0.18), bob, "Buckle")

	# Soft armor overlays (chest + pads) — hidden until a defensive cloak is worn
	var chest_plate := _mi(_box(Vector3(0.42, 0.34, 0.10)), Vector3(0, 1.16, 0.16), bob, "ChestPlate")
	chest_plate.visible = false
	var l_pad := _mi(_box(Vector3(0.22, 0.12, 0.24)), Vector3(-0.30, 1.40, 0.02), bob, "LPad")
	l_pad.visible = false
	var r_pad := _mi(_box(Vector3(0.22, 0.12, 0.24)), Vector3(0.30, 1.40, 0.02), bob, "RPad")
	r_pad.visible = false

	# Accessory (chest charm / belt pouch / lantern) — hidden until equipped
	var accessory := Node3D.new()
	accessory.name = "Accessory"
	accessory.visible = false
	accessory.position = Vector3(0.0, 1.12, 0.20)
	bob.add_child(accessory)
	var acc_body := _mi(_sphere(0.11), Vector3(0, 0, 0), accessory, "AccBody")
	var acc_glow := _mi(_sphere(0.06), Vector3(0, 0.08, 0.04), accessory, "AccGlow")
	var acc_strap := _mi(_box(Vector3(0.08, 0.22, 0.04)), Vector3(0, 0.16, -0.02), accessory, "AccStrap")

	# --- Arms (shoulder pivots + elbow pivots so limbs read from above) ---
	var l_arm := Node3D.new()
	l_arm.name = "LArm"
	l_arm.position = Vector3(-0.42, 1.36, 0)
	l_arm.rotation.z = deg_to_rad(-16)
	bob.add_child(l_arm)
	var l_upper := _mi(_capsule(0.09, 0.40), Vector3(-0.02, -0.18, 0), l_arm, "LUpperArm")
	var l_elbow := _mi(_sphere(0.075), Vector3(-0.03, -0.38, 0), l_arm, "LElbow")
	var l_forearm := Node3D.new()
	l_forearm.name = "LForearm"
	l_forearm.position = Vector3(-0.03, -0.38, 0)
	l_arm.add_child(l_forearm)
	var l_lower := _mi(_capsule(0.075, 0.38), Vector3(0, -0.20, 0), l_forearm, "LLowerArm")
	var l_cuff := _mi(_cyl(0.085, 0.088, 0.08), Vector3(0, -0.36, 0), l_forearm, "LCuff")
	var l_hand := _mi(_sphere(0.09), Vector3(0, -0.42, 0.02), l_forearm, "LHand")

	var r_arm := Node3D.new()
	r_arm.name = "RArm"
	r_arm.position = Vector3(0.42, 1.36, 0)
	r_arm.rotation.z = deg_to_rad(16)
	bob.add_child(r_arm)
	var r_upper := _mi(_capsule(0.09, 0.40), Vector3(0.02, -0.18, 0), r_arm, "RUpperArm")
	var r_elbow := _mi(_sphere(0.075), Vector3(0.03, -0.38, 0), r_arm, "RElbow")
	var r_forearm := Node3D.new()
	r_forearm.name = "RForearm"
	r_forearm.position = Vector3(0.03, -0.38, 0)
	r_arm.add_child(r_forearm)
	var r_lower := _mi(_capsule(0.075, 0.38), Vector3(0, -0.20, 0), r_forearm, "RLowerArm")
	var r_cuff := _mi(_cyl(0.085, 0.088, 0.08), Vector3(0, -0.36, 0), r_forearm, "RCuff")
	var r_hand := _mi(_sphere(0.09), Vector3(0, -0.42, 0.02), r_forearm, "RHand")

	# Weapon held in the right hand so walk/attack swings it (RuneScape-style)
	# r_arm.add_child(weapon) — live parent is the forearm (child of r_arm) so elbow flex carries the blade.
	var weapon := Node3D.new()
	weapon.name = "Weapon"
	weapon.visible = false
	weapon.position = Vector3(0.08, -0.44, 0.06)
	weapon.rotation_degrees = Vector3(8, 0, -12)
	r_forearm.add_child(weapon)
	var blade := _mi(_box(Vector3(0.07, 0.78, 0.07)), Vector3(0, 0.42, 0), weapon, "Blade")
	var hilt := _mi(_box(Vector3(0.16, 0.07, 0.07)), Vector3(0, 0.0, 0), weapon, "Hilt")
	var pommel := _mi(_sphere(0.055), Vector3(0, -0.10, 0), weapon, "Pommel")

	# --- Legs (hip pivots + knee pivots; wider stance for top-down read) ---
	var l_leg := Node3D.new()
	l_leg.name = "LLeg"
	l_leg.position = Vector3(-0.22, 0.72, 0)
	bob.add_child(l_leg)
	var l_thigh := _mi(_capsule(0.11, 0.40), Vector3(0, -0.18, 0), l_leg, "LUpperLeg")
	var l_knee := _mi(_sphere(0.09), Vector3(0, -0.38, 0), l_leg, "LKnee")
	var l_shin_pivot := Node3D.new()
	l_shin_pivot.name = "LShinPivot"
	l_shin_pivot.position = Vector3(0, -0.38, 0)
	l_leg.add_child(l_shin_pivot)
	var l_shin := _mi(_capsule(0.09, 0.38), Vector3(0, -0.20, 0), l_shin_pivot, "LLowerLeg")
	var l_boot := _mi(_cyl(0.095, 0.10, 0.16), Vector3(0, -0.28, 0), l_shin_pivot, "LBoot")
	var l_foot := _mi(_box(Vector3(0.17, 0.13, 0.32)), Vector3(0, -0.38, 0.09), l_shin_pivot, "LFoot")

	var r_leg := Node3D.new()
	r_leg.name = "RLeg"
	r_leg.position = Vector3(0.22, 0.72, 0)
	bob.add_child(r_leg)
	var r_thigh := _mi(_capsule(0.11, 0.40), Vector3(0, -0.18, 0), r_leg, "RUpperLeg")
	var r_knee := _mi(_sphere(0.09), Vector3(0, -0.38, 0), r_leg, "RKnee")
	var r_shin_pivot := Node3D.new()
	r_shin_pivot.name = "RShinPivot"
	r_shin_pivot.position = Vector3(0, -0.38, 0)
	r_leg.add_child(r_shin_pivot)
	var r_shin := _mi(_capsule(0.09, 0.38), Vector3(0, -0.20, 0), r_shin_pivot, "RLowerLeg")
	var r_boot := _mi(_cyl(0.095, 0.10, 0.16), Vector3(0, -0.28, 0), r_shin_pivot, "RBoot")
	var r_foot := _mi(_box(Vector3(0.17, 0.13, 0.32)), Vector3(0, -0.38, 0.09), r_shin_pivot, "RFoot")

	return {
		"bob": bob,
		"torso": torso,
		"pelvis": pelvis,
		"hem": hem,
		"skirt": skirt,
		"collar": collar,
		"neck": neck,
		"head": head,
		"hair": hair,
		"bangs": bangs,
		"hair_long": hair_long,
		"hair_l_lock": hair_l_lock,
		"hair_r_lock": hair_r_lock,
		"hair_wave_l": hair_wave_l,
		"hair_wave_r": hair_wave_r,
		"hair_spike_l": hair_spike_l,
		"hair_spike_m": hair_spike_m,
		"hair_spike_r": hair_spike_r,
		"hair_ponytail": hair_ponytail,
		"hair_bun": hair_bun,
		"face_stubble": face_stubble,
		"face_mustache": face_mustache,
		"face_goatee": face_goatee,
		"face_beard": face_beard,
		"l_shoulder": l_shoulder,
		"r_shoulder": r_shoulder,
		"hat": hat,
		"hat_crown": hat_crown,
		"hat_brim": hat_brim,
		"hat_jewel": hat_jewel,
		"cape": cape,
		"belt": belt,
		"buckle": buckle,
		"chest_plate": chest_plate,
		"l_pad": l_pad,
		"r_pad": r_pad,
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
		"l_boot": l_boot,
		"r_boot": r_boot,
		"l_cuff": l_cuff,
		"r_cuff": r_cuff,
		"l_upper": l_upper,
		"r_upper": r_upper,
		"l_lower": l_lower,
		"r_lower": r_lower,
		"l_thigh": l_thigh,
		"r_thigh": r_thigh,
		"l_shin": l_shin,
		"r_shin": r_shin,
		"l_forearm": l_forearm,
		"r_forearm": r_forearm,
		"l_shin_pivot": l_shin_pivot,
		"r_shin_pivot": r_shin_pivot,
		"l_elbow": l_elbow,
		"r_elbow": r_elbow,
		"l_knee": l_knee,
		"r_knee": r_knee,
		"l_eye": l_eye,
		"r_eye": r_eye,
		"l_pupil": l_pupil,
		"r_pupil": r_pupil,
		"l_brow": l_brow,
		"r_brow": r_brow,
		"nose": nose,
		"mouth": mouth,
		"l_ear": l_ear,
		"r_ear": r_ear,
	}


## Apply player-style colors: skin on exposed parts, outfit on clothes, etc.
static func apply_human_colors(parts: Dictionary, skin: Color, hair: Color, outfit: Color, cape_col: Color, shoe: Color = Color("#3b2f2f")) -> void:
	set_color(parts.get("head"), skin)
	set_color(parts.get("neck"), skin)
	set_color(parts.get("hair"), hair)
	set_color(parts.get("bangs"), hair.darkened(0.06))
	var pants := Color("#4a3a32")
	set_color(parts.get("torso"), outfit)
	set_color(parts.get("pelvis"), pants)
	set_color(parts.get("hem"), outfit.darkened(0.16))
	set_color(parts.get("collar"), outfit.lightened(0.10))
	set_color(parts.get("belt"), Color("#5c3d24"))
	set_color(parts.get("buckle"), Color("#c9a227"), 0.4)
	var belt_n: MeshInstance3D = parts.get("belt")
	if belt_n:
		belt_n.visible = true
	set_color(parts.get("l_cuff"), outfit.darkened(0.12))
	set_color(parts.get("r_cuff"), outfit.darkened(0.12))
	# Arms: sleeves (outfit) + hands (skin)
	set_color(parts.get("l_upper"), outfit)
	set_color(parts.get("r_upper"), outfit)
	set_color(parts.get("l_lower"), outfit.lightened(0.05))
	set_color(parts.get("r_lower"), outfit.lightened(0.05))
	set_color(parts.get("l_hand"), skin)
	set_color(parts.get("r_hand"), skin)
	set_color(parts.get("l_elbow"), skin)
	set_color(parts.get("r_elbow"), skin)
	set_color(parts.get("l_knee"), pants.darkened(0.08))
	set_color(parts.get("r_knee"), pants.darkened(0.08))
	# Face
	set_color(parts.get("l_eye"), Color("#f4f0e6"), 0.4)
	set_color(parts.get("r_eye"), Color("#f4f0e6"), 0.4)
	set_color(parts.get("l_pupil"), Color("#1a1410"), 0.35)
	set_color(parts.get("r_pupil"), Color("#1a1410"), 0.35)
	set_color(parts.get("l_brow"), hair.darkened(0.1))
	set_color(parts.get("r_brow"), hair.darkened(0.1))
	set_color(parts.get("nose"), skin.darkened(0.06))
	set_color(parts.get("mouth"), skin.darkened(0.18))
	set_color(parts.get("l_ear"), skin.darkened(0.04))
	set_color(parts.get("r_ear"), skin.darkened(0.04))
	# Legs / feet
	set_color(parts.get("l_thigh"), pants)
	set_color(parts.get("r_thigh"), pants)
	set_color(parts.get("l_shin"), pants.darkened(0.10))
	set_color(parts.get("r_shin"), pants.darkened(0.10))
	set_color(parts.get("l_foot"), shoe)
	set_color(parts.get("r_foot"), shoe)
	set_color(parts.get("l_boot"), shoe.lightened(0.08))
	set_color(parts.get("r_boot"), shoe.lightened(0.08))
	set_color(parts.get("cape"), cape_col)
	set_color(parts.get("l_shoulder"), outfit)
	set_color(parts.get("r_shoulder"), outfit)
	set_color(parts.get("chest_plate"), outfit.darkened(0.12))
	set_color(parts.get("l_pad"), outfit.darkened(0.18))
	set_color(parts.get("r_pad"), outfit.darkened(0.18))
	# Gender extras / style extras share hair / outfit palette when visible
	set_color(parts.get("hair_long"), hair.darkened(0.04))
	set_color(parts.get("hair_l_lock"), hair.darkened(0.02))
	set_color(parts.get("hair_r_lock"), hair.darkened(0.02))
	set_color(parts.get("hair_wave_l"), hair.darkened(0.03))
	set_color(parts.get("hair_wave_r"), hair.darkened(0.03))
	set_color(parts.get("hair_spike_l"), hair.lightened(0.04))
	set_color(parts.get("hair_spike_m"), hair.lightened(0.06))
	set_color(parts.get("hair_spike_r"), hair.lightened(0.04))
	set_color(parts.get("hair_ponytail"), hair.darkened(0.05))
	set_color(parts.get("hair_bun"), hair.darkened(0.02))
	set_color(parts.get("face_stubble"), hair.darkened(0.15))
	set_color(parts.get("face_mustache"), hair.darkened(0.08))
	set_color(parts.get("face_goatee"), hair.darkened(0.10))
	set_color(parts.get("face_beard"), hair.darkened(0.12))
	set_color(parts.get("skirt"), outfit.darkened(0.08))


## Boy / girl body silhouette (skirt / shoulders). Hair is handled by apply_hair_style.
static func apply_gender(parts: Dictionary, gender: String) -> void:
	var is_girl := str(gender).to_lower() == "girl"
	var skirt_n: Node = parts.get("skirt")
	if skirt_n:
		skirt_n.visible = is_girl
	var hem_n: MeshInstance3D = parts.get("hem")
	var l_sh: MeshInstance3D = parts.get("l_shoulder")
	var r_sh: MeshInstance3D = parts.get("r_shoulder")
	if is_girl:
		if hem_n:
			hem_n.visible = false
		if l_sh:
			l_sh.scale = Vector3(0.90, 0.92, 0.92)
		if r_sh:
			r_sh.scale = Vector3(0.90, 0.92, 0.92)
	else:
		if hem_n:
			hem_n.visible = true
			hem_n.scale = Vector3.ONE
			hem_n.position = Vector3(0, 0.74, 0.02)
		if l_sh:
			l_sh.scale = Vector3.ONE
		if r_sh:
			r_sh.scale = Vector3.ONE


const HAIR_STYLE_PARTS := [
	"hair_long", "hair_l_lock", "hair_r_lock", "hair_wave_l", "hair_wave_r",
	"hair_spike_l", "hair_spike_m", "hair_spike_r", "hair_ponytail", "hair_bun",
]
const FACIAL_HAIR_PARTS := ["face_stubble", "face_mustache", "face_goatee", "face_beard"]


## Hair styles: short / neat / spiky / fringe / wavy / long / ponytail / bun.
static func apply_hair_style(parts: Dictionary, style: String) -> void:
	var s := str(style).to_lower()
	for key in HAIR_STYLE_PARTS:
		var n: Node = parts.get(key)
		if n:
			n.visible = false
	var hair_n: MeshInstance3D = parts.get("hair")
	var bangs_n: MeshInstance3D = parts.get("bangs")
	if hair_n:
		hair_n.visible = true
		hair_n.scale = Vector3.ONE
		hair_n.position = Vector3(0, 1.86, -0.06)
	if bangs_n:
		bangs_n.visible = true
		bangs_n.scale = Vector3.ONE
		bangs_n.position = Vector3(0, 1.88, 0.14)
	match s:
		"neat":
			if hair_n:
				hair_n.scale = Vector3(1.02, 0.78, 1.05)
				hair_n.position = Vector3(0, 1.84, -0.04)
			if bangs_n:
				bangs_n.scale = Vector3(0.85, 0.7, 1.0)
				bangs_n.position = Vector3(0, 1.86, 0.14)
		"spiky":
			if hair_n:
				hair_n.scale = Vector3(0.95, 0.85, 0.95)
				hair_n.position = Vector3(0, 1.88, -0.05)
			if bangs_n:
				bangs_n.visible = false
			_show_parts(parts, ["hair_spike_l", "hair_spike_m", "hair_spike_r"])
		"fringe":
			if hair_n:
				hair_n.scale = Vector3(1.05, 1.0, 1.05)
			if bangs_n:
				bangs_n.scale = Vector3(1.35, 1.45, 1.2)
				bangs_n.position = Vector3(0, 1.86, 0.17)
		"wavy":
			if hair_n:
				hair_n.scale = Vector3(1.12, 1.08, 1.12)
				hair_n.position = Vector3(0, 1.88, -0.04)
			_show_parts(parts, ["hair_wave_l", "hair_wave_r", "hair_l_lock", "hair_r_lock"])
		"long":
			if hair_n:
				hair_n.scale = Vector3(1.10, 1.15, 1.12)
				hair_n.position = Vector3(0, 1.90, -0.04)
			if bangs_n:
				bangs_n.scale = Vector3(1.15, 1.1, 1.05)
			_show_parts(parts, ["hair_long", "hair_l_lock", "hair_r_lock"])
		"ponytail":
			if hair_n:
				hair_n.scale = Vector3(0.92, 0.88, 0.95)
				hair_n.position = Vector3(0, 1.88, -0.02)
			if bangs_n:
				bangs_n.scale = Vector3(0.95, 0.9, 1.0)
			_show_parts(parts, ["hair_ponytail"])
		"bun":
			if hair_n:
				hair_n.scale = Vector3(0.98, 0.85, 1.0)
				hair_n.position = Vector3(0, 1.86, -0.03)
			if bangs_n:
				bangs_n.scale = Vector3(1.05, 0.95, 1.0)
			_show_parts(parts, ["hair_bun"])
		_:
			# short — default bowl cut
			pass


## Facial hair for boys: none / stubble / mustache / goatee / beard. Girls always clear.
static func apply_facial_hair(parts: Dictionary, style: String, gender: String = "boy") -> void:
	for key in FACIAL_HAIR_PARTS:
		var n: Node = parts.get(key)
		if n:
			n.visible = false
	if str(gender).to_lower() == "girl":
		return
	match str(style).to_lower():
		"stubble":
			_show_parts(parts, ["face_stubble"])
		"mustache":
			_show_parts(parts, ["face_mustache"])
		"goatee":
			_show_parts(parts, ["face_mustache", "face_goatee"])
		"beard":
			_show_parts(parts, ["face_beard", "face_mustache"])
		_:
			pass


static func _show_parts(parts: Dictionary, keys: Array) -> void:
	for key in keys:
		var n: Node = parts.get(key)
		if n:
			n.visible = true


static func apply_npc_colors(parts: Dictionary, accent: Color, skin: Color = Color("#c68642")) -> void:
	var outfit := accent
	var hair := accent.darkened(0.35)
	apply_human_colors(parts, skin, hair, outfit, accent.darkened(0.2))
	# NPCs show a small cape stub in accent; no player armor overlays / style extras
	var cape: MeshInstance3D = parts.get("cape")
	if cape:
		cape.visible = true
	var hide_keys: Array = [
		"chest_plate", "l_pad", "r_pad", "hat", "weapon", "accessory", "skirt",
	]
	hide_keys.append_array(HAIR_STYLE_PARTS)
	hide_keys.append_array(FACIAL_HAIR_PARTS)
	for key in hide_keys:
		var n: Node = parts.get(key)
		if n:
			n.visible = false
	var belt_n: MeshInstance3D = parts.get("belt")
	if belt_n:
		belt_n.visible = true
	apply_hair_style(parts, "short")


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
		root.position = Vector3(0.36, 0.88, 0.12)
		if body and body.mesh is SphereMesh:
			pass
		# Swap to box-ish lantern look via scale
		if body:
			body.scale = Vector3(0.7, 1.1, 0.7)
		if glow:
			glow.visible = true
			glow.scale = Vector3.ONE
	elif "bead" in iid or "prayer" in name:
		root.position = Vector3(0, 1.48, 0.16)
		if body:
			body.scale = Vector3(1.4, 0.45, 1.4)
		if glow:
			glow.visible = false
	elif "pin" in iid or "star" in name or "badge" in name:
		root.position = Vector3(0.18, 1.22, 0.16)
		if body:
			body.scale = Vector3(0.9, 0.35, 0.9)
		if glow:
			glow.visible = true
			glow.scale = Vector3(0.6, 0.6, 0.6)
	elif "scroll" in iid or "notebook" in name or "bookmark" in name or "map" in name:
		root.position = Vector3(-0.32, 1.00, 0.1)
		if body:
			body.scale = Vector3(0.55, 1.4, 0.35)
		if glow:
			glow.visible = false
	else:
		# Generic charm / purse at belt
		root.position = Vector3(0.28, 0.84, 0.14)
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
			# Haft + axe head — held in the right hand
			blade = _mi(_box(Vector3(0.09, 0.82, 0.09)), Vector3(0, 0.38, 0), weapon, "Blade")
			hilt = _mi(_box(Vector3(0.40, 0.20, 0.12)), Vector3(0.16, 0.72, 0), weapon, "Hilt")
			pommel = _mi(_sphere(0.07), Vector3(0, -0.12, 0), weapon, "Pommel")
			weapon.position = Vector3(0.06, -0.44, 0.06)
			weapon.rotation_degrees = Vector3(10, 0, -16)
		"staff":
			blade = _mi(_cyl(0.045, 0.055, 1.45), Vector3(0, 0.42, 0), weapon, "Blade")
			hilt = _mi(_sphere(0.09), Vector3(0, 1.12, 0), weapon, "Hilt")
			pommel = _mi(_cyl(0.06, 0.06, 0.08), Vector3(0, -0.28, 0), weapon, "Pommel")
			weapon.position = Vector3(0.05, -0.40, 0.04)
			weapon.rotation_degrees = Vector3(12, 0, -8)
		"bow":
			# Simple recurve silhouette held beside the arm
			blade = _mi(_box(Vector3(0.05, 1.05, 0.07)), Vector3(0, 0.22, 0), weapon, "Blade")
			hilt = _mi(_box(Vector3(0.04, 0.55, 0.04)), Vector3(0.16, 0.22, 0), weapon, "Hilt")
			pommel = _mi(_box(Vector3(0.04, 0.04, 0.32)), Vector3(0.08, 0.62, 0), weapon, "Pommel")
			weapon.position = Vector3(0.10, -0.18, -0.06)
			weapon.rotation_degrees = Vector3(5, 18, -4)
		"dagger":
			blade = _mi(_box(Vector3(0.06, 0.40, 0.06)), Vector3(0, 0.18, 0), weapon, "Blade")
			hilt = _mi(_box(Vector3(0.14, 0.06, 0.06)), Vector3(0, -0.04, 0), weapon, "Hilt")
			pommel = _mi(_sphere(0.05), Vector3(0, -0.12, 0), weapon, "Pommel")
			weapon.position = Vector3(0.06, -0.44, 0.08)
			weapon.rotation_degrees = Vector3(6, 0, -20)
		"mallet":
			blade = _mi(_box(Vector3(0.11, 0.58, 0.11)), Vector3(0, 0.22, 0), weapon, "Blade")
			hilt = _mi(_box(Vector3(0.26, 0.20, 0.20)), Vector3(0, 0.56, 0), weapon, "Hilt")
			pommel = _mi(_sphere(0.07), Vector3(0, -0.12, 0), weapon, "Pommel")
			weapon.position = Vector3(0.06, -0.44, 0.06)
			weapon.rotation_degrees = Vector3(8, 0, -14)
		_:
			blade = _mi(_box(Vector3(0.07, 0.82, 0.07)), Vector3(0, 0.42, 0), weapon, "Blade")
			hilt = _mi(_box(Vector3(0.16, 0.07, 0.07)), Vector3(0, 0.0, 0), weapon, "Hilt")
			pommel = _mi(_sphere(0.055), Vector3(0, -0.10, 0), weapon, "Pommel")
			weapon.position = Vector3(0.06, -0.44, 0.06)
			weapon.rotation_degrees = Vector3(8, 0, -12)

	parts["blade"] = blade
	parts["hilt"] = hilt
	parts["pommel"] = pommel
	parts["weapon_mesh"] = mesh_style
	# Remember rest pose so walk bob / attack wrist-flick can return cleanly (Wave 22).
	weapon.set_meta("rest_rx", weapon.rotation_degrees.x)
	weapon.set_meta("rest_ry", weapon.rotation_degrees.y)
	weapon.set_meta("rest_rz", weapon.rotation_degrees.z)
	weapon.set_meta("rest_pos", weapon.position)

	var col := Color(item.get("color", "#a67c52"))
	set_color(blade, col)
	set_color(hilt, col.darkened(0.25))
	set_color(pommel, col.lightened(0.15))


## Explorer brim vs jeweled crown, colored from the equipped head item.
static func style_hat(parts: Dictionary, item: Dictionary) -> void:
	var hat: Node3D = parts.get("hat")
	if hat == null:
		return
	hat.visible = true
	var iid: String = str(item.get("id", "")).to_lower()
	var name: String = str(item.get("name", "")).to_lower()
	var col := Color(item.get("color", "#5c4033"))
	var crown: MeshInstance3D = parts.get("hat_crown")
	var brim: MeshInstance3D = parts.get("hat_brim")
	var jewel: MeshInstance3D = parts.get("hat_jewel")
	set_color(crown, col)
	set_color(brim, col.darkened(0.15))
	set_color(jewel, col.lightened(0.28), 0.35)
	var is_crown: bool = "crown" in iid or "crown" in name
	if is_crown:
		if crown:
			crown.scale = Vector3(0.88, 1.45, 0.88)
			crown.position = Vector3(0, 0.14, 0)
		if brim:
			brim.scale = Vector3(0.62, 1.0, 0.62)
			brim.position = Vector3(0, -0.02, 0)
		if jewel:
			jewel.visible = true
			jewel.position = Vector3(0, 0.28, 0)
	else:
		if crown:
			crown.scale = Vector3.ONE
			crown.position = Vector3(0, 0.08, 0)
		if brim:
			brim.scale = Vector3.ONE
			brim.position = Vector3(0, -0.02, 0)
		if jewel:
			jewel.visible = false


## Cloak vs tunic: cloaks drape on the back; tunics recolor the torso/sleeves.
static func style_cloak(parts: Dictionary, item: Dictionary) -> void:
	var cape: MeshInstance3D = parts.get("cape")
	var iid: String = str(item.get("id", "")).to_lower()
	var name: String = str(item.get("name", "")).to_lower()
	var col := Color(item.get("color", "#c1121f"))
	var is_tunic: bool = "tunic" in iid or "tunic" in name
	if cape:
		if is_tunic:
			cape.visible = false
		else:
			cape.visible = true
			set_color(cape, col)
			var defn: int = int(item.get("defense", 0))
			if "champion" in name or defn >= 2:
				cape.scale = Vector3(1.08, 1.14, 1.05)
			else:
				cape.scale = Vector3.ONE
	if is_tunic:
		set_color(parts.get("torso"), col)
		set_color(parts.get("hem"), col.darkened(0.12))
		set_color(parts.get("collar"), col.lightened(0.08))
		set_color(parts.get("l_upper"), col)
		set_color(parts.get("r_upper"), col)
		set_color(parts.get("l_shoulder"), col)
		set_color(parts.get("r_shoulder"), col)


## Chest plate + shoulder pads when a cloak/hat carries soft defense.
static func style_armor(parts: Dictionary, item: Dictionary) -> void:
	var defn: int = int(item.get("defense", 0))
	var show: bool = defn > 0
	var col := Color(item.get("color", "#8a8a9a"))
	var plate: MeshInstance3D = parts.get("chest_plate")
	var l_pad: MeshInstance3D = parts.get("l_pad")
	var r_pad: MeshInstance3D = parts.get("r_pad")
	if plate:
		plate.visible = show
		if show:
			set_color(plate, col.lightened(0.08))
	if l_pad:
		l_pad.visible = show
		if show:
			set_color(l_pad, col.darkened(0.1))
	if r_pad:
		r_pad.visible = show
		if show:
			set_color(r_pad, col.darkened(0.1))

