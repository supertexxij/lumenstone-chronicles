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
var _pin_error: Label
var _pin_change_toggle: Button
var _pin_change_open: bool = false
var _campaign_tabs: TabContainer
var _campaign_week_roots: Array = []  # VBoxContainer per campaign tab
var _expanded_weeks: Dictionary = {}  # week int -> bool
var _lock_blurb: Label
var _hero_row: HBoxContainer
var _hero_year: Label
var _hero_mastery: Label
var _hero_help: Label
var _copy_row: HBoxContainer
var _copy_edit: LineEdit
var _copy_btn: Button
var _next_lbl: Label
var _lumen_lbl: Label
var _meta_lbl: Label

const CAMPAIGN_RANGES := [
	{"title": "I · Kindling (1–9)", "lo": 1, "hi": 9},
	{"title": "II · Scrolls (10–18)", "lo": 10, "hi": 18},
	{"title": "III · Builders (19–27)", "lo": 19, "hi": 27},
	{"title": "IV · Light (28–36)", "lo": 28, "hi": 36},
]

func _ready() -> void:
	PanelChrome.apply_overlay(self)
	var title_n: Label = get_node_or_null("Panel/VBox/Title")
	if title_n:
		title_n.text = "Parent Dashboard"
		PanelChrome.style_title(title_n, 24)
	_ensure_content_scroll()
	content.visible = false
	unlock_btn.pressed.connect(_try_pin)
	pin_edit.text_submitted.connect(func(_t): _try_pin())
	close_btn.pressed.connect(func(): closed.emit())
	if change_pin_btn:
		change_pin_btn.pressed.connect(_change_pin)
	if unlock_btn:
		PanelChrome.style_button(unlock_btn, true)
		unlock_btn.text = "Unlock"
	if close_btn:
		PanelChrome.style_button(close_btn)
	_ensure_lock_blurb()
	_ensure_recovery_ui()
	_ensure_pin_error()
	_ensure_pin_change_toggle()
	_ensure_hero_row()
	_ensure_campaign_tabs()

func open() -> void:
	pin_edit.text = ""
	content.visible = false
	pin_edit.visible = true
	unlock_btn.visible = true
	if _lock_blurb:
		_lock_blurb.visible = true
	if _pin_error:
		_pin_error.visible = false
		_pin_error.text = ""
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
	_set_pin_change_visible(false)
	pin_edit.grab_focus()

func _try_pin() -> void:
	if not GameState.verify_pin(pin_edit.text.strip_edges()):
		# Wave 54: clearer PIN wrong toast (default stays 1234; mastery ≥80% unchanged)
		# v1.78 refine: do NOT open the dashboard on a wrong PIN
		if _pin_error:
			_pin_error.text = "That PIN didn't match — try again (default is 1234 until you change it)."
			_pin_error.visible = true
		summary.text = "That PIN didn't match — try again (default is 1234 until you change it)."
		GameState.toast.emit("Wrong PIN — try again (default 1234 unless you changed it).")
		pin_edit.text = ""
		pin_edit.grab_focus()
		content.visible = false
		return
	content.visible = true
	pin_edit.visible = false
	unlock_btn.visible = false
	if _lock_blurb:
		_lock_blurb.visible = false
	if _pin_error:
		_pin_error.visible = false
	if _hint_lbl:
		_hint_lbl.visible = false
	if _reset_edit:
		_reset_edit.visible = false
	if _reset_btn:
		_reset_btn.visible = false
	_set_pin_change_visible(false)
	_refresh()


func _mask_pin_last4(pin: String) -> String:
	## Wave 63: masked last-4 hint for PIN change success (e.g. ••••1234 or ••34).
	var p := pin.strip_edges()
	if p.is_empty():
		return "••••"
	if p.length() <= 2:
		return "•".repeat(p.length())
	if p.length() <= 4:
		return "•".repeat(p.length() - 2) + p.substr(p.length() - 2)
	return "•".repeat(p.length() - 4) + p.substr(p.length() - 4)


func _change_pin() -> void:
	var a: String = new_pin_edit.text.strip_edges() if new_pin_edit else ""
	var b: String = confirm_pin_edit.text.strip_edges() if confirm_pin_edit else ""
	if a != b:
		pin_status.text = "PINs do not match."
		return
	if not GameState.set_parent_pin(a):
		pin_status.text = "Use 4–8 digits only."
		return
	# Wave 40/63: clearer pin-change success with masked last-4 hint (PIN default remains 1234 until changed)
	var hint := _mask_pin_last4(a)
	pin_status.text = "PIN changed successfully — hint %s. Use your new PIN next time you open Parent." % hint
	GameState.toast.emit("Parent PIN updated · hint %s (default was 1234)." % hint)
	new_pin_edit.text = ""
	confirm_pin_edit.text = ""
	AudioBus.play_ui()

func _refresh() -> void:
	var uw: int = GameState.unlocked_week
	var camp: String = _campaign_name(uw)
	var next_gate: String = _next_week_gate(uw)
	var week_prog: Dictionary = GameState.get_week_unlock_progress() if GameState.has_method("get_week_unlock_progress") else {"current": uw, "total": 36, "percent": int(round(float(uw) / 36.0 * 100.0))}
	var quest_prog: Dictionary = GameState.get_quest_mastery_progress() if GameState.has_method("get_quest_mastery_progress") else {"current": GameState.completed_quests.size(), "total": QuestDB.quests.size(), "percent": 0}
	var mastered: int = int(quest_prog.get("current", GameState.completed_quests.size()))
	var total_q: int = int(quest_prog.get("total", QuestDB.quests.size()))
	var mastery_pct: int = int(quest_prog.get("percent", 0))
	var week_pct: int = int(week_prog.get("percent", 0))
	var week_bar: String = _week_progress_bar(uw, 36)
	# Wave 70: mastery year bar shows ★ count beside % (PIN 1234; mastery ≥80% unchanged)
	var mastery_bar: String = _mastery_progress_bar(mastered, maxi(1, total_q))
	var year_note: String = GameState.get_year_progress_note() if GameState.has_method("get_year_progress_note") else "Year: week unlock %d%% · quests mastered %d%%" % [week_pct, mastery_pct]
	var help_preview: Array = GameState.needs_help_quests()
	var help_n: int = help_preview.size()
	var last_sess: String = _format_last_session()
	var export_line: String = GameState.get_parent_export_line() if GameState.has_method("get_parent_export_line") else "Week unlock %d/36 (%d%%) · Year mastery %d%%" % [uw, week_pct, mastery_pct]
	# Wave 49: highlight needs-help count when >0 (warm amber; PIN stays 1234; mastery ≥80%)
	var help_bit: String = ("Needs help: [color=#e8a030][b]%d[/b][/color]" % help_n) if help_n > 0 else ("Needs help: [b]%d[/b]" % help_n)
	# Wave 58: show year % next to child name line (PIN stays 1234; mastery ≥80% unchanged)
	var year_pct_chip: int = GameState.get_year_progress_percent() if GameState.has_method("get_year_progress_percent") else mastery_pct
	var child_line: String = "%s · Year %d%%" % [GameState.child_name, year_pct_chip]
	var lumen_bits: PackedStringArray = []
	for g in ["math","la","science","history","bible"]:
		lumen_bits.append("%s %d" % [GameState.GUILDS[g]["lumen"], int(GameState.lumens.get(g, 0))])
	_ensure_hero_row()
	if _hero_year:
		_hero_year.text = "YEAR\nWeek %d of 36\n%s" % [uw, camp.replace("Campaign ", "")]
	if _hero_mastery:
		_hero_mastery.text = "QUEST MASTERY\n%d%%  ·  %d★\n%d / %d mastered" % [mastery_pct, mastered, mastered, total_q]
	if _hero_help:
		if help_n > 0:
			_hero_help.text = "NEEDS HELP\n%d\nOldest attempt first" % help_n
			_hero_help.add_theme_color_override("font_color", Color(0.95, 0.72, 0.32, 1.0))
		else:
			_hero_help.text = "NEEDS HELP\nAll clear ★\nWonderful work together"
			_hero_help.add_theme_color_override("font_color", Color(0.78, 0.90, 0.62, 1.0))
	if _copy_edit:
		_copy_edit.text = export_line
	if _next_lbl:
		_next_lbl.text = "Next: %s" % next_gate
	if _lumen_lbl:
		_lumen_lbl.text = "Lumens  %s" % " · ".join(lumen_bits)
	# Keep a short skim in Summary so existing smoke strings still live here.
	summary.text = "[b]%s[/b] · Slot %d · %s\n%s\n%s · %s\n%s" % [
		child_line, GameState.active_slot + 1, last_sess,
		help_bit, year_note, week_bar, mastery_bar
	]
	summary.visible = false
	summary.custom_minimum_size = Vector2(0, 0)
	summary.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if _meta_lbl:
		_meta_lbl.text = "%s · Slot %d · %s" % [GameState.child_name, GameState.active_slot + 1, last_sess]
	_refresh_campaign_tabs(uw)
	help_list.clear()
	var help: Array = GameState.needs_help_quests()
	var help_title: Label = content.get_node_or_null("HelpTitle")
	if help_title:
		if help.is_empty():
			help_title.text = "Needs Help — all clear right now ★"
			help_title.remove_theme_color_override("font_color")
		else:
			help_title.text = "Needs Help — %d item%s (oldest attempt first)" % [help.size(), "" if help.size() == 1 else "s"]
			# Wave 49: warm amber highlight when needs-help count > 0
			help_title.add_theme_color_override("font_color", Color(0.92, 0.64, 0.18))
	if help.is_empty():
		# Wave 35: warmer empty-state encouragement (PIN stays 1234; mastery ≥80%)
		# Wave 58: needs-help empty state with week tip
		var tip_week: int = clampi(GameState.unlocked_week, 1, 36)
		help_list.add_item("All clear — wonderful work together! Tip: Week %d is open. A short review keeps mastery humming." % tip_week)
	else:
		help.sort_custom(func(a, b): return int(a.get("timestamp", 0)) < int(b.get("timestamp", 0)))  # Wave 75: oldest attempt first (PIN stays 1234; mastery ≥80%)
		for h in help:
			var q: Dictionary = QuestDB.get_quest(str(h.get("quest_id", "")))
			var week_n: int = int(q.get("week", 0))
			var guild: String = str(q.get("guild", ""))
			var guild_short: String = str(GameState.GUILDS.get(guild, {}).get("short", guild)).to_upper()
			var pct: int = int(float(h.get("percent", 0)) * 100)
			# Wave 35: week + guild read more boldly (ItemList has no BBCode)
			var age: String = _days_since_attempt(int(h.get("timestamp", 0)))
			var line: String = "WEEK %d · %s · %s  %d/%d (%d%%)  ·  %s" % [
				week_n, guild_short, h.get("title", h.get("quest_id", "?")),
				int(h.get("correct", 0)), int(h.get("total", 0)), pct, age
			]  # Wave 67: days-since last attempt (PIN stays 1234; mastery ≥80%)
			help_list.add_item(line)

func _ensure_campaign_tabs() -> void:
	if content.get_node_or_null("CampaignTabs") != null:
		_campaign_tabs = content.get_node("CampaignTabs")
		_campaign_week_roots.clear()
		for i in range(_campaign_tabs.get_tab_count()):
			var sc: ScrollContainer = _campaign_tabs.get_child(i)
			var vbox: VBoxContainer = sc.get_child(0) if sc.get_child_count() > 0 else null
			_campaign_week_roots.append(vbox)
		return
	var title := Label.new()
	title.name = "CampaignTabsTitle"
	title.text = "Weeks — click to expand  (★ mastered · open · locked)"
	PanelChrome.style_muted(title, 13)
	content.add_child(title)
	content.move_child(title, summary.get_index() + 1)
	_campaign_tabs = TabContainer.new()
	_campaign_tabs.name = "CampaignTabs"
	_campaign_tabs.custom_minimum_size = Vector2(0, 280)
	_campaign_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_campaign_tabs)
	content.move_child(_campaign_tabs, title.get_index() + 1)
	summary.custom_minimum_size = Vector2(0, 72)
	summary.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_campaign_week_roots.clear()
	for camp in CAMPAIGN_RANGES:
		var scroll := ScrollContainer.new()
		scroll.name = str(camp["title"]).replace(" ", "_")
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 4)
		scroll.add_child(vbox)
		_campaign_tabs.add_child(scroll)
		_campaign_tabs.set_tab_title(_campaign_tabs.get_tab_count() - 1, str(camp["title"]))
		_campaign_week_roots.append(vbox)

func _refresh_campaign_tabs(uw: int) -> void:
	_ensure_campaign_tabs()
	var tab_idx := 0
	if uw <= 9:
		tab_idx = 0
	elif uw <= 18:
		tab_idx = 1
	elif uw <= 27:
		tab_idx = 2
	else:
		tab_idx = 3
	if _campaign_tabs:
		_campaign_tabs.current_tab = tab_idx
		# Wave 30: highlight the campaign tab that holds the current week
		# Wave 40: campaign tab shows mastered/total for that campaign
		for i in range(_campaign_tabs.get_tab_count()):
			var camp_i: Dictionary = CAMPAIGN_RANGES[i] if i < CAMPAIGN_RANGES.size() else {}
			var base: String = str(camp_i.get("title", "Campaign"))
			var lo_i: int = int(camp_i.get("lo", 1))
			var hi_i: int = int(camp_i.get("hi", 9))
			var c_done := 0
			var c_total := 0
			for q in QuestDB.quests:
				var qw: int = int(q.get("week", 1))
				if qw >= lo_i and qw <= hi_i:
					c_total += 1
					if str(q.get("id", "")) in GameState.completed_quests:
						c_done += 1
			var titled: String = "%s · %d/%d" % [base, c_done, c_total]
			if i == tab_idx:
				_campaign_tabs.set_tab_title(i, "★ %s" % titled)
			else:
				_campaign_tabs.set_tab_title(i, titled)
			# Wave 49: campaign tab tooltip with week range
			if _campaign_tabs.has_method("set_tab_tooltip"):
				_campaign_tabs.set_tab_tooltip(i, "Weeks %d–%d · %d/%d mastered" % [lo_i, hi_i, c_done, c_total])
	# Restore persisted expand state; default current week open on first visit
	if _expanded_weeks.is_empty() and not GameState.parent_expanded_weeks.is_empty():
		_expanded_weeks = GameState.parent_expanded_weeks.duplicate()
	if not _expanded_weeks.has(uw):
		_expanded_weeks[uw] = true
	for i in range(CAMPAIGN_RANGES.size()):
		var camp: Dictionary = CAMPAIGN_RANGES[i]
		var lo: int = int(camp["lo"])
		var hi: int = int(camp["hi"])
		if i >= _campaign_week_roots.size() or _campaign_week_roots[i] == null:
			continue
		var vbox: VBoxContainer = _campaign_week_roots[i]
		while vbox.get_child_count() > 0:
			var ch: Node = vbox.get_child(0)
			vbox.remove_child(ch)
			ch.free()
		for w in range(lo, hi + 1):
			_add_week_row(vbox, w, uw)

func _add_week_row(parent: VBoxContainer, w: int, uw: int) -> void:
	var titles: Array = []
	var done_n := 0
	var total_n := 0
	for q in QuestDB.quests_for_week(w):
		total_n += 1
		var qid: String = str(q["id"])
		var mark := "✓" if qid in GameState.completed_quests else ("·" if w <= uw else "–")
		if qid in GameState.completed_quests:
			done_n += 1
		titles.append("%s %s" % [mark, q.get("title", qid)])
	var lock: String = "" if w <= uw else " · locked"
	var expanded: bool = bool(_expanded_weeks.get(w, false))
	var arrow: String = "▾" if expanded else "▸"
	var status := ""
	if done_n > 0 and done_n == total_n and total_n > 0:
		status = " ★"
	var head: String = "%s  Week %d   %d/%d%s%s" % [arrow, w, done_n, total_n, status, lock]
	if w == uw:
		head += "   ← now"
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var btn := Button.new()
	btn.toggle_mode = true
	btn.button_pressed = expanded
	btn.text = head
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Wave 30: soft gold highlight on the current week row
	if w == uw:
		btn.add_theme_color_override("font_color", Color(0.95, 0.82, 0.28))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.45))
		btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.75, 0.2))
	elif w > uw:
		btn.add_theme_color_override("font_color", Color(0.62, 0.60, 0.55, 0.95))
	elif done_n == total_n and total_n > 0:
		btn.add_theme_color_override("font_color", Color(0.62, 0.82, 0.50))
	var detail := RichTextLabel.new()
	detail.bbcode_enabled = true
	detail.fit_content = true
	detail.scroll_active = false
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.custom_minimum_size = Vector2(0, 8)
	if titles.is_empty():
		# Wave 63/73: warmer empty campaign week row (PIN stays 1234; mastery ≥80%)
		detail.text = "  A quiet week for now — nothing listed here yet. Browse another week, or check back after a curriculum update. You're doing great!"
	else:
		detail.text = "  " + "\n  ".join(titles)
	detail.visible = expanded
	var week_num := w
	btn.toggled.connect(func(on: bool) -> void:
		_expanded_weeks[week_num] = on
		detail.visible = on
		var a2: String = "▾" if on else "▸"
		var h2: String = "%s  Week %d   %d/%d%s%s" % [a2, week_num, done_n, total_n, status, lock]
		if week_num == uw:
			h2 += "   ← now"
		btn.text = h2
		if GameState.has_method("set_parent_expanded_weeks"):
			GameState.set_parent_expanded_weeks(_expanded_weeks)
	)
	row.add_child(btn)
	row.add_child(detail)
	parent.add_child(row)

func _format_last_session() -> String:
	## Wave 27/44: show last save/session time + relative age (local clock; PIN stays 1234).
	var ts: int = int(GameState.last_played) if GameState.get("last_played") != null else 0
	if ts <= 0:
		return "Last session: not saved yet"
	# Godot 4.3: unix dict is UTC — shift by system timezone bias (minutes).
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(ts + bias * 60)
	var absolute: String = "%04d-%02d-%02d %02d:%02d" % [
		int(dt.get("year", 0)), int(dt.get("month", 0)), int(dt.get("day", 0)),
		int(dt.get("hour", 0)), int(dt.get("minute", 0))
	]
	var rel: String = _relative_session_age(ts)
	return "Last session: %s (%s)" % [absolute, rel]


func _days_since_attempt(ts: int) -> String:
	## Wave 67: compact days-since last Needs Help attempt for parent skim (PIN stays 1234; mastery ≥80%).
	if ts <= 0:
		return "last try unknown"
	var now: int = int(Time.get_unix_time_from_system())
	var sec: int = maxi(0, now - ts)
	if sec < 3600:
		return "last try today"
	var d: int = int(sec / 86400)
	if d <= 0:
		return "last try today"
	if d == 1:
		return "1 day since last try"
	if d < 14:
		return "%d days since last try" % d
	return "%d weeks since last try" % maxi(1, int(round(float(d) / 7.0)))


func _relative_session_age(ts: int) -> String:
	## Wave 44: soft relative last-session age for parent skim (PIN stays 1234; mastery ≥80%).
	var now: int = int(Time.get_unix_time_from_system())
	var sec: int = maxi(0, now - ts)
	if sec < 60:
		return "just now"
	if sec < 3600:
		var m: int = int(sec / 60)
		return "%d minute%s ago" % [m, "" if m == 1 else "s"]
	if sec < 86400:
		var h: int = int(sec / 3600)
		return "%d hour%s ago" % [h, "" if h == 1 else "s"]
	var d: int = int(sec / 86400)
	if d < 14:
		return "%d day%s ago" % [d, "" if d == 1 else "s"]
	return "%d weeks ago" % maxi(1, int(round(float(d) / 7.0)))


func _campaign_name(week: int) -> String:
	if week <= 9:
		return "Campaign I — Kindling the Lamps"
	if week <= 18:
		return "Campaign II — Scrolls of the Free"
	if week <= 27:
		return "Campaign III — Builders of the Republic"
	return "Campaign IV — Light for the Realm"

func _week_progress_bar(cur: int, mx: int) -> String:
	## Wave 24: clearer year/week bars — quarter ticks + fraction so parents can skim progress.
	var filled: int = clampi(int(round(float(cur) / float(maxi(1, mx)) * 20.0)), 0, 20)
	var chars: PackedStringArray = []
	for i in 20:
		if i < filled:
			chars.append("█")
		elif i % 5 == 0:
			chars.append("¦")
		else:
			chars.append("·")
	var pct: int = int(round(float(cur) / float(maxi(1, mx)) * 100.0))
	return "[%s] %d/%d (%d%%)" % ["".join(chars), cur, mx, pct]


func _mastery_progress_bar(cur: int, mx: int) -> String:
	## Wave 70: parent year/mastery bar shows ★ count beside % (PIN 1234; mastery ≥80% unchanged).
	var filled: int = clampi(int(round(float(cur) / float(maxi(1, mx)) * 20.0)), 0, 20)
	var chars: PackedStringArray = []
	for i in 20:
		if i < filled:
			chars.append("█")
		elif i % 5 == 0:
			chars.append("¦")
		else:
			chars.append("·")
	var pct: int = int(round(float(cur) / float(maxi(1, mx)) * 100.0))
	return "[%s] %d/%d (%d%% · %d★)" % ["".join(chars), cur, mx, pct, cur]


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

func _ensure_content_scroll() -> void:
	## Keep title + Close on screen; scroll the unlocked dashboard.
	var vbox: VBoxContainer = $Panel/VBox
	if vbox.get_node_or_null("ContentScroll") != null:
		return
	if content == null:
		return
	var scroll := ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var idx: int = content.get_index()
	vbox.remove_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	vbox.add_child(scroll)
	vbox.move_child(scroll, idx)
	if close_btn:
		vbox.move_child(close_btn, vbox.get_child_count() - 1)


func _ensure_lock_blurb() -> void:
	var vbox: VBoxContainer = $Panel/VBox
	if vbox.get_node_or_null("LockBlurb") != null:
		_lock_blurb = vbox.get_node("LockBlurb")
		return
	_lock_blurb = Label.new()
	_lock_blurb.name = "LockBlurb"
	_lock_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lock_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lock_blurb.text = "For grown-ups. Enter the PIN to see year, mastery, and what needs practice."
	PanelChrome.style_muted(_lock_blurb, 14)
	vbox.add_child(_lock_blurb)
	vbox.move_child(_lock_blurb, pin_edit.get_index())


func _ensure_hero_row() -> void:
	if content.get_node_or_null("HeroRow") != null:
		_hero_row = content.get_node("HeroRow")
		_hero_year = _hero_row.get_node_or_null("YearCard/YearLbl")
		_hero_mastery = _hero_row.get_node_or_null("MasteryCard/MasteryLbl")
		_hero_help = _hero_row.get_node_or_null("HelpCard/HelpLbl")
		_copy_row = content.get_node_or_null("CopyRow")
		_copy_edit = _copy_row.get_node_or_null("CopyEdit") if _copy_row else null
		_copy_btn = _copy_row.get_node_or_null("CopyBtn") if _copy_row else null
		_next_lbl = content.get_node_or_null("NextLbl")
		_lumen_lbl = content.get_node_or_null("LumenLbl")
		_meta_lbl = content.get_node_or_null("MetaLbl")
		return
	_hero_row = HBoxContainer.new()
	_hero_row.name = "HeroRow"
	_hero_row.add_theme_constant_override("separation", 10)
	_hero_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hero_year = _make_hero_card(_hero_row, "YearCard", "YearLbl", "YEAR")
	_hero_mastery = _make_hero_card(_hero_row, "MasteryCard", "MasteryLbl", "QUEST MASTERY")
	_hero_help = _make_hero_card(_hero_row, "HelpCard", "HelpLbl", "NEEDS HELP")
	content.add_child(_hero_row)
	content.move_child(_hero_row, 0)
	_meta_lbl = Label.new()
	_meta_lbl.name = "MetaLbl"
	_meta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PanelChrome.style_muted(_meta_lbl, 13)
	content.add_child(_meta_lbl)
	content.move_child(_meta_lbl, _hero_row.get_index() + 1)
	_copy_row = HBoxContainer.new()
	_copy_row.name = "CopyRow"
	_copy_row.add_theme_constant_override("separation", 8)
	var copy_lab := Label.new()
	copy_lab.text = "Copy"
	PanelChrome.style_muted(copy_lab, 13)
	_copy_row.add_child(copy_lab)
	_copy_edit = LineEdit.new()
	_copy_edit.name = "CopyEdit"
	_copy_edit.editable = false
	_copy_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_copy_edit.placeholder_text = "Week unlock · Year mastery · Needs help"
	_copy_row.add_child(_copy_edit)
	_copy_btn = Button.new()
	_copy_btn.name = "CopyBtn"
	_copy_btn.text = "Copy line"
	PanelChrome.style_button(_copy_btn, true)
	_copy_btn.pressed.connect(_copy_export_line)
	_copy_row.add_child(_copy_btn)
	content.add_child(_copy_row)
	content.move_child(_copy_row, _meta_lbl.get_index() + 1)
	_next_lbl = Label.new()
	_next_lbl.name = "NextLbl"
	_next_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PanelChrome.style_body(_next_lbl, 14)
	content.add_child(_next_lbl)
	content.move_child(_next_lbl, _copy_row.get_index() + 1)
	_lumen_lbl = Label.new()
	_lumen_lbl.name = "LumenLbl"
	_lumen_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PanelChrome.style_muted(_lumen_lbl, 13)
	content.add_child(_lumen_lbl)
	content.move_child(_lumen_lbl, _next_lbl.get_index() + 1)


func _make_hero_card(host: HBoxContainer, panel_name: String, label_name: String, fallback: String) -> Label:
	var card := PanelContainer.new()
	card.name = panel_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PanelChrome.apply_card(card)
	var lab := Label.new()
	lab.name = label_name
	lab.text = fallback
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PanelChrome.style_body(lab, 14)
	card.add_child(lab)
	host.add_child(card)
	return lab


func _copy_export_line() -> void:
	var line: String = GameState.get_parent_export_line() if GameState.has_method("get_parent_export_line") else ""
	if _copy_edit:
		line = _copy_edit.text.strip_edges()
	if line == "":
		return
	DisplayServer.clipboard_set(line)
	GameState.toast.emit("Copied parent line — week, mastery, needs-help.")
	AudioBus.play_ui()


func _ensure_pin_error() -> void:
	## v1.78 refine: wrong-PIN message lives outside Content so the dashboard stays locked.
	var vbox: VBoxContainer = $Panel/VBox
	if vbox.get_node_or_null("PinError") != null:
		_pin_error = vbox.get_node("PinError")
		return
	_pin_error = Label.new()
	_pin_error.name = "PinError"
	_pin_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pin_error.add_theme_color_override("font_color", Color(0.92, 0.55, 0.28))
	_pin_error.visible = false
	vbox.add_child(_pin_error)
	vbox.move_child(_pin_error, unlock_btn.get_index() + 1)

func _ensure_pin_change_toggle() -> void:
	## v1.78 refine: PIN change fields stay collapsed until a parent asks.
	if content.get_node_or_null("PinChangeToggle") != null:
		_pin_change_toggle = content.get_node("PinChangeToggle")
		_set_pin_change_visible(_pin_change_open)
		return
	_pin_change_toggle = Button.new()
	_pin_change_toggle.name = "PinChangeToggle"
	_pin_change_toggle.text = "Change PIN…"
	_pin_change_toggle.pressed.connect(func():
		_set_pin_change_visible(not _pin_change_open)
	)
	var title_n: Node = content.get_node_or_null("PinChangeTitle")
	if title_n:
		content.add_child(_pin_change_toggle)
		content.move_child(_pin_change_toggle, title_n.get_index())
	else:
		content.add_child(_pin_change_toggle)
	_set_pin_change_visible(false)

func _set_pin_change_visible(on: bool) -> void:
	_pin_change_open = on
	if _pin_change_toggle:
		_pin_change_toggle.text = "Hide PIN change" if on else "Change PIN…"
	var title_n = content.get_node_or_null("PinChangeTitle")
	if title_n:
		title_n.visible = on
	if new_pin_edit:
		new_pin_edit.visible = on
	if confirm_pin_edit:
		confirm_pin_edit.visible = on
	if change_pin_btn:
		change_pin_btn.visible = on
	if pin_status:
		pin_status.visible = on

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
	_hint_lbl.text = "Forgot PIN? Type RESET twice to restore 1234. Save slots stay."
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
		if _pin_error:
			_pin_error.text = "Type RESET exactly to recover the parent PIN."
			_pin_error.visible = true
		summary.text = "Type RESET exactly to recover the parent PIN."
		content.visible = false
		_reset_armed = false
		return
	if not _reset_armed:
		_reset_armed = true
		if _pin_error:
			_pin_error.text = "Confirm: type RESET again and press Reset PIN once more."
			_pin_error.visible = true
		summary.text = "Confirm: type RESET again and press Reset PIN once more."
		content.visible = false
		if _reset_btn:
			_reset_btn.text = "Confirm RESET"
		if _reset_edit:
			_reset_edit.text = ""
		return
	GameState.reset_parent_pin_to_default()
	_reset_armed = false
	if _pin_error:
		_pin_error.text = "Parent PIN restored to 1234. Save slots were not changed."
		_pin_error.visible = true
	summary.text = "Parent PIN restored to 1234. Save slots were not changed."
	content.visible = false
	if _reset_btn:
		_reset_btn.text = "Reset PIN"
	if _reset_edit:
		_reset_edit.text = ""
	AudioBus.play_ui()
