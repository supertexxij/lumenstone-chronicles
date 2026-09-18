extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(800, 800)
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
	light.rotation_degrees = Vector3(-35, 25, 0)
	light.light_energy = 1.2
	vp.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -60, 0)
	fill.light_energy = 0.4
	vp.add_child(fill)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6, 6)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color("#6aa35a")
	ground.material_override = gmat
	vp.add_child(ground)
	var cam := Camera3D.new()
	cam.current = true
	vp.add_child(cam)
	var player_root := Node3D.new()
	vp.add_child(player_root)
	var parts: Dictionary = HumanoidBuilder.build(player_root)
	HumanoidBuilder.apply_human_colors(parts, Color("#c68642"), Color("#5c4033"), Color("#f5f0e1"), Color("#c1121f"))
	var cape = parts.get("cape")
	if cape: cape.visible = true
	cam.position = Vector3(0.15, 1.85, 1.35)
	cam.look_at(Vector3(0, 1.82, 0.1), Vector3.UP)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var img: Image = vp.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/friendly_face_hero.png")
	print("HERO_OK")
	quit(0)
