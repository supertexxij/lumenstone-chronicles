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
	var uw: int = GameState.unlocked_week
	var camp: String = _campaign_name(uw)
	var next_gate: String = _next_week_gate(uw)
	var mastered: int = GameState.completed_quests.size()
	var total_q: int = QuestDB.quests.size()
	var bar: String = _week_progress_bar(uw, 36)
	var lines: String = "[b]Parent Dashboard[/b]\nChild: %s\nSave slot: %d\nXP: %d · Level: %d · Combat Lv: %d\n\n[b]Week unlock progress[/b]\nWeek [b]%d[/b] / 36 unlocked · %s\n%s\nNext gate: %s\nQuests mastered: %d / %d\n\n[b]Lumens[/b]\n" % [
		GameState.child_name, GameState.active_slot + 1,
		GameState.xp, GameState.level, GameState.combat_level,
		uw, camp, bar, next_gate,
		mastered, total_q
	]
	for g in ["math","la","science","history","bible"]:
		lines += "%s (%s): %d\n" % [GameState.GUILDS[g]["name"], GameState.GUILDS[g]["lumen"], GameState.lumens.get(g, 0)]
	lines += "\n[b]Skills / quests by week[/b]  (✓ mastered · open · [locked])\n"
	for w in range(1, 37):
		var titles: Array = []
		var done_n := 0
		var total_n := 0
		for q in QuestDB.quests:
			if int(q.get("week", 1)) != w:
				continue
			total_n += 1
			var qid: String = str(q["id"])
			var mark := "✓" if qid in GameState.completed_quests else ("·" if w <= uw else "–")
			if qid in GameState.completed_quests:
				done_n += 1
			titles.append("%s %s" % [mark, q.get("title", qid)])
		var lock: String = "" if w <= uw else " [locked]"
		var head: String = "Week %d (%d/%d)%s" % [w, done_n, total_n, lock]
		if w == uw:
			head = "[b]%s ← current[/b]" % head
		lines += "%s: %s\n" % [head, ", ".join(titles)]
	summary.text = lines
	help_list.clear()
	var help: Array = GameState.needs_help_quests()
	if help.is_empty():
		help_list.add_item("No needs-help items — great work!")
	else:
		# Sort by lowest percent first so weakest skills rise to the top
		help.sort_custom(func(a, b): return float(a.get("percent", 0)) < float(b.get("percent", 0)))
		for h in help:
			var q: Dictionary = QuestDB.get_quest(str(h.get("quest_id", "")))
			var week_n: int = int(q.get("week", 0))
			var guild: String = str(q.get("guild", ""))
			var guild_short: String = str(GameState.GUILDS.get(guild, {}).get("short", guild))
			var pct: int = int(float(h.get("percent", 0)) * 100)
			var line: String = "Wk %d · %s · %s — %d/%d (%d%%) — needs practice" % [
				week_n, guild_short, h.get("title", h.get("quest_id", "?")),
				int(h.get("correct", 0)), int(h.get("total", 0)), pct
			]
			help_list.add_item(line)

func _campaign_name(week: int) -> String:
	if week <= 9:
		return "Campaign I — Kindling the Lamps"
	if week <= 18:
		return "Campaign II — Scrolls of the Free"
	if week <= 27:
		return "Campaign III — Builders of the Republic"
	return "Campaign IV — Light for the Realm"

func _week_progress_bar(cur: int, mx: int) -> String:
	var filled: int = clampi(int(round(float(cur) / float(mx) * 20.0)), 0, 20)
	var empty: int = 20 - filled
	return "[%s%s] %d%%" % ["█".repeat(filled), "·".repeat(empty), int(round(float(cur) / float(mx) * 100.0))]

func _next_week_gate(uw: int) -> String:
	if uw >= 36:
		return "Year complete — Festival of Lumens!"
	var raid_gate := {
		1: "w1-raid-review", 2: "w2-raid-review", 3: "w3-raid-review", 4: "w4-raid-review",
		5: "w5-raid-review", 6: "w6-raid-review", 7: "w7-raid-review", 8: "w8-raid-review",
		9: "w9-raid-feast",
		10: "w10-raid-review", 11: "w11-raid-review", 12: "w12-raid-review", 13: "w13-raid-review",
		14: "w14-raid-review", 15: "w15-raid-review", 16: "w16-raid-review", 17: "w17-raid-review",
		18: "w18-raid-feast",
		19: "w19-raid-review", 20: "w20-raid-review", 21: "w21-raid-review", 22: "w22-raid-review",
		23: "w23-raid-review", 24: "w24-raid-review", 25: "w25-raid-review", 26: "w26-raid-review",
		27: "w27-raid-feast",
		28: "w28-raid-review", 29: "w29-raid-review", 30: "w30-raid-review", 31: "w31-raid-review",
		32: "w32-raid-review", 33: "w33-raid-review", 34: "w34-raid-review",
		35: "w35-raid-supreme", 36: "w36-raid-feast",
	}
	var rid: String = str(raid_gate.get(uw, ""))
	if rid == "":
		return "Master more Week %d quests (or the Friday raid)." % uw
	var q: Dictionary = QuestDB.get_quest(rid)
	var title: String = str(q.get("title", rid))
	if rid in GameState.completed_quests:
		return "Week %d raid done — week unlock should advance soon." % uw
	return "Master Week %d Friday raid: %s (or 4+ quests that week)." % [uw, title]

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
