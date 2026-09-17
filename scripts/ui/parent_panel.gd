extends Control

signal closed

@onready var pin_edit: LineEdit = $Panel/VBox/PinEdit
@onready var unlock_btn: Button = $Panel/VBox/UnlockBtn
@onready var close_btn: Button = $Panel/VBox/CloseBtn
@onready var content: VBoxContainer = $Panel/VBox/Content
@onready var summary: RichTextLabel = $Panel/VBox/Content/Summary
@onready var help_list: ItemList = $Panel/VBox/Content/HelpList

func _ready() -> void:
	content.visible = false
	unlock_btn.pressed.connect(_try_pin)
	pin_edit.text_submitted.connect(func(_t): _try_pin())
	close_btn.pressed.connect(func(): closed.emit())

func open() -> void:
	pin_edit.text = ""
	content.visible = false
	pin_edit.visible = true
	unlock_btn.visible = true
	pin_edit.grab_focus()

func _try_pin() -> void:
	if not GameState.verify_pin(pin_edit.text.strip_edges()):
		summary.text = "Incorrect PIN."
		content.visible = true
		return
	content.visible = true
	pin_edit.visible = false
	unlock_btn.visible = false
	_refresh()

func _refresh() -> void:
	var lines: String = "[b]Parent Dashboard[/b]\nChild: %s\nXP: %d · Level: %d · Combat Lv: %d\nCampaign week unlocked: %d / 36\nQuests mastered: %d / %d\n\n[b]Lumens[/b]\n" % [
		GameState.child_name, GameState.xp, GameState.level, GameState.combat_level,
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
