extends SceneTree
func _count_meshes(root: Node) -> Dictionary:
	var by := {}
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var p: Node = n.get_parent()
			var key := "other"
			while p != null:
				var nm := str(p.name)
				if nm in ["Entities", "StaticWorld", "AmbientLife", "MeshRoot", "Player"]:
					key = nm
					break
				# climb to find enemy/npc
				if p.is_in_group("enemies"):
					key = "enemy"
					break
				if p.is_in_group("npcs"):
					key = "npc"
					break
				if p.is_in_group("player"):
					key = "player"
					break
				p = p.get_parent()
			by[key] = int(by.get(key, 0)) + 1
		for c in n.get_children():
			stack.append(c)
	return by

func _initialize() -> void:
	print("FPS_PROBE_START")
	var world_ps: PackedScene = load("res://scenes/world/world.tscn")
	var world: Node = world_ps.instantiate()
	get_root().add_child(world)
	await process_frame
	await create_timer(3.5).timeout
	var by = _count_meshes(world)
	print("MESH_BREAKDOWN", by)
	var part_emit := 0
	var part_amt := 0
	var part_n := 0
	var stack: Array = [world]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CPUParticles3D:
			part_n += 1
			var p := n as CPUParticles3D
			part_amt += p.amount
			if p.emitting and p.visible:
				part_emit += 1
		for c in n.get_children():
			stack.append(c)
	print("CPU_PARTICLE_SYSTEMS", part_n)
	print("CPU_PARTICLE_EMITTING", part_emit)
	print("CPU_PARTICLE_AMOUNT_SUM", part_amt)
	print("MESH_INSTANCES", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	# Stay at plaza — typical play
	var player = get_first_node_in_group("player")
	if player:
		player.global_position = Vector3(0, 0, 10)
	var samples: Array = []
	for i in 90:
		await process_frame
		samples.append(Engine.get_frames_per_second())
	var avg := 0.0
	var mn := 9999.0
	for s in samples:
		avg += float(s)
		mn = minf(mn, float(s))
	avg /= float(samples.size())
	print("FPS_AVG", "%.1f" % avg)
	print("FPS_MIN", "%.1f" % mn)
	print("TIME_PROCESS", Performance.get_monitor(Performance.TIME_PROCESS))
	print("TIME_PHYSICS", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))
	print("OBJECT_NODES", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("DRAW_CALLS", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("FPS_PROBE_OK")
	quit(0)
