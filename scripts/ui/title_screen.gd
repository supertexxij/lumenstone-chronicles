extends Control

signal new_game_pressed(slot: int)
signal continue_pressed(slot: int)
signal clear_slot_pressed(slot: int)

@onready var subtitle: Label = $Panel/VBox/Subtitle
@onready var slots_box: VBoxContainer = $Panel/VBox/Slots
@onready var status_lbl: Label = $Panel/VBox/StatusLbl

var _slot_rows: Array = []

func _ready() -> void:
	subtitle.text = "Christian · Creationist · Grade 3 Homeschool RPG"
	_ensure_slot_ui()
	_ensure_rename_row()
	refresh_slots()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and is_node_ready():
		refresh_slots()

func _ensure_slot_ui() -> void:
	if slots_box == null:
		return
	if not _slot_rows.is_empty():
		return
	for i in GameState.SLOT_COUNT:
		var row := HBoxContainer.new()
		row.name = "SlotRow%d" % i
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var info := Label.new()
		info.name = "Info"
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.text = "Slot %d" % (i + 1)
		row.add_child(info)
		var cont := Button.new()
		cont.name = "Continue"
		cont.text = "Continue"
		cont.pressed.connect(_on_continue.bind(i))
		row.add_child(cont)
		var neu := Button.new()
		neu.name = "New"
		neu.text = "New"
		neu.pressed.connect(_on_new.bind(i))
		row.add_child(neu)
		var clr := Button.new()
		clr.name = "Clear"
		clr.text = "Clear"
		clr.pressed.connect(_on_clear.bind(i))
		row.add_child(clr)
		slots_box.add_child(row)
		_slot_rows.append({"row": row, "info": info, "continue": cont, "new": neu, "clear": clr})

func refresh_slots() -> void:
	_ensure_slot_ui()
	_ensure_rename_row()
	for i in _slot_rows.size():
		var widgets: Dictionary = _slot_rows[i]
		var summary: Dictionary = GameState.slot_summary(i)
		var info: Label = widgets["info"]
		var cont: Button = widgets["continue"]
		var clr: Button = widgets["clear"]
		if summary.get("empty", true):
			info.text = "Slot %d — empty" % (i + 1)
			cont.disabled = true
			clr.disabled = true
		else:
			var name_s: String = str(summary.get("child_name", "Apprentice"))
			var lab: String = str(summary.get("slot_label", "")).strip_edges()
			var lab_s: String = (" “%s”" % lab) if lab != "" else ""
			info.text = "Slot %d — %s%s · Lv %d · Wk %d · Combat %d" % [
				i + 1, name_s, lab_s, int(summary.get("level", 1)),
				int(summary.get("unlocked_week", 1)), int(summary.get("combat_level", 1))
			]
			cont.disabled = false
			clr.disabled = false
	if status_lbl:
		status_lbl.text = "Pick a save slot (3 slots). Older single saves load in Slot 1."

func _on_continue(slot: int) -> void:
	AudioBus.play_ui()
	continue_pressed.emit(slot)

func _on_new(slot: int) -> void:
	AudioBus.play_ui()
	new_game_pressed.emit(slot)

func _on_clear(slot: int) -> void:
	AudioBus.play_ui()
	clear_slot_pressed.emit(slot)

func _ensure_rename_row() -> void:
	if slots_box == null:
		return
	if slots_box.get_parent().has_node("RenameRow"):
		return
	var row := HBoxContainer.new()
	row.name = "RenameRow"
	var edit := LineEdit.new()
	edit.name = "LabelEdit"
	edit.placeholder_text = "Optional label for selected slot"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(edit)
	var btn := Button.new()
	btn.text = "Set label"
	btn.pressed.connect(_on_set_label)
	row.add_child(btn)
	slots_box.get_parent().add_child(row)
	slots_box.get_parent().move_child(row, slots_box.get_index() + 1)

func _on_set_label() -> void:
	var row = slots_box.get_parent().get_node_or_null("RenameRow")
	if row == null:
		return
	var edit: LineEdit = row.get_node("LabelEdit")
	var slot := GameState.active_slot
	if not GameState.has_save(slot):
		for i in GameState.SLOT_COUNT:
			if GameState.has_save(i):
				slot = i
				break
	if not GameState.has_save(slot):
		if status_lbl:
			status_lbl.text = "Create or continue a save before setting a label."
		return
	if GameState.set_slot_label_on_slot(slot, edit.text):
		AudioBus.play_ui()
		refresh_slots()
		if status_lbl:
			status_lbl.text = "Label saved on slot %d (PIN settings unchanged)." % (slot + 1)
	else:
		if status_lbl:
			status_lbl.text = "Could not save that label."
