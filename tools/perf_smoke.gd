extends SceneTree
## Headless perf probe for v1.84 smooth — loads world.tscn, checks foe LOD.

func _initialize() -> void:
	print("PERF_SMOKE_START")
	var world_ps: PackedScene = load("res://scenes/world/world.tscn")
	if world_ps == null:
		printerr("PERF_FAIL no world.tscn")
		quit(1)
		return
	var world: Node = world_ps.instantiate()
	get_root().add_child(world)
	# World _ready builds dense village + 263 foes; wait for it
	await process_frame
	await process_frame
	await create_timer(2.5).timeout

	print("WORLD_FOUND", world != null)
	var enemies: Array = get_nodes_in_group("enemies")
	print("ENEMY_COUNT", enemies.size())
	var hidden := 0
	var visible_n := 0
	var nav_off := 0
	var physics_off := 0
	var player: Node = get_first_node_in_group("player")
	print("PLAYER_FOUND", player != null)
	if player:
		print("PLAYER_POS", player.global_position)
	for e in enemies:
		if e == null or not is_instance_valid(e):
			continue
		if bool(e.get("_lod_hidden")):
			hidden += 1
		if e.visible:
			visible_n += 1
		var obs = e.get_node_or_null("NavObstacle")
		if obs != null and not bool(obs.avoidance_enabled):
			nav_off += 1
		if not e.is_physics_processing():
			physics_off += 1
	print("ENEMY_LOD_HIDDEN", hidden)
	print("ENEMY_VISIBLE", visible_n)
	print("ENEMY_NAV_OFF", nav_off)
	print("ENEMY_PHYSICS_OFF", physics_off)
	print("LOD_HIDES_MOST", hidden > int(enemies.size() * 0.5))
	print("LOD_SLEEPS_NAV", nav_off > int(enemies.size() * 0.5))
	print("LOD_SLEEPS_PHYS", physics_off > int(enemies.size() * 0.5))

	var player_src := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	print("SPEED_8_2", "const SPEED := 8.2" in player_src)
	var tick_src := FileAccess.get_file_as_string("res://data/enemies.json")
	print("TICK_0_55", '"tick_sec": 0.55' in tick_src)

	var samples: Array = []
	for i in 45:
		await process_frame
		samples.append(Engine.get_frames_per_second())
	var avg := 0.0
	for s in samples:
		avg += float(s)
	avg /= maxf(1.0, float(samples.size()))
	print("FPS_SAMPLES", samples.size())
	print("FPS_AVG", "%.1f" % avg)
	print("PERF_SMOKE_OK")
	quit(0)
