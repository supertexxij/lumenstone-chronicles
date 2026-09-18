extends SceneTree
## Headless: build cartoon humanoids into a SubViewport and save a PNG for walkthrough proof.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(960, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#7eb8d4")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.95, 0.92, 0.88)
	environment.ambient_light_energy = 0.85
	env.environment = environment
	vp.add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, 35, 0)
	light.light_energy = 1.15
	vp.add_child(light)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -50, 0)
	fill.light_energy = 0.35
	fill.light_color = Color(0.85, 0.9, 1.0)
	vp.add_child(fill)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color("#5a8f4a")
	gmat.roughness = 0.9
	ground.material_override = gmat
	vp.add_child(ground)

	var cam := Camera3D.new()
	cam.current = true
	vp.add_child(cam)
	cam.position = Vector3(2.4, 2.8, 3.6)
	cam.look_at(Vector3(0.4, 1.1, 0), Vector3.UP)

	# Player-style apprentice
	var player_root := Node3D.new()
	player_root.position = Vector3(-0.55, 0, 0)
	vp.add_child(player_root)
	var p_parts: Dictionary = HumanoidBuilder.build(player_root)
	HumanoidBuilder.apply_human_colors(
		p_parts,
		Color("#c68642"),
		Color("#5c4033"),
		Color("#f5f0e1"),
		Color("#c1121f")
	)
	# Show cape + a soft sword so gear reads cartoon too
	var cape: MeshInstance3D = p_parts.get("cape")
	if cape:
		cape.visible = true
	HumanoidBuilder.style_weapon(p_parts, {"id": "sword_wood", "name": "Wood Sword", "mesh": "sword", "color": "#a67c52"})
	var weapon: Node3D = p_parts.get("weapon")
	if weapon:
		weapon.visible = true

	# NPC mentor accent
	var npc_root := Node3D.new()
	npc_root.position = Vector3(0.85, 0, 0.2)
	npc_root.rotation_degrees.y = -25
	vp.add_child(npc_root)
	var n_parts: Dictionary = HumanoidBuilder.build(npc_root)
	HumanoidBuilder.apply_npc_colors(n_parts, Color("#2a6fbb"), Color("#e0b48a"))

	# Wait a few frames for the viewport to draw
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("RENDER_FAIL null image")
		quit(1)
		return
	var out_path := "/opt/cursor/artifacts/friendly_faces_pair.png"
	DirAccess.make_dir_recursive_absolute("/opt/cursor/artifacts")
	var err := img.save_png(out_path)
	print("RENDER_PNG ", out_path, " ", err == OK, " torso=", p_parts["torso"].mesh.get_class(), " head=", p_parts["head"].mesh.get_class(), " foot=", p_parts["l_foot"].mesh.get_class())
	# Face-forward close-up so eyes / smile are easy to judge
	player_root.rotation_degrees.y = 8
	npc_root.position = Vector3(1.05, 0, 0.15)
	npc_root.rotation_degrees.y = -8
	cam.position = Vector3(0.5, 1.95, 1.85)
	cam.look_at(Vector3(0.2, 1.82, 0.15), Vector3.UP)
	await process_frame
	await process_frame
	await process_frame
	var img2: Image = vp.get_texture().get_image()
	var out2 := "/opt/cursor/artifacts/friendly_faces_closeup.png"
	img2.save_png(out2)
	print("RENDER_CLOSE ", out2)
	print("RENDER_OK")
	quit(0)
