extends SceneTree

var _src := {}

func _load_src(path: String) -> String:
	if not _src.has(path):
		_src[path] = FileAccess.get_file_as_string(path)
	return str(_src[path])

func _ver(v: String) -> bool:
	var proj := _load_src("res://project.godot")
	if ('config/version="%s"' % v) in proj:
		return true
	# Later builds still satisfy historical wave version checks.
	for cur in ["1.78.0", "1.78.1"]:
		if ('config/version="%s"' % cur) in proj:
			return true
	return false


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
	var toads := 0
	var weasels := 0
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
		if str(foe.get("kind")) == "chestnut_toad":
			toads += 1
		if str(foe.get("kind")) == "walnut_weasel":
			weasels += 1
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
	print("TOADS", toads)
	print("WEASELS", weasels)
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
	var gs_src = _load_src("res://scripts/autoload/game_state.gd")
	print("BEST_FOOD", "func use_best_consumable" in gs_src)
	print("HONEY_CAKE", '"honey_cake"' in _load_src("res://data/items.json"))
	print("HEARTY_STEW", '"hearty_stew"' in _load_src("res://data/items.json"))
	print("PEEK_FOOD", "func peek_best_consumable" in gs_src)
	print("PARENT_TABS", "_ensure_campaign_tabs" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("WASD_FORCED", "set_velocity_forced" in _load_src("res://scripts/player/player.gd"))
	print("FOUNTAIN_REST", "func rest_at_fountain" in gs_src)
	print("HEADLESS_GUARD", FileAccess.file_exists("res://scripts/util/headless_guard.gd"))
	print("PARENT_WEEK_ROWS", "_add_week_row" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("CLICK_MARKER", "_show_click_marker" in _load_src("res://scripts/player/player.gd"))
	print("FOOT_DUST", "_puff_foot_dust" in _load_src("res://scripts/player/player.gd"))
	print("LANDMARK_APPROACH", "_update_landmark_approach" in _load_src("res://scripts/world/world.gd"))
	print("STRONG_HIT", "strong_foe" in _load_src("res://scripts/combat/hitsplat.gd"))
	print("KILL_FLASH", "_begin_kill_flash" in _load_src("res://scripts/world/enemy.gd"))
	print("PARENT_EXPAND_PERSIST", "expanded_weeks" in _load_src("res://scripts/autoload/game_state.gd"))
	print("LANDMARK_GREET", "greeted_landmarks" in _load_src("res://scripts/autoload/game_state.gd"))
	print("SOFT_TRAVEL_NOTE", world.has_method("note_soft_travel_arrival") if world else false)
	print("CRIT_VARIANCE", "bright" in _load_src("res://scripts/world/enemy.gd"))
	print("SPUR_DENSITY", "LookoutTrim" in _load_src("res://scripts/world/world.gd"))
	print("DEFENSE_API", "func get_defense" in _load_src("res://scripts/autoload/game_state.gd"))
	print("DISCOVERED_LANDMARKS", "discovered_landmarks" in _load_src("res://scripts/autoload/game_state.gd"))
	print("FIRST_TOAST", "first_toast" in _load_src("res://scripts/world/world.gd"))
	print("INCOMING_VARIANCE", "get_defense" in _load_src("res://scripts/world/enemy.gd"))
	print("KILL_FLASH_RESTORE", "_restore_kill_flash_colors" in _load_src("res://scripts/world/enemy.gd"))
	print("SPUR_DENSITY_W15", "GladeTrim" in _load_src("res://scripts/world/world.gd") and "RidgeTrim" in _load_src("res://scripts/world/world.gd"))
	print("DEFENSE_BREAKDOWN", "func get_defense_breakdown" in _load_src("res://scripts/autoload/game_state.gd"))
	print("AMBIENT_LIFE", world.static_world.get_node_or_null("AmbientLife") != null if world else false)
	print("HIT_PAUSE", "_play_hit_pause" in _load_src("res://scripts/ui/main.gd"))
	print("HURT_VIGNETTE", "_update_hurt_vignette" in _load_src("res://scripts/ui/hud.gd"))
	print("VILLAGE_AMBIENT", "0.0, 0, 8.0" in _load_src("res://scripts/world/world.gd"))
	print("ARMOR_ICONS", "_make_slot_icon" in _load_src("res://scripts/ui/inventory_panel.gd"))
	print("HUD_DEF", "· Def" in _load_src("res://scripts/ui/hud.gd"))
	print("LATE_WILDS_TUNE", '"max_hp": 24' in _load_src("res://data/enemies.json") and '"max_hp": 34' in _load_src("res://data/enemies.json"))
	print("PLAZA_AMBIENT_DENSE", '"dense": true' in _load_src("res://scripts/world/world.gd"))
	print("LOADOUT_ARMOR_ICONS", "SlotRows" in _load_src("res://scripts/ui/inventory_panel.gd") and "SoftArmor" in _load_src("res://scenes/main.tscn"))
	print("CEDAR_STAG", '"cedar_stag"' in _load_src("res://data/enemies.json"))
	print("CEDAR_HOLLOW_SRC", "_build_cedar_hollow" in _load_src("res://scripts/world/world.gd"))
	print("HELD_WEAPON", "r_arm.add_child(weapon)" in _load_src("res://scripts/characters/humanoid_builder.gd"))
	print("STYLE_ARMOR", "func style_armor" in _load_src("res://scripts/characters/humanoid_builder.gd"))
	print("YARD_ANIMALS", '"hen"' in _load_src("res://scripts/world/world.gd"))
	print("YEAR_PROGRESS_API", "func get_year_progress_note" in _load_src("res://scripts/autoload/game_state.gd"))
	print("WILLOW_BEND_SRC", "_build_willow_bend" in _load_src("res://scripts/world/world.gd"))
	print("HIT_FLASH", "func _begin_hit_flash" in _load_src("res://scripts/world/enemy.gd"))
	print("PARENT_YEAR_MASTERY", "quest mastery" in _load_src("res://scripts/ui/parent_panel.gd").to_lower())
	print("REED_POOL_SRC", "_build_reed_pool" in _load_src("res://scripts/world/world.gd"))
	print("YEAR_CHIP_SRC", "_year_chip" in _load_src("res://scripts/ui/hud.gd"))
	print("DAILY_REMINDER_SRC", "maybe_daily_checkpoint_reminder" in _load_src("res://scripts/autoload/game_state.gd"))
	print("WEAPON_SWING_SRC", "Wave 22" in _load_src("res://scripts/player/player.gd"))
	print("QUIET_CROSS_SRC", "_build_quiet_cross" in _load_src("res://scripts/world/world.gd"))
	print("AGGRO_RIM_SRC", "AggroRim" in _load_src("res://scripts/world/enemy.gd"))
	print("JOURNAL_RAID_SRC", "_is_friday_raid" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("WEEK_UNLOCK_PCT_SRC", "of the year" in _load_src("res://scripts/autoload/game_state.gd"))
	print("STONE_ARCH_SRC", "_build_stone_arch" in _load_src("res://scripts/world/world.gd"))
	print("STONE_ARCH_NODE", world.static_world.get_node_or_null("StoneArch") != null if world else false)
	print("FOUNTAIN_FX_SRC", "_play_fountain_restore_fx" in _load_src("res://scripts/world/world.gd"))
	print("FOOD_HEAL_SRC", "healed +" in _load_src("res://scripts/autoload/game_state.gd"))
	print("PARENT_HELP_SRC", "Needs help:" in _load_src("res://scripts/ui/parent_panel.gd") or "Needs Help —" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("AMBER_KNOLL_SRC", "_build_amber_knoll" in _load_src("res://scripts/world/world.gd"))
	print("AMBER_KNOLL_NODE", world.static_world.get_node_or_null("AmberKnoll") != null if world else false)
	print("MINIMAP_ICON_SRC", "_draw_landmark_icon" in _load_src("res://scripts/ui/minimap.gd"))
	print("COMPASS_TICK_SRC", "_update_landmark_tick" in _load_src("res://scripts/ui/hud.gd"))
	print("UNEQUIP_TOAST_SRC", "Unequipped" in _load_src("res://scripts/autoload/game_state.gd"))
	print("DEF_FLASH_SRC", "softens the hit" in _load_src("res://scripts/ui/hud.gd"))
	print("WARDROBE_PREVIEW_SRC", "PreviewRow" in _load_src("res://scripts/ui/customize_screen.gd"))
	print("BIRCH_REST_SRC", "_build_birch_rest" in _load_src("res://scripts/world/world.gd"))
	print("BIRCH_REST_NODE", world.static_world.get_node_or_null("BirchRest") != null if world else false)
	print("DAY_NIGHT_AUDIO_SRC", "set_day_night_audio" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("WEATHER_CLOUDS_SRC", "WeatherClouds" in _load_src("res://scripts/world/world.gd"))
	print("QUEST_MASTERY_PCT_SRC", "Toward mastery" in _load_src("res://scripts/ui/quest_panel.gd"))
	print("NPC_IDLE6_SRC", "% 6" in _load_src("res://scripts/world/npc.gd"))
	print("FERN_DELL_SRC", "_build_fern_dell" in _load_src("res://scripts/world/world.gd"))
	print("FERN_DELL_NODE", world.static_world.get_node_or_null("FernDell") != null if world else false)
	print("DOOR_GLOW_SRC", "_update_door_glows" in _load_src("res://scripts/world/world.gd"))
	print("JOURNAL_CAMP_SRC", "Kindling the Lamps" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("PARENT_SESSION_SRC", "_format_last_session" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("HEATHER_HEATH_SRC", "_build_heather_heath" in _load_src("res://scripts/world/world.gd"))
	print("HEATHER_HEATH_NODE", world.static_world.get_node_or_null("HeatherHeath") != null if world else false)
	print("DUSK_LAMPS_SRC", "_update_village_dusk_lamps" in _load_src("res://scripts/world/world.gd"))
	print("RAIN_SPLASH_SRC", "_setup_rain_splash" in _load_src("res://scripts/world/world.gd"))
	print("THISTLE_RISE_SRC", "_build_thistle_rise" in _load_src("res://scripts/world/world.gd"))
	print("THISTLE_RISE_NODE", world.static_world.get_node_or_null("ThistleRise") != null if world else false)
	print("FOG_MIST_SRC", "_setup_fog_mist" in _load_src("res://scripts/world/world.gd"))
	print("QUEST_SPARKLE_SRC", "_play_quest_victory_sparkle" in _load_src("res://scripts/world/world.gd"))
	print("MAPLE_COPSE_SRC", "_build_maple_copse" in _load_src("res://scripts/world/world.gd"))
	print("MAPLE_COPSE_NODE", world.static_world.get_node_or_null("MapleCopse") != null if world else false)
	print("WIND_LEAVES_SRC", "_setup_wind_leaves" in _load_src("res://scripts/world/world.gd"))
	print("PARENT_EXPORT_SRC", "get_parent_export_line" in _load_src("res://scripts/autoload/game_state.gd"))
	print("PINE_FOX_SRC", '"pine_fox"' in _load_src("res://data/enemies.json"))
	print("PLAZA_CAMPFIRE_NODE", world.static_world.get_node_or_null("PlazaCampfire") != null if world else false)
	print("PLAZA_CAMPFIRE_SRC", "_build_plaza_campfire" in _load_src("res://scripts/world/world.gd"))
	print("NPC_TALK_PROMPT_SRC", "Talk (F)" in _load_src("res://scripts/world/npc.gd"))
	print("TARGET_RETICLE_SRC", "TargetReticle" in _load_src("res://scripts/world/enemy.gd"))
	print("JOURNAL_MASTER_SRC", "Mastered this week" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("OAK_HARE_SRC", '"oak_hare"' in _load_src("res://data/enemies.json"))
	print("CAMPFIRE_SPARKS_SRC", "CampfireSparks" in _load_src("res://scripts/world/world.gd"))
	print("YEAR_CHIP_PLATE_SRC", "YearChipPanel" in _load_src("res://scripts/ui/hud.gd"))
	print("TALK_DUCK_SRC", "set_talk_duck" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("PANTRY_HEAL_SRC", "+%d HP" in _load_src("res://scripts/ui/inventory_panel.gd"))
	print("BIRCH_SQUIRREL_SRC", '"birch_squirrel"' in _load_src("res://data/enemies.json"))
	print("CAMPFIRE_CRACKLE_SRC", "set_campfire_audio" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("SOFTER_RAIN_SRC", "Wave 33: softer rain mix" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("NEAR_MISS_SRC", "Near miss — mastery" in _load_src("res://scripts/autoload/game_state.gd"))
	print("NPC_STAR_SRC", "Wave 33" in _load_src("res://scripts/ui/npc_panel.gd"))
	print("VERSION_133_SRC", _ver("1.33.0"))
	print("ASPEN_OTTER_SRC", '"aspen_otter"' in _load_src("res://data/enemies.json"))
	print("WIND_WHOOSH_SRC", "set_wind_audio" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("LAST_TRAVEL_SRC", "last_travel_label" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_134_SRC", _ver("1.34.0"))
	print("ELM_RACCOON_SRC", '"elm_raccoon"' in _load_src("res://data/enemies.json"))
	print("FOOT_PITCH_SRC", "_play_foot_varied" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("HUD_HP_CLEAR_SRC", "_ensure_clear_hp_text" in _load_src("res://scripts/ui/hud.gd"))
	print("DUSK_FLICKER_SRC", "Wave 35: soft dusk lamp flicker" in _load_src("res://scripts/world/world.gd"))
	print("PARENT_HELP_BOLD_SRC", "WEEK %d" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("VERSION_135_SRC", _ver("1.35.0"))
	print("HAZEL_HEDGEHOG_SRC", '"hazel_hedgehog"' in _load_src("res://data/enemies.json"))
	print("SWING_WHOOSH_SRC", "_play_swing_varied" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("MINIMAP_ZOOM_SRC", "Wave 36: clearer minimap zoom feel" in _load_src("res://scripts/ui/minimap.gd"))
	print("JOURNAL_ATTEMPT_SRC", "get_latest_attempt_percent" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_136_SRC", _ver("1.36.0"))
	print("WILLOW_WREN_SRC", '"willow_wren"' in _load_src("res://data/enemies.json"))
	print("HALL_REVERB_SRC", "set_hall_reverb" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("LEAF_RUSTLE_SRC", "_update_leaf_rustle" in _load_src("res://scripts/world/world.gd"))
	print("AGGRO_COUNTDOWN_SRC", "_countdown_nudge" in _load_src("res://scripts/world/enemy.gd"))
	print("INV_SLOT_TAGS_SRC", "SLOT_TAGS" in _load_src("res://scripts/ui/inventory_panel.gd"))
	print("VERSION_137_SRC", _ver("1.37.0"))

	print("MAPLE_MOUSE_SRC", '"maple_mouse"' in _load_src("res://data/enemies.json"))
	print("BROOK_MURMUR_SRC", "_update_brook_murmur" in _load_src("res://scripts/world/world.gd"))
	print("QUEST_CHIME_SRC", "_quest_chime" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("MUTE_CLEAR_SRC", "Muted · M" in _load_src("res://scripts/ui/hud.gd"))
	print("SAVE_CHIP_SRC", "_ensure_save_chip" in _load_src("res://scripts/ui/hud.gd"))
	print("VERSION_138_SRC", _ver("1.38.0"))

	print("SPRUCE_MOLE_SRC", '"spruce_mole"' in _load_src("res://data/enemies.json"))
	print("DUSK_FIREFLIES_SRC", "_setup_dusk_fireflies" in _load_src("res://scripts/world/world.gd"))
	print("COMPASS_N_SRC", "_ensure_clear_compass_n" in _load_src("res://scripts/ui/hud.gd"))
	print("TRAVEL_SEARCH_SRC", "_refresh_travel_list" in _load_src("res://scripts/ui/main.gd"))
	print("PANTRY_EMPTY_SRC", "fountain (H)" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_139_SRC", _ver("1.39.0"))

	print("BEECH_CHIPMUNK_SRC", '"beech_chipmunk"' in _load_src("res://data/enemies.json"))
	print("MILESTONE_TOAST_SRC", "✦ Milestone · Week" in _load_src("res://scripts/autoload/game_state.gd"))
	print("LANDMARK_NEAR_SRC", "✦ New landmark" in _load_src("res://scripts/world/world.gd"))
	print("XP_FLOAT_SRC", "spawn_xp" in _load_src("res://scripts/combat/hitsplat.gd"))
	print("PARENT_PIN_SRC", "PIN changed successfully" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("CAMPAIGN_COUNTS_SRC", "Wave 40: campaign tab shows mastered/total" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("VERSION_140_SRC", _ver("1.40.0"))

	print("ALDER_DUCK_SRC", '"alder_duck"' in _load_src("res://data/enemies.json"))
	print("PUDDLE_RIPPLES_SRC", "_setup_rain_puddle_ripples" in _load_src("res://scripts/world/world.gd"))
	print("FIRST_FIGHT_TIP_SRC", "First fight: soft ticks" in _load_src("res://scripts/world/enemy.gd"))
	print("HP_COMBAT_LV_SRC", "HP %d / %d · Lv %d" in _load_src("res://scripts/ui/hud.gd"))
	print("FOOD_READY_FLASH_SRC", "_food_ready_flash_t" in _load_src("res://scripts/ui/hud.gd"))
	print("VERSION_141_SRC", _ver("1.41.0"))

	print("FIR_FROG_SRC", '"fir_frog"' in _load_src("res://data/enemies.json"))
	print("HALL_CHATTER_SRC", "set_hall_chatter" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("FOUNTAIN_GLOW_SRC", "FountainRestoreGlow" in _load_src("res://scripts/world/world.gd"))
	print("WARDROBE_SPARKLE_SRC", "_play_wardrobe_equip_sparkle" in _load_src("res://scripts/ui/customize_screen.gd"))
	print("JOURNAL_PROGRESS_SRC", "_campaign_progress_fraction" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("VERSION_142_SRC", _ver("1.42.0"))

	print("CYPRESS_TURTLE_SRC", '"cypress_turtle"' in _load_src("res://data/enemies.json"))
	print("CRICKET_HUSH_SRC", "_night_cricket_hush" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("TRAVEL_FADE_SRC", "_soft_travel_with_fade" in _load_src("res://scripts/ui/main.gd"))
	print("HIT_EDGE_SOFT_SRC", "_hit_edge_flash_t" in _load_src("res://scripts/ui/hud.gd"))
	print("INV_SORT_UNLOCK_SRC", "SLOT_SORT" in _load_src("res://scripts/ui/inventory_panel.gd") and "_append_locked_gear_hints" in _load_src("res://scripts/ui/inventory_panel.gd"))
	print("VERSION_143_SRC", _ver("1.43.0"))

	print("POPLAR_DOVE_SRC", '"poplar_dove"' in _load_src("res://data/enemies.json"))
	print("DAWN_BIRD_SWELL_SRC", "_apply_dawn_bird_swell" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("WEATHER_CYCLE_TOAST_SRC", "Weather cycle ·" in _load_src("res://scripts/world/world.gd"))
	print("TALK_CAM_NUDGE_SRC", "begin_talk_camera_nudge" in _load_src("res://scripts/player/player.gd"))
	print("PARENT_EXPORT_HELP_SRC", "Needs help:" in _load_src("res://scripts/autoload/game_state.gd") and "_relative_session_age" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("VERSION_144_SRC", _ver("1.44.0"))


	print("ROWAN_ROBIN_SRC", '"rowan_robin"' in _load_src("res://data/enemies.json"))
	print("CAMPFIRE_SMOKE_SRC", "CampfireSmoke" in _load_src("res://scripts/world/world.gd"))
	print("MUTE_TOAST_SRC", "Muted · soft hush" in _load_src("res://scripts/ui/hud.gd"))
	print("PULLBACK_SPARKLE_SRC", "CombatPullbackSparkle" in _load_src("res://scripts/player/player.gd"))
	print("TRAVEL_DIST_SRC", "_travel_distance_label" in _load_src("res://scripts/ui/main.gd"))
	print("VERSION_145_SRC", _ver("1.45.0"))


	print("ASH_SPARROW_SRC", '"ash_sparrow"' in _load_src("res://data/enemies.json"))
	print("EDGE_FOG_SRC", "_setup_edge_fog_banks" in _load_src("res://scripts/world/world.gd"))
	print("YEAR_FLASH_SRC", "_apply_year_chip_flash" in _load_src("res://scripts/ui/hud.gd"))
	print("MASTERY_GLOW_SRC", "QuestVictoryGlow" in _load_src("res://scripts/world/world.gd"))
	print("LANDMARK_CHIP_SRC", "_ensure_landmark_chip" in _load_src("res://scripts/ui/hud.gd") and "landmark_name" in _load_src("res://scripts/world/world.gd"))
	print("VERSION_146_SRC", _ver("1.46.0"))


	print("HICKORY_QUAIL_SRC", '"hickory_quail"' in _load_src("res://data/enemies.json"))
	print("SNOWDUST_SRC", "_setup_snowdust" in _load_src("res://scripts/world/world.gd"))
	print("DOOR_WHOOSH_SRC", "play_door_whoosh" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("SOFT_DEFEAT_HP_SRC", "heal_tick.emit(restored)" in _load_src("res://scripts/autoload/game_state.gd"))
	print("JOURNAL_CAMPAIGN_STARS_SRC", "_count_campaign_mastered" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("VERSION_147_SRC", _ver("1.47.0"))


	print("JUNIPER_JAY_SRC", '"juniper_jay"' in _load_src("res://data/enemies.json"))
	print("CANOPY_DRIP_SRC", "_setup_canopy_drip" in _load_src("res://scripts/world/world.gd"))
	print("TARGET_NAMEPLATE_SRC", "_update_target_nameplate" in _load_src("res://scripts/world/enemy.gd"))
	print("WARDROBE_CLOSE_SRC", "_play_wardrobe_close_flourish" in _load_src("res://scripts/ui/customize_screen.gd"))
	print("EQUIP_TOAST_SRC", "Equipped %s." in _load_src("res://scripts/autoload/game_state.gd"))
	print("FOOD_STACK_SRC", "stack %d/%d" in _load_src("res://scripts/ui/inventory_panel.gd"))
	print("VERSION_148_SRC", _ver("1.48.0"))


	print("SYCAMORE_SKINK_SRC", '"sycamore_skink"' in _load_src("res://data/enemies.json"))
	print("DUSK_OWL_SRC", "DuskOwlHoot" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("TRAVEL_PUFF_SRC", "SoftTravelLandingPuff" in _load_src("res://scripts/ui/main.gd"))
	print("FOOD_HEAL_SPARKLE_SRC", "FoodHealSparkle" in _load_src("res://scripts/player/player.gd"))
	print("NEEDS_HELP_HL_SRC", "Wave 49: highlight needs-help count when >0" in _load_src("res://scripts/ui/parent_panel.gd") and "set_tab_tooltip" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("VERSION_149_SRC", _ver("1.49.0"))



	print("CHESTNUT_TOAD_SRC", '"chestnut_toad"' in _load_src("res://data/enemies.json"))
	print("FESTIVAL_SRC", "play_festival_decade_sparkle" in _load_src("res://scripts/world/world.gd"))
	print("FOUNTAIN_MIST_SRC", "FountainPlazaMist" in _load_src("res://scripts/world/world.gd"))
	print("SOFT_AGGRO_COMBO_SRC", "Wave 50: clearer soft-aggro name+countdown combo" in _load_src("res://scripts/world/enemy.gd"))
	print("FOE_COUNT_SRC", "_ensure_foe_count" in _load_src("res://scripts/ui/hud.gd"))
	print("WAVE50_TOAST_SRC", "maybe_wave_50_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_150_SRC", _ver("1.50.0"))



	print("WALNUT_WEASEL_SRC", '"walnut_weasel"' in _load_src("res://data/enemies.json"))
	print("EAVES_SPLASH_SRC", "_setup_eaves_splash" in _load_src("res://scripts/world/world.gd"))
	print("JOURNAL_FLOURISH_SRC", "_play_journal_open_flourish" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("XP_FLOAT_SIZE_SRC", "amount >= 100" in _load_src("res://scripts/combat/hitsplat.gd"))
	print("TRAVEL_FAV_SRC", "favorite_landmark" in _load_src("res://scripts/autoload/game_state.gd") and "PinFavBtn" in _load_src("res://scripts/ui/main.gd"))
	print("WAVE51_TOAST_SRC", "maybe_wave_51_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_151_SRC", _ver("1.51.0"))




	print("PECAN_POSSUM_SRC", '"pecan_possum"' in _load_src("res://data/enemies.json"))
	print("WIND_CHIME_SRC", "HallWindChime" in _load_src("res://scripts/autoload/audio_bus.gd") and "_update_hall_wind_chime" in _load_src("res://scripts/world/world.gd"))
	print("DEFEAT_CAM_SRC", "_play_soft_defeat_camera_settle" in _load_src("res://scripts/player/player.gd"))
	print("WARDROBE_PULSE_SRC", "_play_wardrobe_preview_pulse" in _load_src("res://scripts/ui/customize_screen.gd"))
	print("JOURNAL_OPEN_ONLY_SRC", "OpenOnlyBtn" in _load_src("res://scripts/ui/journal_panel.gd") and "weeks locked" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("WAVE52_TOAST_SRC", "maybe_wave_52_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_152_SRC", _ver("1.52.0"))




	print("MAGNOLIA_BEAVER_SRC", '"magnolia_beaver"' in _load_src("res://data/enemies.json"))
	print("GARDEN_FIREFLIES_SRC", "PrayerGardenFireflies" in _load_src("res://scripts/world/world.gd"))
	print("MUTE_PULSE_SRC", "_pulse_mute_plate" in _load_src("res://scripts/ui/hud.gd"))
	print("SOFT_PULL_COLOR_SRC", "Wave 53: soft color shift yellow" in _load_src("res://scripts/world/enemy.gd"))
	print("BAG_DEF_SRC", "Worn gear · Def %d" in _load_src("res://scripts/ui/inventory_panel.gd"))
	print("WAVE53_TOAST_SRC", "maybe_wave_53_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_153_SRC", _ver("1.53.0"))



	print("OLIVE_OWL_SRC", '"olive_owl"' in _load_src("res://data/enemies.json"))
	print("BROOK_SPARKLE_SRC", "BrookSparkle" in _load_src("res://scripts/world/world.gd"))
	print("TRAVEL_FLOURISH_SRC", "_play_travel_open_flourish" in _load_src("res://scripts/ui/main.gd"))
	print("NEAR_MISS_CHIME_SRC", "play_quest_near_miss" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("PIN_WRONG_TOAST_SRC", "Wrong PIN" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("WAVE54_TOAST_SRC", "maybe_wave_54_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_154_SRC", _ver("1.54.0"))




	print("PALM_PIKA_SRC", '"palm_pika"' in _load_src("res://data/enemies.json"))
	print("EMBER_POP_SRC", "play_ember_pop" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("YEAR_WEEK_FLASH_SRC", "_year_chip_last_week" in _load_src("res://scripts/ui/hud.gd"))
	print("DEFEAT_MIST_LINGER_SRC", "lifetime = 3.2" in _load_src("res://scripts/world/world.gd"))
	print("SAVE_SLOT_CHIP_SRC", "Save · #%d · %s" in _load_src("res://scripts/ui/hud.gd"))
	print("WAVE55_TOAST_SRC", "maybe_wave_55_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_155_SRC", _ver("1.55.0") or _ver("1.56.0"))

	print("LEMON_LEMMING_SRC", '"lemon_lemming"' in _load_src("res://data/enemies.json"))
	print("MAPLE_LEAVES_SRC", "_setup_maple_leaves" in _load_src("res://scripts/world/world.gd"))
	print("COMPASS_PULSE_SRC", "Wave 56: clearer compass tick pulse" in _load_src("res://scripts/ui/hud.gd"))
	print("MASTERY_WEEK_TOAST_SRC", "Quest complete ·" in _load_src("res://scripts/autoload/game_state.gd") or "Quest mastered · Week" in _load_src("res://scripts/autoload/game_state.gd"))
	print("TRAVEL_FAV_TOP_SRC", "show ★ fav at top of travel list" in _load_src("res://scripts/ui/main.gd"))
	print("WAVE56_TOAST_SRC", "maybe_wave_56_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_156_SRC", _ver("1.56.0") or _ver("1.57.0"))




	print("CHERRY_CHINCHILLA_SRC", '"cherry_chinchilla"' in _load_src("res://data/enemies.json"))
	print("REED_SWAY_SRC", "_update_reed_sway" in _load_src("res://scripts/world/world.gd"))
	print("READY_FLASH_SRC", "Wave 57: clearer Ready flash color" in _load_src("res://scripts/ui/hud.gd"))
	print("DEFEAT_FOUNTAIN_SRC", "rest safe at Fountain" in _load_src("res://scripts/autoload/game_state.gd"))
	print("JOURNAL_OPEN_COUNT_SRC", "Open only · %d" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("WAVE57_TOAST_SRC", "maybe_wave_57_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_157_SRC", _ver("1.57.0") or _ver("1.58.0"))


	print("PLUM_PORCUPINE_SRC", '"plum_porcupine"' in _load_src("res://data/enemies.json"))
	print("THISTLE_SWAY_SRC", "_update_thistle_sway" in _load_src("res://scripts/world/world.gd"))
	print("MID_TELEGRAPH_SRC", "Wave 58: clearer soft-aggro mid-telegraph toast" in _load_src("res://scripts/world/enemy.gd"))
	print("WARDROBE_SPARKLE_SRC", "Wave 58: stronger wardrobe equip sparkle" in _load_src("res://scripts/ui/customize_screen.gd"))
	print("PARENT_YEAR_PCT_SRC", "Wave 58: show year %" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("WAVE58_TOAST_SRC", "maybe_wave_58_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_158_SRC", _ver("1.58.0") or _ver("1.59.0") or _ver("1.60.0") or _ver("1.61.0") or _ver("1.62.0"))



	print("PEACH_PUFFIN_SRC", '"peach_puffin"' in _load_src("res://data/enemies.json"))
	print("KNOLL_DUSK_GLOW_SRC", "_update_knoll_dusk_glow" in _load_src("res://scripts/world/world.gd"))
	print("MUTE_WEATHER_SRC", "Wave 59: clearer mute unmute with weather note" in _load_src("res://scripts/ui/hud.gd"))
	print("XP_STACK_SRC", "_xp_stack_i" in _load_src("res://scripts/combat/hitsplat.gd"))
	print("FAV_PACES_SRC", "_refresh_fav_paces" in _load_src("res://scripts/ui/hud.gd"))
	print("WAVE59_TOAST_SRC", "maybe_wave_59_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_159_SRC", _ver("1.59.0") or _ver("1.60.0") or _ver("1.61.0") or _ver("1.62.0"))



	print("FIG_FINCH_SRC", '"fig_finch"' in _load_src("res://data/enemies.json"))
	print("FESTIVAL_CONFETTI_SRC", "play_wave60_festival_confetti" in _load_src("res://scripts/world/world.gd"))
	print("LANDMARK_PACES_SRC", "Wave 60: clearer landmark approach with paces" in _load_src("res://scripts/world/world.gd"))
	print("PLAZA_FLICKER_SRC", "plaza dusk lantern flicker sync" in _load_src("res://scripts/world/world.gd"))
	print("JOURNAL_TOTAL_STARS_SRC", "★ Total mastered:" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("WAVE60_TOAST_SRC", "maybe_wave_60_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_160_SRC", _ver("1.60.0") or _ver("1.61.0") or _ver("1.62.0"))



	print("GRAPE_GECKO_SRC", '"grape_gecko"' in _load_src("res://data/enemies.json"))
	print("WILLOW_SWAY_SRC", "_update_willow_sway" in _load_src("res://scripts/world/world.gd"))
	print("FOOD_EMPTY_H_SRC", "press H for Fountain to refill" in _load_src("res://scripts/autoload/game_state.gd"))
	print("UNEQUIP_ALL_SRC", "unequip_all_slots" in _load_src("res://scripts/autoload/game_state.gd"))
	print("WAVE61_TOAST_SRC", "maybe_wave_61_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_161_SRC", _ver("1.61.0") or _ver("1.62.0"))



	print("APRICOT_ARMADILLO_SRC", '"apricot_armadillo"' in _load_src("res://data/enemies.json"))
	print("FERN_SWAY_SRC", "_update_fern_sway" in _load_src("res://scripts/world/world.gd"))
	print("TRAVEL_FADE_NAME_SRC", "SoftTravelFadeLabel" in _load_src("res://scripts/ui/main.gd"))
	print("PULLBACK_DENSE_SRC", "Wave 62: denser combat pull-back sparkle" in _load_src("res://scripts/player/player.gd"))
	print("JOURNAL_OPEN_ONLY_SAVE_SRC", "journal_open_only" in _load_src("res://scripts/autoload/game_state.gd"))
	print("WAVE62_TOAST_SRC", "maybe_wave_62_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_162_SRC", _ver("1.62.0") or _ver("1.63.0") or _ver("1.65.0") or _ver("1.66.0") or _ver("1.67.0") or _ver("1.68.0"))


	print("BLUEBERRY_BUNNY_SRC", '"blueberry_bunny"' in _load_src("res://data/enemies.json"))
	print("HEATHER_SWAY_SRC", "_update_heather_sway" in _load_src("res://scripts/world/world.gd"))
	print("YEAR_CHIP_MASTERY_SRC", "Year · mastery" in _load_src("res://scripts/ui/hud.gd"))
	print("HALL_LIGHT_DIP_SRC", "_begin_hall_light_dip" in _load_src("res://scripts/world/world.gd"))
	print("WAVE63_TOAST_SRC", "maybe_wave_63_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_163_SRC", _ver("1.63.0") or _ver("1.65.0") or _ver("1.66.0") or _ver("1.67.0") or _ver("1.68.0"))

	print("CRANBERRY_CAPYBARA_SRC", '"cranberry_capybara"' in _load_src("res://data/enemies.json"))
	print("ARCH_DUSK_GLOW_SRC", "_update_arch_dusk_glow" in _load_src("res://scripts/world/world.gd"))
	print("AGGRO_DEF_RING_SRC", "Wave 64: clearer soft-aggro ring when armor Def high" in _load_src("res://scripts/world/enemy.gd"))
	print("FAV_SHORT_SRC", "_fav_landmark_short" in _load_src("res://scripts/ui/hud.gd"))
	print("TRAVEL_SEARCH_REMEMBER_SRC", "_travel_last_query" in _load_src("res://scripts/ui/main.gd"))
	print("WAVE64_TOAST_SRC", "maybe_wave_64_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_164_SRC", _ver("1.64.0") or _ver("1.65.0") or _ver("1.66.0") or _ver("1.67.0") or _ver("1.68.0"))


	print("RASPBERRY_RAM_SRC", '"raspberry_ram"' in _load_src("res://data/enemies.json"))
	print("CROSS_DUSK_GLOW_SRC", "_update_cross_dusk_glow" in _load_src("res://scripts/world/world.gd"))
	print("FIRST_FIGHT_FOE_SRC", "Wave 65: clearer first-fight tip with foe name" in _load_src("res://scripts/world/enemy.gd"))
	print("YEAR_WEATHER_LETTER_SRC", "Wave 65: weather icon letter beside Year chip" in _load_src("res://scripts/ui/hud.gd"))
	print("READY_CHIME_SRC", "play_ready_chime" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("WAVE65_TOAST_SRC", "maybe_wave_65_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_165_SRC", _ver("1.65.0") or _ver("1.66.0") or _ver("1.67.0") or _ver("1.68.0"))

	print("STRAWBERRY_STOAT_SRC", '"strawberry_stoat"' in _load_src("res://data/enemies.json"))
	print("BIRCH_FIREFLIES_SRC", "BirchRestFireflies" in _load_src("res://scripts/world/world.gd"))
	print("ARRIVAL_SHORT_SRC", "_travel_landmark_short" in _load_src("res://scripts/ui/main.gd"))
	print("VICTORY_SPARKLE_SRC", "Wave 66: softer richer victory sparkle polish" in _load_src("res://scripts/world/world.gd"))
	print("JOURNAL_OPEN_STICKY_SRC", "Open only · %d quests still open" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("TRAVEL_NEAREST_SRC", "Wave 66: highlight nearest landmark" in _load_src("res://scripts/ui/main.gd"))
	print("WAVE66_TOAST_SRC", "maybe_wave_66_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_166_SRC", _ver("1.66.0") or _ver("1.67.0") or _ver("1.68.0") or _ver("1.69.0") or _ver("1.70.0") or _ver("1.71.0") or _ver("1.72.0") or _ver("1.73.0") or _ver("1.74.0") or _ver("1.75.0") or _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))


	print("BLACKBERRY_BEAR_SRC", '"blackberry_bear"' in _load_src("res://data/enemies.json"))
	print("REED_POOL_GLEAM_SRC", "ReedPoolRippleGleam" in _load_src("res://scripts/world/world.gd"))
	print("LOW_HP_TOAST_SRC", "_maybe_low_hp_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("FOES_PULSE_SRC", "_update_foe_pulse" in _load_src("res://scripts/ui/hud.gd"))
	print("NEEDS_HELP_DAYS_SRC", "_days_since_attempt" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("WAVE67_TOAST_SRC", "maybe_wave_67_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_167_SRC", _ver("1.67.0") or _ver("1.68.0") or _ver("1.69.0") or _ver("1.70.0") or _ver("1.71.0") or _ver("1.72.0") or _ver("1.73.0") or _ver("1.74.0") or _ver("1.75.0") or _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))


	print("GUAVA_GOAT_SRC", '"guava_goat"' in _load_src("res://data/enemies.json"))
	print("WILLOW_LEAVES_SRC", "WillowBendLeafDrift" in _load_src("res://scripts/world/world.gd"))
	print("NEAR_MISS_TITLE_SRC", "short_title" in _load_src("res://scripts/autoload/game_state.gd"))
	print("FOUNTAIN_CHIME_SRC", "play_fountain_rest_chime" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("UNEQUIP_COUNT_SRC", "Confirm? · %d" in _load_src("res://scripts/ui/inventory_panel.gd"))
	print("YEAR_MASTERY_GOLD_SRC", "_year_chip_last_mastery" in _load_src("res://scripts/ui/hud.gd"))
	print("WAVE68_TOAST_SRC", "maybe_wave_68_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_168_SRC", _ver("1.68.0") or _ver("1.69.0") or _ver("1.70.0") or _ver("1.71.0") or _ver("1.72.0") or _ver("1.73.0") or _ver("1.74.0") or _ver("1.75.0") or _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))


	print("KIWI_KOALA_SRC", '"kiwi_koala"' in _load_src("res://data/enemies.json"))
	print("FERN_FRONDS_SRC", "FernDellFrondDrift" in _load_src("res://scripts/world/world.gd"))
	print("LANDMARK_PACES_CHIP_SRC", "landmark_dist" in _load_src("res://scripts/world/world.gd") and "✦ %s · ~%d paces" in _load_src("res://scripts/ui/hud.gd"))
	print("CANOPY_DRIP_POLISH_SRC", "Wave 69: soft rain-canopy drip polish" in _load_src("res://scripts/world/world.gd"))
	print("MASTERED_FILTER_COUNT_SRC", "Mastered ★ · %d" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("SAVE_CHIP_PULSE_SRC", "_on_game_saved_pulse" in _load_src("res://scripts/ui/hud.gd"))
	print("WAVE69_TOAST_SRC", "maybe_wave_69_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_169_SRC", _ver("1.69.0") or _ver("1.70.0") or _ver("1.71.0") or _ver("1.72.0") or _ver("1.73.0") or _ver("1.74.0") or _ver("1.75.0") or _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))


	print("MANGO_MONGOOSE_SRC", '"mango_mongoose"' in _load_src("res://data/enemies.json"))
	print("HEATHER_BLOOMS_SRC", "HeatherHeathBloomDrift" in _load_src("res://scripts/world/world.gd"))
	print("HEATHER_DUSK_SWAY_SRC", "Wave 70: soft heather sway reads stronger at dusk" in _load_src("res://scripts/world/world.gd"))
	print("PARENT_MASTERY_STARS_SRC", "_mastery_progress_bar" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("WAVE70_TOAST_SRC", "maybe_wave_70_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_170_SRC", _ver("1.70.0") or _ver("1.71.0") or _ver("1.72.0") or _ver("1.73.0") or _ver("1.74.0") or _ver("1.75.0") or _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))


	print("PAPAYA_PANDA_SRC", '"papaya_panda"' in _load_src("res://data/enemies.json"))
	print("THISTLE_BLOOMS_SRC", "ThistleRiseBloomDrift" in _load_src("res://scripts/world/world.gd"))
	print("THISTLE_DUSK_SWAY_SRC", "Wave 71: soft thistle sway reads stronger at dusk" in _load_src("res://scripts/world/world.gd"))
	print("DAILY_CHECKPOINT_CLEAR_SRC", "Daily checkpoint · open Parent" in _load_src("res://scripts/autoload/game_state.gd"))
	print("BREAD_LOW_FLASH_SRC", "_food_bread_low" in _load_src("res://scripts/ui/hud.gd"))
	print("WAVE71_TOAST_SRC", "maybe_wave_71_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_171_SRC", _ver("1.71.0") or _ver("1.72.0") or _ver("1.73.0") or _ver("1.74.0") or _ver("1.75.0") or _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))



	print("COCONUT_CRAB_SRC", '"coconut_crab"' in _load_src("res://data/enemies.json"))
	print("MAPLE_DUSK_LEAVES_SRC", "MapleCopseDuskLeafDrift" in _load_src("res://scripts/world/world.gd"))
	print("MAPLE_DUSK_BOOST_SRC", "Wave 72: denser Maple Copse leaf fall reads stronger at dusk" in _load_src("res://scripts/world/world.gd"))
	print("EDGE_FOG_POLISH_SRC", "Wave 72: soft edge-fog banks polish" in _load_src("res://scripts/world/world.gd"))
	print("FOUNTAIN_REST_CLEAR_SRC", "Fountain rest · HP returning gently" in _load_src("res://scripts/autoload/game_state.gd"))
	print("JOURNAL_OPEN_WEEKS_SRC", "_format_open_quest_weeks" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("WAVE72_TOAST_SRC", "maybe_wave_72_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_172_SRC", _ver("1.72.0") or _ver("1.73.0") or _ver("1.74.0") or _ver("1.75.0") or _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))


	print("LIME_LLAMA_SRC", '"lime_llama"' in _load_src("res://data/enemies.json"))
	print("AMBER_GLOW_MOTES_SRC", "AmberKnollGlowMotes" in _load_src("res://scripts/world/world.gd"))
	print("AMBER_GLOW_POLISH_SRC", "Wave 73: soft Amber Knoll amber-glow polish at dusk" in _load_src("res://scripts/world/world.gd"))
	print("BROOK_MURMUR_POLISH_SRC", "Wave 73: soft brook murmur polish" in _load_src("res://scripts/world/world.gd"))
	print("PUDDLE_RIPPLE_POLISH_SRC", "Wave 73: soft puddle ripple polish" in _load_src("res://scripts/world/world.gd"))
	print("QUEST_COMPLETE_TITLE_SRC", "Quest complete ·" in _load_src("res://scripts/autoload/game_state.gd"))
	print("PARENT_EMPTY_WARMER_SRC", "A quiet week for now" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("BAG_STACK_TYPE_HINT_SRC", "🍞 stack" in _load_src("res://scripts/ui/inventory_panel.gd"))
	print("WAVE73_TOAST_SRC", "maybe_wave_73_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_173_SRC", _ver("1.73.0") or _ver("1.74.0") or _ver("1.75.0") or _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))



	print("MELON_MOOSE_SRC", '"melon_moose"' in _load_src("res://data/enemies.json"))
	print("CEDAR_NEEDLE_DRIFT_SRC", "CedarHollowNeedleDrift" in _load_src("res://scripts/world/world.gd"))
	print("PLAZA_LANTERN_SYNC_SRC", "Wave 74: plaza dusk lantern sync polish" in _load_src("res://scripts/world/world.gd"))
	print("FOE_VICTORY_SPARKLE_SRC", "_play_foe_victory_sparkle" in _load_src("res://scripts/world/enemy.gd"))
	print("YEAR_CHIP_WEEK_SRC", "week %d of 36" in _load_src("res://scripts/ui/hud.gd"))
	print("TRAVEL_NEAR_PULSE_SRC", "_tick_travel_near_pulse" in _load_src("res://scripts/ui/main.gd"))
	print("WAVE74_TOAST_SRC", "maybe_wave_74_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_174_SRC", _ver("1.74.0") or _ver("1.75.0") or _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))


	print("QUINCE_QUOKKA_SRC", '"quince_quokka"' in _load_src("res://data/enemies.json"))
	print("STONE_ARCH_DUST_SRC", "StoneArchLimestoneDust" in _load_src("res://scripts/world/world.gd"))
	print("WIND_LEAF_POLISH_SRC", "Wave 75 soft wind leaf particles polish" in _load_src("res://scripts/world/world.gd"))
	print("FIRST_DISCOVERY_TOAST_SRC", "✦ First discovery ·" in _load_src("res://scripts/world/world.gd"))
	print("JOURNAL_MASTERED_STICKY_COUNT_SRC", "Mastered this week sticky ·" in _load_src("res://scripts/ui/journal_panel.gd"))
	print("PARENT_OLDEST_HELP_SRC", "oldest attempt first" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("WAVE75_TOAST_SRC", "maybe_wave_75_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_175_SRC", _ver("1.75.0") or _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))


	print("WATERMELON_WALLABY_SRC", '"watermelon_wallaby"' in _load_src("res://data/enemies.json"))
	print("CROSS_LANTERN_MOTHS_SRC", "QuietCrossLanternMoths" in _load_src("res://scripts/world/world.gd"))
	print("CRICKET_HUSH_POLISH_SRC", "Wave 76 soft night cricket hush polish" in _load_src("res://scripts/autoload/audio_bus.gd") or "Wave 43/76: soft night cricket hush" in _load_src("res://scripts/autoload/audio_bus.gd"))
	print("DEF_EQUIP_FLASH_SRC", "_def_equip_flash_id" in _load_src("res://scripts/ui/inventory_panel.gd"))
	print("FOES_UP_CHIP_SRC", "Foes · %d ↑" in _load_src("res://scripts/ui/hud.gd"))
	print("WAVE76_TOAST_SRC", "maybe_wave_76_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_176_SRC", _ver("1.76.0") or _ver("1.77.0") or _ver("1.78.0"))


	print("HONEYDEW_HAMSTER_SRC", '"honeydew_hamster"' in _load_src("res://data/enemies.json"))
	print("BIRCH_FIREFLY_DENSE_SRC", "Wave 66/77: soft birch-rest firefly denser wink" in _load_src("res://scripts/world/world.gd"))
	print("CAMPFIRE_POLISH_SRC", "Wave 77: soft campfire glow polish" in _load_src("res://scripts/world/world.gd"))
	print("SOFT_TRAVEL_ARRIVAL_SRC", "Arrived · Soft travel ·" in _load_src("res://scripts/ui/main.gd"))
	print("FAV_CHIP_PACES_SRC", "Wave 77: ★ fav chip shows paces to fav" in _load_src("res://scripts/ui/hud.gd"))
	print("WAVE77_TOAST_SRC", "maybe_wave_77_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_177_SRC", _ver("1.77.0") or _ver("1.78.0"))

	print("PLAZA_COBBLE_SRC", "PlazaCobble" in _load_src("res://scripts/world/world.gd"))
	print("HUMANOID_FACE_SRC", "LEye" in _load_src("res://scripts/characters/humanoid_builder.gd"))
	print("PARENT_PIN_LOCK_SRC", "do NOT open the dashboard on a wrong PIN" in _load_src("res://scripts/ui/parent_panel.gd"))
	print("REFINE_178_TOAST_SRC", "maybe_refine_178_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_178_SRC", _ver("1.78.0"))
	print("LANDMARK_CATALOG_SRC", "class_name LandmarkCatalog" in _load_src("res://scripts/util/landmarks.gd"))
	print("WAVE_TOAST_HELPER_SRC", "func _emit_once_toast" in _load_src("res://scripts/autoload/game_state.gd"))
	print("RAID_GATE_SRC", "const RAID_GATE" in _load_src("res://scripts/autoload/game_state.gd"))
	print("VERSION_1781_SRC", _ver("1.78.1") or _ver("1.78.0"))

	print("WORLD_SMOKE_OK")
	quit(0)
