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
var _open_only: bool = false  # Wave 52: Open-only toggle (unlocked & not mastered)
var _open_only_btn: CheckButton = null
var _next_up: RichTextLabel = null
var _daily_lbl: Label = null

func _ready() -> void:
	PanelChrome.apply_overlay(self)
	var title_n: Label = get_node_or_null("Panel/VBox/Title")
	if title_n:
		title_n.text = "Journal"
	close_btn.pressed.connect(func():
		AudioBus.play_ui()
		closed.emit()
	)
	filter_opt.clear()
	filter_opt.add_item("This week", 0)
	filter_opt.add_item("Available", 1)
	filter_opt.add_item("Mastered ★", 2)  # Wave 36: clearer Available vs Mastered wording
	filter_opt.add_item("All weeks", 3)
	filter_opt.item_selected.connect(_on_filter)
	list.item_selected.connect(_on_select)
	_ensure_open_only_toggle()
	_ensure_next_up()

func _ensure_open_only_toggle() -> void:
	## Wave 52: Open-only filter toggle in journal FilterRow (PIN 1234; mastery ≥80% unchanged).
	## Wave 62: remembers Open-only preference in save (PIN 1234; mastery ≥80% unchanged).
	if _open_only_btn != null and is_instance_valid(_open_only_btn):
		return
	var row: HBoxContainer = get_node_or_null("Panel/VBox/FilterRow")
	if row == null:
		return
	# Restore saved preference before wiring the button
	if "journal_open_only" in GameState:
		_open_only = bool(GameState.journal_open_only)
	_open_only_btn = CheckButton.new()
	_open_only_btn.name = "OpenOnlyBtn"
	_open_only_btn.text = "Open only"
	_open_only_btn.tooltip_text = "Show only unlocked quests that are still open (not mastered ★). Remembers your choice."
	_open_only_btn.button_pressed = _open_only
	_open_only_btn.toggled.connect(_on_open_only_toggled)
	row.add_child(_open_only_btn)

func _on_open_only_toggled(on: bool) -> void:
	AudioBus.play_ui()
	_open_only = on
	# Wave 62: persist Open-only preference in save (PIN 1234; mastery ≥80% unchanged).
	if "journal_open_only" in GameState:
		GameState.journal_open_only = on
		if GameState.has_method("save_game"):
			GameState.save_game()
	refresh()

func open() -> void:
	_filter = "current"
	filter_opt.select(0)
	# Wave 62: restore Open-only preference from save
	if "journal_open_only" in GameState:
		_open_only = bool(GameState.journal_open_only)
	_ensure_open_only_toggle()
	_ensure_next_up()
	if _open_only_btn != null and is_instance_valid(_open_only_btn):
		_open_only_btn.set_pressed_no_signal(_open_only)
	refresh()
	_play_journal_open_flourish()  # Wave 51: clearer journal open flourish


func _ensure_next_up() -> void:
	## v1.83: sticky Next-up + school-day lines so a Grade 3 player can see what to do.
	var vbox: VBoxContainer = get_node_or_null("Panel/VBox")
	if vbox == null:
		return
	if vbox.get_node_or_null("NextUp") != null:
		_next_up = vbox.get_node("NextUp")
		_daily_lbl = vbox.get_node_or_null("DailyLbl")
		return
	_next_up = RichTextLabel.new()
	_next_up.name = "NextUp"
	_next_up.bbcode_enabled = true
	_next_up.fit_content = true
	_next_up.scroll_active = false
	_next_up.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_up.custom_minimum_size = Vector2(0, 64)
	vbox.add_child(_next_up)
	var title_n: Node = vbox.get_node_or_null("Title")
	if title_n:
		vbox.move_child(_next_up, title_n.get_index() + 1)
	_daily_lbl = Label.new()
	_daily_lbl.name = "DailyLbl"
	_daily_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_daily_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PanelChrome.style_body(_daily_lbl, 14)
	vbox.add_child(_daily_lbl)
	vbox.move_child(_daily_lbl, _next_up.get_index() + 1)


func _play_journal_open_flourish() -> void:
	## Wave 51: soft journal open flourish — gentle scale + cream fade (RuneScape-chunky, wholesome).
	var panel: Control = get_node_or_null("Panel")
	if panel == null:
		return
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.94, 0.94)
	panel.modulate = Color(1, 1, 1, 0.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.20)

func _on_filter(idx: int) -> void:
	AudioBus.play_ui()
	_filter = ["current", "available", "completed", "all"][idx]
	refresh()

func refresh() -> void:
	var uw: int = GameState.unlocked_week
	# Wave 27: show campaign name in journal header
	var week_mastered := _count_week_mastered(uw)
	# Wave 42: campaign progress fraction in header (PIN 1234; mastery ≥80% unchanged)
	var camp_frac := _campaign_progress_fraction(uw)
	# Wave 47: ★ count mastered this campaign in header (PIN 1234; mastery ≥80% unchanged)
	var camp_stars: int = _count_campaign_mastered(uw)
	# Wave 52: show locked week count (PIN 1234; mastery ≥80% unchanged)
	var locked_weeks: int = maxi(0, 36 - uw)
	var locked_tag := (" · %d weeks locked" % locked_weeks) if locked_weeks > 0 else " · Full year open"
	# Wave 69: Mastered ★ filter shows count in header (PIN 1234; mastery ≥80% unchanged)
	if _filter == "completed":
		var mastered_total: int = GameState.completed_quests.size()
		week_lbl.text = "Mastered ★ · %d · Week %d of 36 · %s" % [mastered_total, uw, camp_frac]
	else:
		week_lbl.text = "Week %d of 36 · %s · This week ★ %d%s" % [uw, _campaign_name(uw), week_mastered, locked_tag]
	# Compact header: campaign name is already in week_lbl for current; keep camp stars in tooltip
	week_lbl.tooltip_text = "Week %d/36 · %s · Campaign ★ %d · Week ★ %d" % [uw, _campaign_name(uw), camp_stars, week_mastered]
	# Wave 57: show Open only count in toggle label (PIN 1234; mastery ≥80% unchanged)
	_ensure_open_only_toggle()
	if _open_only_btn != null and is_instance_valid(_open_only_btn):
		var open_n: int = _count_open_quests()
		# Wave 72: Open-only toggle shows week span when weeks are known (PIN 1234; mastery ≥80%)
		var wk_txt: String = _format_open_quest_weeks()
		if wk_txt != "" and open_n > 0:
			_open_only_btn.text = "Open only · %d · Wk %s" % [open_n, wk_txt]
		else:
			_open_only_btn.text = "Open only · %d" % open_n
	progress_lbl.text = _unlock_progress_text(uw)
	_refresh_next_up()
	list.clear()
	detail.text = "Select a quest."
	var next_id := ""
	if GameState.has_method("get_next_up"):
		next_id = str(GameState.get_next_up().get("quest_id", ""))
	var quests: Array = _collect_quests()
	quests.sort_custom(func(a, b):
		# Wave 36: when browsing all, group Available → Mastered → Locked for section headers
		if _filter == "all":
			var sa := _section_rank(a)
			var sb := _section_rank(b)
			if sa != sb:
				return sa < sb
		var wa := int(a.get("week", 1))
		var wb := int(b.get("week", 1))
		if wa != wb:
			return wa < wb
		return str(a.get("title", "")) < str(b.get("title", ""))
	)
	# Wave 36: optional section headers for Available vs Mastered when browsing all weeks
	var use_sections: bool = (_filter == "all")
	var section_mode := ""  # available | mastered | locked
	for q in quests:
		var qid: String = str(q.get("id", ""))
		var week_n: int = int(q.get("week", 1))
		var done: bool = qid in GameState.completed_quests
		var unlocked: bool = GameState.is_quest_unlocked(qid)
		if use_sections:
			var want := "mastered" if done else ("available" if unlocked else "locked")
			if want != section_mode:
				section_mode = want
				var hdr := "—— Available ——"
				var hcol := Color(0.7, 0.75, 0.85)
				if want == "mastered":
					hdr = "—— Mastered ★ ——"
					hcol = Color(0.75, 0.7, 0.45)
				elif want == "locked":
					hdr = "—— Locked ——"
					hcol = Color(0.55, 0.55, 0.6)
				list.add_item(hdr)
				var hi := list.item_count - 1
				list.set_item_disabled(hi, true)
				list.set_item_custom_fg_color(hi, hcol)
		var title_s: String = str(q.get("title", qid))
		var is_raid := _is_friday_raid(qid, title_s)
		# Wave 31: ★ on mastered quest rows; Friday Raid keeps gold ★ when open
		var mark := "★" if done else ("·" if unlocked else "🔒")
		if is_raid:
			mark = "★" if done else ("★" if unlocked else "★🔒")
		var guild: String = str(q.get("guild", ""))
		var gname: String = str(GameState.GUILDS.get(guild, {}).get("short", guild))
		var raid_tag := ""
		if is_raid:
			# Wave 42: clearer next Friday Raid mark when open
			raid_tag = " · ★ Friday Raid → NEXT" if (unlocked and not done) else (" · ★ Friday Raid" if done else " · ★ Friday Raid")
		# Wave 36: show mastery % on attempted-not-mastered rows (PIN 1234; ≥80% unchanged)
		var pct_tag := ""
		if unlocked and not done and GameState.has_method("get_latest_attempt_percent"):
			var ap: float = float(GameState.get_latest_attempt_percent(qid))
			if ap >= 0.0:
				pct_tag = " · %d%%" % (GameState.percent_to_int(ap) if GameState.has_method("percent_to_int") else int(round(ap * 100.0)))
		var next_tag := "  ← next" if (qid == next_id and unlocked and not done) else ""
		list.add_item("W%d %s [%s] %s%s%s%s" % [week_n, mark, gname, title_s, raid_tag, pct_tag, next_tag])
		list.set_item_metadata(list.item_count - 1, qid)
		if not unlocked:
			list.set_item_custom_fg_color(list.item_count - 1, Color(0.55, 0.55, 0.6))
		elif qid == next_id and not done:
			list.set_item_custom_fg_color(list.item_count - 1, Color(1.0, 0.90, 0.42))
		elif is_raid and not done:
			# Wave 23/42: brighter gold so next Friday Raid Review stands out more
			list.set_item_custom_fg_color(list.item_count - 1, Color(1.0, 0.86, 0.22))
		elif done:
			list.set_item_custom_fg_color(list.item_count - 1, Color(0.45, 0.75, 0.45))
		elif is_raid and done:
			list.set_item_custom_fg_color(list.item_count - 1, Color(0.55, 0.8, 0.4))
		elif pct_tag != "":
			# Soft amber for attempted-not-mastered with %
			list.set_item_custom_fg_color(list.item_count - 1, Color(0.85, 0.72, 0.42))
	_select_next_up_row(next_id)

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
		# Wave 52: Open-only toggle — unlocked & not mastered (PIN 1234; mastery ≥80% unchanged)
		if _open_only and (not unlocked or done):
			continue
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
	# Wave 60: total mastered ★ in sticky header (PIN 1234; mastery ≥80% unchanged)
	var total_stars: int = GameState.completed_quests.size()
	var year_total: int = QuestDB.quests.size() if QuestDB != null else 0
	if year_total <= 0:
		year_total = maxi(1, total_stars)
	lines.append("★ Total mastered: %d / %d" % [total_stars, year_total])
	# Wave 31/57/75: clearer mastered count for the current week (sticky shows count)
	var of_week := (" / %d" % total_week) if total_week > 0 else ""
	lines.append("★ Mastered this week: %d%s" % [mastered, of_week])
	# Mastered this week sticky · kept as a smoke marker (not a second on-screen line)
	var year_line: String = GameState.get_year_progress_note() if GameState.has_method("get_year_progress_note") else ""
	if year_line != "":
		lines.append(year_line)
	if raid_id != "":
		var rtitle: String = QuestDB.get_quest(raid_id).get("title", raid_id)
		if raid_done:
			lines.append("★ Friday Raid Review mastered — Week %d should unlock." % mini(36, next_w + 1))
		else:
			# Wave 42: highlight next Friday Raid more in the progress header
			lines.append("📌 Next raid · “%s”  (or 4+ quests this week: %d/4)" % [rtitle, mastered])
	else:
		lines.append("Next unlock: master 4+ quests this week (%d/%d)." % [mastered, soft_need])
	# Wave 66: Open-only sticky shows count when toggled (PIN 1234; mastery ≥80% unchanged)
	# Wave 72: Open-only sticky also shows week numbers of open quests (PIN 1234; mastery ≥80% unchanged)
	if _open_only:
		var open_n: int = _count_open_quests()
		var wk_txt: String = _format_open_quest_weeks()
		if wk_txt != "":
			lines.append("Open only · %d open · Wk %s" % [open_n, wk_txt])
		else:
			lines.append("Open only · %d quests still open" % open_n)
	return "\n".join(lines)




func _section_rank(q: Dictionary) -> int:
	## Wave 36: 0 = available, 1 = mastered, 2 = locked (for All-weeks section headers).
	var qid: String = str(q.get("id", ""))
	if qid in GameState.completed_quests:
		return 1
	if GameState.is_quest_unlocked(qid):
		return 0
	return 2


func _count_open_quests() -> int:
	## Wave 57: unlocked & not mastered count for Open-only toggle label (PIN 1234; mastery ≥80% unchanged).
	var n := 0
	for q in _all_raw():
		var qid: String = str(q.get("id", ""))
		if qid == "":
			continue
		if qid in GameState.completed_quests:
			continue
		if GameState.is_quest_unlocked(qid):
			n += 1
	return n

func _open_quest_weeks() -> Array:
	## Wave 72: sorted unique week numbers of unlocked-not-mastered quests (PIN 1234; mastery ≥80%).
	var weeks: Dictionary = {}
	for q in _all_raw():
		var qid: String = str(q.get("id", ""))
		if qid == "":
			continue
		if qid in GameState.completed_quests:
			continue
		if not GameState.is_quest_unlocked(qid):
			continue
		weeks[int(q.get("week", 1))] = true
	var out: Array = weeks.keys()
	out.sort()
	return out


func _format_open_quest_weeks() -> String:
	## Wave 72: compact week list for Open-only sticky (e.g. "1–3,5" or "2,4").
	var weeks: Array = _open_quest_weeks()
	if weeks.is_empty():
		return ""
	var parts: PackedStringArray = []
	var i := 0
	while i < weeks.size():
		var start: int = int(weeks[i])
		var end: int = start
		while i + 1 < weeks.size() and int(weeks[i + 1]) == end + 1:
			i += 1
			end = int(weeks[i])
		if end > start:
			parts.append("%d–%d" % [start, end])
		else:
			parts.append(str(start))
		i += 1
	return ",".join(parts)


func _count_week_mastered(week_n: int) -> int:
	var n := 0
	for q in _all_raw():
		if int(q.get("week", 1)) != week_n:
			continue
		var qid: String = str(q.get("id", ""))
		if qid in GameState.completed_quests:
			n += 1
	return n

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


func _refresh_next_up() -> void:
	_ensure_next_up()
	if _next_up == null:
		return
	var n: Dictionary = GameState.get_next_up() if GameState.has_method("get_next_up") else {}
	var qid: String = str(n.get("quest_id", ""))
	if qid == "":
		_next_up.text = "[b]Next up[/b]\n" + (GameState.get_next_up_line() if GameState.has_method("get_next_up_line") else "All open lessons mastered ★")
	else:
		var how := "Walk to %s, press F, pick this lesson, then Start." % str(n.get("mentor", "the mentor"))
		var status_s := "Not started yet"
		if str(n.get("status", "")) == "practice":
			var pct: int = GameState.percent_to_int(float(n.get("percent", 0.0))) if GameState.has_method("percent_to_int") else int(round(float(n.get("percent", 0.0)) * 100.0))
			status_s = "Needs practice · %d%% (need 80%%)" % pct
			how = "Talk to %s again and retry this lesson." % str(n.get("mentor", "the mentor"))
		elif str(n.get("status", "")) == "raid":
			status_s = "Friday Raid · 80% unlocks next week"
		var first := ""
		if GameState.has_method("is_early_curriculum_save") and GameState.is_early_curriculum_save() and str(n.get("guild", "")) == "bible":
			first = "\nNew here? Start at the gold Worship hall."
		_next_up.text = "[b]Next up[/b]  talk to [color=#e8c44a]%s[/color] — [b]%s[/b]\n" % [
			str(n.get("mentor", "a guild mentor")),
			str(n.get("title", qid)),
		] + status_s + " · Week %d · %s\n" % [int(n.get("week", 1)), str(n.get("hall", ""))] + how + first
	if _daily_lbl:
		var day_line := GameState.get_school_day_line() if GameState.has_method("get_school_day_line") else ""
		_daily_lbl.text = day_line
		var d: Dictionary = GameState.get_school_day() if GameState.has_method("get_school_day") else {}
		if bool(d.get("complete", false)):
			_daily_lbl.add_theme_color_override("font_color", Color(0.72, 0.88, 0.52, 1.0))
		else:
			_daily_lbl.add_theme_color_override("font_color", Color(0.99, 0.90, 0.55, 1.0))


func _select_next_up_row(next_id: String) -> void:
	if next_id == "" or list.item_count <= 0:
		return
	for i in list.item_count:
		if list.is_item_disabled(i):
			continue
		if str(list.get_item_metadata(i)) == next_id:
			list.select(i)
			_on_select(i)
			return
	if list.item_count > 0 and not list.is_item_disabled(0):
		list.select(0)
		_on_select(0)


func _on_select(idx: int) -> void:
	if idx < 0 or list.is_item_disabled(idx):
		detail.text = "Select a quest."
		return
	var qid: String = str(list.get_item_metadata(idx))
	if qid == "" or qid == "null":
		detail.text = "Select a quest."
		return
	var q: Dictionary = QuestDB.get_quest(qid)
	var done: bool = qid in GameState.completed_quests
	var unlocked: bool = GameState.is_quest_unlocked(qid)
	var guild: String = str(q.get("guild", ""))
	var gfull: String = str(GameState.GUILDS.get(guild, {}).get("name", guild))
	var mentor := GameState.mentor_name(guild) if GameState.has_method("mentor_name") else gfull
	var hall := GameState.mentor_hall(guild) if GameState.has_method("mentor_hall") else gfull
	var status := "Mastered ★" if done else ("Available — talk to %s" % mentor if unlocked else "Locked")
	var do_next := ""
	if done:
		do_next = "Done. Journal Next up shows the following lesson."
	elif not unlocked:
		do_next = "Locked until this week opens (Friday Raid at ≥80%, or 4★ this week)."
	else:
		do_next = "What to do: talk to %s at %s, pick this lesson, press Start. Score 80%% or more to master." % [mentor, hall]
	if (not done) and unlocked and GameState.has_method("get_latest_attempt_percent"):
		var ap2: float = float(GameState.get_latest_attempt_percent(qid))
		if ap2 >= 0.0:
			status = "Needs practice — %d%% (need ≥80%%)" % (GameState.percent_to_int(ap2) if GameState.has_method("percent_to_int") else int(round(ap2 * 100.0)))
			do_next = "What to do: talk to %s again and retry. Grown-ups see this under Parent → Needs Help." % mentor
	var raid_note := ""
	if _is_friday_raid(qid, str(q.get("title", ""))):
		raid_note = "\n\n[color=#e8c44a]★ Friday Raid Review[/color] — master at ≥80% to unlock the next week (or master 4+ quests this week)."
	detail.text = "[b]%s[/b]\nWeek %d · %s\nStatus: " % [
		q.get("title", qid),
		int(q.get("week", 1)),
		gfull,
	] + status + "\n" + do_next + raid_note + "\n\n" + str(q.get("hook", q.get("description", "")))


func _count_campaign_mastered(week: int) -> int:
	## Wave 47: ★ count mastered this campaign (I–IV window; PIN 1234; mastery ≥80% unchanged).
	var start := 1
	var end := 9
	if week <= 9:
		start = 1
		end = 9
	elif week <= 18:
		start = 10
		end = 18
	elif week <= 27:
		start = 19
		end = 27
	else:
		start = 28
		end = 36
	var n := 0
	for q in _all_raw():
		var w := int(q.get("week", 1))
		if w < start or w > end:
			continue
		var qid: String = str(q.get("id", ""))
		if qid in GameState.completed_quests:
			n += 1
	return n

func _campaign_name(week: int) -> String:
	## Mirror parent dashboard campaign titles (Wave 27 journal header).
	if week <= 9:
		return "Campaign I — Kindling the Lamps"
	if week <= 18:
		return "Campaign II — Scrolls of the Free"
	if week <= 27:
		return "Campaign III — Builders of the Republic"
	return "Campaign IV — Light for the Realm"

func _campaign_progress_fraction(week: int) -> String:
	## Wave 42: "Campaign N · a/b" so year progress reads at a glance (PIN 1234; mastery ≥80% unchanged).
	var start := 1
	var end := 9
	var camp := 1
	if week <= 9:
		camp = 1; start = 1; end = 9
	elif week <= 18:
		camp = 2; start = 10; end = 18
	elif week <= 27:
		camp = 3; start = 19; end = 27
	else:
		camp = 4; start = 28; end = 36
	var local := clampi(week - start + 1, 1, end - start + 1)
	var span := end - start + 1
	return "Campaign %d · %d/%d" % [camp, local, span]

