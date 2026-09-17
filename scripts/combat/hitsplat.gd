class_name Hitsplat
extends RefCounted
## Clear RuneScape-like floating damage / heal numbers (wholesome — no gore).

static func spawn(parent: Node, dmg: int, is_player_hit: bool, y: float = 2.15) -> void:
	_spawn(parent, dmg, "damage" if not is_player_hit else "hit_foe", y)

static func spawn_heal(parent: Node, amount: int, y: float = 2.15) -> void:
	_spawn(parent, amount, "heal", y)

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
	elif amount <= 0:
		dmat.albedo_color = Color(0.55, 0.55, 0.6, 0.75)
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

	var tw := parent.get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(root, "position:y", y + 1.1, 0.85).set_ease(Tween.EASE_OUT)
	if splat:
		tw.tween_property(splat, "modulate:a", 0.0, 0.85)
	tw.tween_property(dmat, "albedo_color:a", 0.0, 0.85)
	tw.chain().tween_callback(root.queue_free)
