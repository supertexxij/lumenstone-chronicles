extends SceneTree
## Headless check: opaque party unicorn sheet + Sprite3D frame helper markers.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("UNICORN_ART_SMOKE_START")
	var path := "res://assets/vfx/party_unicorn_dance_sheet.png"
	assert(ResourceLoader.exists(path))
	var tex: Texture2D = load(path)
	print("TEX_SIZE=", tex.get_width(), "x", tex.get_height())
	var cols := 6
	var cell_w := int(tex.get_width() / cols)
	var cell_h := tex.get_height()
	print("CELL=", cell_w, "x", cell_h)
	assert(cell_w > 0 and cell_h > 0)

	var world_src := FileAccess.get_file_as_string("res://scripts/world/world.gd")
	assert("_make_party_unicorn_sprite" in world_src)
	assert("_set_party_unicorn_frame" in world_src)
	assert("ALPHA_CUT_OPAQUE_PREPASS" in world_src)
	assert("party_unicorn_dance_sheet.png" in world_src)

	var root := Node3D.new()
	get_root().add_child(root)
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(0, 0, cell_w, cell_h)
	var spr := Sprite3D.new()
	spr.texture = atlas
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.transparent = true
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	spr.alpha_scissor_threshold = 0.5
	spr.modulate = Color(1, 1, 1, 1)
	root.add_child(spr)
	# Advance a couple frames like the dance loop does
	atlas.region = Rect2(2 * cell_w, 0, cell_w, cell_h)
	atlas.region = Rect2(4 * cell_w, 0, cell_w, cell_h)
	print("SPRITE_READY alpha_cut=", spr.alpha_cut, " modulate_a=", spr.modulate.a)
	print("UNICORN_ART_SMOKE_OK")
	quit()
