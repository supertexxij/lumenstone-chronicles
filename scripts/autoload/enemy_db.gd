extends Node

var defs: Dictionary = {}
var spawns: Array = []
var base_combat: Dictionary = {}
## JSON still lists ~263 historic polish spawns; many sit past the walk clamp
## (player x[-54,52] z[-62,52]). v1.86 only instantiates playable-rim foes.
var raw_spawn_count: int = 0
const PLAYABLE_X_MIN := -60.0
const PLAYABLE_X_MAX := 58.0
const PLAYABLE_Z_MIN := -68.0
const PLAYABLE_Z_MAX := 58.0

func _ready() -> void:
	var f: FileAccess = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		f.close()
		defs = data.get("defs", {})
		var raw: Array = data.get("spawns", [])
		raw_spawn_count = raw.size()
		spawns = _filter_playable_spawns(raw)
		base_combat = data.get("base_combat", {})

func _filter_playable_spawns(raw: Array) -> Array:
	## Drop unreachable far-wilds rows so 200+ CharacterBody3D meshes never spawn.
	## Keep a 6-pace rim past the walk clamp so edge combat still works.
	var kept: Array = []
	for s in raw:
		if typeof(s) != TYPE_DICTIONARY:
			continue
		if spawn_in_playable(s):
			kept.append(s)
	return kept

func spawn_in_playable(s: Dictionary) -> bool:
	var x: float = float(s.get("x", 0.0))
	var z: float = float(s.get("z", 0.0))
	return x >= PLAYABLE_X_MIN and x <= PLAYABLE_X_MAX and z >= PLAYABLE_Z_MIN and z <= PLAYABLE_Z_MAX

func get_def(kind: String) -> Dictionary:
	return defs.get(kind, {})
