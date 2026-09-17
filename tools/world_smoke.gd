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
	print("MILL", world.static_world.get_node_or_null("MillBridge") != null if world else false)
	print("NAV", world.get_node_or_null("OutdoorNavRegion") != null if world else false)
	print("INDOOR_NAV", world.get_node_or_null("IndoorNavRegion") != null if world else false)
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
	var gs_src = FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd")
	print("BEST_FOOD", "func use_best_consumable" in gs_src)
	print("HONEY_CAKE", '"honey_cake"' in FileAccess.get_file_as_string("res://data/items.json"))
	print("HEARTY_STEW", '"hearty_stew"' in FileAccess.get_file_as_string("res://data/items.json"))
	print("PEEK_FOOD", "func peek_best_consumable" in gs_src)
	print("PARENT_TABS", "_ensure_campaign_tabs" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd"))
	print("WASD_FORCED", "set_velocity_forced" in FileAccess.get_file_as_string("res://scripts/player/player.gd"))
	print("FOUNTAIN_REST", "func rest_at_fountain" in gs_src)
	print("HEADLESS_GUARD", FileAccess.file_exists("res://scripts/util/headless_guard.gd"))
	print("PARENT_WEEK_ROWS", "_add_week_row" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd"))
	print("CLICK_MARKER", "_show_click_marker" in FileAccess.get_file_as_string("res://scripts/player/player.gd"))
	print("FOOT_DUST", "_puff_foot_dust" in FileAccess.get_file_as_string("res://scripts/player/player.gd"))
	print("LANDMARK_APPROACH", "_update_landmark_approach" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("STRONG_HIT", "strong_foe" in FileAccess.get_file_as_string("res://scripts/combat/hitsplat.gd"))
	print("KILL_FLASH", "_begin_kill_flash" in FileAccess.get_file_as_string("res://scripts/world/enemy.gd"))
	print("PARENT_EXPAND_PERSIST", "expanded_weeks" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("LANDMARK_GREET", "greeted_landmarks" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("SOFT_TRAVEL_NOTE", world.has_method("note_soft_travel_arrival") if world else false)
	print("CRIT_VARIANCE", "bright" in FileAccess.get_file_as_string("res://scripts/world/enemy.gd"))
	print("SPUR_DENSITY", "LookoutTrim" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("DEFENSE_API", "func get_defense" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("DISCOVERED_LANDMARKS", "discovered_landmarks" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("FIRST_TOAST", "first_toast" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("INCOMING_VARIANCE", "get_defense" in FileAccess.get_file_as_string("res://scripts/world/enemy.gd"))
	print("KILL_FLASH_RESTORE", "_restore_kill_flash_colors" in FileAccess.get_file_as_string("res://scripts/world/enemy.gd"))
	print("SPUR_DENSITY_W15", "GladeTrim" in FileAccess.get_file_as_string("res://scripts/world/world.gd") and "RidgeTrim" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("WORLD_SMOKE_OK")
	quit(0)
