extends Control

signal new_game_pressed(slot: int)
signal continue_pressed(slot: int)
signal clear_slot_pressed(slot: int)

@onready var subtitle: Label = $Panel/VBox/Subtitle
@onready var slots_box: VBoxContainer = $Panel/VBox/Slots
@onready var status_lbl: Label = $Panel/VBox/StatusLbl

var _slot_rows: Array = []

func _ready() -> void:
	PanelChrome.apply_overlay(self)
	subtitle.text = "Christian · Creationist · Grade 3 Homeschool RPG"
	_ensure_start_guide()
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
		PanelChrome.style_button(cont, true)
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
			info.text = "Slot %d — empty  ·  press Start" % (i + 1)
			cont.disabled = true
			cont.text = "Continue"
			neu.text = "Start"
			clr.disabled = true
		else:
			var name_s: String = str(summary.get("child_name", "Apprentice"))
			var lab: String = str(summary.get("slot_label", "")).strip_edges()
			var lab_s: String = ""
			if lab != "":
				lab_s = " (%s)" % lab
			info.text = "Slot %d — %s%s · Lv %d · Week %d" % [
				i + 1, name_s, lab_s, int(summary.get("level", 1)),
				int(summary.get("unlocked_week", 1))
			]
			cont.disabled = false
			cont.text = "Continue"
			neu.text = "New"
			clr.disabled = false
	_sync_rename_edits()
	if status_lbl:
		status_lbl.text = "Continue a save, or Start on an empty slot."

func _on_continue(slot: int) -> void:
	AudioBus.play_ui()
	continue_pressed.emit(slot)

func _on_new(slot: int) -> void:
	AudioBus.play_ui()
	new_game_pressed.emit(slot)

func _on_clear(slot: int) -> void:
	AudioBus.play_ui()
	clear_slot_pressed.emit(slot)

func _ensure_start_guide() -> void:
	var vbox: VBoxContainer = get_node_or_null("Panel/VBox")
	if vbox == null:
		return
	var title_n: Label = vbox.get_node_or_null("Title")
	if title_n:
		PanelChrome.style_title(title_n, 32)
	if subtitle:
		PanelChrome.style_muted(subtitle, 14)
	var blurb: Label = vbox.get_node_or_null("Blurb")
	if blurb:
		blurb.text = "Grown-ups: Parent dashboard is in the game (PIN 1234)."
		PanelChrome.style_muted(blurb, 13)
	if vbox.get_node_or_null("StartGuide") != null:
		return
	var guide := Label.new()
	guide.name = "StartGuide"
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.text = "How to start: Continue a save, or press Start on an empty slot."
	PanelChrome.style_body(guide, 15)
	vbox.add_child(guide)
	var slots_n: Node = vbox.get_node_or_null("Slots")
	if slots_n:
		vbox.move_child(guide, slots_n.get_index())
	if status_lbl:
		PanelChrome.style_muted(status_lbl, 13)


func _ensure_rename_row() -> void:
	if slots_box == null:
		return
	if slots_box.get_parent().has_node("RenameRows"):
		return
	var box := VBoxContainer.new()
	box.name = "RenameRows"
	var hint := Label.new()
	hint.text = "Optional nickname per slot, then Set. Helps tell siblings' saves apart."
	hint.visible = false
	box.add_child(hint)
	var toggle := Button.new()
	toggle.name = "NicknameToggle"
	toggle.text = "Nickname a save…"
	toggle.pressed.connect(func():
		hint.visible = not hint.visible
		for i in GameState.SLOT_COUNT:
			var r = box.get_node_or_null("RenameRow%d" % i)
			if r:
				r.visible = hint.visible
		toggle.text = "Hide nicknames" if hint.visible else "Nickname a save…"
	)
	box.add_child(toggle)
	for i in GameState.SLOT_COUNT:
		var row := HBoxContainer.new()
		row.name = "RenameRow%d" % i
		var lab := Label.new()
		lab.text = "Slot %d" % (i + 1)
		lab.custom_minimum_size = Vector2(52, 0)
		row.add_child(lab)
		var edit := LineEdit.new()
		edit.name = "LabelEdit"
		edit.placeholder_text = "Name…"
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(edit)
		var btn := Button.new()
		btn.text = "Set"
		btn.pressed.connect(_on_set_label_slot.bind(i))
		row.add_child(btn)
		row.visible = false
		box.add_child(row)
	slots_box.get_parent().add_child(box)
	slots_box.get_parent().move_child(box, slots_box.get_index() + 1)

func _sync_rename_edits() -> void:
	var box = slots_box.get_parent().get_node_or_null("RenameRows") if slots_box else null
	if box == null:
		return
	for i in GameState.SLOT_COUNT:
		var row = box.get_node_or_null("RenameRow%d" % i)
		if row == null:
			continue
		var edit: LineEdit = row.get_node_or_null("LabelEdit")
		if edit == null:
			continue
		var sum: Dictionary = GameState.slot_summary(i)
		if sum.get("empty", true):
			edit.text = ""
			edit.editable = false
		else:
			edit.editable = true
			edit.text = str(sum.get("slot_label", ""))

func _on_set_label_slot(slot: int) -> void:
	var box = slots_box.get_parent().get_node_or_null("RenameRows")
	if box == null:
		return
	var row = box.get_node_or_null("RenameRow%d" % slot)
	if row == null:
		return
	var edit: LineEdit = row.get_node("LabelEdit")
	if not GameState.has_save(slot):
		if status_lbl:
			status_lbl.text = "Create a save in slot %d before naming it." % (slot + 1)
		return
	if GameState.set_slot_label_on_slot(slot, edit.text):
		AudioBus.play_ui()
		refresh_slots()
		if status_lbl:
			status_lbl.text = "Label saved on slot %d (PIN settings unchanged)." % (slot + 1)
	else:
		if status_lbl:
			status_lbl.text = "Could not save that label."
