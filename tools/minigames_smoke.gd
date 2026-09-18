extends SceneTree
## Headless smoke for Village Games (no Virtue Match — Wisp Pop instead).

func _initialize() -> void:
	print("MINIGAMES_SMOKE_START")
	var ok := true
	var panel_src := FileAccess.get_file_as_string("res://scripts/ui/minigames_panel.gd")
	var gs_src := FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd")
	var main_src := FileAccess.get_file_as_string("res://scripts/ui/main.gd")
	var hud_src := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var proj := FileAccess.get_file_as_string("res://project.godot")

	if "Virtue Match" in panel_src or "GAME_MATCH" in panel_src or "_begin_match" in panel_src:
		print("FAIL_VIRTUE_MATCH_STILL_PRESENT")
		ok = false
	if "Village Games" not in panel_src or "Lantern Catch" not in panel_src:
		print("FAIL_PANEL_LANTERN")
		ok = false
	if "Wisp Pop" not in panel_src or "Fact Dash" not in panel_src:
		print("FAIL_PANEL_GAMES")
		ok = false
	if "_burst" not in panel_src or "_float_score" not in panel_src or "_spawn_wisp" not in panel_src:
		print("FAIL_COLORFUL_VFX")
		ok = false
	if "WISP_PALETTE" not in panel_src or "FACT_BTN_COLORS" not in panel_src:
		print("FAIL_ICONS_COLORS")
		ok = false
	if "func record_minigame_score" not in gs_src or "func get_minigame_best" not in gs_src:
		print("FAIL_GS_API")
		ok = false
	if '"wisp"' not in gs_src or "minigame_scores" not in gs_src:
		print("FAIL_GS_SAVE")
		ok = false
	if "maybe_minigames_184_toast" not in gs_src:
		print("FAIL_GS_TOAST")
		ok = false
	if "_toggle_minigames" not in main_src or "_setup_minigames_panel" not in main_src:
		print("FAIL_MAIN_WIRE")
		ok = false
	if "games_pressed" not in hud_src or "GamesBtn" not in hud_src:
		print("FAIL_HUD")
		ok = false
	if 'config/version="1.84.6"' not in proj and 'config/version="1.84.0"' not in proj:
		print("FAIL_VERSION")
		ok = false

	var gs = root.get_node_or_null("GameState")
	if gs == null:
		print("FAIL_NO_GAMESTATE")
		quit(1)
		return

	gs.new_game("SmokeKid", {"hair":"brown","skin":"medium","cape_color":"crimson","outfit":"cream"}, 0)
	var before_xp: int = int(gs.xp)
	var r1: Dictionary = gs.record_minigame_score("lantern", 12)
	print("SCORE1", r1)
	if not bool(r1.get("new_best", false)) or int(r1.get("xp_awarded", 0)) != 2:
		print("FAIL_FIRST_BEST")
		ok = false
	if int(gs.xp) != before_xp + 2:
		print("FAIL_XP_APPLY")
		ok = false
	var r2: Dictionary = gs.record_minigame_score("lantern", 10)
	print("SCORE2", r2)
	if bool(r2.get("new_best", false)) or int(r2.get("xp_awarded", 0)) != 0:
		print("FAIL_LOWER_SCORE")
		ok = false
	var r3: Dictionary = gs.record_minigame_score("wisp", 20)
	print("SCORE3", r3)
	if not bool(r3.get("new_best", false)) or int(gs.get_minigame_best("wisp")) != 20:
		print("FAIL_WISP_BEST")
		ok = false
	gs.minigame_xp_today = 6
	var dt := Time.get_datetime_dict_from_system()
	gs.minigame_xp_date = "%04d-%02d-%02d" % [int(dt.get("year", 0)), int(dt.get("month", 0)), int(dt.get("day", 0))]
	var r4: Dictionary = gs.record_minigame_score("facts", 9)
	print("SCORE4_CAPPED", r4)
	if int(r4.get("xp_awarded", -1)) != 0 or not bool(r4.get("new_best", false)):
		print("FAIL_DAILY_CAP")
		ok = false

	var panel_script: Script = load("res://scripts/ui/minigames_panel.gd")
	if panel_script == null:
		print("FAIL_LOAD_PANEL")
		ok = false
	else:
		var node := Control.new()
		node.set_script(panel_script)
		root.add_child(node)
		if node.has_method("open"):
			node.open()
			print("PANEL_OPEN_OK", node.visible)
			if node.has_method("_start_game"):
				node._start_game("lantern")
				print("LANTERN_START_OK", str(node.get("_mode")))
				node._start_game("wisp")
				print("WISP_START_OK", str(node.get("_mode")))
				node._start_game("facts")
				print("FACTS_START_OK", str(node.get("_mode")))
		node.queue_free()

	if ok:
		print("MINIGAMES_SMOKE_OK")
		quit(0)
	else:
		print("MINIGAMES_SMOKE_FAIL")
		quit(1)
