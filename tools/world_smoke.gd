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
	var badgers := 0
	var stags := 0
	var foxes := 0
	var hares := 0
	for foe in root.get_tree().get_nodes_in_group("enemies"):
		if str(foe.get("kind")) == "moss_badger":
			badgers += 1
		if str(foe.get("kind")) == "cedar_stag":
			stags += 1
		if str(foe.get("kind")) == "pine_fox":
			foxes += 1
		if str(foe.get("kind")) == "oak_hare":
			hares += 1
	print("ENEMIES", root.get_tree().get_nodes_in_group("enemies").size())
	print("BADGERS", badgers)
	print("STAGS", stags)
	print("FOXES", foxes)
	print("HARES", hares)
	print("STATIC", world.static_world.get_child_count() if world else -1)
	print("INTERIORS", world.get_node_or_null("Interiors") != null if world else false)
	print("GLADE", world.static_world.get_node_or_null("LanternGlade") != null if world else false)
	print("PINE", world.static_world.get_node_or_null("PineRidge") != null if world else false)
	print("GARDEN", world.static_world.get_node_or_null("PrayerGarden") != null if world else false)
	print("LOOKOUT", world.static_world.get_node_or_null("LookoutRock") != null if world else false)
	print("MILL", world.static_world.get_node_or_null("MillBridge") != null if world else false)
	print("HOLLOW", world.static_world.get_node_or_null("CedarHollow") != null if world else false)
	print("REED", world.static_world.get_node_or_null("ReedPool") != null if world else false)
	print("WILLOW", world.static_world.get_node_or_null("WillowBend") != null if world else false)
	print("CROSS", world.static_world.get_node_or_null("QuietCross") != null if world else false)
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
	print("DEFENSE_BREAKDOWN", "func get_defense_breakdown" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("AMBIENT_LIFE", world.static_world.get_node_or_null("AmbientLife") != null if world else false)
	print("HIT_PAUSE", "_play_hit_pause" in FileAccess.get_file_as_string("res://scripts/ui/main.gd"))
	print("HURT_VIGNETTE", "_update_hurt_vignette" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("VILLAGE_AMBIENT", "0.0, 0, 8.0" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("ARMOR_ICONS", "_make_slot_icon" in FileAccess.get_file_as_string("res://scripts/ui/inventory_panel.gd"))
	print("HUD_DEF", "· Def" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("LATE_WILDS_TUNE", '"max_hp": 24' in FileAccess.get_file_as_string("res://data/enemies.json") and '"max_hp": 34' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("PLAZA_AMBIENT_DENSE", '"dense": true' in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("LOADOUT_ARMOR_ICONS", "SlotRows" in FileAccess.get_file_as_string("res://scripts/ui/inventory_panel.gd") and "SoftArmor" in FileAccess.get_file_as_string("res://scenes/main.tscn"))
	print("CEDAR_STAG", '"cedar_stag"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("CEDAR_HOLLOW_SRC", "_build_cedar_hollow" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("HELD_WEAPON", "r_arm.add_child(weapon)" in FileAccess.get_file_as_string("res://scripts/characters/humanoid_builder.gd"))
	print("STYLE_ARMOR", "func style_armor" in FileAccess.get_file_as_string("res://scripts/characters/humanoid_builder.gd"))
	print("YARD_ANIMALS", '"hen"' in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("YEAR_PROGRESS_API", "func get_year_progress_note" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("WILLOW_BEND_SRC", "_build_willow_bend" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("HIT_FLASH", "func _begin_hit_flash" in FileAccess.get_file_as_string("res://scripts/world/enemy.gd"))
	print("PARENT_YEAR_MASTERY", "quest mastery" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd").to_lower())
	print("REED_POOL_SRC", "_build_reed_pool" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("YEAR_CHIP_SRC", "_year_chip" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("DAILY_REMINDER_SRC", "maybe_daily_checkpoint_reminder" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("WEAPON_SWING_SRC", "Wave 22" in FileAccess.get_file_as_string("res://scripts/player/player.gd"))
	print("QUIET_CROSS_SRC", "_build_quiet_cross" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("AGGRO_RIM_SRC", "AggroRim" in FileAccess.get_file_as_string("res://scripts/world/enemy.gd"))
	print("JOURNAL_RAID_SRC", "_is_friday_raid" in FileAccess.get_file_as_string("res://scripts/ui/journal_panel.gd"))
	print("WEEK_UNLOCK_PCT_SRC", "of the year" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("STONE_ARCH_SRC", "_build_stone_arch" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("STONE_ARCH_NODE", world.static_world.get_node_or_null("StoneArch") != null if world else false)
	print("FOUNTAIN_FX_SRC", "_play_fountain_restore_fx" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("FOOD_HEAL_SRC", "healed +" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("PARENT_HELP_SRC", "Needs help:" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd") or "Needs Help —" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd"))
	print("AMBER_KNOLL_SRC", "_build_amber_knoll" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("AMBER_KNOLL_NODE", world.static_world.get_node_or_null("AmberKnoll") != null if world else false)
	print("MINIMAP_ICON_SRC", "_draw_landmark_icon" in FileAccess.get_file_as_string("res://scripts/ui/minimap.gd"))
	print("COMPASS_TICK_SRC", "_update_landmark_tick" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("UNEQUIP_TOAST_SRC", "Unequipped" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("DEF_FLASH_SRC", "softens the hit" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("WARDROBE_PREVIEW_SRC", "PreviewRow" in FileAccess.get_file_as_string("res://scripts/ui/customize_screen.gd"))
	print("BIRCH_REST_SRC", "_build_birch_rest" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("BIRCH_REST_NODE", world.static_world.get_node_or_null("BirchRest") != null if world else false)
	print("DAY_NIGHT_AUDIO_SRC", "set_day_night_audio" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("WEATHER_CLOUDS_SRC", "WeatherClouds" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("QUEST_MASTERY_PCT_SRC", "Toward mastery" in FileAccess.get_file_as_string("res://scripts/ui/quest_panel.gd"))
	print("NPC_IDLE6_SRC", "% 6" in FileAccess.get_file_as_string("res://scripts/world/npc.gd"))
	print("FERN_DELL_SRC", "_build_fern_dell" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("FERN_DELL_NODE", world.static_world.get_node_or_null("FernDell") != null if world else false)
	print("DOOR_GLOW_SRC", "_update_door_glows" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("JOURNAL_CAMP_SRC", "Kindling the Lamps" in FileAccess.get_file_as_string("res://scripts/ui/journal_panel.gd"))
	print("PARENT_SESSION_SRC", "_format_last_session" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd"))
	print("HEATHER_HEATH_SRC", "_build_heather_heath" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("HEATHER_HEATH_NODE", world.static_world.get_node_or_null("HeatherHeath") != null if world else false)
	print("DUSK_LAMPS_SRC", "_update_village_dusk_lamps" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("RAIN_SPLASH_SRC", "_setup_rain_splash" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("THISTLE_RISE_SRC", "_build_thistle_rise" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("THISTLE_RISE_NODE", world.static_world.get_node_or_null("ThistleRise") != null if world else false)
	print("FOG_MIST_SRC", "_setup_fog_mist" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("QUEST_SPARKLE_SRC", "_play_quest_victory_sparkle" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("MAPLE_COPSE_SRC", "_build_maple_copse" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("MAPLE_COPSE_NODE", world.static_world.get_node_or_null("MapleCopse") != null if world else false)
	print("WIND_LEAVES_SRC", "_setup_wind_leaves" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("PARENT_EXPORT_SRC", "get_parent_export_line" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("PINE_FOX_SRC", '"pine_fox"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("PLAZA_CAMPFIRE_NODE", world.static_world.get_node_or_null("PlazaCampfire") != null if world else false)
	print("PLAZA_CAMPFIRE_SRC", "_build_plaza_campfire" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("NPC_TALK_PROMPT_SRC", "Talk (F)" in FileAccess.get_file_as_string("res://scripts/world/npc.gd"))
	print("TARGET_RETICLE_SRC", "TargetReticle" in FileAccess.get_file_as_string("res://scripts/world/enemy.gd"))
	print("JOURNAL_MASTER_SRC", "Mastered this week" in FileAccess.get_file_as_string("res://scripts/ui/journal_panel.gd"))
	print("DAY_CASH_SRC", "award_day_cash" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd") and "DAY CASH" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("OAK_HARE_SRC", '"oak_hare"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("CAMPFIRE_SPARKS_SRC", "CampfireSparks" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("YEAR_CHIP_PLATE_SRC", "YearChipPanel" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("TALK_DUCK_SRC", "set_talk_duck" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("PANTRY_HEAL_SRC", "+%d HP" in FileAccess.get_file_as_string("res://scripts/ui/inventory_panel.gd"))
	print("WORLD_SMOKE_OK")
	quit(0)
