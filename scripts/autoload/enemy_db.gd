extends Node

var defs: Dictionary = {}
var spawns: Array = []
var base_combat: Dictionary = {}

func _ready() -> void:
	var f: FileAccess = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		f.close()
		defs = data.get("defs", {})
		spawns = data.get("spawns", [])
		base_combat = data.get("base_combat", {})

func get_def(kind: String) -> Dictionary:
	return defs.get(kind, {})
