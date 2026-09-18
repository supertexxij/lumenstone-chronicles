extends SceneTree
## Headless smoke: week unicorn party signal + celebrate source markers (v1.84).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("CELEBRATE_SMOKE_START")
	var gs_src := FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd")
	var world_src := FileAccess.get_file_as_string("res://scripts/world/world.gd")
	var audio_src := FileAccess.get_file_as_string("res://scripts/autoload/audio_bus.gd")
	var creature_src := FileAccess.get_file_as_string("res://scripts/characters/creature_builder.gd")
	assert("signal week_advanced" in gs_src)
	assert("week_advanced.emit" in gs_src)
	assert("unicorns celebrate" in gs_src)
	assert("_play_quest_mini_fireworks" in world_src)
	assert("_spawn_firework_burst" in world_src)
	assert("_play_week_unicorn_party" in world_src)
	assert("_dance_unicorn" in world_src)
	assert("week_advanced.is_connected" in world_src)
	assert("play_firework_pop" in audio_src and "play_unicorn_party" in audio_src)
	assert("party_unicorn" in creature_src and "_build_party_unicorn" in creature_src)
	assert("Horn" in creature_src and "ManeA" in creature_src and "Forelock" in creature_src and "Muzzle" in creature_src)
	assert("EyeWhiteL" in creature_src and "IrisL" in creature_src and "ShineL" in creature_src)
	assert("colorize_party_unicorn" in creature_src)
	print("SOURCE_OK")

	var gs: Node = get_root().get_node_or_null("/root/GameState")
	assert(gs != null)
	var quest_db: Node = get_root().get_node_or_null("/root/QuestDB")
	assert(quest_db != null)

	var got := {"fired": false, "new_week": -1, "completed": -1}
	gs.week_advanced.connect(func(nw: int, cw: int):
		got["fired"] = true
		got["new_week"] = nw
		got["completed"] = cw
	)
	gs.call("new_game", "PartyTester", {"hair":"brown","skin":"medium","cape_color":"crimson","outfit":"cream"}, 0)

	var week1_ids: Array = []
	for q in quest_db.quests:
		if int(q.get("week", 0)) == 1:
			week1_ids.append(str(q.get("id", "")))
	assert(week1_ids.size() >= 4)
	var before_week: int = int(gs.get("unlocked_week"))
	# Soft unlock needs 4 mastered in the week (or the raid). Master four.
	for i in 4:
		gs.call("record_quest_attempt", week1_ids[i], 5, 5)
	var after_week: int = int(gs.get("unlocked_week"))
	print("WEEK_BEFORE", before_week, "AFTER", after_week, "SIGNAL", got)
	assert(after_week > before_week)
	assert(bool(got["fired"]))
	assert(int(got["new_week"]) == after_week)
	assert(int(got["completed"]) == before_week)
	print("CELEBRATE_SMOKE_OK")
	quit(0)
