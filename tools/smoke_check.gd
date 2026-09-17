extends SceneTree
func _initialize():
	print("CHECK_START")
	var w = load("res://scripts/world/world.gd")
	var p = load("res://scripts/player/player.gd")
	var e = load("res://scripts/world/enemy.gd")
	var a = load("res://scripts/autoload/audio_bus.gd")
	var j = load("res://scripts/ui/journal_panel.gd")
	var h = load("res://scripts/combat/hitsplat.gd")
	var hb = load("res://scripts/characters/humanoid_builder.gd")
	print("LOADED", w!=null, p!=null, e!=null, a!=null, j!=null, h!=null, hb!=null)
	# Build humanoid
	var root = Node3D.new()
	root.name = "T"
	get_root().add_child(root)
	var parts = HumanoidBuilder.build(root)
	print("PARTS", parts.has("accessory"), parts.has("weapon"), parts.has("l_arm"))
	HumanoidBuilder.style_accessory(parts, {"id":"brass_lantern","name":"Brass Lantern","color":"#f4a261"})
	print("ACCESSORY_OK")
	# Audio streams
	print("CHECK_OK")
	quit(0)
