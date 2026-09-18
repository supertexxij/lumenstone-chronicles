extends SceneTree
## Live GameState reward check (runtime autoload lookup).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("LIVE_REWARD_START")
	var gs: Node = root.get_node_or_null("/root/GameState")
	if gs == null:
		print("NO_GAMESTATE")
		quit(1)
		return
	gs.call("new_game", "RewardTester", {"hair":"brown","skin":"medium","cape_color":"crimson","outfit":"cream"}, 0)
	var before_xp: int = int(gs.get("xp"))
	var before_lumens: int = int(gs.get("lumens")["bible"])

	var qid := "w1-bible-genesis"
	var miss: Dictionary = gs.call("record_quest_attempt", qid, 3, 5)
	print("NEAR_MISS", miss)
	assert(not bool(miss.get("mastered", true)))
	assert(int(miss.get("xp_awarded", 0)) == 6)
	assert(int(gs.get("xp")) == before_xp + 6)
	assert(int(gs.get("lumens")["bible"]) == before_lumens)

	var before2: int = int(gs.get("xp"))
	var win: Dictionary = gs.call("record_quest_attempt", qid, 5, 5)
	print("MASTERY", win)
	assert(bool(win.get("mastered", false)))
	assert(int(win.get("xp_awarded", 0)) == 20)
	assert(int(win.get("lumens_awarded", 0)) == 2)
	assert(int(gs.get("xp")) == before2 + 20)
	assert(int(gs.get("lumens")["bible"]) == before_lumens + 2)
	assert(qid in gs.get("completed_quests"))

	print("LIVE_REWARD_OK")
	quit(0)
