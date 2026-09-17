class_name Hitsplat
extends RefCounted
## Clear RuneScape-like floating damage / heal numbers (wholesome — no gore).

static func spawn(parent: Node, dmg: int, is_player_hit: bool, y: float = 2.15, strong: bool = false) -> void:
	var kind := "damage" if not is_player_hit else "hit_foe"
	if strong and dmg > 0:
		kind = "strong_hit" if not is_player_hit else "strong_foe"
	_spawn(parent, dmg, kind, y)

static func spawn_heal(parent: Node, amount: int, y: float = 2.15) -> void:
	_spawn(parent, amount, "heal", y)

static func spawn_xp(parent: Node, amount: int, y: float = 2.35) -> void:
	## Wave 40: quiet soft cream XP float on foe defeat (wholesome, no cheesy combat labels).
	_spawn(parent, amount, "xp", y)

static func _spawn(parent: Node, amount: int, kind: String, y: float) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var root := Node3D.new()
	root.position = Vector3(randf_range(-0.35, 0.35), y, randf_range(-0.15, 0.15))
	parent.add_child(root)

	# Soft disc behind the number
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.28
	cyl.bottom_radius = 0.28
	cyl.height = 0.04
	disc.mesh = cyl
	disc.rotation_degrees = Vector3(90, 0, 0)
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var label_text := "miss"
	var font_sz := 40
	var text_col := Color(0.9, 0.9, 0.95)
	var outline_col := Color(0.1, 0.1, 0.12)
	if kind == "heal":
		dmat.albedo_color = Color(0.35, 0.85, 0.45, 0.88)
		label_text = "+%d" % maxi(0, amount)
		font_sz = 52
		text_col = Color(0.05, 0.2, 0.08)
		outline_col = Color(0.85, 1.0, 0.9)
	elif kind == "xp":
		# Soft cream gold — quiet combat XP float (Wave 40)
		dmat.albedo_color = Color(0.92, 0.84, 0.45, 0.82)
		label_text = "+%d XP" % maxi(0, amount)
		font_sz = 44
		text_col = Color(0.12, 0.08, 0.02)
		outline_col = Color(1.0, 0.98, 0.88)
	elif amount <= 0:
		dmat.albedo_color = Color(0.55, 0.55, 0.6, 0.75)
	elif kind == "strong_foe":
		# Soft gold/white — crisp bright hit on foe (wholesome, not gore)
		dmat.albedo_color = Color(1.0, 0.96, 0.48, 0.95)
		label_text = str(amount)
		font_sz = 68
		text_col = Color(0.1, 0.06, 0.02)
		outline_col = Color(1, 1, 0.95)
	elif kind == "strong_hit":
		# Amber flash when player takes a heavy hit
		dmat.albedo_color = Color(1.0, 0.45, 0.2, 0.9)
		label_text = str(amount)
		font_sz = 62
		text_col = Color(0.12, 0.05, 0.02)
		outline_col = Color(1, 0.95, 0.85)
	elif kind == "hit_foe":
		dmat.albedo_color = Color(0.95, 0.82, 0.15, 0.85)  # yellow splat on foe
		label_text = str(amount)
		font_sz = 56
		text_col = Color(0.1, 0.08, 0.05)
		outline_col = Color(1, 1, 1)
	else:
		dmat.albedo_color = Color(0.9, 0.25, 0.22, 0.85)  # red splat on player
		label_text = str(amount)
		font_sz = 56
		text_col = Color(0.1, 0.08, 0.05)
		outline_col = Color(1, 1, 1)
	disc.material_override = dmat
	root.add_child(disc)
	HeadlessGuard.guard_mesh(disc)

	var splat := HeadlessGuard.make_label3d()
	if splat:
		splat.text = label_text
		splat.font_size = font_sz
		splat.modulate = text_col
		splat.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		splat.outline_size = 10
		splat.outline_modulate = outline_col
		splat.position = Vector3(0, 0.02, 0.02)
		root.add_child(splat)

	# Wave 27: soft scale pop so HP floats read chunkier (RuneScape-feel, no cheesy labels)
	root.scale = Vector3(0.72, 0.72, 0.72)
	var lift := 1.35 if kind == "xp" else (1.25 if kind in ["strong_foe", "strong_hit"] else 1.1)
	var dur := 1.15 if kind == "xp" else (0.95 if kind in ["strong_foe", "strong_hit"] else 0.85)
	var peak := 1.12 if kind == "xp" else (1.18 if kind in ["strong_foe", "strong_hit"] else 1.08)
	var tw := parent.get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(root, "scale", Vector3(peak, peak, peak), 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "position:y", y + lift, dur).set_ease(Tween.EASE_OUT)
	if splat:
		tw.tween_property(splat, "modulate:a", 0.0, dur)
	tw.tween_property(dmat, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(root.queue_free)
