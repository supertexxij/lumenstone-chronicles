extends SceneTree
## Seed slot 0 so Continue enters the world for celebrate VFX demo.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var gs: Node = get_root().get_node_or_null("/root/GameState")
	assert(gs != null)
	gs.call("new_game", "CelebrateKid", {"hair":"brown","skin":"medium","cape_color":"crimson","outfit":"cream"}, 0)
	gs.call("save_game")
	print("SEEDED_SLOT0", gs.call("has_save", 0))
	quit(0)
