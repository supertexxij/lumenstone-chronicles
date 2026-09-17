class_name HeadlessGuard
extends RefCounted
## Quiet headless / dummy-renderer teardown: skip Label3D and clear mesh RIDs on exit
## so mesh_get_surface_count does not spam ERROR Parameter "m" is null.

static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


static func guard_mesh(mi: MeshInstance3D) -> MeshInstance3D:
	if mi == null or not is_headless():
		return mi
	# Clear before dummy renderer frees the RID (avoids mesh_get_surface_count spam).
	mi.tree_exiting.connect(func () -> void:
		if is_instance_valid(mi):
			mi.mesh = null
			mi.material_override = null
	)
	return mi


static func guard_particles(p: CPUParticles3D) -> void:
	if p == null or not is_headless():
		return
	p.tree_exiting.connect(func () -> void:
		if is_instance_valid(p):
			p.emitting = false
			p.mesh = null
	)


static func make_label3d() -> Label3D:
	## Label3D font meshes trip dummy storage on free — skip entirely in headless.
	if is_headless():
		return null
	return Label3D.new()


static func strip_label(node: Node) -> void:
	## Free a scene-placed Label3D when running headless.
	if node == null or not is_headless():
		return
	if node is Label3D:
		node.queue_free()
