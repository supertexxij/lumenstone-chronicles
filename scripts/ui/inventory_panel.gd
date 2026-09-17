extends Control

signal closed

@onready var list: ItemList = $Panel/VBox/ItemList
@onready var detail: Label = $Panel/VBox/Detail
@onready var equip_btn: Button = $Panel/VBox/HBox/EquipBtn
@onready var unequip_btn: Button = $Panel/VBox/HBox/UnequipBtn
@onready var close_btn: Button = $Panel/VBox/HBox/CloseBtn
@onready var use_btn: Button = $Panel/VBox/HBox/UseBtn
@onready var loadout: Label = $Panel/VBox/Loadout

var selected_id: String = ""

func _ready() -> void:
	if use_btn == null:
		use_btn = Button.new()
		use_btn.name = "UseBtn"
		use_btn.text = "Use"
		use_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		$Panel/VBox/HBox.add_child(use_btn)
		$Panel/VBox/HBox.move_child(use_btn, unequip_btn.get_index() + 1)
	close_btn.pressed.connect(func(): AudioBus.play_ui(); closed.emit())
	list.item_selected.connect(_on_select)
	equip_btn.pressed.connect(_on_equip)
	unequip_btn.pressed.connect(_on_unequip)
	if use_btn:
		use_btn.pressed.connect(_on_use)

func refresh() -> void:
	list.clear()
	selected_id = ""
	for id in GameState.unlocked_items:
		var item := ItemDB.get_item(id)
		var equipped_mark := ""
		for slot in GameState.equipped:
			if GameState.equipped[slot] == id:
				equipped_mark = " [E]"
		var stack_mark := ""
		if str(item.get("slot", "")) == "consumable" and GameState.has_method("pantry_count"):
			stack_mark = " ×%d/%d" % [GameState.pantry_count(id), GameState.pantry_max(id)]
		list.add_item("%s%s%s" % [item.get("name", id), equipped_mark, stack_mark])
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
	var extra := ""
	var req: int = int(item.get("combat_level_req", 0))
	if req > 0:
		extra = "\nCombat Lv req: %d" % req
	if item.get("slot", "") == "weapon":
		extra += "\nDamage %s · Accuracy %s" % [item.get("damage", "?"), item.get("accuracy", "?")]
	if str(item.get("slot", "")) == "consumable":
		extra += "\nHeals %d HP (Use)." % int(item.get("heal", 0))
		if GameState.has_method("pantry_count"):
			extra += "\nPantry %d / %d" % [GameState.pantry_count(selected_id), GameState.pantry_max(selected_id)]
			if GameState.consumable_cd > 0.05:
				extra += "\nCooldown %.1fs" % GameState.consumable_cd
	detail.text = "%s\n%s\nSlot: %s%s" % [item.get("name",""), item.get("description",""), item.get("slot",""), extra]
	if use_btn:
		use_btn.disabled = str(item.get("slot", "")) != "consumable"

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

func _on_use() -> void:
	if selected_id == "":
		return
	AudioBus.play_ui()
	if GameState.use_consumable(selected_id):
		refresh()
