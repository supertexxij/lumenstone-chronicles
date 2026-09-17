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
	var squirrels := 0
	var raccoons := 0
	var hedgehogs := 0
	var wrens := 0
	var mice := 0
	var moles := 0
	var chipmunks := 0
	var ducks := 0
	var frogs := 0
	var turtles := 0
	var doves := 0
	var robins := 0
	var sparrows := 0
	var quails := 0
	var jays := 0
	var skinks := 0
	for foe in root.get_tree().get_nodes_in_group("enemies"):
		if str(foe.get("kind")) == "moss_badger":
			badgers += 1
		if str(foe.get("kind")) == "cedar_stag":
			stags += 1
		if str(foe.get("kind")) == "pine_fox":
			foxes += 1
		if str(foe.get("kind")) == "oak_hare":
			hares += 1
		if str(foe.get("kind")) == "birch_squirrel":
			squirrels += 1
		if str(foe.get("kind")) == "elm_raccoon":
			raccoons += 1
		if str(foe.get("kind")) == "hazel_hedgehog":
			hedgehogs += 1
		if str(foe.get("kind")) == "willow_wren":
			wrens += 1
		if str(foe.get("kind")) == "maple_mouse":
			mice += 1
		if str(foe.get("kind")) == "spruce_mole":
			moles += 1
		if str(foe.get("kind")) == "beech_chipmunk":
			chipmunks += 1
		if str(foe.get("kind")) == "alder_duck":
			ducks += 1
		if str(foe.get("kind")) == "fir_frog":
			frogs += 1
		if str(foe.get("kind")) == "cypress_turtle":
			turtles += 1
		if str(foe.get("kind")) == "poplar_dove":
			doves += 1
		if str(foe.get("kind")) == "rowan_robin":
			robins += 1
		if str(foe.get("kind")) == "ash_sparrow":
			sparrows += 1
		if str(foe.get("kind")) == "hickory_quail":
			quails += 1
		if str(foe.get("kind")) == "juniper_jay":
			jays += 1
		if str(foe.get("kind")) == "sycamore_skink":
			skinks += 1
	print("ENEMIES", root.get_tree().get_nodes_in_group("enemies").size())
	print("BADGERS", badgers)
	print("STAGS", stags)
	print("FOXES", foxes)
	print("HARES", hares)
	print("SQUIRRELS", squirrels)
	print("RACCOONS", raccoons)
	print("HEDGEHOGS", hedgehogs)
	print("WRENS", wrens)
	print("MICE", mice)
	print("MOLES", moles)
	print("CHIPMUNKS", chipmunks)
	print("DUCKS", ducks)
	print("FROGS", frogs)
	print("TURTLES", turtles)
	print("DOVES", doves)
	print("ROBINS", robins)
	print("SPARROWS", sparrows)
	print("QUAILS", quails)
	print("JAYS", jays)
	print("SKINKS", skinks)
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
	print("OAK_HARE_SRC", '"oak_hare"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("CAMPFIRE_SPARKS_SRC", "CampfireSparks" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("YEAR_CHIP_PLATE_SRC", "YearChipPanel" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("TALK_DUCK_SRC", "set_talk_duck" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("PANTRY_HEAL_SRC", "+%d HP" in FileAccess.get_file_as_string("res://scripts/ui/inventory_panel.gd"))
	print("BIRCH_SQUIRREL_SRC", '"birch_squirrel"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("CAMPFIRE_CRACKLE_SRC", "set_campfire_audio" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("SOFTER_RAIN_SRC", "Wave 33: softer rain mix" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("NEAR_MISS_SRC", "Near miss — mastery" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("NPC_STAR_SRC", "Wave 33" in FileAccess.get_file_as_string("res://scripts/ui/npc_panel.gd"))
	print("VERSION_133_SRC", 'config/version="1.33.0"' in FileAccess.get_file_as_string("res://project.godot"))
	print("ASPEN_OTTER_SRC", '"aspen_otter"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("WIND_WHOOSH_SRC", "set_wind_audio" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("LAST_TRAVEL_SRC", "last_travel_label" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("VERSION_134_SRC", 'config/version="1.34.0"' in FileAccess.get_file_as_string("res://project.godot"))
	print("ELM_RACCOON_SRC", '"elm_raccoon"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("FOOT_PITCH_SRC", "_play_foot_varied" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("HUD_HP_CLEAR_SRC", "_ensure_clear_hp_text" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("DUSK_FLICKER_SRC", "Wave 35: soft dusk lamp flicker" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("PARENT_HELP_BOLD_SRC", "WEEK %d" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd"))
	print("VERSION_135_SRC", 'config/version="1.35.0"' in FileAccess.get_file_as_string("res://project.godot"))
	print("HAZEL_HEDGEHOG_SRC", '"hazel_hedgehog"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("SWING_WHOOSH_SRC", "_play_swing_varied" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("MINIMAP_ZOOM_SRC", "Wave 36: clearer minimap zoom feel" in FileAccess.get_file_as_string("res://scripts/ui/minimap.gd"))
	print("JOURNAL_ATTEMPT_SRC", "get_latest_attempt_percent" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("VERSION_136_SRC", 'config/version="1.36.0"' in FileAccess.get_file_as_string("res://project.godot"))
	print("WILLOW_WREN_SRC", '"willow_wren"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("HALL_REVERB_SRC", "set_hall_reverb" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("LEAF_RUSTLE_SRC", "_update_leaf_rustle" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("AGGRO_COUNTDOWN_SRC", "_countdown_nudge" in FileAccess.get_file_as_string("res://scripts/world/enemy.gd"))
	print("INV_SLOT_TAGS_SRC", "SLOT_TAGS" in FileAccess.get_file_as_string("res://scripts/ui/inventory_panel.gd"))
	print("VERSION_137_SRC", 'config/version="1.37.0"' in FileAccess.get_file_as_string("res://project.godot"))

	print("MAPLE_MOUSE_SRC", '"maple_mouse"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("BROOK_MURMUR_SRC", "_update_brook_murmur" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("QUEST_CHIME_SRC", "_quest_chime" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("MUTE_CLEAR_SRC", "Muted · M" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("SAVE_CHIP_SRC", "_ensure_save_chip" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("VERSION_138_SRC", 'config/version="1.38.0"' in FileAccess.get_file_as_string("res://project.godot"))

	print("SPRUCE_MOLE_SRC", '"spruce_mole"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("DUSK_FIREFLIES_SRC", "_setup_dusk_fireflies" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("COMPASS_N_SRC", "_ensure_clear_compass_n" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("TRAVEL_SEARCH_SRC", "_refresh_travel_list" in FileAccess.get_file_as_string("res://scripts/ui/main.gd"))
	print("PANTRY_EMPTY_SRC", "fountain (H)" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("VERSION_139_SRC", 'config/version="1.39.0"' in FileAccess.get_file_as_string("res://project.godot"))

	print("BEECH_CHIPMUNK_SRC", '"beech_chipmunk"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("MILESTONE_TOAST_SRC", "✦ Milestone · Week" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("LANDMARK_NEAR_SRC", "✦ New landmark" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("XP_FLOAT_SRC", "spawn_xp" in FileAccess.get_file_as_string("res://scripts/combat/hitsplat.gd"))
	print("PARENT_PIN_SRC", "PIN changed successfully" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd"))
	print("CAMPAIGN_COUNTS_SRC", "Wave 40: campaign tab shows mastered/total" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd"))
	print("VERSION_140_SRC", 'config/version="1.40.0"' in FileAccess.get_file_as_string("res://project.godot"))

	print("ALDER_DUCK_SRC", '"alder_duck"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("PUDDLE_RIPPLES_SRC", "_setup_rain_puddle_ripples" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("FIRST_FIGHT_TIP_SRC", "First fight: soft ticks" in FileAccess.get_file_as_string("res://scripts/world/enemy.gd"))
	print("HP_COMBAT_LV_SRC", "HP %d / %d · Lv %d" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("FOOD_READY_FLASH_SRC", "_food_ready_flash_t" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("VERSION_141_SRC", 'config/version="1.41.0"' in FileAccess.get_file_as_string("res://project.godot"))

	print("FIR_FROG_SRC", '"fir_frog"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("HALL_CHATTER_SRC", "set_hall_chatter" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("FOUNTAIN_GLOW_SRC", "FountainRestoreGlow" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("WARDROBE_SPARKLE_SRC", "_play_wardrobe_equip_sparkle" in FileAccess.get_file_as_string("res://scripts/ui/customize_screen.gd"))
	print("JOURNAL_PROGRESS_SRC", "_campaign_progress_fraction" in FileAccess.get_file_as_string("res://scripts/ui/journal_panel.gd"))
	print("VERSION_142_SRC", 'config/version="1.42.0"' in FileAccess.get_file_as_string("res://project.godot"))

	print("CYPRESS_TURTLE_SRC", '"cypress_turtle"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("CRICKET_HUSH_SRC", "_night_cricket_hush" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("TRAVEL_FADE_SRC", "_soft_travel_with_fade" in FileAccess.get_file_as_string("res://scripts/ui/main.gd"))
	print("HIT_EDGE_SOFT_SRC", "_hit_edge_flash_t" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("INV_SORT_UNLOCK_SRC", "SLOT_SORT" in FileAccess.get_file_as_string("res://scripts/ui/inventory_panel.gd") and "_append_locked_gear_hints" in FileAccess.get_file_as_string("res://scripts/ui/inventory_panel.gd"))
	print("VERSION_143_SRC", 'config/version="1.43.0"' in FileAccess.get_file_as_string("res://project.godot"))

	print("POPLAR_DOVE_SRC", '"poplar_dove"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("DAWN_BIRD_SWELL_SRC", "_apply_dawn_bird_swell" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("WEATHER_CYCLE_TOAST_SRC", "Weather cycle ·" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("TALK_CAM_NUDGE_SRC", "begin_talk_camera_nudge" in FileAccess.get_file_as_string("res://scripts/player/player.gd"))
	print("PARENT_EXPORT_HELP_SRC", "Needs help:" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd") and "_relative_session_age" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd"))
	print("VERSION_144_SRC", 'config/version="1.44.0"' in FileAccess.get_file_as_string("res://project.godot"))


	print("ROWAN_ROBIN_SRC", '"rowan_robin"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("CAMPFIRE_SMOKE_SRC", "CampfireSmoke" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("MUTE_TOAST_SRC", "Muted · soft hush" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("PULLBACK_SPARKLE_SRC", "CombatPullbackSparkle" in FileAccess.get_file_as_string("res://scripts/player/player.gd"))
	print("TRAVEL_DIST_SRC", "_travel_distance_label" in FileAccess.get_file_as_string("res://scripts/ui/main.gd"))
	print("VERSION_145_SRC", 'config/version="1.45.0"' in FileAccess.get_file_as_string("res://project.godot"))


	print("ASH_SPARROW_SRC", '"ash_sparrow"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("EDGE_FOG_SRC", "_setup_edge_fog_banks" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("YEAR_FLASH_SRC", "_apply_year_chip_flash" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd"))
	print("MASTERY_GLOW_SRC", "QuestVictoryGlow" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("LANDMARK_CHIP_SRC", "_ensure_landmark_chip" in FileAccess.get_file_as_string("res://scripts/ui/hud.gd") and "landmark_name" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("VERSION_146_SRC", 'config/version="1.46.0"' in FileAccess.get_file_as_string("res://project.godot"))


	print("HICKORY_QUAIL_SRC", '"hickory_quail"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("SNOWDUST_SRC", "_setup_snowdust" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("DOOR_WHOOSH_SRC", "play_door_whoosh" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("SOFT_DEFEAT_HP_SRC", "heal_tick.emit(restored)" in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("JOURNAL_CAMPAIGN_STARS_SRC", "_count_campaign_mastered" in FileAccess.get_file_as_string("res://scripts/ui/journal_panel.gd"))
	print("VERSION_147_SRC", 'config/version="1.47.0"' in FileAccess.get_file_as_string("res://project.godot"))


	print("JUNIPER_JAY_SRC", '"juniper_jay"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("CANOPY_DRIP_SRC", "_setup_canopy_drip" in FileAccess.get_file_as_string("res://scripts/world/world.gd"))
	print("TARGET_NAMEPLATE_SRC", "_update_target_nameplate" in FileAccess.get_file_as_string("res://scripts/world/enemy.gd"))
	print("WARDROBE_CLOSE_SRC", "_play_wardrobe_close_flourish" in FileAccess.get_file_as_string("res://scripts/ui/customize_screen.gd"))
	print("EQUIP_TOAST_SRC", "Equipped %s." in FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd"))
	print("FOOD_STACK_SRC", "stack %d/%d" in FileAccess.get_file_as_string("res://scripts/ui/inventory_panel.gd"))
	print("VERSION_148_SRC", 'config/version="1.48.0"' in FileAccess.get_file_as_string("res://project.godot"))


	print("SYCAMORE_SKINK_SRC", '"sycamore_skink"' in FileAccess.get_file_as_string("res://data/enemies.json"))
	print("DUSK_OWL_SRC", "DuskOwlHoot" in FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd"))
	print("TRAVEL_PUFF_SRC", "SoftTravelLandingPuff" in FileAccess.get_file_as_string("res://scripts/ui/main.gd"))
	print("FOOD_HEAL_SPARKLE_SRC", "FoodHealSparkle" in FileAccess.get_file_as_string("res://scripts/player/player.gd"))
	print("NEEDS_HELP_HL_SRC", "Wave 49: highlight needs-help count when >0" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd") and "set_tab_tooltip" in FileAccess.get_file_as_string("res://scripts/ui/parent_panel.gd"))
	print("VERSION_149_SRC", 'config/version="1.49.0"' in FileAccess.get_file_as_string("res://project.godot"))


	print("WORLD_SMOKE_OK")
	quit(0)
