extends Node
## Quest definitions (Weeks 1–36 Campaigns I–IV)

var quests: Array = []
var by_id: Dictionary = {}

func _ready() -> void:
	var f: FileAccess = FileAccess.open("res://data/quests.json", FileAccess.READ)
	if f:
		quests = JSON.parse_string(f.get_as_text())
		f.close()
	for q in quests:
		by_id[q["id"]] = q

func get_quest(id: String) -> Dictionary:
	return by_id.get(id, {})

func get_by_guild(guild: String) -> Array:
	var out: Array = []
	for q in quests:
		if q["guild"] == guild:
			out.append(q)
	return out
