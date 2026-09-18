class_name HumanoidBuilder
extends RefCounted
## Soft cartoon humanoid from MeshInstance3D primitives (storybook toon, not Roblox boxes).
## Kid-readable proportions: big head, big eyes on the face, rounded torso, pudgy feet.

static func make_mat(c: Color, roughness: float = 0.72, outlined: bool = true) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = roughness
	mat.metallic = 0.0
	# Flat cartoon bands instead of shiny plastic / Roblox lighting.
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	if outlined:
		# Soft ink outline on body silhouette — skip on tiny face parts (looks chunky).
		var outline := StandardMaterial3D.new()
		outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		outline.albedo_color = Color(0.14, 0.10, 0.12)
		outline.cull_mode = BaseMaterial3D.CULL_FRONT
		outline.grow = true
		outline.grow_amount = 0.024
		mat.next_pass = outline
	return mat


static func set_color(mi: MeshInstance3D, c: Color, roughness: float = 0.72, outlined: bool = true) -> void:
	if mi == null:
		return
	mi.material_override = make_mat(c, roughness, outlined)


static func set_face_color(mi: MeshInstance3D, c: Color, roughness: float = 0.48) -> void:
	## Face features stay soft and clean — no ink grow outline.
	set_color(mi, c, roughness, false)


static func _load_face_tex() -> Texture2D:
	return _load_png_tex("res://assets/faces/apprentice_face.png")


static func _load_png_tex(res_path: String) -> Texture2D:
	var path := ProjectSettings.globalize_path(res_path)
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		push_warning("HumanoidBuilder: could not load texture %s (%s)" % [res_path, err])
		return null
	return ImageTexture.create_from_image(img)


static func _make_alpha_card(parent: Node3D, name: String, tex: Texture2D, size: Vector2, pos: Vector3, rot_deg: Vector3, priority: int = 8, overdraw: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if tex:
		mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	# Face/bangs overdraw so elevated cam stays readable; back hair keeps depth so it
	# cannot paint over the chin/face when viewed from the front.
	if overdraw:
		mat.no_depth_test = true
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	else:
		mat.no_depth_test = false
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	mat.render_priority = priority
	mi.material_override = mat
	HeadlessGuard.guard_mesh(mi)
	return mi


static func _tint_card(mi: MeshInstance3D, c: Color) -> void:
	if mi == null or mi.material_override == null:
		return
	var mat := mi.material_override as StandardMaterial3D
	if mat:
		# Texture is a light grayscale alpha silhouette — multiply by wardrobe hair color.
		mat.albedo_color = c


static func _make_face_decal(parent: Node3D) -> MeshInstance3D:
	## Painted storybook face card — tipped toward the elevated village camera.
	return _make_alpha_card(
		parent,
		"FaceDecal",
		_load_face_tex(),
		Vector2(0.55, 0.55),
		Vector3(0, 1.92, 0.22),
		Vector3(-40, 0, 0),
		10
	)


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

	# --- Core (v1.84 cartoon: chibi toon silhouette that reads from the elevated camera) ---
	# Capsule/sphere body — no hard boxes so it doesn't read as Roblox blocks.
	var torso := _mi(_capsule(0.30, 0.56), Vector3(0, 1.10, 0), bob, "Torso")
	var pelvis := _mi(_sphere(0.26, 0.28), Vector3(0, 0.76, 0), bob, "Pelvis")
	var hem := _mi(_sphere(0.32, 0.20), Vector3(0, 0.68, 0.02), bob, "Hem")
	var neck := _mi(_cyl(0.11, 0.13, 0.10), Vector3(0, 1.42, 0), bob, "Neck")
	var collar := _mi(_sphere(0.20, 0.12), Vector3(0, 1.36, 0.03), bob, "Collar")
	# Big storybook head — face features sit on the front surface (not buried inside).
	var head := _mi(_sphere(0.32), Vector3(0, 1.78, 0.04), bob, "Head")
	# Soft anime short-hair: fluffy crown volume + painted bangs/back cards
	# (cute layered fringe — not geometric cone spikes).
	var hair := _mi(_sphere(0.30, 0.24), Vector3(0, 1.94, -0.10), bob, "Hair")
	hair.scale = Vector3(1.18, 0.78, 1.12)
	# Soft top fluff tufts (small, sit on crown — do not swallow the face)
	var hair_spike_c := _mi(_sphere(0.08, 0.12), Vector3(0.02, 2.10, -0.04), bob, "HairSpikeC")
	hair_spike_c.scale = Vector3(1.05, 0.75, 0.85)
	var hair_spike_l := _mi(_sphere(0.07, 0.11), Vector3(-0.14, 2.05, 0.0), bob, "HairSpikeL")
	hair_spike_l.scale = Vector3(0.95, 0.7, 0.8)
	var hair_spike_r := _mi(_sphere(0.07, 0.11), Vector3(0.14, 2.05, 0.0), bob, "HairSpikeR")
	hair_spike_r.scale = Vector3(0.95, 0.7, 0.8)
	var hair_spike_bl := _mi(_sphere(0.075, 0.11), Vector3(-0.10, 1.98, -0.16), bob, "HairSpikeBL")
	var hair_spike_br := _mi(_sphere(0.075, 0.11), Vector3(0.10, 1.98, -0.16), bob, "HairSpikeBR")
	# Soft side volume (kept for wardrobe API)
	var hair_spike_wl := _mi(_sphere(0.06, 0.10), Vector3(-0.26, 1.88, -0.02), bob, "HairSpikeWL")
	var hair_spike_wr := _mi(_sphere(0.06, 0.10), Vector3(0.26, 1.88, -0.02), bob, "HairSpikeWR")
	# Painted bangs card — soft curtain fringe above the eyes
	var bangs := _make_alpha_card(
		bob,
		"Bangs",
		_load_png_tex("res://assets/faces/apprentice_bangs.png"),
		Vector2(0.58, 0.34),
		Vector3(0.0, 2.02, 0.18),
		Vector3(-38, 0, 0),
		9
	)
	# Tiny soft 3D bang accents (subtle under the painted fringe)
	var bang_l := _mi(_sphere(0.045, 0.09), Vector3(-0.12, 1.96, 0.20), bob, "BangL")
	bang_l.scale = Vector3(0.85, 0.9, 0.45)
	bang_l.rotation_degrees = Vector3(28, 8, -8)
	var bang_r := _mi(_sphere(0.045, 0.09), Vector3(0.12, 1.96, 0.20), bob, "BangR")
	bang_r.scale = Vector3(0.85, 0.9, 0.45)
	bang_r.rotation_degrees = Vector3(28, -8, 8)
	# Soft cheek-framing locks
	var l_lock := _mi(_capsule(0.045, 0.24), Vector3(-0.26, 1.72, 0.10), bob, "LLock")
	l_lock.rotation_degrees = Vector3(10, 5, 18)
	var r_lock := _mi(_capsule(0.045, 0.24), Vector3(0.26, 1.72, 0.10), bob, "RLock")
	r_lock.rotation_degrees = Vector3(10, -5, -18)
	# Tiny soft tuft
	var ahoge := _mi(_sphere(0.04, 0.09), Vector3(0.07, 2.16, 0.02), bob, "Ahoge")
	ahoge.scale = Vector3(0.65, 0.95, 0.65)
	ahoge.rotation_degrees = Vector3(8, 0, 22)
	# Painted soft bob card on the back — depth-tested so it stays behind the head.
	var hair_back := _make_alpha_card(
		bob,
		"HairBack",
		_load_png_tex("res://assets/faces/apprentice_hair_back.png"),
		Vector2(0.70, 0.70),
		Vector3(0.0, 1.86, -0.22),
		Vector3(16, 180, 0),
		7,
		false
	)

	var l_shoulder := _mi(_sphere(0.15), Vector3(-0.36, 1.32, 0), bob, "LShoulder")
	var r_shoulder := _mi(_sphere(0.15), Vector3(0.36, 1.32, 0), bob, "RShoulder")
	# Face — big friendly eyes on the head surface + warm iris + curved smile.
	# Pupils sit high in the whites so the elevated camera doesn't make them look sleepy.
	var l_eye := _mi(_sphere(0.090, 0.102), Vector3(-0.125, 1.855, 0.335), bob, "LEye")
	l_eye.scale = Vector3(1.18, 1.12, 0.88)
	var r_eye := _mi(_sphere(0.090, 0.102), Vector3(0.125, 1.855, 0.335), bob, "REye")
	r_eye.scale = Vector3(1.18, 1.12, 0.88)
	var l_iris := _mi(_sphere(0.052, 0.056), Vector3(-0.125, 1.862, 0.388), bob, "LIris")
	var r_iris := _mi(_sphere(0.052, 0.056), Vector3(0.125, 1.862, 0.388), bob, "RIris")
	var l_pupil := _mi(_sphere(0.026, 0.028), Vector3(-0.125, 1.864, 0.422), bob, "LPupil")
	var r_pupil := _mi(_sphere(0.026, 0.028), Vector3(0.125, 1.864, 0.422), bob, "RPupil")
	var l_shine := _mi(_sphere(0.017), Vector3(-0.108, 1.885, 0.440), bob, "LShine")
	var r_shine := _mi(_sphere(0.017), Vector3(0.142, 1.885, 0.440), bob, "RShine")
	# Soft arched brows (thin, angled, clear gap — never a unibrow).
	var l_brow := _mi(_sphere(0.034, 0.011), Vector3(-0.130, 1.950, 0.318), bob, "LBrow")
	l_brow.scale = Vector3(1.15, 0.65, 0.5)
	l_brow.rotation_degrees.z = -16
	var r_brow := _mi(_sphere(0.034, 0.011), Vector3(0.130, 1.950, 0.318), bob, "RBrow")
	r_brow.scale = Vector3(1.15, 0.65, 0.5)
	r_brow.rotation_degrees.z = 16
	# Nearly invisible nose.
	var nose := _mi(_sphere(0.018), Vector3(0, 1.790, 0.370), bob, "Nose")
	# Clear curved smile: center low, corners lifted.
	var mouth := _mi(_sphere(0.032, 0.013), Vector3(0, 1.640, 0.352), bob, "Mouth")
	mouth.scale = Vector3(1.15, 0.5, 0.5)
	var mouth_l := _mi(_sphere(0.028, 0.018), Vector3(-0.078, 1.682, 0.338), bob, "MouthL")
	var mouth_r := _mi(_sphere(0.028, 0.018), Vector3(0.078, 1.682, 0.338), bob, "MouthR")
	# Soft blush — subtle, close to skin.
	var l_cheek := _mi(_sphere(0.038, 0.022), Vector3(-0.175, 1.725, 0.308), bob, "LCheek")
	var r_cheek := _mi(_sphere(0.038, 0.022), Vector3(0.175, 1.725, 0.308), bob, "RCheek")
	var l_ear := _mi(_sphere(0.055, 0.07), Vector3(-0.30, 1.78, -0.02), bob, "LEar")
	var r_ear := _mi(_sphere(0.055, 0.07), Vector3(0.30, 1.78, -0.02), bob, "REar")
	# Ears tuck under side locks for a cleaner anime silhouette.
	l_ear.visible = false
	r_ear.visible = false
	# Painted face card (visible). Keep primitive face parts for API/smoke but hide the ugly blobs.
	var face_decal := _make_face_decal(bob)
	for n in [l_eye, r_eye, l_iris, r_iris, l_pupil, r_pupil, l_shine, r_shine, l_brow, r_brow, nose, mouth, mouth_l, mouth_r, l_cheek, r_cheek]:
		n.visible = false

	# Hat (explorer brim + crown; jewel for crownlets) — hidden until equipped
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.visible = false
	hat.position = Vector3(0, 2.28, 0)
	bob.add_child(hat)
	var hat_crown := _mi(_sphere(0.22, 0.26), Vector3(0, 0.10, 0), hat, "HatCrown")
	var hat_brim := _mi(_cyl(0.40, 0.40, 0.045), Vector3(0, -0.02, 0), hat, "HatBrim")
	var hat_jewel := _mi(_sphere(0.07), Vector3(0, 0.26, 0), hat, "HatJewel")
	hat_jewel.visible = false

	# Soft cape drape — flattened capsule (reads as cloth, not a plank).
	var cape := _mi(_capsule(0.32, 0.88), Vector3(0, 0.98, -0.26), bob, "Cape")
	cape.scale = Vector3(1.05, 1.0, 0.22)

	# Soft belt ring + round buckle so the tunic/pants break still reads from above.
	var belt := _mi(_cyl(0.29, 0.29, 0.09), Vector3(0, 0.80, 0), bob, "Belt")
	belt.visible = true
	var buckle := _mi(_sphere(0.06), Vector3(0, 0.80, 0.22), bob, "Buckle")

	# Soft armor overlays (chest + pads) — hidden until a defensive cloak is worn
	var chest_plate := _mi(_sphere(0.22, 0.28), Vector3(0, 1.10, 0.20), bob, "ChestPlate")
	chest_plate.scale = Vector3(1.15, 1.0, 0.35)
	chest_plate.visible = false
	var l_pad := _mi(_sphere(0.13), Vector3(-0.32, 1.34, 0.02), bob, "LPad")
	l_pad.visible = false
	var r_pad := _mi(_sphere(0.13), Vector3(0.32, 1.34, 0.02), bob, "RPad")
	r_pad.visible = false

	# Accessory (chest charm / belt pouch / lantern) — hidden until equipped
	var accessory := Node3D.new()
	accessory.name = "Accessory"
	accessory.visible = false
	accessory.position = Vector3(0.0, 1.08, 0.22)
	bob.add_child(accessory)
	var acc_body := _mi(_sphere(0.11), Vector3(0, 0, 0), accessory, "AccBody")
	var acc_glow := _mi(_sphere(0.06), Vector3(0, 0.08, 0.04), accessory, "AccGlow")
	var acc_strap := _mi(_capsule(0.03, 0.22), Vector3(0, 0.16, -0.02), accessory, "AccStrap")

	# --- Arms (same pivots as before so walk/attack anim still lands) ---
	var l_arm := Node3D.new()
	l_arm.name = "LArm"
	l_arm.position = Vector3(-0.42, 1.36, 0)
	l_arm.rotation.z = deg_to_rad(-16)
	bob.add_child(l_arm)
	var l_upper := _mi(_capsule(0.11, 0.38), Vector3(-0.02, -0.18, 0), l_arm, "LUpperArm")
	var l_elbow := _mi(_sphere(0.09), Vector3(-0.03, -0.38, 0), l_arm, "LElbow")
	var l_forearm := Node3D.new()
	l_forearm.name = "LForearm"
	l_forearm.position = Vector3(-0.03, -0.38, 0)
	l_arm.add_child(l_forearm)
	var l_lower := _mi(_capsule(0.09, 0.36), Vector3(0, -0.20, 0), l_forearm, "LLowerArm")
	var l_cuff := _mi(_cyl(0.10, 0.105, 0.08), Vector3(0, -0.36, 0), l_forearm, "LCuff")
	var l_hand := _mi(_sphere(0.11), Vector3(0, -0.42, 0.02), l_forearm, "LHand")

	var r_arm := Node3D.new()
	r_arm.name = "RArm"
	r_arm.position = Vector3(0.42, 1.36, 0)
	r_arm.rotation.z = deg_to_rad(16)
	bob.add_child(r_arm)
	var r_upper := _mi(_capsule(0.11, 0.38), Vector3(0.02, -0.18, 0), r_arm, "RUpperArm")
	var r_elbow := _mi(_sphere(0.09), Vector3(0.03, -0.38, 0), r_arm, "RElbow")
	var r_forearm := Node3D.new()
	r_forearm.name = "RForearm"
	r_forearm.position = Vector3(0.03, -0.38, 0)
	r_arm.add_child(r_forearm)
	var r_lower := _mi(_capsule(0.09, 0.36), Vector3(0, -0.20, 0), r_forearm, "RLowerArm")
	var r_cuff := _mi(_cyl(0.10, 0.105, 0.08), Vector3(0, -0.36, 0), r_forearm, "RCuff")
	var r_hand := _mi(_sphere(0.11), Vector3(0, -0.42, 0.02), r_forearm, "RHand")

	# Weapon held in the right hand so walk/attack swings it
	# Live parent is the forearm so elbow flex carries the blade.
	var weapon := Node3D.new()
	weapon.name = "Weapon"
	weapon.visible = false
	weapon.position = Vector3(0.08, -0.44, 0.06)
	weapon.rotation_degrees = Vector3(8, 0, -12)
	r_forearm.add_child(weapon)
	var blade := _mi(_cyl(0.035, 0.045, 0.78), Vector3(0, 0.42, 0), weapon, "Blade")
	var hilt := _mi(_cyl(0.06, 0.06, 0.14), Vector3(0, 0.0, 0), weapon, "Hilt")
	hilt.rotation_degrees.z = 90
	var pommel := _mi(_sphere(0.055), Vector3(0, -0.10, 0), weapon, "Pommel")

	# --- Legs (same hip/knee pivots; pudgy cartoon boots) ---
	var l_leg := Node3D.new()
	l_leg.name = "LLeg"
	l_leg.position = Vector3(-0.22, 0.72, 0)
	bob.add_child(l_leg)
	var l_thigh := _mi(_capsule(0.13, 0.38), Vector3(0, -0.18, 0), l_leg, "LUpperLeg")
	var l_knee := _mi(_sphere(0.11), Vector3(0, -0.38, 0), l_leg, "LKnee")
	var l_shin_pivot := Node3D.new()
	l_shin_pivot.name = "LShinPivot"
	l_shin_pivot.position = Vector3(0, -0.38, 0)
	l_leg.add_child(l_shin_pivot)
	var l_shin := _mi(_capsule(0.11, 0.36), Vector3(0, -0.20, 0), l_shin_pivot, "LLowerLeg")
	var l_boot := _mi(_sphere(0.12, 0.16), Vector3(0, -0.28, 0), l_shin_pivot, "LBoot")
	var l_foot := _mi(_sphere(0.12, 0.14), Vector3(0, -0.38, 0.11), l_shin_pivot, "LFoot")
	l_foot.scale = Vector3(1.0, 0.85, 1.45)

	var r_leg := Node3D.new()
	r_leg.name = "RLeg"
	r_leg.position = Vector3(0.22, 0.72, 0)
	bob.add_child(r_leg)
	var r_thigh := _mi(_capsule(0.13, 0.38), Vector3(0, -0.18, 0), r_leg, "RUpperLeg")
	var r_knee := _mi(_sphere(0.11), Vector3(0, -0.38, 0), r_leg, "RKnee")
	var r_shin_pivot := Node3D.new()
	r_shin_pivot.name = "RShinPivot"
	r_shin_pivot.position = Vector3(0, -0.38, 0)
	r_leg.add_child(r_shin_pivot)
	var r_shin := _mi(_capsule(0.11, 0.36), Vector3(0, -0.20, 0), r_shin_pivot, "RLowerLeg")
	var r_boot := _mi(_sphere(0.12, 0.16), Vector3(0, -0.28, 0), r_shin_pivot, "RBoot")
	var r_foot := _mi(_sphere(0.12, 0.14), Vector3(0, -0.38, 0.11), r_shin_pivot, "RFoot")
	r_foot.scale = Vector3(1.0, 0.85, 1.45)

	return {
		"bob": bob,
		"torso": torso,
		"pelvis": pelvis,
		"hem": hem,
		"collar": collar,
		"neck": neck,
		"head": head,
		"hair": hair,
		"bangs": bangs,
		"bang_l": bang_l,
		"bang_r": bang_r,
		"hair_spike_c": hair_spike_c,
		"hair_spike_l": hair_spike_l,
		"hair_spike_r": hair_spike_r,
		"hair_spike_bl": hair_spike_bl,
		"hair_spike_br": hair_spike_br,
		"hair_spike_wl": hair_spike_wl,
		"hair_spike_wr": hair_spike_wr,
		"ahoge": ahoge,
		"hair_back": hair_back,
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
		"l_iris": l_iris,
		"r_iris": r_iris,
		"l_pupil": l_pupil,
		"r_pupil": r_pupil,
		"l_shine": l_shine,
		"r_shine": r_shine,
		"l_brow": l_brow,
		"r_brow": r_brow,
		"nose": nose,
		"mouth": mouth,
		"mouth_l": mouth_l,
		"mouth_r": mouth_r,
		"l_cheek": l_cheek,
		"r_cheek": r_cheek,
		"l_lock": l_lock,
		"r_lock": r_lock,
		"l_ear": l_ear,
		"r_ear": r_ear,
		"face_decal": face_decal,
	}


## Apply player-style colors: skin on exposed parts, outfit on clothes, etc.
static func apply_human_colors(parts: Dictionary, skin: Color, hair: Color, outfit: Color, cape_col: Color, shoe: Color = Color("#3b2f2f")) -> void:
	set_color(parts.get("head"), skin)
	set_color(parts.get("neck"), skin)
	# Soft anime hair — tint painted cards + soft fluff meshes (no ink-grow slabs).
	set_color(parts.get("hair"), hair, 0.7, false)
	set_color(parts.get("bang_l"), hair.lightened(0.05), 0.65, false)
	set_color(parts.get("bang_r"), hair.lightened(0.05), 0.65, false)
	set_color(parts.get("hair_spike_c"), hair.lightened(0.04), 0.65, false)
	set_color(parts.get("hair_spike_l"), hair.darkened(0.03), 0.68, false)
	set_color(parts.get("hair_spike_r"), hair.darkened(0.03), 0.68, false)
	set_color(parts.get("hair_spike_bl"), hair.darkened(0.06), 0.7, false)
	set_color(parts.get("hair_spike_br"), hair.darkened(0.06), 0.7, false)
	set_color(parts.get("hair_spike_wl"), hair.darkened(0.04), 0.68, false)
	set_color(parts.get("hair_spike_wr"), hair.darkened(0.04), 0.68, false)
	set_color(parts.get("l_lock"), hair.darkened(0.05), 0.68, false)
	set_color(parts.get("r_lock"), hair.darkened(0.05), 0.68, false)
	set_color(parts.get("ahoge"), hair.lightened(0.08), 0.62, false)
	_tint_card(parts.get("bangs"), hair.lightened(0.05))
	_tint_card(parts.get("hair_back"), hair)
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
	# Face — clean features without chunky ink outlines
	set_face_color(parts.get("l_eye"), Color("#fffdf8"), 0.28)
	set_face_color(parts.get("r_eye"), Color("#fffdf8"), 0.28)
	set_face_color(parts.get("l_iris"), Color("#6b4528"), 0.42)
	set_face_color(parts.get("r_iris"), Color("#6b4528"), 0.42)
	set_face_color(parts.get("l_pupil"), Color("#1a100c"), 0.38)
	set_face_color(parts.get("r_pupil"), Color("#1a100c"), 0.38)
	set_face_color(parts.get("l_shine"), Color("#ffffff"), 0.1)
	set_face_color(parts.get("r_shine"), Color("#ffffff"), 0.1)
	set_face_color(parts.get("l_brow"), hair.darkened(0.18), 0.7)
	set_face_color(parts.get("r_brow"), hair.darkened(0.18), 0.7)
	set_face_color(parts.get("nose"), skin, 0.55)
	set_face_color(parts.get("mouth"), Color("#c46870"), 0.48)
	set_face_color(parts.get("mouth_l"), Color("#c46870"), 0.48)
	set_face_color(parts.get("mouth_r"), Color("#c46870"), 0.48)
	set_face_color(parts.get("l_cheek"), skin.lerp(Color("#f2b0b6"), 0.28), 0.8)
	set_face_color(parts.get("r_cheek"), skin.lerp(Color("#f2b0b6"), 0.28), 0.8)
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


static func apply_npc_colors(parts: Dictionary, accent: Color, skin: Color = Color("#c68642")) -> void:
	var outfit := accent
	# Keep NPC hair a natural brown/auburn so accent color doesn't read as a weird hat.
	var hair := Color("#5c4033").lerp(accent.darkened(0.45), 0.25)
	apply_human_colors(parts, skin, hair, outfit, accent.darkened(0.2))
	# NPCs show a small cape stub in accent; no player armor overlays
	var cape: MeshInstance3D = parts.get("cape")
	if cape:
		cape.visible = true
	for key in ["chest_plate", "l_pad", "r_pad", "hat", "weapon", "accessory"]:
		var n: Node = parts.get(key)
		if n:
			n.visible = false
	var belt_n: MeshInstance3D = parts.get("belt")
	if belt_n:
		belt_n.visible = true


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
			# Rounded haft + soft axe head — held in the right hand
			blade = _mi(_cyl(0.04, 0.05, 0.82), Vector3(0, 0.38, 0), weapon, "Blade")
			hilt = _mi(_sphere(0.14, 0.22), Vector3(0.16, 0.72, 0), weapon, "Hilt")
			hilt.scale = Vector3(1.6, 1.0, 0.7)
			pommel = _mi(_sphere(0.07), Vector3(0, -0.12, 0), weapon, "Pommel")
			weapon.position = Vector3(0.06, -0.44, 0.06)
			weapon.rotation_degrees = Vector3(10, 0, -16)
		"staff":
			blade = _mi(_cyl(0.045, 0.055, 1.45), Vector3(0, 0.42, 0), weapon, "Blade")
			hilt = _mi(_sphere(0.10), Vector3(0, 1.12, 0), weapon, "Hilt")
			pommel = _mi(_sphere(0.06), Vector3(0, -0.28, 0), weapon, "Pommel")
			weapon.position = Vector3(0.05, -0.40, 0.04)
			weapon.rotation_degrees = Vector3(12, 0, -8)
		"bow":
			# Soft recurve silhouette held beside the arm
			blade = _mi(_capsule(0.035, 1.05), Vector3(0, 0.22, 0), weapon, "Blade")
			hilt = _mi(_capsule(0.028, 0.55), Vector3(0.16, 0.22, 0), weapon, "Hilt")
			pommel = _mi(_capsule(0.025, 0.32), Vector3(0.08, 0.62, 0), weapon, "Pommel")
			pommel.rotation_degrees.z = 90
			weapon.position = Vector3(0.10, -0.18, -0.06)
			weapon.rotation_degrees = Vector3(5, 18, -4)
		"dagger":
			blade = _mi(_cyl(0.03, 0.04, 0.40), Vector3(0, 0.18, 0), weapon, "Blade")
			hilt = _mi(_cyl(0.05, 0.05, 0.12), Vector3(0, -0.04, 0), weapon, "Hilt")
			hilt.rotation_degrees.z = 90
			pommel = _mi(_sphere(0.05), Vector3(0, -0.12, 0), weapon, "Pommel")
			weapon.position = Vector3(0.06, -0.44, 0.08)
			weapon.rotation_degrees = Vector3(6, 0, -20)
		"mallet":
			blade = _mi(_cyl(0.055, 0.06, 0.58), Vector3(0, 0.22, 0), weapon, "Blade")
			hilt = _mi(_sphere(0.14), Vector3(0, 0.56, 0), weapon, "Hilt")
			pommel = _mi(_sphere(0.07), Vector3(0, -0.12, 0), weapon, "Pommel")
			weapon.position = Vector3(0.06, -0.44, 0.06)
			weapon.rotation_degrees = Vector3(8, 0, -14)
		_:
			blade = _mi(_cyl(0.035, 0.045, 0.82), Vector3(0, 0.42, 0), weapon, "Blade")
			hilt = _mi(_cyl(0.055, 0.055, 0.14), Vector3(0, 0.0, 0), weapon, "Hilt")
			hilt.rotation_degrees.z = 90
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


## Soft armor overlays — rounded chest plate + shoulder pads when defense > 0.
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

