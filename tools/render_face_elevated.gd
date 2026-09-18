extends SceneTree
## Render face from the elevated village-style camera angle.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(960, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#8ec5e0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.98, 0.95, 0.92)
	environment.ambient_light_energy = 0.9
	env.environment = environment
	vp.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	light.light_energy = 1.15
	vp.add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8, 8)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color("#6aa35a")
	ground.material_override = gmat
	vp.add_child(ground)
	var cam := Camera3D.new()
	cam.current = true
	vp.add_child(cam)
	# Elevated oblique camera like the in-game village view
	cam.position = Vector3(1.6, 3.4, 2.8)
	cam.look_at(Vector3(0, 1.5, 0), Vector3.UP)
	var player_root := Node3D.new()
	vp.add_child(player_root)
	var parts: Dictionary = HumanoidBuilder.build(player_root)
	HumanoidBuilder.apply_human_colors(parts, Color("#c68642"), Color("#5c4033"), Color("#f5f0e1"), Color("#c1121f"))
	var cape = parts.get("cape")
	if cape:
		cape.visible = true
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var img: Image = vp.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/better_faces_elevated_cam.png")
	# Closer elevated look at the face
	cam.position = Vector3(0.9, 2.6, 1.6)
	cam.look_at(Vector3(0, 1.85, 0.1), Vector3.UP)
	await process_frame
	await process_frame
	await process_frame
	img = vp.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/better_faces_elevated_close.png")
	print("ELEVATED_OK")
	quit(0)
