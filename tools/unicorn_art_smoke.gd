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
	assert("discard" in world_src)
	assert("_set_party_unicorn_frame" in world_src)
	assert("party_unicorn_frame_%d.png" in world_src)
	assert("ShaderMaterial" in world_src)

	var root := Node3D.new()
	get_root().add_child(root)
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, specular_disabled;
uniform sampler2D unicorn_tex : source_color, filter_linear;
void fragment() {
	vec4 c = texture(unicorn_tex, UV);
	if (c.a < 0.5) { discard; }
	ALBEDO = c.rgb;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("unicorn_tex", load("res://assets/vfx/party_unicorn_frame_0.png"))
	var quad := QuadMesh.new()
	quad.size = Vector2(1.5, 2.1)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	root.add_child(mi)
	mat.set_shader_parameter("unicorn_tex", load("res://assets/vfx/party_unicorn_frame_3.png"))
	print("MESH_READY shader_ok")
	print("UNICORN_ART_SMOKE_OK")
	quit()
