extends Control

signal closed
signal quest_chosen(quest_id: String)

@onready var title_lbl: Label = $Panel/VBox/Title
@onready var desc_lbl: Label = $Panel/VBox/Desc
@onready var list: ItemList = $Panel/VBox/QuestList
@onready var start_btn: Button = $Panel/VBox/HBox/StartBtn
@onready var close_btn: Button = $Panel/VBox/HBox/CloseBtn

var current_npc: Node = null
var selected_quest: String = ""

func _ready() -> void:
	close_btn.pressed.connect(func(): closed.emit())
	start_btn.pressed.connect(_on_start)
	list.item_selected.connect(_on_select)
	list.item_activated.connect(func(i): _on_select(i); _on_start())

func open(npc: Node) -> void:
	current_npc = npc
	title_lbl.text = "%s — %s" % [npc.npc_name, npc.title]
	desc_lbl.text = "Choose a lesson-quest. Mastery (≥80%%) unlocks gear and XP. Weeks unlock after each Friday Raid Review."
	list.clear()
	selected_quest = ""
	for qid in npc.quest_ids:
		var q := QuestDB.get_quest(qid)
		var week_n := int(q.get("week", 1))
		var status := ""
		if qid in GameState.completed_quests:
			status = " ✓"
		elif not GameState.is_quest_unlocked(qid):
			status = " (Week %d locked)" % week_n
		var prefix := "W%d · " % week_n
		list.add_item("%s%s%s" % [prefix, q.get("title", qid), status])
		list.set_item_metadata(list.item_count - 1, qid)
		if not GameState.is_quest_unlocked(qid):
			list.set_item_disabled(list.item_count - 1, true)


func _on_select(idx: int) -> void:
	selected_quest = str(list.get_item_metadata(idx))

func _on_start() -> void:
	if selected_quest != "" and GameState.is_quest_unlocked(selected_quest):
		quest_chosen.emit(selected_quest)
