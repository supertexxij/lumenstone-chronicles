extends Control

signal closed

@onready var pin_edit: LineEdit = $Panel/VBox/PinEdit
@onready var unlock_btn: Button = $Panel/VBox/UnlockBtn
@onready var close_btn: Button = $Panel/VBox/CloseBtn
@onready var content: VBoxContainer = $Panel/VBox/Content
@onready var summary: RichTextLabel = $Panel/VBox/Content/Summary
@onready var help_list: ItemList = $Panel/VBox/Content/HelpList
@onready var new_pin_edit: LineEdit = $Panel/VBox/Content/NewPinEdit
@onready var confirm_pin_edit: LineEdit = $Panel/VBox/Content/ConfirmPinEdit
@onready var change_pin_btn: Button = $Panel/VBox/Content/ChangePinBtn
@onready var pin_status: Label = $Panel/VBox/Content/PinStatus

var _reset_edit: LineEdit
var _reset_btn: Button
var _reset_armed: bool = false
var _hint_lbl: Label

func _ready() -> void:
	content.visible = false
	unlock_btn.pressed.connect(_try_pin)
	pin_edit.text_submitted.connect(func(_t): _try_pin())
	close_btn.pressed.connect(func(): closed.emit())
	if change_pin_btn:
		change_pin_btn.pressed.connect(_change_pin)
	_ensure_recovery_ui()

func open() -> void:
	pin_edit.text = ""
	content.visible = false
	pin_edit.visible = true
	unlock_btn.visible = true
	if new_pin_edit:
		new_pin_edit.text = ""
	if confirm_pin_edit:
		confirm_pin_edit.text = ""
	if pin_status:
		pin_status.text = "Default PIN is 1234 until you change it."
	_reset_armed = false
	if _reset_edit:
		_reset_edit.text = ""
	if _hint_lbl:
		_hint_lbl.visible = true
	if _reset_edit:
		_reset_edit.visible = true
	if _reset_btn:
		_reset_btn.visible = true
		_reset_btn.text = "Reset PIN"
	pin_edit.grab_focus()

func _try_pin() -> void:
	if not GameState.verify_pin(pin_edit.text.strip_edges()):
		summary.text = "Incorrect PIN."
		content.visible = true
		return
	content.visible = true
	pin_edit.visible = false
	unlock_btn.visible = false
	if _hint_lbl:
		_hint_lbl.visible = false
	if _reset_edit:
		_reset_edit.visible = false
	if _reset_btn:
		_reset_btn.visible = false
	_refresh()

func _change_pin() -> void:
	var a: String = new_pin_edit.text.strip_edges() if new_pin_edit else ""
	var b: String = confirm_pin_edit.text.strip_edges() if confirm_pin_edit else ""
	if a != b:
		pin_status.text = "PINs do not match."
		return
	if not GameState.set_parent_pin(a):
		pin_status.text = "Use 4–8 digits only."
		return
	pin_status.text = "PIN updated. Remember it for next time."
	new_pin_edit.text = ""
	confirm_pin_edit.text = ""
	AudioBus.play_ui()

func _refresh() -> void:
	var lines: String = "[b]Parent Dashboard[/b]\nChild: %s\nSave slot: %d\nXP: %d · Level: %d · Combat Lv: %d\nCampaign week unlocked: %d / 36\nQuests mastered: %d / %d\n\n[b]Lumens[/b]\n" % [
		GameState.child_name, GameState.active_slot + 1,
		GameState.xp, GameState.level, GameState.combat_level,
		GameState.unlocked_week,
		GameState.completed_quests.size(), QuestDB.quests.size()
	]
	for g in ["math","la","science","history","bible"]:
		lines += "%s (%s): %d\n" % [GameState.GUILDS[g]["name"], GameState.GUILDS[g]["lumen"], GameState.lumens.get(g, 0)]
	lines += "\n[b]Skills / quests by week[/b]\n"
	for w in range(1, 37):
		var titles: Array = []
		for q in QuestDB.quests:
			if int(q.get("week", 1)) != w:
				continue
			var mark := "✓" if str(q["id"]) in GameState.completed_quests else "·"
			titles.append("%s %s" % [mark, q.get("title", q["id"])])
		lines += "Week %d: %s\n" % [w, ", ".join(titles)]
	summary.text = lines
	help_list.clear()
	var help: Array = GameState.needs_help_quests()
	if help.is_empty():
		help_list.add_item("No needs-help items — great work!")
	else:
		for h in help:
			help_list.add_item("%s — %d/%d (%d%%)" % [h["title"], h["correct"], h["total"], int(h["percent"] * 100)])

func _ensure_recovery_ui() -> void:
	var vbox: VBoxContainer = $Panel/VBox
	if vbox.get_node_or_null("ResetHint") != null:
		_hint_lbl = vbox.get_node("ResetHint")
		_reset_edit = vbox.get_node("ResetEdit")
		_reset_btn = vbox.get_node("ResetBtn")
		return
	_hint_lbl = Label.new()
	_hint_lbl.name = "ResetHint"
	_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_lbl.text = "Forgot PIN? Type RESET below, press Reset PIN, then type RESET again to confirm. Restores default 1234. Save slots stay."
	vbox.add_child(_hint_lbl)
	vbox.move_child(_hint_lbl, unlock_btn.get_index() + 1)
	_reset_edit = LineEdit.new()
	_reset_edit.name = "ResetEdit"
	_reset_edit.placeholder_text = "Type RESET"
	vbox.add_child(_reset_edit)
	vbox.move_child(_reset_edit, _hint_lbl.get_index() + 1)
	_reset_btn = Button.new()
	_reset_btn.name = "ResetBtn"
	_reset_btn.text = "Reset PIN"
	_reset_btn.pressed.connect(_try_pin_reset)
	vbox.add_child(_reset_btn)
	vbox.move_child(_reset_btn, _reset_edit.get_index() + 1)

func _try_pin_reset() -> void:
	var typed: String = _reset_edit.text.strip_edges().to_upper() if _reset_edit else ""
	if typed != "RESET":
		summary.text = "Type RESET exactly to recover the parent PIN."
		content.visible = true
		_reset_armed = false
		return
	if not _reset_armed:
		_reset_armed = true
		summary.text = "Confirm: type RESET again and press Reset PIN once more."
		content.visible = true
		if _reset_btn:
			_reset_btn.text = "Confirm RESET"
		if _reset_edit:
			_reset_edit.text = ""
		return
	GameState.reset_parent_pin_to_default()
	_reset_armed = false
	summary.text = "Parent PIN restored to 1234. Save slots were not changed."
	content.visible = true
	if _reset_btn:
		_reset_btn.text = "Reset PIN"
	if _reset_edit:
		_reset_edit.text = ""
	AudioBus.play_ui()
