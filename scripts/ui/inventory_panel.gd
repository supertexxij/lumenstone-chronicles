extends Control

signal closed

@onready var list: ItemList = $Panel/VBox/ItemList
@onready var detail: Label = $Panel/VBox/Detail
@onready var equip_btn: Button = $Panel/VBox/HBox/EquipBtn
@onready var unequip_btn: Button = $Panel/VBox/HBox/UnequipBtn
@onready var close_btn: Button = $Panel/VBox/HBox/CloseBtn
@onready var loadout: Label = $Panel/VBox/Loadout

var selected_id: String = ""

func _ready() -> void:
	close_btn.pressed.connect(func(): AudioBus.play_ui(); closed.emit())
	list.item_selected.connect(_on_select)
	equip_btn.pressed.connect(_on_equip)
	unequip_btn.pressed.connect(_on_unequip)

func refresh() -> void:
	list.clear()
	selected_id = ""
	for id in GameState.unlocked_items:
		var item := ItemDB.get_item(id)
		var equipped_mark := ""
		for slot in GameState.equipped:
			if GameState.equipped[slot] == id:
				equipped_mark = " [E]"
		list.add_item("%s%s" % [item.get("name", id), equipped_mark])
		list.set_item_metadata(list.item_count - 1, id)
	_update_loadout()
	detail.text = "Select an item to equip."

func _update_loadout() -> void:
	var parts: PackedStringArray = []
	for slot in ["head","cape","accessory","weapon","belt"]:
		var id = GameState.equipped.get(slot)
		var name := "—"
		if id != null:
			name = ItemDB.get_item(str(id)).get("name", str(id))
		parts.append("%s: %s" % [slot.capitalize(), name])
	loadout.text = "\n".join(parts)

func _on_select(idx: int) -> void:
	selected_id = str(list.get_item_metadata(idx))
	var item := ItemDB.get_item(selected_id)
	detail.text = "%s\n%s\nSlot: %s" % [item.get("name",""), item.get("description",""), item.get("slot","")]

func _on_equip() -> void:
	if selected_id != "":
		AudioBus.play_ui()
		GameState.equip_item(selected_id)
		refresh()

func _on_unequip() -> void:
	if selected_id != "":
		AudioBus.play_ui()
		var item := ItemDB.get_item(selected_id)
		GameState.unequip_slot(item.get("slot", ""))
		refresh()
