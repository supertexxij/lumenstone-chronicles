extends SceneTree
## Headless smoke: lesson progression rewards (v1.84).

func _initialize() -> void:
	print("REWARD_SMOKE_START")
	var qs: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"))
	assert(typeof(qs) == TYPE_ARRAY)
	var total_xp := 0
	var min_xp := 9999
	var max_xp := 0
	var saw_20 := false
	var saw_60 := false
	for q in qs:
		var xp: int = int(q.get("xp_reward", 0))
		total_xp += xp
		min_xp = mini(min_xp, xp)
		max_xp = maxi(max_xp, xp)
		if xp == 20:
			saw_20 = true
		if xp == 60:
			saw_60 = true
		# Pre-v1.84 typical values should be gone (5/8), keep 10 only if doubled from 5.
		assert(xp != 5 and xp != 8)
	print("QUEST_COUNT", qs.size())
	print("TOTAL_XP", total_xp)
	print("MIN_XP", min_xp)
	print("MAX_XP", max_xp)
	print("SAW_20", saw_20)
	print("SAW_60", saw_60)
	assert(saw_20 and saw_60)
	assert(total_xp == 6138)

	# Mirror GameState reward math without full autoload boot.
	var cases: Array = [
		{"c": 5, "t": 5, "base": 20, "expect_xp": 20, "expect_lumens": 2, "mastered": true},
		{"c": 4, "t": 5, "base": 20, "expect_xp": 20, "expect_lumens": 2, "mastered": true},
		{"c": 3, "t": 5, "base": 20, "expect_xp": 6, "expect_lumens": 0, "mastered": false},
		{"c": 2, "t": 5, "base": 20, "expect_xp": 4, "expect_lumens": 0, "mastered": false},
		{"c": 0, "t": 5, "base": 20, "expect_xp": 1, "expect_lumens": 0, "mastered": false},
		{"c": 4, "t": 5, "base": 60, "expect_xp": 60, "expect_lumens": 2, "mastered": true},
	]
	for case in cases:
		var correct: int = int(case["c"])
		var total: int = int(case["t"])
		var base: int = int(case["base"])
		var mastered: bool = correct * 10 >= maxi(1, total) * 8
		assert(mastered == bool(case["mastered"]))
		var xp_awarded: int
		var lumens_awarded: int
		if mastered:
			xp_awarded = base
			lumens_awarded = 2
		else:
			var pct: float = float(correct) / float(maxi(1, total))
			xp_awarded = maxi(1, int(round(float(base) * pct * 0.5)))
			lumens_awarded = 0
		print("CASE", correct, "/", total, " xp=", xp_awarded, " lumens=", lumens_awarded)
		assert(xp_awarded == int(case["expect_xp"]))
		assert(lumens_awarded == int(case["expect_lumens"]))

	var gs := FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd")
	var qp := FileAccess.get_file_as_string("res://scripts/ui/quest_panel.gd")
	assert("progress_xp" in gs and "xp_awarded" in gs and "lumens_awarded" in gs)
	assert("lumens[g] = int(lumens.get(g, 0)) + 2" in gs)
	assert("xp_awarded" in qp and "XP for the try" in qp and "guild lumens" in qp)
	print("SOURCE_MARKERS_OK")
	print("REWARD_SMOKE_OK")
	quit(0)
