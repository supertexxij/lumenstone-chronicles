extends SceneTree
## Headless check: 3D party unicorn body is longer nose→tail than wide.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("UNICORN_MESH_PROPORTION_START")
	var CB = load("res://scripts/characters/creature_builder.gd")
	var holder := Node3D.new()
	get_root().add_child(holder)
	var bob: Node3D = CB.build("party_unicorn", holder)
	var body: MeshInstance3D = bob.get_node("Body") as MeshInstance3D
	assert(body != null)
	print("BODY_ROT=", body.rotation_degrees)
	var aabb: AABB = body.get_aabb()
	var min_v := Vector3(INF, INF, INF)
	var max_v := Vector3(-INF, -INF, -INF)
	for i in 8:
		var c: Vector3 = body.transform * aabb.get_endpoint(i)
		min_v = min_v.min(c)
		max_v = max_v.max(c)
	var size: Vector3 = max_v - min_v
	print("BODY_SIZE_XYZ=", size)
	assert(size.z > size.x * 1.5, "body must be clearly longer (Z) than wide (X)")
	assert(absf(body.rotation_degrees.x - 90.0) < 0.1)
	print("ASPECT_LENGTH_OVER_WIDTH=", size.z / size.x)
	print("UNICORN_MESH_PROPORTION_OK")
	quit()
