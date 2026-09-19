extends SceneTree
## Windowed/headless walkthrough: open customize, cycle looks, save PNG frames.

const OUT_DIR := "/opt/cursor/artifacts"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var main_ps: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_ps.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var customize: Control = main.get_node_or_null("UI/CustomizeScreen")
	var title: Control = main.get_node_or_null("UI/TitleScreen")
	if title:
		title.visible = false
	if customize == null:
		print("FAIL_NO_CUSTOMIZE")
		quit(1)
		return
	customize.open_new()
	customize.visible = true
	await process_frame
	await process_frame
	_shot("customize_01_boy_short.png")
	print("SHOT_01")

	customize.call("_cycle_gender", 1)
	await process_frame
	await create_timer(0.35).timeout
	_shot("customize_02_girl_short.png")
	print("SHOT_02")

	for i in 3:
		customize.call("_cycle_hair_style", 1)
		await process_frame
		await create_timer(0.3).timeout
	_shot("customize_03_girl_longish.png")
	print("SHOT_03")

	customize.call("_cycle_hair_style", 1)  # bun-ish depending on start
	await process_frame
	await create_timer(0.3).timeout
	customize.call("_cycle_hair_style", 1)
	await process_frame
	await create_timer(0.3).timeout
	_shot("customize_04_girl_pony_or_spiky.png")
	print("SHOT_04")

	if customize.hair_opt:
		customize.hair_opt.select(2)
		customize.call("_refresh_preview")
	if customize.outfit_opt:
		customize.outfit_opt.select(2)
		customize.call("_refresh_preview")
	await process_frame
	await create_timer(0.35).timeout
	_shot("customize_05_colors.png")
	print("SHOT_05")
	print("CUSTOMIZE_SHOTS_OK")
	quit(0)


func _shot(name: String) -> void:
	var img: Image = root.get_texture().get_image()
	if img == null:
		print("FAIL_SHOT ", name)
		return
	var path := "%s/%s" % [OUT_DIR, name]
	var err := img.save_png(path)
	print("SAVE ", path, " ", err)
