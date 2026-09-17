extends SceneTree

var _world: Node = null
var _frames: int = 0
var _done: bool = false

func _init():
	print("WORLD_SMOKE_START")

func _initialize():
	var gs = root.get_node_or_null("GameState")
	var aud = root.get_node_or_null("AudioBus")
	print("GS", gs != null, "AUD", aud != null)
	var qdb = root.get_node_or_null("QuestDB")
	var edb = root.get_node_or_null("EnemyDB")
	print("QDB", qdb != null, "EDB", edb != null)
	if gs:
		print("SLOTS", gs.SLOT_COUNT, "HAS0", gs.has_save(0), "PIN_DEFAULT", gs.verify_pin("1234"))
		print("PIN_SET", gs.set_parent_pin("5678"), "PIN_NEW", gs.verify_pin("5678"))
		gs.set_parent_pin("1234")
	var world_ps = load("res://scenes/world/world.tscn")
	if world_ps == null:
		print("WORLD_PACKED_NULL")
		quit(1)
		return
	_world = world_ps.instantiate()
	root.add_child(_world)
	print("WORLD_ADDED")

func _process(_delta):
	if _done:
		return
	_frames += 1
	if _frames < 8:
		return
	_done = true
	_finish()

func _finish():
	var gs = root.get_node_or_null("GameState")
	var aud = root.get_node_or_null("AudioBus")
	var world = _world
	print("PLAYER", world != null and world.get("player") != null)
	print("NPCS", root.get_tree().get_nodes_in_group("npcs").size())
	print("ENEMIES", root.get_tree().get_nodes_in_group("enemies").size())
	print("STATIC", world.static_world.get_child_count() if world else -1)
	print("INTERIORS", world.get_node_or_null("Interiors") != null if world else false)
	print("GLADE", world.static_world.get_node_or_null("LanternGlade") != null if world else false)
	print("PINE", world.static_world.get_node_or_null("PineRidge") != null if world else false)
	print("GARDEN", world.static_world.get_node_or_null("PrayerGarden") != null if world else false)
	print("LOOKOUT", world.static_world.get_node_or_null("LookoutRock") != null if world else false)
	print("DESKS", root.get_tree().get_nodes_in_group("quest_desks").size())
	print("RAIN_AUDIO", aud != null and aud.has_method("set_rain_audio"))
	print("DRIP_AUDIO", aud != null and aud.has_method("set_indoor_drip"))
	print("COMBAT_TUT", gs != null and gs.has_method("mark_combat_tutorial"))
	if world and world.has_method("get_weather_label"):
		print("WEATHER", world.get_weather_label())
	print("MARKERS", world.has_method("get_minimap_markers") if world else false)
	if world and world.has_method("toggle_weather_auto"):
		world.toggle_weather_auto()
		print("WEATHER2", world.get_weather_label())
	if world and world.has_method("set_weather"):
		world.set_weather(2, false)
		world._inside_hall = "hall-math"
		world._apply_weather_visuals(false)
		print("INDOOR_RAIN_MODE", world.get_weather_label(), "INSIDE", world._inside_hall)
		world._inside_hall = ""
		world._apply_weather_visuals(false)
	print("WORLD_SMOKE_OK")
	quit(0)
