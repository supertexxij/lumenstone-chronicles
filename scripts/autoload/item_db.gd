extends Node
## Item definitions loaded from data/items.json

var items: Dictionary = {}

func _ready() -> void:
	var f: FileAccess = FileAccess.open("res://data/items.json", FileAccess.READ)
	if f:
		items = JSON.parse_string(f.get_as_text())
		f.close()

func get_item(id: String) -> Dictionary:
	return items.get(id, {})

func starter_ids() -> Array:
	var out: Array = []
	for id in items:
		if items[id].get("starter", false):
			out.append(id)
	return out

func all_items() -> Array:
	return items.values()
