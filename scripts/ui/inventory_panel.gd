extends Control

signal closed

@onready var list: ItemList = $Panel/VBox/ItemList
@onready var detail: Label = $Panel/VBox/Detail
@onready var equip_btn: Button = $Panel/VBox/HBox/EquipBtn
@onready var unequip_btn: Button = $Panel/VBox/HBox/UnequipBtn
@onready var close_btn: Button = $Panel/VBox/HBox/CloseBtn
@onready var use_btn: Button = $Panel/VBox/HBox/UseBtn
@onready var loadout: VBoxContainer = $Panel/VBox/Loadout
@onready var loadout_title: Label = $Panel/VBox/Loadout/WornTitle
@onready var loadout_slots: VBoxContainer = $Panel/VBox/Loadout/SlotRows
@onready var loadout_soft: Label = $Panel/VBox/Loadout/SoftArmor

var selected_id: String = ""
var _cd_label_was: float = -1.0

const SLOT_LABELS := {
	"head": "Head",
	"cape": "Cape",
	"accessory": "Accessory",
	"weapon": "Weapon",
	"belt": "Belt",
}

## Wave 37: worn-row tags read clearly in the loadout list.
const SLOT_TAGS := {
	"head": "[Head]",
	"cape": "[Cape]",
	"accessory": "[Acc]",
	"weapon": "[Wpn]",
	"belt": "[Belt]",
}

## Wave 43: bag sort order by type (weapon → armor → belt → food → other).
const SLOT_SORT := {
	"weapon": 0,
	"head": 1,
	"cape": 2,
	"accessory": 3,
	"belt": 4,
	"consumable": 5,
}

var _icon_head: Texture2D
var _icon_cape: Texture2D
var _icon_gear: Texture2D
var _icon_food: Texture2D

func _ready() -> void:
	_ensure_slot_icons()
	_ensure_loadout_nodes()
	list.fixed_icon_size = Vector2(16, 16)
	if use_btn == null:
		use_btn = Button.new()
		use_btn.name = "UseBtn"
		use_btn.text = "Use"
		use_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		$Panel/VBox/HBox.add_child(use_btn)
		$Panel/VBox/HBox.move_child(use_btn, unequip_btn.get_index() + 1)
	# Room for defense breakdown + icon rows
	var panel: PanelContainer = $Panel
	if panel:
		panel.offset_top = -310.0
		panel.offset_bottom = 310.0
		panel.offset_left = -290.0
		panel.offset_right = 290.0
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
	# Wave 43: sort bag by type (weapon/armor/belt/food), then name
	var bag_ids: Array = []
	for id in GameState.unlocked_items:
		bag_ids.append(id)
	bag_ids.sort_custom(func(a, b):
		var ia: Dictionary = ItemDB.get_item(str(a))
		var ib: Dictionary = ItemDB.get_item(str(b))
		var sa: int = int(SLOT_SORT.get(str(ia.get("slot", "")), 9))
		var sb: int = int(SLOT_SORT.get(str(ib.get("slot", "")), 9))
		if sa != sb:
			return sa < sb
		return str(ia.get("name", a)).to_lower() < str(ib.get("name", b)).to_lower()
	)
	for id in bag_ids:
		var item := ItemDB.get_item(id)
		var equipped_mark := ""
		var worn_slot := ""
		for slot in GameState.equipped:
			if GameState.equipped[slot] == id:
				worn_slot = str(slot)
				# Wave 37: clearer equipped mark names the slot
				equipped_mark = "  %s on" % str(SLOT_TAGS.get(slot, "[E]"))
		var stack_mark := ""
		var heal_mark := ""
		var slot_s: String = str(item.get("slot", ""))
		if slot_s == "consumable":
			var heal_n: int = int(item.get("heal", 0))
			if heal_n > 0:
				heal_mark = " · +%d HP" % heal_n  # Wave 32: pantry heal preview
			if GameState.has_method("pantry_count"):
				# Wave 48: clearer food stack counts
				stack_mark = "  · stack %d/%d" % [GameState.pantry_count(id), GameState.pantry_max(id)]
		var def_mark := ""
		var def_n: int = int(item.get("defense", 0))
		if def_n > 0:
			def_mark = "  [Def +%d]" % def_n  # Wave 32: clearer armor Def on bag rows
		# Wave 37: gray out unequippable gear with reason (combat level / food)
		var lock_mark := ""
		var unequippable := false
		var req_lv: int = int(item.get("combat_level_req", 0))
		if slot_s == "consumable":
			unequippable = true
			lock_mark = "  (Use — not gear)"
		elif req_lv > 0 and GameState.combat_level < req_lv:
			unequippable = true
			lock_mark = "  (need Combat Lv %d)" % req_lv
		list.add_item("%s%s%s%s%s%s" % [item.get("name", id), def_mark, heal_mark, equipped_mark, stack_mark, lock_mark])
		var idx: int = list.item_count - 1
		list.set_item_metadata(idx, id)
		list.set_item_icon(idx, _icon_for_item(item))
		if unequippable and worn_slot == "":
			list.set_item_custom_fg_color(idx, Color(0.55, 0.55, 0.58, 0.95))
		elif worn_slot != "":
			list.set_item_custom_fg_color(idx, Color(0.85, 0.92, 0.55, 1.0))
	# Wave 43: show nearby locked gear with unlock-quest hint (PIN 1234; mastery ≥80% unchanged)
	_append_locked_gear_hints()
	_update_loadout()
	detail.text = "Select gear to see armor & defense, or food to Use. Locked rows show unlock quests."

func _slot_label(slot: String) -> String:
	return str(SLOT_LABELS.get(slot, slot.capitalize()))

func _ensure_loadout_nodes() -> void:
	## Worn-gear rows with armor icons (Wave 18) — create if scene is older.
	if loadout == null:
		return
	if loadout_title == null:
		loadout_title = loadout.get_node_or_null("WornTitle")
	if loadout_title == null:
		loadout_title = Label.new()
		loadout_title.name = "WornTitle"
		loadout.add_child(loadout_title)
		loadout.move_child(loadout_title, 0)
	if loadout_slots == null:
		loadout_slots = loadout.get_node_or_null("SlotRows")
	if loadout_slots == null:
		loadout_slots = VBoxContainer.new()
		loadout_slots.name = "SlotRows"
		loadout_slots.add_theme_constant_override("separation", 2)
		loadout.add_child(loadout_slots)
	if loadout_soft == null:
		loadout_soft = loadout.get_node_or_null("SoftArmor")
	if loadout_soft == null:
		loadout_soft = Label.new()
		loadout_soft.name = "SoftArmor"
		loadout_soft.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		loadout.add_child(loadout_soft)

func _update_loadout() -> void:
	_ensure_slot_icons()
	_ensure_loadout_nodes()
	if loadout_title:
		loadout_title.text = "— Worn gear (slot labels) —"  # Wave 37: clearer equipped slots
	var by_slot: Dictionary = {}
	if GameState.has_method("get_defense_breakdown"):
		by_slot = GameState.get_defense_breakdown().get("by_slot", {})
	# Clear prior icon rows (deferred free from last refresh)
	if loadout_slots:
		# Free immediately so icon rows do not briefly double after refresh.
		var prior_rows: Array = loadout_slots.get_children()
		for child in prior_rows:
			loadout_slots.remove_child(child)
			child.free()
	for slot in ["head", "cape", "accessory", "weapon", "belt"]:
		var id = GameState.equipped.get(slot)
		var name := "—"
		var def_bit := ""
		var icon: Texture2D = _icon_gear
		if id != null:
			var item := ItemDB.get_item(str(id))
			name = str(item.get("name", str(id)))
			icon = _icon_for_item(item)
			var d: int = int(by_slot.get(slot, 0))
			if d <= 0:
				d = int(item.get("defense", 0))
			if d > 0:
				def_bit = "  [Def +%d]" % d
			elif slot in ["head", "cape"]:
				def_bit = "  [Def +0]"
		else:
			# Empty armor slots still show the slot icon so Head/Cape read clearly.
			if slot == "head":
				icon = _icon_head
			elif slot == "cape":
				icon = _icon_cape
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var tex := TextureRect.new()
		tex.texture = icon
		tex.custom_minimum_size = Vector2(16, 16)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var lbl := Label.new()
		# Wave 37: chunky slot tag so Head/Cape/Weapon read at a glance
		var tag: String = str(SLOT_TAGS.get(slot, _slot_label(slot)))
		lbl.text = "%s  %s%s" % [tag, name, def_bit]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tex)
		row.add_child(lbl)
		if loadout_slots:
			loadout_slots.add_child(row)
	var soft_parts: PackedStringArray = []
	if GameState.has_method("get_defense_breakdown"):
		var bd: Dictionary = GameState.get_defense_breakdown()
		soft_parts.append("— Soft armor —")
		soft_parts.append("From combat level: +%d" % int(bd.get("level", 0)))
		soft_parts.append("From worn gear: +%d" % int(bd.get("gear", 0)))
		var total_d: int = int(bd.get("total", 0))
		var raw_d: int = int(bd.get("raw", total_d))
		var cap_d: int = int(bd.get("cap", 7))
		if raw_d > total_d:
			soft_parts.append("Total defense: %d of soft max %d (extra gear counted; hits still tick)" % [total_d, cap_d])
		elif total_d >= cap_d:
			soft_parts.append("Total defense: %d — at soft max %d (late cloaks & crowns can fill this; hits still tick)" % [total_d, cap_d])
		else:
			soft_parts.append("Total defense: %d / soft max %d — mid & late cloaks raise this; hits still tick" % [total_d, cap_d])
	elif GameState.has_method("get_defense"):
		soft_parts.append("Defense: %d" % GameState.get_defense())
	if loadout_soft:
		loadout_soft.text = "\n".join(soft_parts)

func _refresh_detail_only() -> void:
	if selected_id == "":
		return
	var item := ItemDB.get_item(selected_id)
	var extra := ""
	var slot: String = str(item.get("slot", ""))
	var req: int = int(item.get("combat_level_req", 0))
	if req > 0:
		if GameState.combat_level < req:
			# Wave 37: gray-out reason mirrored in detail
			extra = "\nUnequippable yet — need Combat Lv %d (you are %d)." % [req, GameState.combat_level]
		else:
			extra = "\nCombat Lv req: %d — ready to equip." % req
	var uqid: String = str(item.get("unlock_quest_id", ""))
	if uqid != "":
		var qtitle: String = _unlock_quest_title(uqid)
		if selected_id not in GameState.unlocked_items:
			extra += "\n🔒 Unlock via quest: %s" % qtitle
		else:
			extra += "\nFrom quest: %s" % qtitle
	if slot == "weapon":
		extra += "\nDamage %s · Accuracy %s" % [item.get("damage", "?"), item.get("accuracy", "?")]
	var def_n: int = int(item.get("defense", 0))
	if def_n > 0:
		extra += "\nArmor: Defense +%d (soft — foes poke you for less; soft max applies)" % def_n
	elif slot in ["head", "cape"]:
		extra += "\nArmor slot: no defense bonus (Travel Cape / plain hats are soft)"
	if slot == "consumable":
		extra += "\nHeal preview: +%d HP when used (Use)." % int(item.get("heal", 0))
		if GameState.has_method("pantry_count"):
			extra += "\nPantry %d / %d" % [GameState.pantry_count(selected_id), GameState.pantry_max(selected_id)]
			if GameState.consumable_cd > 0.05:
				extra += "\nCooldown %.1fs" % GameState.consumable_cd
			else:
				extra += "\nReady"
	var slot_txt := _slot_label(slot) if SLOT_LABELS.has(slot) else slot
	detail.text = "%s\n%s\nSlot: %s%s" % [item.get("name", ""), item.get("description", ""), slot_txt, extra]

func _on_select(idx: int) -> void:
	var meta: String = str(list.get_item_metadata(idx))
	if meta.begins_with("locked:"):
		selected_id = meta.substr(7)
	else:
		selected_id = meta
	_cd_label_was = -1.0
	_refresh_detail_only()
	if use_btn:
		var is_food: bool = str(ItemDB.get_item(selected_id).get("slot", "")) == "consumable"
		var empty: bool = is_food and GameState.has_method("pantry_count") and int(GameState.pantry_count(selected_id)) <= 0
		use_btn.disabled = (not is_food) or GameState.consumable_cd > 0.05 or empty
	if equip_btn:
		var it_sel := ItemDB.get_item(selected_id)
		var slot: String = str(it_sel.get("slot", ""))
		var req_sel: int = int(it_sel.get("combat_level_req", 0))
		var under: bool = req_sel > 0 and GameState.combat_level < req_sel
		var not_owned: bool = selected_id not in GameState.unlocked_items
		equip_btn.disabled = slot == "" or slot == "consumable" or under or not_owned
	if unequip_btn:
		var slot2: String = str(ItemDB.get_item(selected_id).get("slot", ""))
		var worn: bool = slot2 != "" and slot2 != "consumable" and str(GameState.equipped.get(slot2, "")) == selected_id
		unequip_btn.disabled = not worn

func _on_equip() -> void:
	if selected_id != "":
		AudioBus.play_ui()
		GameState.equip_item(selected_id)
		refresh()

func _on_unequip() -> void:
	if selected_id == "":
		return
	var item := ItemDB.get_item(selected_id)
	var slot: String = str(item.get("slot", ""))
	if slot == "" or slot == "consumable":
		return
	# v1.17 bug fix: only unequip when this item is the one worn in that slot
	if str(GameState.equipped.get(slot, "")) != selected_id:
		GameState.toast.emit("That item is not equipped — pick the [E] row first.")
		return
	AudioBus.play_ui()
	GameState.unequip_slot(slot)
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

func _ensure_slot_icons() -> void:
	## Tiny plain armor-slot icons so Head/Cape read clearly in the bag and loadout.
	if _icon_head != null:
		return
	_icon_head = _make_slot_icon(Color(0.72, 0.78, 0.88), "head")
	_icon_cape = _make_slot_icon(Color(0.78, 0.45, 0.42), "cape")
	_icon_gear = _make_slot_icon(Color(0.70, 0.62, 0.48), "gear")
	_icon_food = _make_slot_icon(Color(0.55, 0.72, 0.48), "food")


func _icon_for_item(item: Dictionary) -> Texture2D:
	_ensure_slot_icons()
	var slot: String = str(item.get("slot", ""))
	match slot:
		"head":
			return _icon_head
		"cape":
			return _icon_cape
		"consumable":
			return _icon_food
		_:
			return _icon_gear


func _make_slot_icon(base: Color, kind: String) -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Soft plate background
	for y in range(1, 15):
		for x in range(1, 15):
			img.set_pixel(x, y, Color(base.r * 0.35, base.g * 0.35, base.b * 0.35, 0.85))
	match kind:
		"head":
			# Round helm dome
			for y in range(3, 10):
				for x in range(4, 12):
					var dx := float(x) - 7.5
					var dy := float(y) - 6.0
					if dx * dx + dy * dy <= 16.0:
						img.set_pixel(x, y, base)
			for x in range(5, 11):
				img.set_pixel(x, 10, base.darkened(0.15))
				img.set_pixel(x, 11, base.darkened(0.25))
		"cape":
			# Draped cape trapezoid
			for y in range(3, 14):
				var half := 2 + int((y - 3) * 0.35)
				for x in range(8 - half, 8 + half):
					if x >= 1 and x <= 14:
						img.set_pixel(x, y, base if y < 12 else base.darkened(0.2))
			for x in range(6, 10):
				img.set_pixel(x, 2, base.lightened(0.15))
		"food":
			for y in range(5, 12):
				for x in range(4, 12):
					img.set_pixel(x, y, base)
			for x in range(5, 11):
				img.set_pixel(x, 4, base.lightened(0.2))
		_:
			# Simple gear square / buckle
			for y in range(4, 12):
				for x in range(4, 12):
					img.set_pixel(x, y, base)
			for y in range(6, 10):
				for x in range(6, 10):
					img.set_pixel(x, y, base.darkened(0.35))
	return ImageTexture.create_from_image(img)

func _unlock_quest_title(qid: String) -> String:
	## Wave 43: plain quest title for locked-gear unlock hints.
	if qid == "":
		return "(quest)"
	var q: Dictionary = QuestDB.get_quest(qid)
	var title: String = str(q.get("title", ""))
	if title == "":
		return qid
	return title


func _append_locked_gear_hints() -> void:
	## Show a short list of locked (not-yet-unlocked) gear with unlock-quest hints.
	var locked: Array = []
	for it in ItemDB.all_items():
		if typeof(it) != TYPE_DICTIONARY:
			continue
		var iid: String = str(it.get("id", ""))
		if iid == "" or iid in GameState.unlocked_items:
			continue
		if bool(it.get("starter", false)):
			continue
		var slot: String = str(it.get("slot", ""))
		if slot == "" or slot == "consumable":
			continue
		var uqid: String = str(it.get("unlock_quest_id", ""))
		if uqid == "":
			continue
		# Prefer gear from near the current unlocked week (avoid dumping the whole catalog)
		var q: Dictionary = QuestDB.get_quest(uqid)
		var qw: int = int(q.get("week", 99))
		if qw > int(GameState.unlocked_week) + 1:
			continue
		locked.append({"id": iid, "item": it, "week": qw, "uqid": uqid})
	locked.sort_custom(func(a, b):
		if int(a["week"]) != int(b["week"]):
			return int(a["week"]) < int(b["week"])
		return str(a["item"].get("name", "")) < str(b["item"].get("name", ""))
	)
	var shown: int = 0
	for row in locked:
		if shown >= 8:
			break
		var item: Dictionary = row["item"]
		var iid: String = str(row["id"])
		var qtitle: String = _unlock_quest_title(str(row["uqid"]))
		list.add_item("🔒 %s  (unlock: %s)" % [item.get("name", iid), qtitle])
		var idx: int = list.item_count - 1
		list.set_item_metadata(idx, "locked:" + iid)
		list.set_item_icon(idx, _icon_for_item(item))
		list.set_item_custom_fg_color(idx, Color(0.58, 0.56, 0.52, 0.9))
		shown += 1

