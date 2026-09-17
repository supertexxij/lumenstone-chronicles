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
var _cd_label_was: float = -1.0

const SLOT_LABELS := {
	"head": "Head (armor)",
	"cape": "Cape (armor)",
	"accessory": "Accessory",
	"weapon": "Weapon",
	"belt": "Belt",
}

func _ready() -> void:
	if use_btn == null:
		use_btn = Button.new()
		use_btn.name = "UseBtn"
		use_btn.text = "Use"
		use_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		$Panel/VBox/HBox.add_child(use_btn)
		$Panel/VBox/HBox.move_child(use_btn, unequip_btn.get_index() + 1)
	# Room for defense breakdown lines
	var panel: PanelContainer = $Panel
	if panel:
		panel.offset_top = -290.0
		panel.offset_bottom = 290.0
		panel.offset_left = -280.0
		panel.offset_right = 280.0
	close_btn.pressed.connect(func(): AudioBus.play_ui(); closed.emit())
	list.item_selected.connect(_on_select)
	equip_btn.pressed.connect(_on_equip)
	unequip_btn.pressed.connect(_on_unequip)
	if use_btn:
		use_btn.pressed.connect(_on_use)

func _process(_delta: float) -> void:
	## Live cooldown ticks while inventory is open (Bread / Water / Trail Rations).
	if not visible:
		return
	if selected_id == "":
		return
	var item := ItemDB.get_item(selected_id)
	if str(item.get("slot", "")) != "consumable":
		return
	var cd: float = float(GameState.consumable_cd)
	# Refresh detail ~10×/sec while cooling down, and once when it clears
	var bucket: float = floorf(cd * 10.0)
	if bucket != _cd_label_was or (cd <= 0.05 and _cd_label_was > 0.0):
		_cd_label_was = bucket
		_refresh_detail_only()
		if use_btn:
			use_btn.disabled = cd > 0.05 or int(GameState.pantry_count(selected_id)) <= 0

func refresh() -> void:
	list.clear()
	selected_id = ""
	_cd_label_was = -1.0
	for id in GameState.unlocked_items:
		var item := ItemDB.get_item(id)
		var equipped_mark := ""
		for slot in GameState.equipped:
			if GameState.equipped[slot] == id:
				equipped_mark = " [E]"
		var stack_mark := ""
		if str(item.get("slot", "")) == "consumable" and GameState.has_method("pantry_count"):
			stack_mark = " ×%d/%d" % [GameState.pantry_count(id), GameState.pantry_max(id)]
		var def_mark := ""
		var def_n: int = int(item.get("defense", 0))
		if def_n > 0:
			def_mark = " · Def +%d" % def_n
		list.add_item("%s%s%s%s" % [item.get("name", id), def_mark, equipped_mark, stack_mark])
		list.set_item_metadata(list.item_count - 1, id)
	_update_loadout()
	detail.text = "Select gear to see armor & defense, or food to Use."

func _slot_label(slot: String) -> String:
	return str(SLOT_LABELS.get(slot, slot.capitalize()))

func _update_loadout() -> void:
	var parts: PackedStringArray = []
	parts.append("— Worn gear —")
	var by_slot: Dictionary = {}
	if GameState.has_method("get_defense_breakdown"):
		by_slot = GameState.get_defense_breakdown().get("by_slot", {})
	for slot in ["head", "cape", "accessory", "weapon", "belt"]:
		var id = GameState.equipped.get(slot)
		var name := "—"
		var def_bit := ""
		if id != null:
			name = ItemDB.get_item(str(id)).get("name", str(id))
			var d: int = int(by_slot.get(slot, 0))
			if d <= 0:
				d = int(ItemDB.get_item(str(id)).get("defense", 0))
			if d > 0:
				def_bit = " · Def +%d" % d
			elif slot in ["head", "cape"]:
				def_bit = " · Def +0"
		parts.append("%s: %s%s" % [_slot_label(slot), name, def_bit])
	if GameState.has_method("get_defense_breakdown"):
		var bd: Dictionary = GameState.get_defense_breakdown()
		parts.append("— Soft armor —")
		parts.append("From combat level: +%d" % int(bd.get("level", 0)))
		parts.append("From worn gear: +%d" % int(bd.get("gear", 0)))
		parts.append("Total defense: %d (soft hits hurt less)" % int(bd.get("total", 0)))
	elif GameState.has_method("get_defense"):
		parts.append("Defense: %d" % GameState.get_defense())
	loadout.text = "\n".join(parts)

func _refresh_detail_only() -> void:
	if selected_id == "":
		return
	var item := ItemDB.get_item(selected_id)
	var extra := ""
	var slot: String = str(item.get("slot", ""))
	var req: int = int(item.get("combat_level_req", 0))
	if req > 0:
		extra = "\nCombat Lv req: %d" % req
	if slot == "weapon":
		extra += "\nDamage %s · Accuracy %s" % [item.get("damage", "?"), item.get("accuracy", "?")]
	var def_n: int = int(item.get("defense", 0))
	if def_n > 0:
		extra += "\nArmor: Defense +%d (soft — foes poke you for less)" % def_n
	elif slot in ["head", "cape"]:
		extra += "\nArmor slot: no defense bonus (Travel Cape / plain hats are soft)"
	if slot == "consumable":
		extra += "\nHeals %d HP (Use)." % int(item.get("heal", 0))
		if GameState.has_method("pantry_count"):
			extra += "\nPantry %d / %d" % [GameState.pantry_count(selected_id), GameState.pantry_max(selected_id)]
			if GameState.consumable_cd > 0.05:
				extra += "\nCooldown %.1fs" % GameState.consumable_cd
			else:
				extra += "\nReady"
	var slot_txt := _slot_label(slot) if SLOT_LABELS.has(slot) else slot
	detail.text = "%s\n%s\nSlot: %s%s" % [item.get("name", ""), item.get("description", ""), slot_txt, extra]

func _on_select(idx: int) -> void:
	selected_id = str(list.get_item_metadata(idx))
	_cd_label_was = -1.0
	_refresh_detail_only()
	if use_btn:
		var is_food: bool = str(ItemDB.get_item(selected_id).get("slot", "")) == "consumable"
		var empty: bool = is_food and GameState.has_method("pantry_count") and int(GameState.pantry_count(selected_id)) <= 0
		use_btn.disabled = (not is_food) or GameState.consumable_cd > 0.05 or empty
	if equip_btn:
		var slot: String = str(ItemDB.get_item(selected_id).get("slot", ""))
		equip_btn.disabled = slot == "" or slot == "consumable"
	if unequip_btn:
		var slot2: String = str(ItemDB.get_item(selected_id).get("slot", ""))
		unequip_btn.disabled = slot2 == "" or slot2 == "consumable"

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
		var keep := selected_id
		refresh()
		# Reselect after refresh so cooldown ticks keep updating
		for i in list.item_count:
			if str(list.get_item_metadata(i)) == keep:
				list.select(i)
				_on_select(i)
				break
