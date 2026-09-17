extends Control

signal closed

@onready var title_lbl: Label = $Panel/VBox/Title
@onready var subject_lbl: Label = $Panel/VBox/Subject
@onready var dialogue_lbl: RichTextLabel = $Panel/VBox/Dialogue
@onready var prompt_lbl: Label = $Panel/VBox/Prompt
@onready var options: VBoxContainer = $Panel/VBox/Options
@onready var fill_edit: LineEdit = $Panel/VBox/FillEdit
@onready var submit_btn: Button = $Panel/VBox/SubmitBtn
@onready var hint_lbl: Label = $Panel/VBox/Hint
@onready var progress_lbl: Label = $Panel/VBox/Progress
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var quest: Dictionary = {}
var phase: String = "dialogue" # dialogue | challenge | result
var dialogue_i: int = 0
var challenge_i: int = 0
var correct_count: int = 0
var selected_option: String = ""

func _ready() -> void:
	close_btn.pressed.connect(func(): AudioBus.play_ui(); closed.emit())
	submit_btn.pressed.connect(_on_submit)
	fill_edit.text_submitted.connect(func(_t): _on_submit())

func open(quest_id: String) -> void:
	quest = QuestDB.get_quest(quest_id)
	phase = "dialogue"
	dialogue_i = 0
	challenge_i = 0
	correct_count = 0
	title_lbl.text = quest.get("title", "")
	subject_lbl.text = quest.get("subject_label", "")
	_show_dialogue()

func _clear_options() -> void:
	for c in options.get_children():
		c.queue_free()
	selected_option = ""

func _show_dialogue() -> void:
	fill_edit.visible = false
	_clear_options()
	var lines: Array = quest.get("dialogue", [])
	if dialogue_i < lines.size():
		var line = lines[dialogue_i]
		dialogue_lbl.text = "[b]%s[/b]\n%s" % [line.get("speaker",""), line.get("text","")]
		prompt_lbl.text = quest.get("hook", "") if dialogue_i == 0 else ""
		hint_lbl.text = ""
		progress_lbl.text = "Story %d / %d" % [dialogue_i + 1, lines.size()]
		submit_btn.text = "Continue"
	else:
		phase = "challenge"
		_show_challenge()

func _show_challenge() -> void:
	var challenges: Array = quest.get("challenges", [])
	if challenge_i >= challenges.size():
		_finish()
		return
	var ch = challenges[challenge_i]
	dialogue_lbl.text = ""
	prompt_lbl.text = ch.get("prompt", "")
	hint_lbl.text = ch.get("hint", "")
	progress_lbl.text = "Question %d / %d · Correct so far: %d" % [challenge_i + 1, challenges.size(), correct_count]
	_clear_options()
	var ctype: String = ch.get("type", "multiple-choice")
	if ctype == "fill-blank":
		fill_edit.visible = true
		fill_edit.text = ""
		fill_edit.grab_focus()
		submit_btn.text = "Check"
	else:
		fill_edit.visible = false
		for opt in ch.get("options", []):
			var btn := Button.new()
			btn.text = str(opt)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.pressed.connect(_make_select(str(opt), btn))
			options.add_child(btn)
		submit_btn.text = "Check Answer"

func _make_select(opt: String, btn: Button) -> Callable:
	return func():
		selected_option = opt
		for c in options.get_children():
			c.modulate = Color.WHITE
		btn.modulate = Color(0.7, 0.95, 0.7)

func _on_submit() -> void:
	AudioBus.play_ui()
	if phase == "dialogue":
		dialogue_i += 1
		_show_dialogue()
		return
	if phase == "result":
		closed.emit()
		return
	# challenge
	var challenges: Array = quest.get("challenges", [])
	var ch = challenges[challenge_i]
	var response := ""
	var ctype: String = ch.get("type", "multiple-choice")
	if ctype == "fill-blank":
		response = fill_edit.text
	else:
		response = selected_option
		if response == "":
			hint_lbl.text = "Please select an answer."
			return
	var ok := GameState.check_answer(ch, response)
	if ok:
		correct_count += 1
		hint_lbl.text = "Correct!"
		hint_lbl.modulate = Color(0.4, 0.9, 0.4)
	else:
		hint_lbl.text = "Not quite. The answer was: %s" % str(ch.get("answer",""))
		hint_lbl.modulate = Color(0.95, 0.5, 0.4)
	challenge_i += 1
	await get_tree().create_timer(0.85).timeout
	hint_lbl.modulate = Color.WHITE
	_show_challenge()

func _finish() -> void:
	phase = "result"
	var total: int = quest.get("challenges", []).size()
	var attempt: Dictionary = GameState.record_quest_attempt(str(quest.get("id", "")), correct_count, total)
	fill_edit.visible = false
	_clear_options()
	var pct: int = int(float(attempt.get("percent", 0)) * 100)
	if attempt.get("mastered", false):
		dialogue_lbl.text = "[b]Mastered![/b]\nYou scored %d / %d (%d%%).\nGear and XP awarded. Well done, apprentice!" % [correct_count, total, pct]
	else:
		dialogue_lbl.text = "[b]Needs practice[/b]\nYou scored %d / %d (%d%%).\nNeed ≥80%% for mastery. Talk to the NPC again to retry — parents can see this under Needs Help." % [correct_count, total, pct]
	prompt_lbl.text = ""
	hint_lbl.text = ""
	progress_lbl.text = ""
	submit_btn.text = "Close"
