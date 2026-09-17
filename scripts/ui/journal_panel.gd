extends Control
## In-game quest journal: available / completed by week + unlock progress.

signal closed

@onready var week_lbl: Label = $Panel/VBox/WeekLbl
@onready var progress_lbl: Label = $Panel/VBox/ProgressLbl
@onready var list: ItemList = $Panel/VBox/QuestList
@onready var detail: RichTextLabel = $Panel/VBox/Detail
@onready var filter_opt: OptionButton = $Panel/VBox/FilterRow/FilterOpt
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var _filter: String = "current"  # current | available | completed | all

func _ready() -> void:
	close_btn.pressed.connect(func():
		AudioBus.play_ui()
		closed.emit()
	)
	filter_opt.clear()
	filter_opt.add_item("This week", 0)
	filter_opt.add_item("Available", 1)
	filter_opt.add_item("Completed", 2)
	filter_opt.add_item("All weeks", 3)
	filter_opt.item_selected.connect(_on_filter)
	list.item_selected.connect(_on_select)

func open() -> void:
	_filter = "current"
	filter_opt.select(0)
	refresh()

func _on_filter(idx: int) -> void:
	AudioBus.play_ui()
	_filter = ["current", "available", "completed", "all"][idx]
	refresh()

func refresh() -> void:
	var uw: int = GameState.unlocked_week
	week_lbl.text = "Campaign Week %d unlocked (of 36)" % uw
	progress_lbl.text = _unlock_progress_text(uw)
	list.clear()
	detail.text = "Select a quest for details."
	var quests: Array = _collect_quests()
	quests.sort_custom(func(a, b):
		var wa := int(a.get("week", 1))
		var wb := int(b.get("week", 1))
		if wa != wb:
			return wa < wb
		return str(a.get("title", "")) < str(b.get("title", ""))
	)
	for q in quests:
		var qid: String = str(q.get("id", ""))
		var week_n: int = int(q.get("week", 1))
		var done: bool = qid in GameState.completed_quests
		var unlocked: bool = GameState.is_quest_unlocked(qid)
		var title_s: String = str(q.get("title", qid))
		var is_raid := _is_friday_raid(qid, title_s)
		var mark := "✓" if done else ("·" if unlocked else "🔒")
		if is_raid:
			mark = "★✓" if done else ("★" if unlocked else "★🔒")
		var guild: String = str(q.get("guild", ""))
		var gname: String = str(GameState.GUILDS.get(guild, {}).get("short", guild))
		var raid_tag := " · Friday Raid" if is_raid else ""
		list.add_item("W%d %s [%s] %s%s" % [week_n, mark, gname, title_s, raid_tag])
		list.set_item_metadata(list.item_count - 1, qid)
		if not unlocked:
			list.set_item_custom_fg_color(list.item_count - 1, Color(0.55, 0.55, 0.6))
		elif is_raid and not done:
			# Wave 23: gold highlight so Friday Raid Review stands out in the journal
			list.set_item_custom_fg_color(list.item_count - 1, Color(0.92, 0.78, 0.28))
		elif done:
			list.set_item_custom_fg_color(list.item_count - 1, Color(0.45, 0.75, 0.45))
		elif is_raid and done:
			list.set_item_custom_fg_color(list.item_count - 1, Color(0.55, 0.8, 0.4))

func _collect_quests() -> Array:
	var out: Array = []
	var uw: int = GameState.unlocked_week
	var all: Array = QuestDB.all_quests()
	for q in all:
		if typeof(q) != TYPE_DICTIONARY:
			continue
		var qid: String = str(q.get("id", ""))
		var week_n: int = int(q.get("week", 1))
		var done: bool = qid in GameState.completed_quests
		var unlocked: bool = week_n <= uw
		match _filter:
			"current":
				if week_n != uw:
					continue
			"available":
				if not unlocked or done:
					continue
			"completed":
				if not done:
					continue
			"all":
				pass
		out.append(q)
	return out

func _unlock_progress_text(uw: int) -> String:
	if uw >= 36:
		return "Full year unlocked — Festival of Lumens awaits!"
	var next_w: int = uw
	# Count mastered in current week toward soft unlock / raid gate
	var mastered := 0
	var total_week := 0
	var raid_done := false
	var raid_id := ""
	# Gather week quests
	var week_quests: Array = []
	for q in _all_raw():
		if int(q.get("week", 1)) == next_w:
			week_quests.append(q)
			total_week += 1
			var qid: String = str(q.get("id", ""))
			if qid in GameState.completed_quests:
				mastered += 1
			var title: String = str(q.get("title", "")).to_lower()
			var idl: String = qid.to_lower()
			if "raid" in idl or "feast" in idl or "raid" in title:
				raid_id = qid
				if qid in GameState.completed_quests:
					raid_done = true
	var soft_need: int = 4
	var lines: PackedStringArray = []
	lines.append("Week %d progress: %d mastered" % [next_w, mastered] + (" of ~%d" % total_week if total_week > 0 else ""))
	if raid_id != "":
		var rtitle: String = QuestDB.get_quest(raid_id).get("title", raid_id)
		if raid_done:
			lines.append("★ Friday Raid Review mastered — Week %d should unlock." % mini(36, next_w + 1))
		else:
			lines.append("★ Next unlock: master Friday Raid “%s” (≥80%%), or master 4+ quests this week (%d/4)." % [rtitle, mastered])
	else:
		lines.append("Next unlock: master 4+ quests this week (%d/%d)." % [mastered, soft_need])
	var year_line: String = GameState.get_year_progress_note() if GameState.has_method("get_year_progress_note") else ""
	if year_line != "":
		lines.insert(0, year_line)
	return "\n".join(lines)


func _is_friday_raid(qid: String, title: String = "") -> bool:
	## Wave 23: flag Friday Raid Review / Feast / Supreme for clearer journal marks.
	var idl := qid.to_lower()
	var tl := title.to_lower()
	if "raid" in idl or "feast" in idl or "supreme" in idl:
		return true
	if "raid" in tl or "feast" in tl:
		return true
	return false

func _all_raw() -> Array:
	return QuestDB.all_quests()

func _on_select(idx: int) -> void:
	var qid: String = str(list.get_item_metadata(idx))
	var q: Dictionary = QuestDB.get_quest(qid)
	var done: bool = qid in GameState.completed_quests
	var unlocked: bool = GameState.is_quest_unlocked(qid)
	var status := "Completed" if done else ("Available — talk to the guild NPC" if unlocked else "Locked")
	var guild: String = str(q.get("guild", ""))
	var gfull: String = str(GameState.GUILDS.get(guild, {}).get("name", guild))
	var raid_note := ""
	if _is_friday_raid(qid, str(q.get("title", ""))):
		raid_note = "\n\n[color=#e8c44a]★ Friday Raid Review[/color] — master at ≥80% to unlock the next week (or master 4+ quests this week)."
	detail.text = "[b]%s[/b]\nWeek %d · %s\n%s\n\n%s\n\nStatus: %s%s" % [
		q.get("title", qid),
		int(q.get("week", 1)),
		q.get("subject_label", gfull),
		gfull,
		q.get("hook", q.get("description", "")),
		status,
		raid_note,
	]
