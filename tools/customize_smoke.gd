extends SceneTree
## Headless smoke for gender / hair-style humanoid apply + customize preview helpers.

func _src(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _initialize() -> void:
	print("CUSTOMIZE_SMOKE_START")
	var gs = root.get_node_or_null("GameState")
	print("GS", gs != null)

	var mesh_root := Node3D.new()
	mesh_root.name = "TmpHumanoid"
	root.add_child(mesh_root)
	var parts: Dictionary = HumanoidBuilder.build(mesh_root)
	print("HAS_BUN", parts.has("hair_bun"))
	print("HAS_PONY", parts.has("hair_pony"))
	HumanoidBuilder.apply_human_colors(
		parts,
		Color("#c68642"),
		Color("#5c4033"),
		Color("#f4e4bc"),
		Color("#c1121f")
	)
	for style in ["short", "tidy", "long", "bun", "pony", "spiky"]:
		HumanoidBuilder.apply_hair_style(parts, style)
		print("HAIR_STYLE_OK ", style)
	HumanoidBuilder.apply_gender(parts, "boy")
	var hem_boy: MeshInstance3D = parts.get("hem")
	var boy_y: float = hem_boy.position.y if hem_boy else -1.0
	HumanoidBuilder.apply_gender(parts, "girl")
	var hem_girl: MeshInstance3D = parts.get("hem")
	var girl_y: float = hem_girl.position.y if hem_girl else -1.0
	print("GENDER_HEM_DIFF ", girl_y < boy_y)
	var bun: MeshInstance3D = parts.get("hair_bun")
	HumanoidBuilder.apply_hair_style(parts, "bun")
	print("BUN_VISIBLE ", bun != null and bun.visible)
	HumanoidBuilder.apply_hair_style(parts, "pony")
	var pony: MeshInstance3D = parts.get("hair_pony")
	print("PONY_VISIBLE ", pony != null and pony.visible)

	if gs:
		gs.appearance = {"hair": "blonde", "skin": "fair"}
		gs.normalize_appearance()
		print("NORMALIZE_GENDER ", gs.appearance.get("gender") == "boy")
		print("NORMALIZE_STYLE ", gs.appearance.get("hair_style") == "short")
	else:
		print("NORMALIZE_GENDER ", false)
		print("NORMALIZE_STYLE ", false)

	var cust := _src("res://scripts/ui/customize_screen.gd")
	print("PREVIEW_SRC ", "_build_character_preview" in cust and "look_at_from_position" in cust)
	print("GENDER_OPT_SRC ", "GenderOpt" in cust and "HairStyleOpt" in cust)
	mesh_root.queue_free()
	print("CUSTOMIZE_SMOKE_OK")
	quit(0)
