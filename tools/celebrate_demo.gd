extends SceneTree
## Visual demo: force quest fireworks + unicorn party (DISPLAY required).
## Usage: godot --path /workspace -s res://tools/celebrate_demo.gd

func _initialize() -> void:
	call_deferred("_boot")

func _boot() -> void:
	print("CELEBRATE_DEMO_BOOT")
	var err := change_scene_to_file("res://scenes/main.tscn")
	print("SCENE_ERR", err)
	get_root().ready.connect(_after_ready, CONNECT_ONE_SHOT)

func _after_ready() -> void:
	call_deferred("_kick")

func _kick() -> void:
	# Wait for world/player to exist
	await create_timer(2.5).timeout
	var world := _find_world(get_root())
	print("WORLD", world)
	if world == null:
		print("NO_WORLD")
		quit(1)
		return
	# Skip title if present — try continue / start
	var main := get_root().get_child(get_root().get_child_count() - 1)
	print("MAIN", main)
	# Force a quick new game if title is showing
	var gs: Node = get_root().get_node_or_null("/root/GameState")
	if gs and int(gs.get("unlocked_week")) <= 1 and str(gs.get("child_name")) == "Apprentice":
		if gs.has_method("new_game"):
			gs.call("new_game", "DemoKid", {"hair":"brown","skin":"medium","cape_color":"crimson","outfit":"cream"}, 0)
			gs.set("in_world", true)
	await create_timer(1.0).timeout
	world = _find_world(get_root())
	if world == null:
		print("NO_WORLD2")
		quit(1)
		return
	print("FIREWORKS")
	if world.has_method("_play_quest_victory_sparkle"):
		world.call("_play_quest_victory_sparkle", "demo-quest")
	await create_timer(2.2).timeout
	print("UNICORN_PARTY")
	if world.has_method("_play_week_unicorn_party"):
		world.call("_play_week_unicorn_party", 2, 1)
	await create_timer(8.5).timeout
	print("CELEBRATE_DEMO_OK")
	# Keep running a moment for screenshot capture
	await create_timer(1.0).timeout
	quit(0)

func _find_world(n: Node) -> Node:
	if n == null:
		return null
	if n.get_script() != null and str(n.get_script().resource_path).ends_with("world.gd"):
		return n
	if n.name == "World" or n.name == "GameWorld":
		return n
	for c in n.get_children():
		var f := _find_world(c)
		if f:
			return f
	return null
