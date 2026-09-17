extends SceneTree
func _init():
	call_deferred("_go")
func _go():
	print("WORLD_SMOKE_START")
	# Load project main? Autoloads exist when using --path with main scene.
	# When --script is used, still load autoloads in 4.3 if project is set.
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	var aud = Engine.get_main_loop().root.get_node_or_null("AudioBus")
	print("GS", gs != null, "AUD", aud != null)
	if gs == null:
		print("NO_AUTOLOADS — falling back to direct load")
	var qdb = Engine.get_main_loop().root.get_node_or_null("QuestDB")
	var edb = Engine.get_main_loop().root.get_node_or_null("EnemyDB")
	print("QDB", qdb != null, "EDB", edb != null)
	var world_ps = load("res://scenes/world/world.tscn")
	var world = world_ps.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	await process_frame
	print("PLAYER", world.player != null)
	print("NPCS", root.get_tree().get_nodes_in_group("npcs").size())
	print("ENEMIES", root.get_tree().get_nodes_in_group("enemies").size())
	print("STATIC", world.static_world.get_child_count())
	print("INTERIORS", world.get_node_or_null("Interiors") != null)
	print("GLADE", world.static_world.get_node_or_null("LanternGlade") != null)
	print("PINE", world.static_world.get_node_or_null("PineRidge") != null)
	print("DESKS", root.get_tree().get_nodes_in_group("quest_desks").size())
	print("RAIN_AUDIO", aud != null and aud.has_method("set_rain_audio"))
	print("COMBAT_TUT", gs != null and gs.has_method("mark_combat_tutorial"))
	print("WEATHER", world.has_method("get_weather_label"), world.get_weather_label() if world.has_method("get_weather_label") else "?")
	print("MARKERS", world.has_method("get_minimap_markers"))
	if world.has_method("toggle_weather_auto"):
		world.toggle_weather_auto()
		print("WEATHER2", world.get_weather_label())
	print("WORLD_SMOKE_OK")
	quit(0)
