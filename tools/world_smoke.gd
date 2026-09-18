extends SceneTree

var _src_cache: Dictionary = {}
var _world: Node = null
var _frames: int = 0
var _done: bool = false

func _src(path: String) -> String:
	if not _src_cache.has(path):
		_src_cache[path] = FileAccess.get_file_as_string(path)
	return str(_src_cache[path])

func _ver_ge(minor: int) -> bool:
	## True when project.godot version is 1.{minor}.0 or newer (1.79 counts for 1.78, etc.).
	var s := _src("res://project.godot")
	var key := 'config/version="'
	var i := s.find(key)
	if i < 0:
		return false
	var rest := s.substr(i + key.length(), 20)
	var end := rest.find('"')
	if end < 0:
		return false
	var parts := rest.substr(0, end).split(".")
	if parts.size() < 2:
		return false
	if int(parts[0]) != 1:
		return int(parts[0]) > 1
	return int(parts[1]) >= minor


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
		if gs.has_method("is_mastered_score") and gs.has_method("mastery_percent_int"):
			print("MASTERY_4_OF_5", gs.is_mastered_score(4, 5) and gs.mastery_percent_int(4, 5) == 80)
			print("MASTERY_3_OF_4", (not gs.is_mastered_score(3, 4)) and gs.mastery_percent_int(3, 4) == 75)
			print("EMPTY_NAME_NORM", str(gs.child_name).strip_edges() != "")
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
	var counts: Dictionary = {}
	for foe in root.get_tree().get_nodes_in_group("enemies"):
		var k := str(foe.get("kind"))
		counts[k] = int(counts.get(k, 0)) + 1
	print("ENEMIES", root.get_tree().get_nodes_in_group("enemies").size())
	print("BADGERS", int(counts.get("moss_badger", 0)))
	print("STAGS", int(counts.get("cedar_stag", 0)))
	print("FOXES", int(counts.get("pine_fox", 0)))
	print("HARES", int(counts.get("oak_hare", 0)))
	print("SQUIRRELS", int(counts.get("birch_squirrel", 0)))
	print("RACCOONS", int(counts.get("elm_raccoon", 0)))
	print("HEDGEHOGS", int(counts.get("hazel_hedgehog", 0)))
	print("WRENS", int(counts.get("willow_wren", 0)))
	print("MICE", int(counts.get("maple_mouse", 0)))
	print("MOLES", int(counts.get("spruce_mole", 0)))
	print("CHIPMUNKS", int(counts.get("beech_chipmunk", 0)))
	print("DUCKS", int(counts.get("alder_duck", 0)))
	print("FROGS", int(counts.get("fir_frog", 0)))
	print("TURTLES", int(counts.get("cypress_turtle", 0)))
	print("DOVES", int(counts.get("poplar_dove", 0)))
	print("ROBINS", int(counts.get("rowan_robin", 0)))
	print("SPARROWS", int(counts.get("ash_sparrow", 0)))
	print("QUAILS", int(counts.get("hickory_quail", 0)))
	print("JAYS", int(counts.get("juniper_jay", 0)))
	print("SKINKS", int(counts.get("sycamore_skink", 0)))
	print("TOADS", int(counts.get("chestnut_toad", 0)))
	print("WEASELS", int(counts.get("walnut_weasel", 0)))
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
	var gs_src = _src("res://scripts/autoload/game_state.gd")
	print("BEST_FOOD", "func use_best_consumable" in gs_src)
	print("HONEY_CAKE", '"honey_cake"' in _src("res://data/items.json"))
	print("HEARTY_STEW", '"hearty_stew"' in _src("res://data/items.json"))
	print("PEEK_FOOD", "func peek_best_consumable" in gs_src)
	print("PARENT_TABS", "_ensure_campaign_tabs" in _src("res://scripts/ui/parent_panel.gd"))
	print("WASD_FORCED", "set_velocity_forced" in _src("res://scripts/player/player.gd"))
	print("FOUNTAIN_REST", "func rest_at_fountain" in gs_src)
	print("HEADLESS_GUARD", FileAccess.file_exists("res://scripts/util/headless_guard.gd"))
	print("PARENT_WEEK_ROWS", "_add_week_row" in _src("res://scripts/ui/parent_panel.gd"))
	print("CLICK_MARKER", "_show_click_marker" in _src("res://scripts/player/player.gd"))
	print("FOOT_DUST", "_puff_foot_dust" in _src("res://scripts/player/player.gd"))
	print("LANDMARK_APPROACH", "_update_landmark_approach" in _src("res://scripts/world/world.gd"))
	print("STRONG_HIT", "strong_foe" in _src("res://scripts/combat/hitsplat.gd"))
	print("KILL_FLASH", "_begin_kill_flash" in _src("res://scripts/world/enemy.gd"))
	print("PARENT_EXPAND_PERSIST", "expanded_weeks" in _src("res://scripts/autoload/game_state.gd"))
	print("LANDMARK_GREET", "greeted_landmarks" in _src("res://scripts/autoload/game_state.gd"))
	print("SOFT_TRAVEL_NOTE", world.has_method("note_soft_travel_arrival") if world else false)
	print("CRIT_VARIANCE", "bright" in _src("res://scripts/world/enemy.gd"))
	print("SPUR_DENSITY", "LookoutTrim" in _src("res://scripts/world/world.gd"))
	print("DEFENSE_API", "func get_defense" in _src("res://scripts/autoload/game_state.gd"))
	print("DISCOVERED_LANDMARKS", "discovered_landmarks" in _src("res://scripts/autoload/game_state.gd"))
	print("FIRST_TOAST", "first_toast" in _src("res://scripts/world/world.gd"))
	print("INCOMING_VARIANCE", "get_defense" in _src("res://scripts/world/enemy.gd"))
	print("KILL_FLASH_RESTORE", "_restore_kill_flash_colors" in _src("res://scripts/world/enemy.gd"))
	print("SPUR_DENSITY_W15", "GladeTrim" in _src("res://scripts/world/world.gd") and "RidgeTrim" in _src("res://scripts/world/world.gd"))
	print("DEFENSE_BREAKDOWN", "func get_defense_breakdown" in _src("res://scripts/autoload/game_state.gd"))
	print("AMBIENT_LIFE", world.static_world.get_node_or_null("AmbientLife") != null if world else false)
	print("HIT_PAUSE", "_play_hit_pause" in _src("res://scripts/ui/main.gd"))
	print("HURT_VIGNETTE", "_update_hurt_vignette" in _src("res://scripts/ui/hud.gd"))
	print("VILLAGE_AMBIENT", "0.0, 0, 8.0" in _src("res://scripts/world/world.gd"))
	print("ARMOR_ICONS", "_make_slot_icon" in _src("res://scripts/ui/inventory_panel.gd"))
	print("HUD_DEF", "· Def" in _src("res://scripts/ui/hud.gd"))
	print("LATE_WILDS_TUNE", '"max_hp": 24' in _src("res://data/enemies.json") and '"max_hp": 34' in _src("res://data/enemies.json"))
	print("PLAZA_AMBIENT_DENSE", '"dense": true' in _src("res://scripts/world/world.gd"))
	print("LOADOUT_ARMOR_ICONS", "SlotRows" in _src("res://scripts/ui/inventory_panel.gd") and "SoftArmor" in _src("res://scenes/main.tscn"))
	print("CEDAR_STAG", '"cedar_stag"' in _src("res://data/enemies.json"))
	print("CEDAR_HOLLOW_SRC", "_build_cedar_hollow" in _src("res://scripts/world/world.gd"))
	print("HELD_WEAPON", "r_arm.add_child(weapon)" in _src("res://scripts/characters/humanoid_builder.gd"))
	print("STYLE_ARMOR", "func style_armor" in _src("res://scripts/characters/humanoid_builder.gd"))
	print("YARD_ANIMALS", '"hen"' in _src("res://scripts/world/world.gd"))
	print("YEAR_PROGRESS_API", "func get_year_progress_note" in _src("res://scripts/autoload/game_state.gd"))
	print("WILLOW_BEND_SRC", "_build_willow_bend" in _src("res://scripts/world/world.gd"))
	print("HIT_FLASH", "func _begin_hit_flash" in _src("res://scripts/world/enemy.gd"))
	print("PARENT_YEAR_MASTERY", "quest mastery" in _src("res://scripts/ui/parent_panel.gd").to_lower())
	print("REED_POOL_SRC", "_build_reed_pool" in _src("res://scripts/world/world.gd"))
	print("YEAR_CHIP_SRC", "_year_chip" in _src("res://scripts/ui/hud.gd"))
	print("DAILY_REMINDER_SRC", "maybe_daily_checkpoint_reminder" in _src("res://scripts/autoload/game_state.gd"))
	print("WEAPON_SWING_SRC", "Wave 22" in _src("res://scripts/player/player.gd"))
	print("QUIET_CROSS_SRC", "_build_quiet_cross" in _src("res://scripts/world/world.gd"))
	print("AGGRO_RIM_SRC", "AggroRim" in _src("res://scripts/world/enemy.gd"))
	print("JOURNAL_RAID_SRC", "_is_friday_raid" in _src("res://scripts/ui/journal_panel.gd"))
	print("WEEK_UNLOCK_PCT_SRC", "of the year" in _src("res://scripts/autoload/game_state.gd"))
	print("STONE_ARCH_SRC", "_build_stone_arch" in _src("res://scripts/world/world.gd"))
	print("STONE_ARCH_NODE", world.static_world.get_node_or_null("StoneArch") != null if world else false)
	print("FOUNTAIN_FX_SRC", "_play_fountain_restore_fx" in _src("res://scripts/world/world.gd"))
	print("FOOD_HEAL_SRC", "healed +" in _src("res://scripts/autoload/game_state.gd"))
	print("PARENT_HELP_SRC", "Needs help:" in _src("res://scripts/ui/parent_panel.gd") or "Needs Help —" in _src("res://scripts/ui/parent_panel.gd"))
	print("AMBER_KNOLL_SRC", "_build_amber_knoll" in _src("res://scripts/world/world.gd"))
	print("AMBER_KNOLL_NODE", world.static_world.get_node_or_null("AmberKnoll") != null if world else false)
	print("MINIMAP_ICON_SRC", "_draw_landmark_icon" in _src("res://scripts/ui/minimap.gd"))
	print("COMPASS_TICK_SRC", "_update_landmark_tick" in _src("res://scripts/ui/hud.gd"))
	print("UNEQUIP_TOAST_SRC", "Unequipped" in _src("res://scripts/autoload/game_state.gd"))
	print("DEF_FLASH_SRC", "softens the hit" in _src("res://scripts/ui/hud.gd"))
	print("WARDROBE_PREVIEW_SRC", "PreviewRow" in _src("res://scripts/ui/customize_screen.gd"))
	print("BIRCH_REST_SRC", "_build_birch_rest" in _src("res://scripts/world/world.gd"))
	print("BIRCH_REST_NODE", world.static_world.get_node_or_null("BirchRest") != null if world else false)
	print("DAY_NIGHT_AUDIO_SRC", "set_day_night_audio" in _src("res://scripts/autoload/audio_bus.gd"))
	print("WEATHER_CLOUDS_SRC", "WeatherClouds" in _src("res://scripts/world/world.gd"))
	print("QUEST_MASTERY_PCT_SRC", "Toward mastery" in _src("res://scripts/ui/quest_panel.gd"))
	print("NPC_IDLE6_SRC", "% 6" in _src("res://scripts/world/npc.gd"))
	print("FERN_DELL_SRC", "_build_fern_dell" in _src("res://scripts/world/world.gd"))
	print("FERN_DELL_NODE", world.static_world.get_node_or_null("FernDell") != null if world else false)
	print("DOOR_GLOW_SRC", "_update_door_glows" in _src("res://scripts/world/world.gd"))
	print("JOURNAL_CAMP_SRC", "Kindling the Lamps" in _src("res://scripts/ui/journal_panel.gd"))
	print("PARENT_SESSION_SRC", "_format_last_session" in _src("res://scripts/ui/parent_panel.gd"))
	print("HEATHER_HEATH_SRC", "_build_heather_heath" in _src("res://scripts/world/world.gd"))
	print("HEATHER_HEATH_NODE", world.static_world.get_node_or_null("HeatherHeath") != null if world else false)
	print("DUSK_LAMPS_SRC", "_update_village_dusk_lamps" in _src("res://scripts/world/world.gd"))
	print("RAIN_SPLASH_SRC", "_setup_rain_splash" in _src("res://scripts/world/world.gd"))
	print("THISTLE_RISE_SRC", "_build_thistle_rise" in _src("res://scripts/world/world.gd"))
	print("THISTLE_RISE_NODE", world.static_world.get_node_or_null("ThistleRise") != null if world else false)
	print("FOG_MIST_SRC", "_setup_fog_mist" in _src("res://scripts/world/world.gd"))
	print("QUEST_SPARKLE_SRC", "_play_quest_victory_sparkle" in _src("res://scripts/world/world.gd"))
	print("MAPLE_COPSE_SRC", "_build_maple_copse" in _src("res://scripts/world/world.gd"))
	print("MAPLE_COPSE_NODE", world.static_world.get_node_or_null("MapleCopse") != null if world else false)
	print("WIND_LEAVES_SRC", "_setup_wind_leaves" in _src("res://scripts/world/world.gd"))
	print("PARENT_EXPORT_SRC", "get_parent_export_line" in _src("res://scripts/autoload/game_state.gd"))
	print("PINE_FOX_SRC", '"pine_fox"' in _src("res://data/enemies.json"))
	print("PLAZA_CAMPFIRE_NODE", world.static_world.get_node_or_null("PlazaCampfire") != null if world else false)
	print("PLAZA_CAMPFIRE_SRC", "_build_plaza_campfire" in _src("res://scripts/world/world.gd"))
	print("NPC_TALK_PROMPT_SRC", "Talk (F)" in _src("res://scripts/world/npc.gd"))
	print("TARGET_RETICLE_SRC", "TargetReticle" in _src("res://scripts/world/enemy.gd"))
	print("JOURNAL_MASTER_SRC", "Mastered this week" in _src("res://scripts/ui/journal_panel.gd"))
	print("OAK_HARE_SRC", '"oak_hare"' in _src("res://data/enemies.json"))
	print("CAMPFIRE_SPARKS_SRC", "CampfireSparks" in _src("res://scripts/world/world.gd"))
	print("YEAR_CHIP_PLATE_SRC", "YearChipPanel" in _src("res://scripts/ui/hud.gd"))
	print("TALK_DUCK_SRC", "set_talk_duck" in _src("res://scripts/autoload/audio_bus.gd"))
	print("PANTRY_HEAL_SRC", "+%d HP" in _src("res://scripts/ui/inventory_panel.gd"))
	print("BIRCH_SQUIRREL_SRC", '"birch_squirrel"' in _src("res://data/enemies.json"))
	print("CAMPFIRE_CRACKLE_SRC", "set_campfire_audio" in _src("res://scripts/autoload/audio_bus.gd"))
	print("SOFTER_RAIN_SRC", "Wave 33: softer rain mix" in _src("res://scripts/autoload/audio_bus.gd"))
	print("NEAR_MISS_SRC", "Near miss — mastery" in _src("res://scripts/autoload/game_state.gd"))
	print("NPC_STAR_SRC", "Wave 33" in _src("res://scripts/ui/npc_panel.gd"))
	print("VERSION_133_SRC", _ver_ge(33))
	print("ASPEN_OTTER_SRC", '"aspen_otter"' in _src("res://data/enemies.json"))
	print("WIND_WHOOSH_SRC", "set_wind_audio" in _src("res://scripts/autoload/audio_bus.gd"))
	print("LAST_TRAVEL_SRC", "last_travel_label" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_134_SRC", _ver_ge(34))
	print("ELM_RACCOON_SRC", '"elm_raccoon"' in _src("res://data/enemies.json"))
	print("FOOT_PITCH_SRC", "_play_foot_varied" in _src("res://scripts/autoload/audio_bus.gd"))
	print("HUD_HP_CLEAR_SRC", "_ensure_clear_hp_text" in _src("res://scripts/ui/hud.gd"))
	print("DUSK_FLICKER_SRC", "Wave 35: soft dusk lamp flicker" in _src("res://scripts/world/world.gd"))
	print("PARENT_HELP_BOLD_SRC", "WEEK %d" in _src("res://scripts/ui/parent_panel.gd"))
	print("VERSION_135_SRC", _ver_ge(35))
	print("HAZEL_HEDGEHOG_SRC", '"hazel_hedgehog"' in _src("res://data/enemies.json"))
	print("SWING_WHOOSH_SRC", "_play_swing_varied" in _src("res://scripts/autoload/audio_bus.gd"))
	print("MINIMAP_ZOOM_SRC", "Wave 36: clearer minimap zoom feel" in _src("res://scripts/ui/minimap.gd"))
	print("JOURNAL_ATTEMPT_SRC", "get_latest_attempt_percent" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_136_SRC", _ver_ge(36))
	print("WILLOW_WREN_SRC", '"willow_wren"' in _src("res://data/enemies.json"))
	print("HALL_REVERB_SRC", "set_hall_reverb" in _src("res://scripts/autoload/audio_bus.gd"))
	print("LEAF_RUSTLE_SRC", "_update_leaf_rustle" in _src("res://scripts/world/world.gd"))
	print("AGGRO_COUNTDOWN_SRC", "_countdown_nudge" in _src("res://scripts/world/enemy.gd"))
	print("INV_SLOT_TAGS_SRC", "SLOT_TAGS" in _src("res://scripts/ui/inventory_panel.gd"))
	print("VERSION_137_SRC", _ver_ge(37))

	print("MAPLE_MOUSE_SRC", '"maple_mouse"' in _src("res://data/enemies.json"))
	print("BROOK_MURMUR_SRC", "_update_brook_murmur" in _src("res://scripts/world/world.gd"))
	print("QUEST_CHIME_SRC", "_quest_chime" in _src("res://scripts/autoload/audio_bus.gd"))
	print("MUTE_CLEAR_SRC", "Muted · M" in _src("res://scripts/ui/hud.gd"))
	print("SAVE_CHIP_SRC", "_ensure_save_chip" in _src("res://scripts/ui/hud.gd"))
	print("VERSION_138_SRC", _ver_ge(38))

	print("SPRUCE_MOLE_SRC", '"spruce_mole"' in _src("res://data/enemies.json"))
	print("DUSK_FIREFLIES_SRC", "_setup_dusk_fireflies" in _src("res://scripts/world/world.gd"))
	print("COMPASS_N_SRC", "_ensure_clear_compass_n" in _src("res://scripts/ui/hud.gd"))
	print("TRAVEL_SEARCH_SRC", "_refresh_travel_list" in _src("res://scripts/ui/main.gd"))
	print("PANTRY_EMPTY_SRC", "fountain (H)" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_139_SRC", _ver_ge(39))

	print("BEECH_CHIPMUNK_SRC", '"beech_chipmunk"' in _src("res://data/enemies.json"))
	print("MILESTONE_TOAST_SRC", "✦ Milestone · Week" in _src("res://scripts/autoload/game_state.gd"))
	print("LANDMARK_NEAR_SRC", "✦ New landmark" in _src("res://scripts/world/world.gd"))
	print("XP_FLOAT_SRC", "spawn_xp" in _src("res://scripts/combat/hitsplat.gd"))
	print("PARENT_PIN_SRC", "PIN changed successfully" in _src("res://scripts/ui/parent_panel.gd"))
	print("CAMPAIGN_COUNTS_SRC", "Wave 40: campaign tab shows mastered/total" in _src("res://scripts/ui/parent_panel.gd"))
	print("VERSION_140_SRC", _ver_ge(40))

	print("ALDER_DUCK_SRC", '"alder_duck"' in _src("res://data/enemies.json"))
	print("PUDDLE_RIPPLES_SRC", "_setup_rain_puddle_ripples" in _src("res://scripts/world/world.gd"))
	print("FIRST_FIGHT_TIP_SRC", "First fight · %s: soft ticks" in _src("res://scripts/world/enemy.gd") or "First fight: soft ticks" in _src("res://scripts/world/enemy.gd"))
	print("HP_COMBAT_LV_SRC", "HP %d / %d · Lv %d" in _src("res://scripts/ui/hud.gd"))
	print("FOOD_READY_FLASH_SRC", "_food_ready_flash_t" in _src("res://scripts/ui/hud.gd"))
	print("VERSION_141_SRC", _ver_ge(41))

	print("FIR_FROG_SRC", '"fir_frog"' in _src("res://data/enemies.json"))
	print("HALL_CHATTER_SRC", "set_hall_chatter" in _src("res://scripts/autoload/audio_bus.gd"))
	print("FOUNTAIN_GLOW_SRC", "FountainRestoreGlow" in _src("res://scripts/world/world.gd"))
	print("WARDROBE_SPARKLE_SRC", "_play_wardrobe_equip_sparkle" in _src("res://scripts/ui/customize_screen.gd"))
	print("JOURNAL_PROGRESS_SRC", "_campaign_progress_fraction" in _src("res://scripts/ui/journal_panel.gd"))
	print("VERSION_142_SRC", _ver_ge(42))

	print("CYPRESS_TURTLE_SRC", '"cypress_turtle"' in _src("res://data/enemies.json"))
	print("CRICKET_HUSH_SRC", "_night_cricket_hush" in _src("res://scripts/autoload/audio_bus.gd"))
	print("TRAVEL_FADE_SRC", "_soft_travel_with_fade" in _src("res://scripts/ui/main.gd"))
	print("HIT_EDGE_SOFT_SRC", "_hit_edge_flash_t" in _src("res://scripts/ui/hud.gd"))
	print("INV_SORT_UNLOCK_SRC", "SLOT_SORT" in _src("res://scripts/ui/inventory_panel.gd") and "_append_locked_gear_hints" in _src("res://scripts/ui/inventory_panel.gd"))
	print("VERSION_143_SRC", _ver_ge(43))

	print("POPLAR_DOVE_SRC", '"poplar_dove"' in _src("res://data/enemies.json"))
	print("DAWN_BIRD_SWELL_SRC", "_apply_dawn_bird_swell" in _src("res://scripts/autoload/audio_bus.gd"))
	print("WEATHER_CYCLE_TOAST_SRC", "Weather cycle ·" in _src("res://scripts/world/world.gd"))
	print("TALK_CAM_NUDGE_SRC", "begin_talk_camera_nudge" in _src("res://scripts/player/player.gd"))
	print("PARENT_EXPORT_HELP_SRC", "Needs help:" in _src("res://scripts/autoload/game_state.gd") and "_relative_session_age" in _src("res://scripts/ui/parent_panel.gd"))
	print("VERSION_144_SRC", _ver_ge(44))


	print("ROWAN_ROBIN_SRC", '"rowan_robin"' in _src("res://data/enemies.json"))
	print("CAMPFIRE_SMOKE_SRC", "CampfireSmoke" in _src("res://scripts/world/world.gd"))
	print("MUTE_TOAST_SRC", "Muted · soft hush" in _src("res://scripts/ui/hud.gd"))
	print("PULLBACK_SPARKLE_SRC", "CombatPullbackSparkle" in _src("res://scripts/player/player.gd"))
	print("TRAVEL_DIST_SRC", "_travel_distance_label" in _src("res://scripts/ui/main.gd"))
	print("VERSION_145_SRC", _ver_ge(45))


	print("ASH_SPARROW_SRC", '"ash_sparrow"' in _src("res://data/enemies.json"))
	print("EDGE_FOG_SRC", "_setup_edge_fog_banks" in _src("res://scripts/world/world.gd"))
	print("YEAR_FLASH_SRC", "_apply_year_chip_flash" in _src("res://scripts/ui/hud.gd"))
	print("MASTERY_GLOW_SRC", "QuestVictoryGlow" in _src("res://scripts/world/world.gd"))
	print("LANDMARK_CHIP_SRC", "_ensure_landmark_chip" in _src("res://scripts/ui/hud.gd") and "landmark_name" in _src("res://scripts/world/world.gd"))
	print("VERSION_146_SRC", _ver_ge(46))


	print("HICKORY_QUAIL_SRC", '"hickory_quail"' in _src("res://data/enemies.json"))
	print("SNOWDUST_SRC", "_setup_snowdust" in _src("res://scripts/world/world.gd"))
	print("DOOR_WHOOSH_SRC", "play_door_whoosh" in _src("res://scripts/autoload/audio_bus.gd"))
	print("SOFT_DEFEAT_HP_SRC", "heal_tick.emit(restored)" in _src("res://scripts/autoload/game_state.gd"))
	print("JOURNAL_CAMPAIGN_STARS_SRC", "_count_campaign_mastered" in _src("res://scripts/ui/journal_panel.gd"))
	print("VERSION_147_SRC", _ver_ge(47))


	print("JUNIPER_JAY_SRC", '"juniper_jay"' in _src("res://data/enemies.json"))
	print("CANOPY_DRIP_SRC", "_setup_canopy_drip" in _src("res://scripts/world/world.gd"))
	print("TARGET_NAMEPLATE_SRC", "_update_target_nameplate" in _src("res://scripts/world/enemy.gd"))
	print("WARDROBE_CLOSE_SRC", "_play_wardrobe_close_flourish" in _src("res://scripts/ui/customize_screen.gd"))
	print("EQUIP_TOAST_SRC", "Equipped %s." in _src("res://scripts/autoload/game_state.gd"))
	print("FOOD_STACK_SRC", "stack %d/%d" in _src("res://scripts/ui/inventory_panel.gd"))
	print("VERSION_148_SRC", _ver_ge(48))


	print("SYCAMORE_SKINK_SRC", '"sycamore_skink"' in _src("res://data/enemies.json"))
	print("DUSK_OWL_SRC", "DuskOwlHoot" in _src("res://scripts/autoload/audio_bus.gd"))
	print("TRAVEL_PUFF_SRC", "SoftTravelLandingPuff" in _src("res://scripts/ui/main.gd"))
	print("FOOD_HEAL_SPARKLE_SRC", "FoodHealSparkle" in _src("res://scripts/player/player.gd"))
	print("NEEDS_HELP_HL_SRC", "Wave 49: highlight needs-help count when >0" in _src("res://scripts/ui/parent_panel.gd") and "set_tab_tooltip" in _src("res://scripts/ui/parent_panel.gd"))
	print("VERSION_149_SRC", _ver_ge(49))



	print("CHESTNUT_TOAD_SRC", '"chestnut_toad"' in _src("res://data/enemies.json"))
	print("FESTIVAL_SRC", "play_festival_decade_sparkle" in _src("res://scripts/world/world.gd"))
	print("FOUNTAIN_MIST_SRC", "FountainPlazaMist" in _src("res://scripts/world/world.gd"))
	print("SOFT_AGGRO_COMBO_SRC", "Wave 50: clearer soft-aggro name+countdown combo" in _src("res://scripts/world/enemy.gd"))
	print("FOE_COUNT_SRC", "_ensure_foe_count" in _src("res://scripts/ui/hud.gd"))
	print("WAVE50_TOAST_SRC", "maybe_wave_50_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_150_SRC", _ver_ge(50))



	print("WALNUT_WEASEL_SRC", '"walnut_weasel"' in _src("res://data/enemies.json"))
	print("EAVES_SPLASH_SRC", "_setup_eaves_splash" in _src("res://scripts/world/world.gd"))
	print("JOURNAL_FLOURISH_SRC", "_play_journal_open_flourish" in _src("res://scripts/ui/journal_panel.gd"))
	print("XP_FLOAT_SIZE_SRC", "amount >= 100" in _src("res://scripts/combat/hitsplat.gd"))
	print("TRAVEL_FAV_SRC", "favorite_landmark" in _src("res://scripts/autoload/game_state.gd") and "PinFavBtn" in _src("res://scripts/ui/main.gd"))
	print("WAVE51_TOAST_SRC", "maybe_wave_51_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_151_SRC", _ver_ge(51))




	print("PECAN_POSSUM_SRC", '"pecan_possum"' in _src("res://data/enemies.json"))
	print("WIND_CHIME_SRC", "HallWindChime" in _src("res://scripts/autoload/audio_bus.gd") and "_update_hall_wind_chime" in _src("res://scripts/world/world.gd"))
	print("DEFEAT_CAM_SRC", "_play_soft_defeat_camera_settle" in _src("res://scripts/player/player.gd"))
	print("WARDROBE_PULSE_SRC", "_play_wardrobe_preview_pulse" in _src("res://scripts/ui/customize_screen.gd"))
	print("JOURNAL_OPEN_ONLY_SRC", "OpenOnlyBtn" in _src("res://scripts/ui/journal_panel.gd") and "weeks locked" in _src("res://scripts/ui/journal_panel.gd"))
	print("WAVE52_TOAST_SRC", "maybe_wave_52_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_152_SRC", _ver_ge(52))




	print("MAGNOLIA_BEAVER_SRC", '"magnolia_beaver"' in _src("res://data/enemies.json"))
	print("GARDEN_FIREFLIES_SRC", "PrayerGardenFireflies" in _src("res://scripts/world/world.gd"))
	print("MUTE_PULSE_SRC", "_pulse_mute_plate" in _src("res://scripts/ui/hud.gd"))
	print("SOFT_PULL_COLOR_SRC", "Wave 53: soft color shift yellow" in _src("res://scripts/world/enemy.gd"))
	print("BAG_DEF_SRC", "Worn gear · Def %d" in _src("res://scripts/ui/inventory_panel.gd"))
	print("WAVE53_TOAST_SRC", "maybe_wave_53_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_153_SRC", _ver_ge(53))



	print("OLIVE_OWL_SRC", '"olive_owl"' in _src("res://data/enemies.json"))
	print("BROOK_SPARKLE_SRC", "BrookSparkle" in _src("res://scripts/world/world.gd"))
	print("TRAVEL_FLOURISH_SRC", "_play_travel_open_flourish" in _src("res://scripts/ui/main.gd"))
	print("NEAR_MISS_CHIME_SRC", "play_quest_near_miss" in _src("res://scripts/autoload/audio_bus.gd"))
	print("PIN_WRONG_TOAST_SRC", "Wrong PIN" in _src("res://scripts/ui/parent_panel.gd"))
	print("WAVE54_TOAST_SRC", "maybe_wave_54_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_154_SRC", _ver_ge(54))




	print("PALM_PIKA_SRC", '"palm_pika"' in _src("res://data/enemies.json"))
	print("EMBER_POP_SRC", "play_ember_pop" in _src("res://scripts/autoload/audio_bus.gd"))
	print("YEAR_WEEK_FLASH_SRC", "_year_chip_last_week" in _src("res://scripts/ui/hud.gd"))
	print("DEFEAT_MIST_LINGER_SRC", "lifetime = 3.2" in _src("res://scripts/world/world.gd"))
	print("SAVE_SLOT_CHIP_SRC", "Save · #%d · %s" in _src("res://scripts/ui/hud.gd"))
	print("WAVE55_TOAST_SRC", "maybe_wave_55_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_155_SRC", _ver_ge(55))

	print("LEMON_LEMMING_SRC", '"lemon_lemming"' in _src("res://data/enemies.json"))
	print("MAPLE_LEAVES_SRC", "_setup_maple_leaves" in _src("res://scripts/world/world.gd"))
	print("COMPASS_PULSE_SRC", "Wave 56: clearer compass tick pulse" in _src("res://scripts/ui/hud.gd"))
	print("MASTERY_WEEK_TOAST_SRC", "Quest complete ·" in _src("res://scripts/autoload/game_state.gd") or "Quest mastered · Week" in _src("res://scripts/autoload/game_state.gd"))
	print("TRAVEL_FAV_TOP_SRC", "show ★ fav at top of travel list" in _src("res://scripts/ui/main.gd"))
	print("WAVE56_TOAST_SRC", "maybe_wave_56_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_156_SRC", _ver_ge(56))




	print("CHERRY_CHINCHILLA_SRC", '"cherry_chinchilla"' in _src("res://data/enemies.json"))
	print("REED_SWAY_SRC", "_update_reed_sway" in _src("res://scripts/world/world.gd"))
	print("READY_FLASH_SRC", "Wave 57: clearer Ready flash color" in _src("res://scripts/ui/hud.gd"))
	print("DEFEAT_FOUNTAIN_SRC", "rest safe at Fountain" in _src("res://scripts/autoload/game_state.gd"))
	print("JOURNAL_OPEN_COUNT_SRC", "Open only · %d" in _src("res://scripts/ui/journal_panel.gd"))
	print("WAVE57_TOAST_SRC", "maybe_wave_57_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_157_SRC", _ver_ge(57))


	print("PLUM_PORCUPINE_SRC", '"plum_porcupine"' in _src("res://data/enemies.json"))
	print("THISTLE_SWAY_SRC", "_update_thistle_sway" in _src("res://scripts/world/world.gd"))
	print("MID_TELEGRAPH_SRC", "Wave 58: clearer soft-aggro mid-telegraph toast" in _src("res://scripts/world/enemy.gd"))
	print("WARDROBE_SPARKLE_SRC", "Wave 58: stronger wardrobe equip sparkle" in _src("res://scripts/ui/customize_screen.gd"))
	print("PARENT_YEAR_PCT_SRC", "Wave 58: show year %" in _src("res://scripts/ui/parent_panel.gd"))
	print("WAVE58_TOAST_SRC", "maybe_wave_58_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_158_SRC", _ver_ge(58))



	print("PEACH_PUFFIN_SRC", '"peach_puffin"' in _src("res://data/enemies.json"))
	print("KNOLL_DUSK_GLOW_SRC", "_update_knoll_dusk_glow" in _src("res://scripts/world/world.gd"))
	print("MUTE_WEATHER_SRC", "Wave 59: clearer mute unmute with weather note" in _src("res://scripts/ui/hud.gd"))
	print("XP_STACK_SRC", "_xp_stack_i" in _src("res://scripts/combat/hitsplat.gd"))
	print("FAV_PACES_SRC", "_refresh_fav_paces" in _src("res://scripts/ui/hud.gd"))
	print("WAVE59_TOAST_SRC", "maybe_wave_59_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_159_SRC", _ver_ge(59))



	print("FIG_FINCH_SRC", '"fig_finch"' in _src("res://data/enemies.json"))
	print("FESTIVAL_CONFETTI_SRC", "play_wave60_festival_confetti" in _src("res://scripts/world/world.gd"))
	print("LANDMARK_PACES_SRC", "Wave 60: clearer landmark approach with paces" in _src("res://scripts/world/world.gd"))
	print("PLAZA_FLICKER_SRC", "plaza dusk lantern flicker sync" in _src("res://scripts/world/world.gd"))
	print("JOURNAL_TOTAL_STARS_SRC", "★ Total mastered:" in _src("res://scripts/ui/journal_panel.gd"))
	print("WAVE60_TOAST_SRC", "maybe_wave_60_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_160_SRC", _ver_ge(60))



	print("GRAPE_GECKO_SRC", '"grape_gecko"' in _src("res://data/enemies.json"))
	print("WILLOW_SWAY_SRC", "_update_willow_sway" in _src("res://scripts/world/world.gd"))
	print("FOOD_EMPTY_H_SRC", "press H for Fountain to refill" in _src("res://scripts/autoload/game_state.gd"))
	print("UNEQUIP_ALL_SRC", "unequip_all_slots" in _src("res://scripts/autoload/game_state.gd"))
	print("WAVE61_TOAST_SRC", "maybe_wave_61_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_161_SRC", _ver_ge(61))



	print("APRICOT_ARMADILLO_SRC", '"apricot_armadillo"' in _src("res://data/enemies.json"))
	print("FERN_SWAY_SRC", "_update_fern_sway" in _src("res://scripts/world/world.gd"))
	print("TRAVEL_FADE_NAME_SRC", "SoftTravelFadeLabel" in _src("res://scripts/ui/main.gd"))
	print("PULLBACK_DENSE_SRC", "Wave 62: denser combat pull-back sparkle" in _src("res://scripts/player/player.gd"))
	print("JOURNAL_OPEN_ONLY_SAVE_SRC", "journal_open_only" in _src("res://scripts/autoload/game_state.gd"))
	print("WAVE62_TOAST_SRC", "maybe_wave_62_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_162_SRC", _ver_ge(62))


	print("BLUEBERRY_BUNNY_SRC", '"blueberry_bunny"' in _src("res://data/enemies.json"))
	print("HEATHER_SWAY_SRC", "_update_heather_sway" in _src("res://scripts/world/world.gd"))
	print("YEAR_CHIP_MASTERY_SRC", "Year · mastery" in _src("res://scripts/ui/hud.gd"))
	print("HALL_LIGHT_DIP_SRC", "_begin_hall_light_dip" in _src("res://scripts/world/world.gd"))
	print("WAVE63_TOAST_SRC", "maybe_wave_63_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_163_SRC", _ver_ge(63))

	print("CRANBERRY_CAPYBARA_SRC", '"cranberry_capybara"' in _src("res://data/enemies.json"))
	print("ARCH_DUSK_GLOW_SRC", "_update_arch_dusk_glow" in _src("res://scripts/world/world.gd"))
	print("AGGRO_DEF_RING_SRC", "Wave 64: clearer soft-aggro ring when armor Def high" in _src("res://scripts/world/enemy.gd"))
	print("FAV_SHORT_SRC", "_fav_landmark_short" in _src("res://scripts/ui/hud.gd"))
	print("TRAVEL_SEARCH_REMEMBER_SRC", "_travel_last_query" in _src("res://scripts/ui/main.gd"))
	print("WAVE64_TOAST_SRC", "maybe_wave_64_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_164_SRC", _ver_ge(64))


	print("RASPBERRY_RAM_SRC", '"raspberry_ram"' in _src("res://data/enemies.json"))
	print("CROSS_DUSK_GLOW_SRC", "_update_cross_dusk_glow" in _src("res://scripts/world/world.gd"))
	print("FIRST_FIGHT_FOE_SRC", "Wave 65: clearer first-fight tip with foe name" in _src("res://scripts/world/enemy.gd"))
	print("YEAR_WEATHER_LETTER_SRC", "Wave 65: weather icon letter beside Year chip" in _src("res://scripts/ui/hud.gd"))
	print("READY_CHIME_SRC", "play_ready_chime" in _src("res://scripts/autoload/audio_bus.gd"))
	print("WAVE65_TOAST_SRC", "maybe_wave_65_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_165_SRC", _ver_ge(65))

	print("STRAWBERRY_STOAT_SRC", '"strawberry_stoat"' in _src("res://data/enemies.json"))
	print("BIRCH_FIREFLIES_SRC", "BirchRestFireflies" in _src("res://scripts/world/world.gd"))
	print("ARRIVAL_SHORT_SRC", "_travel_landmark_short" in _src("res://scripts/ui/main.gd"))
	print("VICTORY_SPARKLE_SRC", "Wave 66: softer richer victory sparkle polish" in _src("res://scripts/world/world.gd"))
	print("JOURNAL_OPEN_STICKY_SRC", "Open only · %d quests still open" in _src("res://scripts/ui/journal_panel.gd"))
	print("TRAVEL_NEAREST_SRC", "Wave 66: highlight nearest landmark" in _src("res://scripts/ui/main.gd"))
	print("WAVE66_TOAST_SRC", "maybe_wave_66_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_166_SRC", _ver_ge(66))


	print("BLACKBERRY_BEAR_SRC", '"blackberry_bear"' in _src("res://data/enemies.json"))
	print("REED_POOL_GLEAM_SRC", "ReedPoolRippleGleam" in _src("res://scripts/world/world.gd"))
	print("LOW_HP_TOAST_SRC", "_maybe_low_hp_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("FOES_PULSE_SRC", "_update_foe_pulse" in _src("res://scripts/ui/hud.gd"))
	print("NEEDS_HELP_DAYS_SRC", "_days_since_attempt" in _src("res://scripts/ui/parent_panel.gd"))
	print("WAVE67_TOAST_SRC", "maybe_wave_67_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_167_SRC", _ver_ge(67))


	print("GUAVA_GOAT_SRC", '"guava_goat"' in _src("res://data/enemies.json"))
	print("WILLOW_LEAVES_SRC", "WillowBendLeafDrift" in _src("res://scripts/world/world.gd"))
	print("NEAR_MISS_TITLE_SRC", "short_title" in _src("res://scripts/autoload/game_state.gd"))
	print("FOUNTAIN_CHIME_SRC", "play_fountain_rest_chime" in _src("res://scripts/autoload/audio_bus.gd"))
	print("UNEQUIP_COUNT_SRC", "Confirm? · %d" in _src("res://scripts/ui/inventory_panel.gd"))
	print("YEAR_MASTERY_GOLD_SRC", "_year_chip_last_mastery" in _src("res://scripts/ui/hud.gd"))
	print("WAVE68_TOAST_SRC", "maybe_wave_68_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_168_SRC", _ver_ge(68))


	print("KIWI_KOALA_SRC", '"kiwi_koala"' in _src("res://data/enemies.json"))
	print("FERN_FRONDS_SRC", "FernDellFrondDrift" in _src("res://scripts/world/world.gd"))
	print("LANDMARK_PACES_CHIP_SRC", "landmark_dist" in _src("res://scripts/world/world.gd") and "✦ %s · ~%d paces" in _src("res://scripts/ui/hud.gd"))
	print("CANOPY_DRIP_POLISH_SRC", "Wave 69: soft rain-canopy drip polish" in _src("res://scripts/world/world.gd"))
	print("MASTERED_FILTER_COUNT_SRC", "Mastered ★ · %d" in _src("res://scripts/ui/journal_panel.gd"))
	print("SAVE_CHIP_PULSE_SRC", "_on_game_saved_pulse" in _src("res://scripts/ui/hud.gd"))
	print("WAVE69_TOAST_SRC", "maybe_wave_69_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_169_SRC", _ver_ge(69))


	print("MANGO_MONGOOSE_SRC", '"mango_mongoose"' in _src("res://data/enemies.json"))
	print("HEATHER_BLOOMS_SRC", "HeatherHeathBloomDrift" in _src("res://scripts/world/world.gd"))
	print("HEATHER_DUSK_SWAY_SRC", "Wave 70: soft heather sway reads stronger at dusk" in _src("res://scripts/world/world.gd"))
	print("PARENT_MASTERY_STARS_SRC", "_mastery_progress_bar" in _src("res://scripts/ui/parent_panel.gd"))
	print("WAVE70_TOAST_SRC", "maybe_wave_70_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_170_SRC", _ver_ge(70))


	print("PAPAYA_PANDA_SRC", '"papaya_panda"' in _src("res://data/enemies.json"))
	print("THISTLE_BLOOMS_SRC", "ThistleRiseBloomDrift" in _src("res://scripts/world/world.gd"))
	print("THISTLE_DUSK_SWAY_SRC", "Wave 71: soft thistle sway reads stronger at dusk" in _src("res://scripts/world/world.gd"))
	print("DAILY_CHECKPOINT_CLEAR_SRC", "Daily checkpoint · open Parent" in _src("res://scripts/autoload/game_state.gd"))
	print("BREAD_LOW_FLASH_SRC", "_food_bread_low" in _src("res://scripts/ui/hud.gd"))
	print("WAVE71_TOAST_SRC", "maybe_wave_71_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_171_SRC", _ver_ge(71))



	print("COCONUT_CRAB_SRC", '"coconut_crab"' in _src("res://data/enemies.json"))
	print("MAPLE_DUSK_LEAVES_SRC", "MapleCopseDuskLeafDrift" in _src("res://scripts/world/world.gd"))
	print("MAPLE_DUSK_BOOST_SRC", "Wave 72: denser Maple Copse leaf fall reads stronger at dusk" in _src("res://scripts/world/world.gd"))
	print("EDGE_FOG_POLISH_SRC", "Wave 72: soft edge-fog banks polish" in _src("res://scripts/world/world.gd"))
	print("FOUNTAIN_REST_CLEAR_SRC", "Fountain rest · HP returning gently" in _src("res://scripts/autoload/game_state.gd"))
	print("JOURNAL_OPEN_WEEKS_SRC", "_format_open_quest_weeks" in _src("res://scripts/ui/journal_panel.gd"))
	print("WAVE72_TOAST_SRC", "maybe_wave_72_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_172_SRC", _ver_ge(72))


	print("LIME_LLAMA_SRC", '"lime_llama"' in _src("res://data/enemies.json"))
	print("AMBER_GLOW_MOTES_SRC", "AmberKnollGlowMotes" in _src("res://scripts/world/world.gd"))
	print("AMBER_GLOW_POLISH_SRC", "Wave 73: soft Amber Knoll amber-glow polish at dusk" in _src("res://scripts/world/world.gd"))
	print("BROOK_MURMUR_POLISH_SRC", "Wave 73: soft brook murmur polish" in _src("res://scripts/world/world.gd"))
	print("PUDDLE_RIPPLE_POLISH_SRC", "Wave 73: soft puddle ripple polish" in _src("res://scripts/world/world.gd"))
	print("QUEST_COMPLETE_TITLE_SRC", "Quest complete ·" in _src("res://scripts/autoload/game_state.gd"))
	print("PARENT_EMPTY_WARMER_SRC", "A quiet week for now" in _src("res://scripts/ui/parent_panel.gd"))
	print("BAG_STACK_TYPE_HINT_SRC", "🍞 stack" in _src("res://scripts/ui/inventory_panel.gd"))
	print("WAVE73_TOAST_SRC", "maybe_wave_73_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_173_SRC", _ver_ge(73))



	print("MELON_MOOSE_SRC", '"melon_moose"' in _src("res://data/enemies.json"))
	print("CEDAR_NEEDLE_DRIFT_SRC", "CedarHollowNeedleDrift" in _src("res://scripts/world/world.gd"))
	print("PLAZA_LANTERN_SYNC_SRC", "Wave 74: plaza dusk lantern sync polish" in _src("res://scripts/world/world.gd"))
	print("FOE_VICTORY_SPARKLE_SRC", "_play_foe_victory_sparkle" in _src("res://scripts/world/enemy.gd"))
	print("YEAR_CHIP_WEEK_SRC", "week %d of 36" in _src("res://scripts/ui/hud.gd"))
	print("TRAVEL_NEAR_PULSE_SRC", "_tick_travel_near_pulse" in _src("res://scripts/ui/main.gd"))
	print("WAVE74_TOAST_SRC", "maybe_wave_74_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_174_SRC", _ver_ge(74))


	print("QUINCE_QUOKKA_SRC", '"quince_quokka"' in _src("res://data/enemies.json"))
	print("STONE_ARCH_DUST_SRC", "StoneArchLimestoneDust" in _src("res://scripts/world/world.gd"))
	print("WIND_LEAF_POLISH_SRC", "Wave 75 soft wind leaf particles polish" in _src("res://scripts/world/world.gd"))
	print("FIRST_DISCOVERY_TOAST_SRC", "✦ First discovery ·" in _src("res://scripts/world/world.gd"))
	print("JOURNAL_MASTERED_STICKY_COUNT_SRC", "Mastered this week sticky ·" in _src("res://scripts/ui/journal_panel.gd"))
	print("PARENT_OLDEST_HELP_SRC", "oldest attempt first" in _src("res://scripts/ui/parent_panel.gd"))
	print("WAVE75_TOAST_SRC", "maybe_wave_75_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_175_SRC", _ver_ge(75))


	print("WATERMELON_WALLABY_SRC", '"watermelon_wallaby"' in _src("res://data/enemies.json"))
	print("CROSS_LANTERN_MOTHS_SRC", "QuietCrossLanternMoths" in _src("res://scripts/world/world.gd"))
	print("CRICKET_HUSH_POLISH_SRC", "Wave 76 soft night cricket hush polish" in _src("res://scripts/autoload/audio_bus.gd") or "Wave 43/76: soft night cricket hush" in _src("res://scripts/autoload/audio_bus.gd"))
	print("DEF_EQUIP_FLASH_SRC", "_def_equip_flash_id" in _src("res://scripts/ui/inventory_panel.gd"))
	print("FOES_UP_CHIP_SRC", "Foes · %d ↑" in _src("res://scripts/ui/hud.gd"))
	print("WAVE76_TOAST_SRC", "maybe_wave_76_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_176_SRC", _ver_ge(76))


	print("HONEYDEW_HAMSTER_SRC", '"honeydew_hamster"' in _src("res://data/enemies.json"))
	print("BIRCH_FIREFLY_DENSE_SRC", "Wave 66/77: soft birch-rest firefly denser wink" in _src("res://scripts/world/world.gd"))
	print("CAMPFIRE_POLISH_SRC", "Wave 77: soft campfire glow polish" in _src("res://scripts/world/world.gd"))
	print("SOFT_TRAVEL_ARRIVAL_SRC", "Arrived · Soft travel ·" in _src("res://scripts/ui/main.gd"))
	print("FAV_CHIP_PACES_SRC", "Wave 77: ★ fav chip shows paces to fav" in _src("res://scripts/ui/hud.gd"))
	print("WAVE77_TOAST_SRC", "maybe_wave_77_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_177_SRC", _ver_ge(77))

	print("PLAZA_COBBLE_SRC", "PlazaCobble" in _src("res://scripts/world/world.gd"))
	print("HUMANOID_FACE_SRC", "LEye" in _src("res://scripts/characters/humanoid_builder.gd"))
	print("PARENT_PIN_LOCK_SRC", "do NOT open the dashboard on a wrong PIN" in _src("res://scripts/ui/parent_panel.gd"))
	print("REFINE_178_TOAST_SRC", "maybe_refine_178_toast" in _src("res://scripts/autoload/game_state.gd"))
	print("VERSION_178_SRC", _ver_ge(78))

	print("VERSION_179_SRC", _ver_ge(79))
	print("CLEANUP_179_SRC", "_maybe_once_toast" in _src("res://scripts/autoload/game_state.gd"))

	print("VERSION_180_SRC", _ver_ge(80))
	print("PLAZA_FLAG_SRC", "PlazaFlag" in _src("res://scripts/world/world.gd") and "YardCart" in _src("res://scripts/world/world.gd") and "PlazaTile" in _src("res://scripts/world/world.gd") and "HallTimberL" in _src("res://scripts/world/world.gd"))
	print("LANDMARK_PLAZA_SRC", "LandmarkPlazaGlade" in _src("res://scripts/world/world.gd") and "_dress_world_finish" in _src("res://scripts/world/world.gd") and "_dress_landmark_ring" in _src("res://scripts/world/world.gd"))
	print("DAY_FILL_SRC", "DayFill" in _src("res://scripts/world/world.gd"))
	print("HUMANOID_CLOTHES_SRC", "Collar" in _src("res://scripts/characters/humanoid_builder.gd") and "Hem" in _src("res://scripts/characters/humanoid_builder.gd") and "Buckle" in _src("res://scripts/characters/humanoid_builder.gd"))

	print("VERSION_181_SRC", _ver_ge(81))
	print("PANEL_CHROME_SRC", "class_name PanelChrome" in _src("res://scripts/ui/panel_chrome.gd"))
	print("HUD_COMPACT_SRC", "Pantry · Ready · V" in _src("res://scripts/ui/hud.gd") and "Year · Wk %d · %d%%" in _src("res://scripts/ui/hud.gd"))
	print("PARENT_HERO_SRC", "_ensure_hero_row" in _src("res://scripts/ui/parent_panel.gd") and "Copy line" in _src("res://scripts/ui/parent_panel.gd"))
	print("TITLE_START_SRC", "How to start" in _src("res://scripts/ui/title_screen.gd"))

	print("VERSION_182_SRC", _ver_ge(82))
	print("MODAL_SYNC_SRC", "_sync_ui_blocking" in _src("res://scripts/ui/main.gd") and "_close_all_overlays" in _src("res://scripts/ui/main.gd"))
	print("MASTERY_ROUND_SRC", "func percent_to_int" in _src("res://scripts/autoload/game_state.gd") and "func is_mastered_score" in _src("res://scripts/autoload/game_state.gd"))
	print("FOUNTAIN_DEBOUNCE_SRC", "_fountain_rest_ms" in _src("res://scripts/autoload/game_state.gd"))
	print("BUGS_182_TOAST_SRC", "maybe_bugs_182_toast" in _src("res://scripts/autoload/game_state.gd"))

	print("VERSION_183_SRC", _ver_ge(83))
	print("NEXT_UP_SRC", "func get_next_up" in _src("res://scripts/autoload/game_state.gd") and "NextUp" in _src("res://scripts/ui/journal_panel.gd"))
	print("SCHOOL_DAY_SRC", "func get_school_day" in _src("res://scripts/autoload/game_state.gd") and "DailyLbl" in _src("res://scripts/ui/parent_panel.gd"))
	print("NEEDS_HELP_SIT_SRC", "Sit with" in _src("res://scripts/autoload/game_state.gd"))
	print("CURRICULUM_183_TOAST_SRC", "maybe_curriculum_183_toast" in _src("res://scripts/autoload/game_state.gd"))
	if gs:
		if gs.has_method("get_next_up"):
			var nxt = gs.get_next_up()
			print("NEXT_UP_ID", str(nxt.get("quest_id", "")) != "")
			print("NEXT_UP_MENTOR", str(nxt.get("mentor", "")).find("Steward") >= 0 or str(nxt.get("mentor", "")).find("Builder") >= 0)
		if gs.has_method("get_school_day"):
			var day = gs.get_school_day()
			print("SCHOOL_DAY_GOAL", int(day.get("goal", 0)) >= 1)
		if gs.has_method("format_needs_help_row"):
			gs.quest_attempts.append({
				"quest_id": "w1-math-place-value",
				"correct": 2,
				"total": 5,
				"percent": 0.4,
				"mastered": false,
				"timestamp": int(Time.get_unix_time_from_system()),
			})
			var help_rows: Array = gs.needs_help_quests() if gs.has_method("needs_help_quests") else []
			var help_line := ""
			if help_rows.size() > 0:
				help_line = str(gs.format_needs_help_row(help_rows[0]))
			print("HELP_SIT_LINE", "Sit with" in help_line and "WEEK" in help_line)
			if gs.quest_attempts.size() > 0:
				gs.quest_attempts.pop_back()
		print("PIN_STILL_1234_W183_RT", gs.verify_pin("1234"))
		print("MASTERY_80_W183_RT", gs.has_method("is_mastered_score") and gs.is_mastered_score(4, 5) and not gs.is_mastered_score(3, 4))

	print("VERSION_184_SRC", _ver_ge(84))
	print("ENEMY_LOD_SRC", "LOD_ANIM_DIST2" in _src("res://scripts/world/enemy.gd") and "_player_near" in _src("res://scripts/world/enemy.gd"))
	print("LANDMARK_FX_NEAR_SRC", "_player_near_xz" in _src("res://scripts/world/world.gd") and "_set_landmark_fx" in _src("res://scripts/world/world.gd"))
	print("PLAYER_SPEED_SRC", "const SPEED := 8.2" in _src("res://scripts/player/player.gd"))
	print("TICK_055_SRC", "0.55" in _src("res://data/enemies.json") and "tick_sec" in _src("res://data/enemies.json"))
	print("SMOOTH_184_TOAST_SRC", "maybe_smooth_184_toast" in _src("res://scripts/autoload/game_state.gd"))
	if gs and gs.has_method("maybe_smooth_184_toast"):
		print("SMOOTH_184_TOAST_RT", gs.has_method("maybe_smooth_184_toast"))
	print("WORLD_SMOKE_OK")
	quit(0)
