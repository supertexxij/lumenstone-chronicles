extends SceneTree
## Headless check: opaque party unicorn frames + alpha-scissor mesh markers.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("UNICORN_ART_SMOKE_START")
	for i in 6:
		var path := "res://assets/vfx/party_unicorn_frame_%d.png" % i
		assert(ResourceLoader.exists(path), path)
		var tex: Texture2D = load(path)
		assert(tex != null)
		print("FRAME", i, " SIZE=", tex.get_width(), "x", tex.get_height())

	var world_src := FileAccess.get_file_as_string("res://scripts/world/world.gd")
	assert("TRANSPARENCY_ALPHA_SCISSOR" in world_src)
	assert("_set_party_unicorn_frame" in world_src)
	assert("party_unicorn_frame_%d.png" in world_src)

	var root := Node3D.new()
	get_root().add_child(root)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(1, 1, 1, 1)
	mat.albedo_texture = load("res://assets/vfx/party_unicorn_frame_0.png")
	var quad := QuadMesh.new()
	quad.size = Vector2(1.4, 1.95)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	root.add_child(mi)
	mat.albedo_texture = load("res://assets/vfx/party_unicorn_frame_3.png")
	print("MESH_READY transparency=", mat.transparency, " albedo_a=", mat.albedo_color.a)
	print("UNICORN_ART_SMOKE_OK")
	quit()
