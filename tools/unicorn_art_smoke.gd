extends SceneTree
## Headless check: party unicorn art sheet loads and AnimatedSprite3D can play.


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
	var frames := SpriteFrames.new()
	frames.add_animation("dance")
	frames.set_animation_speed("dance", 11.0)
	frames.set_animation_loop("dance", true)
	for i in cols:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * cell_w, 0, cell_w, cell_h)
		frames.add_frame("dance", at)
	print("FRAME_COUNT=", frames.get_frame_count("dance"))
	assert(frames.get_frame_count("dance") == 6)

	var world_src := FileAccess.get_file_as_string("res://scripts/world/world.gd")
	assert("_make_party_unicorn_sprite" in world_src)
	assert("party_unicorn_dance_sheet.png" in world_src)
	assert("AnimatedSprite3D" in world_src)

	var root := Node3D.new()
	root.name = "Holder"
	get_root().add_child(root)
	var spr := AnimatedSprite3D.new()
	spr.sprite_frames = frames
	spr.animation = &"dance"
	spr.pixel_size = 0.0042
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.transparent = true
	root.add_child(spr)
	spr.play("dance")
	print("PLAYING=", spr.is_playing(), " ANIM=", String(spr.animation))
	assert(spr.is_playing())
	print("UNICORN_ART_SMOKE_OK")
	quit()
