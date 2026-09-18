extends SceneTree
## Build party unicorn mesh headless and assert cartoon parts exist.

const HeadlessGuardScript = preload("res://scripts/util/headless_guard.gd")
const CreatureBuilderScript = preload("res://scripts/characters/creature_builder.gd")

func _initialize() -> void:
	print("UNICORN_MESH_SMOKE_START")
	# Touch HeadlessGuard so class is loaded before CreatureBuilder statics run.
	var _hg = HeadlessGuardScript
	var root := Node3D.new()
	get_root().add_child(root)
	var bob: Node3D = CreatureBuilderScript.build("party_unicorn", root)
	assert(bob != null)
	for want in ["Body", "Neck", "Head", "Muzzle", "Horn", "Mane", "Tail", "EarL", "EyeL", "Forelock"]:
		assert(_find(bob, want) != null, "missing " + want)
	# Ribbon mane sheets should be boxes, not a sphere-blob cluster on the mane root
	var mane := _find(bob, "Mane")
	assert(mane != null)
	var sheet_count := 0
	for c in mane.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh:
			sheet_count += 1
	assert(sheet_count >= 4, "mane sheets")
	CreatureBuilderScript.colorize_party_unicorn(bob, Color("#f7a8c8"), Color("#ffe08a"))
	var horn_tip := _find(bob, "HornTip")
	assert(horn_tip is MeshInstance3D)
	var mat: Material = (horn_tip as MeshInstance3D).material_override
	assert(mat is StandardMaterial3D)
	print("MANE_SHEETS", sheet_count)
	print("UNICORN_MESH_SMOKE_OK")
	quit(0)


func _find(n: Node, want: String) -> Node:
	if n.name == want:
		return n
	for c in n.get_children():
		var f := _find(c, want)
		if f:
			return f
	return null
