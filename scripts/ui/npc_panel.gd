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

const GREETINGS := {
	"math": [
		"Welcome, apprentice. Numbers are tools the High King gave for careful work — shall we build with them today?",
		"Steady hands and clear place value keep every bridge strong. Ready for a lesson?",
		"Come count with me. Small facts practiced well become great help.",
	],
	"la": [
		"A kind word well written can light a whole hall. Shall we shape sentences together?",
		"Ink and patience — that is how stories grow. Pick a lesson when you are ready.",
		"Listen for clear nouns and honest verbs. The page is waiting for you.",
	],
	"science": [
		"Look closely at what was made — leaves, light, and living things all point to the Maker.",
		"Stewards notice, measure, and care. Shall we study creation together?",
		"The world is orderly and good. Let us learn to tend it with wonder.",
	],
	"history": [
		"Remember the roads that brought us here — courage, hardship, and hope in many homes.",
		"Chronicles keep true names and true days. Ready to walk a page of the past?",
		"Texas and the wider land have stories worth telling carefully. Choose a lesson.",
	],
	"bible": [
		"The Word is a lamp for our feet. Shall we read and remember together?",
		"Quiet hearts hear clearly. Come learn virtue and Scripture with gladness.",
		"Worship is wonder with obedience. Pick a lesson when you are ready.",
	],
}


func _ready() -> void:
	PanelChrome.apply_overlay(self)
	close_btn.pressed.connect(func(): AudioBus.play_ui(); closed.emit())
	start_btn.pressed.connect(_on_start)
	if start_btn:
		PanelChrome.style_button(start_btn, true)
	list.item_selected.connect(_on_select)
	list.item_activated.connect(func(i): _on_select(i); _on_start())

func _greeting_for(npc: Node) -> String:
	var guild := str(npc.guild)
	var lines: Array = GREETINGS.get(guild, ["Peace to you. Choose a lesson-quest when you are ready."])
	var idx: int = abs(hash(str(npc.npc_id) + str(GameState.unlocked_week))) % lines.size()
	var line: String = str(lines[idx])
	return "%s\nMastery (≥80%%) unlocks the next lesson." % line

func open(npc: Node) -> void:
	current_npc = npc
	title_lbl.text = "%s — %s" % [npc.npc_name, npc.title]
	desc_lbl.text = _greeting_for(npc)
	list.clear()
	selected_quest = ""
	for qid in npc.quest_ids:
		var q := QuestDB.get_quest(qid)
		var week_n := int(q.get("week", 1))
		var status := ""
		if qid in GameState.completed_quests:
			status = " ★"  # Wave 33: mastered star on NPC quest list
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
