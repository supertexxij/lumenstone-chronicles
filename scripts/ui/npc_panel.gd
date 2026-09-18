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
		start_btn.text = "Start this lesson"
	list.item_selected.connect(_on_select)
	list.item_activated.connect(func(i): _on_select(i); _on_start())

func _greeting_for(npc: Node) -> String:
	var guild := str(npc.guild)
	var lines: Array = GREETINGS.get(guild, ["Peace to you. Choose a lesson-quest when you are ready."])
	var idx: int = abs(hash(str(npc.npc_id) + str(GameState.unlocked_week))) % lines.size()
	var line: String = str(lines[idx])
	var next: Dictionary = GameState.get_next_up() if GameState.has_method("get_next_up") else {}
	var next_guild := str(next.get("guild", ""))
	var next_title := str(next.get("title", ""))
	if next_title != "" and next_guild == guild:
		return "%s\n\nYour next lesson is “%s”. Select it, then press Start this lesson. Score 80%% or more to master." % [line, next_title]
	if next_title != "":
		return "%s\n\nJournal (J) says your next lesson is with %s. I still have Week %d practice if you want it. Mastery is 80%%." % [
			line, str(next.get("mentor", "another mentor")), GameState.unlocked_week
		]
	return "%s\nMastery (≥80%%) unlocks the next lesson." % line

func open(npc: Node) -> void:
	current_npc = npc
	title_lbl.text = "%s — %s" % [npc.npc_name, npc.title]
	desc_lbl.text = _greeting_for(npc)
	list.clear()
	selected_quest = ""
	var next_id := ""
	if GameState.has_method("get_next_up"):
		next_id = str(GameState.get_next_up().get("quest_id", ""))
	var rows: Array = []
	for qid in npc.quest_ids:
		var q := QuestDB.get_quest(qid)
		rows.append({"id": qid, "q": q})
	rows.sort_custom(func(a, b):
		var aid: String = str(a.get("id", ""))
		var bid: String = str(b.get("id", ""))
		var a_next: int = 0 if aid == next_id else 1
		var b_next: int = 0 if bid == next_id else 1
		if a_next != b_next:
			return a_next < b_next
		var a_done: int = 1 if aid in GameState.completed_quests else 0
		var b_done: int = 1 if bid in GameState.completed_quests else 0
		if a_done != b_done:
			return a_done < b_done
		var a_lock: int = 0 if GameState.is_quest_unlocked(aid) else 1
		var b_lock: int = 0 if GameState.is_quest_unlocked(bid) else 1
		if a_lock != b_lock:
			return a_lock < b_lock
		var aq: Dictionary = a.get("q", {})
		var bq: Dictionary = b.get("q", {})
		return int(aq.get("week", 1)) < int(bq.get("week", 1))
	)
	var auto_idx := -1
	var first_open := -1
	for row in rows:
		var qid: String = str(row.get("id", ""))
		var q: Dictionary = row.get("q", {})
		var week_n := int(q.get("week", 1))
		var unlocked: bool = GameState.is_quest_unlocked(qid)
		var done: bool = qid in GameState.completed_quests
		var status := ""
		if done:
			status = " ★"  # Wave 33: mastered star on NPC quest list
		elif not unlocked:
			status = " (Week %d locked)" % week_n
		elif qid == next_id:
			status = "  ← next"
		elif GameState.has_method("get_latest_attempt_percent"):
			var ap: float = float(GameState.get_latest_attempt_percent(qid))
			if ap >= 0.0:
				var pct: int = GameState.percent_to_int(ap) if GameState.has_method("percent_to_int") else int(round(ap * 100.0))
				status = "  · %d%% try again" % pct
		var prefix := "W%d · " % week_n
		list.add_item("%s%s%s" % [prefix, q.get("title", qid), status])
		list.set_item_metadata(list.item_count - 1, qid)
		var idx: int = list.item_count - 1
		if not unlocked:
			list.set_item_disabled(idx, true)
		else:
			if qid == next_id:
				auto_idx = idx
				list.set_item_custom_fg_color(idx, Color(1.0, 0.90, 0.42))
			elif first_open < 0 and not done:
				first_open = idx
	var pick: int = auto_idx if auto_idx >= 0 else first_open
	if pick >= 0:
		list.select(pick)
		_on_select(pick)
	if start_btn:
		start_btn.text = "Start this lesson"


func _on_select(idx: int) -> void:
	selected_quest = str(list.get_item_metadata(idx))

func _on_start() -> void:
	if selected_quest != "" and GameState.is_quest_unlocked(selected_quest):
		quest_chosen.emit(selected_quest)
