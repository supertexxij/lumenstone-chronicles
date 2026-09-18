extends Node
## Persistent game state + save/load to user://

signal state_changed
signal hp_changed(current: int, maximum: int)
signal toast(msg: String)
signal quest_started(quest_id: String)
signal ui_open_requested(panel: String)
signal combat_target_changed(enemy: Node)
signal soft_defeated
signal quest_mastered(quest_id: String)
signal hurt(amount: int)
signal soft_combat_cleared
signal heal_tick(amount: int)
signal game_saved  # Wave 69: nickname chip pulse on save

const LEGACY_SAVE_PATH := "user://lumenstone_save_v1.json"
const SAVE_SLOT_FMT := "user://lumenstone_save_slot_%d.json"
const PARENT_SETTINGS_PATH := "user://lumenstone_parent.json"
const SLOT_COUNT := 3
const DEFAULT_PIN := "1234"
const MASTERY_PCT := 0.8

const ONCE_TOAST_FLAGS := [
	"seen_wave_50_toast",
	"seen_wave_51_toast",
	"seen_wave_52_toast",
	"seen_wave_53_toast",
	"seen_wave_54_toast",
	"seen_wave_55_toast",
	"seen_wave_56_toast",
	"seen_wave_57_toast",
	"seen_wave_58_toast",
	"seen_wave_59_toast",
	"seen_wave_60_toast",
	"seen_wave_61_toast",
	"seen_wave_62_toast",
	"seen_wave_63_toast",
	"seen_wave_64_toast",
	"seen_wave_65_toast",
	"seen_wave_66_toast",
	"seen_wave_67_toast",
	"seen_wave_68_toast",
	"seen_wave_69_toast",
	"seen_wave_70_toast",
	"seen_wave_71_toast",
	"seen_wave_72_toast",
	"seen_wave_73_toast",
	"seen_wave_74_toast",
	"seen_wave_75_toast",
	"seen_wave_76_toast",
	"seen_wave_77_toast",
	"seen_refine_178_toast",
	"seen_refine_181_toast",
	"seen_bugs_182_toast",
	"seen_curriculum_183_toast",
]


const GUILDS := {
	"math": {"name": "Builder's Guild", "short": "Math", "color": Color("#d4a017"), "lumen": "Gold"},
	"la": {"name": "Scribe's Guild", "short": "LA", "color": Color("#3a6ea5"), "lumen": "Blue"},
	"science": {"name": "Stewards of Creation", "short": "Science", "color": Color("#2d6a4f"), "lumen": "Green"},
	"history": {"name": "Chronicle Keepers", "short": "History", "color": Color("#9b2226"), "lumen": "Crimson"},
	"bible": {"name": "Word & Worship", "short": "Bible", "color": Color("#c9b037"), "lumen": "Silver"},
}

## Village mentors — used by Journal / NPC / Parent "what to do next" copy.
const MENTORS := {
	"math": {"name": "Master Builder", "hall": "Builder's Guild (gold hall)"},
	"la": {"name": "Master Scribe", "hall": "Scribe's Guild (blue hall)"},
	"science": {"name": "Steward of Creation", "hall": "Stewards of Creation (green hall)"},
	"history": {"name": "Chronicle Keeper", "hall": "Chronicle Keepers (crimson hall)"},
	"bible": {"name": "Steward Guide", "hall": "Word & Worship (gold Worship hall)"},
}
const DAILY_LESSON_GOAL := 2

const SKIN_HEX := {"fair":"#ffe0bd","light":"#f1c27d","medium":"#c68642","tan":"#8d5524","deep":"#5c3317"}
const HAIR_HEX := {"brown":"#5c4033","black":"#1a1a1a","blonde":"#d4a84b","auburn":"#8b3a2a","gray":"#8a8a8a"}
const CAPE_HEX := {"crimson":"#c1121f","azure":"#1d7a9c","emerald":"#2d6a4f","gold":"#c9a227","violet":"#6a4c93"}
const OUTFIT_HEX := {"cream":"#f4e4bc","sky":"#87b8d4","forest":"#4a7c59","sand":"#c2b280","rose":"#d4a0a0"}

var child_name: String = "Apprentice"
var appearance: Dictionary = {"hair":"brown","skin":"medium","cape_color":"crimson","outfit":"cream"}
var xp: int = 0
var level: int = 1
var lumens: Dictionary = {"math":0,"la":0,"science":0,"history":0,"bible":0}
var completed_quests: Array = []
var quest_attempts: Array = []
var unlocked_items: Array = []
var equipped: Dictionary = {"head":null,"cape":"default_cape","accessory":null,"weapon":null,"belt":null}
var position_xz: Vector2 = Vector2(0, 10)
var combat_xp: int = 0
var combat_level: int = 1
var muted: bool = false
var seen_aggro_tutorial: bool = false
var seen_combat_tutorial: bool = false
var seen_wave_50_toast: bool = false  # Wave 50: once-per-save polish tip toast on load
var seen_wave_51_toast: bool = false  # Wave 51: once-per-save polish tip toast on load
var seen_wave_52_toast: bool = false  # Wave 52: once-per-save polish tip toast on load
var seen_wave_53_toast: bool = false  # Wave 53: once-per-save polish tip toast on load
var seen_wave_54_toast: bool = false  # Wave 54: once-per-save polish tip toast on load
var seen_wave_55_toast: bool = false  # Wave 55: once-per-save polish tip toast on load
var seen_wave_56_toast: bool = false  # Wave 56: once-per-save polish tip toast on load
var seen_wave_57_toast: bool = false  # Wave 57: once-per-save polish tip toast on load
var seen_wave_58_toast: bool = false  # Wave 58: once-per-save polish tip toast on load
var seen_wave_59_toast: bool = false  # Wave 59: once-per-save polish tip toast on load
var seen_wave_60_toast: bool = false  # Wave 60: once-per-save polish tip toast on load
var seen_wave_61_toast: bool = false  # Wave 61: once-per-save polish tip toast on load
var seen_wave_62_toast: bool = false  # Wave 62: once-per-save polish tip toast on load
var seen_wave_63_toast: bool = false  # Wave 63: once-per-save polish tip toast on load
var seen_wave_64_toast: bool = false  # Wave 64: once-per-save polish tip toast on load
var seen_wave_65_toast: bool = false  # Wave 65: once-per-save polish tip toast on load
var seen_wave_66_toast: bool = false  # Wave 66: once-per-save polish tip toast on load
var seen_wave_67_toast: bool = false  # Wave 67: once-per-save polish tip toast on load
var seen_wave_68_toast: bool = false  # Wave 68: once-per-save polish tip toast on load
var seen_wave_69_toast: bool = false  # Wave 69: once-per-save polish tip toast on load
var seen_wave_70_toast: bool = false  # Wave 70: once-per-save polish tip toast on load
var seen_wave_71_toast: bool = false  # Wave 71: once-per-save polish tip toast on load
var seen_wave_72_toast: bool = false  # Wave 72: once-per-save polish tip toast on load
var seen_wave_73_toast: bool = false  # Wave 73: once-per-save polish tip toast on load
var seen_wave_74_toast: bool = false  # Wave 74: once-per-save polish tip toast on load
var seen_wave_75_toast: bool = false  # Wave 75: once-per-save polish tip toast on load
var seen_wave_76_toast: bool = false  # Wave 76: once-per-save polish tip toast on load
var seen_wave_77_toast: bool = false  # Wave 77: once-per-save polish tip toast on load
var seen_refine_178_toast: bool = false  # v1.78 refine: once-per-save look/HUD/Parent tip
var seen_refine_181_toast: bool = false  # v1.81 UI: once-per-save menus/HUD/Parent tip
var seen_bugs_182_toast: bool = false  # v1.82 bugs: once-per-save Esc/one-menu tip
var seen_curriculum_183_toast: bool = false  # v1.83 curriculum: first-session / next-lesson tip
var _low_hp_toast_armed: bool = true  # Wave 67: clearer low-HP toast (re-arm when HP recovers)
var journal_open_only: bool = false  # Wave 62: persist journal Open-only toggle
var festival_decades_seen: Array = []  # Wave 50: year-% decade marks already celebrated (10/20/…)
## Landmark approach toasts already shown for the current visit (persisted so reload in-zone does not re-greet).
var greeted_landmarks: Array = []
## Landmarks ever visited (persists forever) — drives first-discovery vs return toast flavor.
var discovered_landmarks: Array = []
var last_travel_label: String = ""  # Wave 34: last soft-travel destination
var favorite_landmark: String = ""  # Wave 51: pin/favorite one landmark (★ fav)
var checkpoint_checks: Dictionary = {}
var checkpoint_date: String = ""
var last_daily_reminder_date: String = ""
var created_at: int = 0
var last_played: int = 0
var unlocked_week: int = 1
var active_slot: int = 0
var parent_pin: String = DEFAULT_PIN
var parent_expanded_weeks: Dictionary = {}  # week int (as string keys in JSON) -> bool
var slot_label: String = ""
## Pantry stacks for starter food (refill at fountain). Soft combat balance.
var consumable_charges: Dictionary = {}
var consumable_cd: float = 0.0
var _fountain_regen_left: int = 0
var _fountain_regen_timer: float = 0.0
var _fountain_rest_ms: int = 0  # debounce overlapping fountain rest (travel + Area3D)

var hp: int = 40
var max_hp: int = 40
var in_world: bool = false
var combat_target: Node = null

func _ready() -> void:
	_load_parent_settings()
	_migrate_legacy_save()
	await get_tree().process_frame
	if unlocked_items.is_empty():
		_apply_starters()
	_ensure_pantry_defaults()

func _process(delta: float) -> void:
	if consumable_cd > 0.0:
		consumable_cd = maxf(0.0, consumable_cd - delta)
	_tick_fountain_regen(delta)

func _apply_starters() -> void:
	for id in ItemDB.starter_ids():
		if id not in unlocked_items:
			unlocked_items.append(id)
	if equipped.get("cape") == null:
		equipped["cape"] = "default_cape"

func new_game(p_name: String, appearance_in: Dictionary, slot: int = -1) -> void:
	if slot >= 0:
		active_slot = clampi(slot, 0, SLOT_COUNT - 1)
	child_name = p_name if p_name.strip_edges() != "" else "Apprentice"
	appearance = appearance_in.duplicate()
	slot_label = ""
	consumable_charges = {}
	consumable_cd = 0.0
	_ensure_pantry_defaults()
	xp = 0
	level = 1
	lumens = {"math":0,"la":0,"science":0,"history":0,"bible":0}
	completed_quests = []
	quest_attempts = []
	unlocked_items = []
	equipped = {"head":null,"cape":"default_cape","accessory":null,"weapon":null,"belt":null}
	position_xz = Vector2(0, 10)
	combat_xp = 0
	combat_level = 1
	checkpoint_checks = {}
	checkpoint_date = ""
	last_daily_reminder_date = ""
	created_at = int(Time.get_unix_time_from_system())
	unlocked_week = 1
	seen_aggro_tutorial = false
	seen_combat_tutorial = false
	_reset_once_toasts()
	quiet_legacy_polish_toasts()
	_low_hp_toast_armed = true
	journal_open_only = false
	festival_decades_seen = []
	greeted_landmarks = []
	discovered_landmarks = []
	last_travel_label = ""
	favorite_landmark = ""
	hp = 40
	max_hp = 40
	_apply_starters()
	save_game()
	state_changed.emit()


func _reset_once_toasts() -> void:
	for f in ONCE_TOAST_FLAGS:
		set(f, false)


func _write_once_toasts(data: Dictionary) -> void:
	for f in ONCE_TOAST_FLAGS:
		data[f] = bool(get(f))


func _read_once_toasts(data: Dictionary) -> void:
	for f in ONCE_TOAST_FLAGS:
		set(f, bool(data.get(f, false)))


func slot_path(slot: int) -> String:
	return SAVE_SLOT_FMT % clampi(slot, 0, SLOT_COUNT - 1)

func has_save(slot: int = -1) -> bool:
	var s: int = active_slot if slot < 0 else slot
	if FileAccess.file_exists(slot_path(s)):
		return true
	# Backward compat: legacy single save counts as slot 0
	if s == 0 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		return true
	return false

func any_save_exists() -> bool:
	for i in SLOT_COUNT:
		if has_save(i):
			return true
	return false

func _migrate_legacy_save() -> void:
	## Copy old single-file save into slot 0 once, keep legacy file for older builds.
	if FileAccess.file_exists(slot_path(0)):
		return
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return
	var src := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if not src:
		return
	var raw: String = src.get_as_text()
	src.close()
	var dst := FileAccess.open(slot_path(0), FileAccess.WRITE)
	if dst:
		dst.store_string(raw)
		dst.close()

func _load_parent_settings() -> void:
	parent_pin = DEFAULT_PIN
	parent_expanded_weeks = {}
	if not FileAccess.file_exists(PARENT_SETTINGS_PATH):
		return
	var f := FileAccess.open(PARENT_SETTINGS_PATH, FileAccess.READ)
	if not f:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_DICTIONARY:
		var pin := str(data.get("parent_pin", DEFAULT_PIN)).strip_edges()
		if pin.length() >= 4:
			parent_pin = pin
		var ew = data.get("expanded_weeks", {})
		if typeof(ew) == TYPE_DICTIONARY:
			parent_expanded_weeks = {}
			for k in ew.keys():
				parent_expanded_weeks[int(str(k))] = bool(ew[k])

func _save_parent_settings() -> void:
	var ew_out := {}
	for k in parent_expanded_weeks.keys():
		ew_out[str(int(k))] = bool(parent_expanded_weeks[k])
	var f := FileAccess.open(PARENT_SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"parent_pin": parent_pin, "expanded_weeks": ew_out}))
		f.close()

func set_parent_expanded_weeks(expanded: Dictionary) -> void:
	## Persist which parent-dashboard week rows are open.
	parent_expanded_weeks = {}
	for k in expanded.keys():
		parent_expanded_weeks[int(k)] = bool(expanded[k])
	_save_parent_settings()

func set_parent_pin(new_pin: String) -> bool:
	var pin := new_pin.strip_edges()
	if pin.length() < 4 or pin.length() > 8:
		return false
	for ch in pin:
		if ch < "0" or ch > "9":
			return false
	parent_pin = pin
	_save_parent_settings()
	return true

func reset_parent_pin_to_default() -> void:
	## Recovery path — restores factory PIN without touching save slots.
	parent_pin = DEFAULT_PIN
	_save_parent_settings()

func set_slot_label(label: String) -> void:
	slot_label = label.strip_edges().substr(0, 24)
	save_game()
	state_changed.emit()

func set_slot_label_on_slot(slot: int, label: String) -> bool:
	## Write a label into a slot file without changing the in-memory adventure (parent PIN untouched).
	var s: int = clampi(slot, 0, SLOT_COUNT - 1)
	var text := label.strip_edges().substr(0, 24)
	if s == active_slot:
		set_slot_label(text)
		return true
	if not has_save(s):
		return false
	var path := slot_path(s)
	if not FileAccess.file_exists(path) and s == 0 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		path = LEGACY_SAVE_PATH
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	data["slot_label"] = text
	var out := FileAccess.open(slot_path(s), FileAccess.WRITE)
	if not out:
		return false
	out.store_string(JSON.stringify(data))
	out.close()
	return true


func slot_summary(slot: int) -> Dictionary:
	## Lightweight peek for title UI without mutating active state.
	if not has_save(slot):
		return {"empty": true, "slot": slot}
	var path := slot_path(slot)
	if not FileAccess.file_exists(path) and slot == 0 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		path = LEGACY_SAVE_PATH
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return {"empty": true, "slot": slot}
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return {"empty": true, "slot": slot}
	return {
		"empty": false,
		"slot": slot,
		"child_name": str(data.get("child_name", "Apprentice")),
		"level": int(data.get("level", 1)),
		"xp": int(data.get("xp", 0)),
		"unlocked_week": int(data.get("unlocked_week", 1)),
		"combat_level": int(data.get("combat_level", 1)),
		"last_played": int(data.get("last_played", 0)),
		"slot_label": str(data.get("slot_label", "")),
	}

func clear_slot(slot: int) -> void:
	var path := slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if slot == 0 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH))

func save_game() -> void:
	last_played = int(Time.get_unix_time_from_system())
	var data: Dictionary = {
		"child_name": child_name,
		"appearance": appearance,
		"xp": xp,
		"level": level,
		"lumens": lumens,
		"completed_quests": completed_quests,
		"quest_attempts": quest_attempts,
		"unlocked_items": unlocked_items,
		"equipped": equipped,
		"position_x": position_xz.x,
		"position_z": position_xz.y,
		"combat_xp": combat_xp,
		"combat_level": combat_level,
		"muted": muted,
		"seen_aggro_tutorial": seen_aggro_tutorial,
		"seen_combat_tutorial": seen_combat_tutorial,
		# once-per-save polish toasts (Wave 50–77 + v1.78 refine + v1.81 UI)
		"journal_open_only": journal_open_only,
		"festival_decades_seen": festival_decades_seen,
		"greeted_landmarks": greeted_landmarks,
		"discovered_landmarks": discovered_landmarks,
		"last_travel_label": last_travel_label,
		"favorite_landmark": favorite_landmark,
		"checkpoint_checks": checkpoint_checks,
		"checkpoint_date": checkpoint_date,
		"last_daily_reminder_date": last_daily_reminder_date,
		"created_at": created_at,
		"last_played": last_played,
		"unlocked_week": unlocked_week,
		"slot_label": slot_label,
		"consumable_charges": consumable_charges,
		"hp": hp,
		"save_version": 3,
	}
	_write_once_toasts(data)
	var path := slot_path(active_slot)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()
	# Keep legacy path mirrored for older builds when using slot 0
	if active_slot == 0:
		var leg := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.WRITE)
		if leg:
			leg.store_string(JSON.stringify(data))
			leg.close()
	game_saved.emit()  # Wave 69: nickname chip pulse on save


func load_game(slot: int = -1) -> bool:
	if slot >= 0:
		active_slot = clampi(slot, 0, SLOT_COUNT - 1)
	if not has_save(active_slot):
		return false
	var path := slot_path(active_slot)
	if not FileAccess.file_exists(path) and active_slot == 0 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		path = LEGACY_SAVE_PATH
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not f:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	child_name = str(data.get("child_name", "Apprentice")).strip_edges()
	if child_name == "":
		child_name = "Apprentice"
	appearance = data.get("appearance", appearance)
	xp = int(data.get("xp", 0))
	level = int(data.get("level", 1))
	lumens = data.get("lumens", lumens)
	completed_quests = data.get("completed_quests", [])
	quest_attempts = data.get("quest_attempts", [])
	unlocked_items = data.get("unlocked_items", [])
	equipped = data.get("equipped", equipped)
	position_xz = Vector2(float(data.get("position_x", 0)), float(data.get("position_z", 10)))
	combat_xp = int(data.get("combat_xp", 0))
	combat_level = int(data.get("combat_level", 1))
	muted = bool(data.get("muted", false))
	seen_aggro_tutorial = bool(data.get("seen_aggro_tutorial", false))
	seen_combat_tutorial = bool(data.get("seen_combat_tutorial", false))
	_read_once_toasts(data)
	_low_hp_toast_armed = true
	journal_open_only = bool(data.get("journal_open_only", false))
	var fd = data.get("festival_decades_seen", [])
	festival_decades_seen = []
	if typeof(fd) == TYPE_ARRAY:
		for v in fd:
			festival_decades_seen.append(int(v))
	var gl = data.get("greeted_landmarks", [])
	greeted_landmarks = []
	if typeof(gl) == TYPE_ARRAY:
		for g in gl:
			var sid := str(g)
			if sid != "" and sid not in greeted_landmarks:
				greeted_landmarks.append(sid)
	var dl = data.get("discovered_landmarks", [])
	discovered_landmarks = []
	last_travel_label = ""
	if typeof(dl) == TYPE_ARRAY:
		for d in dl:
			var did := str(d)
			if did != "" and did not in discovered_landmarks:
				discovered_landmarks.append(did)
	last_travel_label = str(data.get("last_travel_label", ""))
	favorite_landmark = str(data.get("favorite_landmark", "")).strip_edges()
	checkpoint_checks = data.get("checkpoint_checks", {})
	checkpoint_date = data.get("checkpoint_date", "")
	last_daily_reminder_date = str(data.get("last_daily_reminder_date", ""))
	created_at = int(data.get("created_at", 0))
	unlocked_week = int(data.get("unlocked_week", 1))
	slot_label = str(data.get("slot_label", ""))
	consumable_charges = data.get("consumable_charges", {})
	if typeof(consumable_charges) != TYPE_DICTIONARY:
		consumable_charges = {}
	consumable_cd = 0.0
	_ensure_pantry_defaults()
	_recalc_unlocked_week()
	_apply_starters()
	check_combat_item_unlocks()
	set_combat_target(null)
	if data.has("hp"):
		hp = clampi(int(data.get("hp", max_hp)), 1, max_hp)
	else:
		hp = max_hp
	state_changed.emit()
	hp_changed.emit(hp, max_hp)
	return true

func combat_level_for_xp(cxp: int) -> int:
	return mini(10, 1 + int(cxp / 50))

func add_xp(amount: int) -> void:
	xp += amount
	_recalc_level()
	state_changed.emit()

func _recalc_level() -> void:
	var thresholds: Array = [0, 100, 250, 450, 700, 1000, 1400, 1900]
	level = 1
	for i in range(thresholds.size()):
		if xp >= thresholds[i]:
			level = i + 1

func unlock_item(id: String) -> void:
	if id == "" or id in unlocked_items:
		return
	unlocked_items.append(id)
	var it: Dictionary = ItemDB.get_item(id)
	# Seed pantry stacks for newly unlocked combat food
	if str(it.get("slot", "")) == "consumable":
		var mx: int = int(it.get("max_stack", 5))
		if int(consumable_charges.get(id, 0)) < mx:
			consumable_charges[id] = mx
	toast.emit("Unlocked: %s" % it.get("name", id))
	state_changed.emit()


func check_combat_item_unlocks() -> void:
	## Grant items gated by combat_level_req once the threshold is met.
	## Consumables: combat level alone is enough (OR with unlock_quest_id via quest mastery).
	## Weapons/gear: if unlock_quest_id is also set, both gates must pass (AND).
	for iid in ItemDB.items:
		var it: Dictionary = ItemDB.items[iid]
		var req: int = int(it.get("combat_level_req", 0))
		if req <= 0:
			continue
		if combat_level < req:
			continue
		var qid: String = str(it.get("unlock_quest_id", ""))
		var is_food: bool = str(it.get("slot", "")) == "consumable"
		if (not is_food) and qid != "" and qid not in completed_quests:
			continue
		unlock_item(str(iid))

func equip_item(id: String) -> void:
	var item: Dictionary = ItemDB.get_item(id)
	if item.is_empty() or id not in unlocked_items:
		return
	var req: int = int(item.get("combat_level_req", 0))
	if req > 0 and combat_level < req:
		toast.emit("Need Combat Lv %d to equip %s." % [req, item.get("name", id)])
		return
	var slot: String = item.get("slot", "")
	if slot == "" or slot == "consumable":
		if slot == "consumable":
			toast.emit("Food is used with Use / V — it is not worn as gear.")
		return
	equipped[slot] = id
	# Wave 48: equip confirmation toast (PIN 1234; mastery ≥80% unchanged)
	toast.emit("Equipped %s." % item.get("name", id))
	state_changed.emit()
	save_game()

func unequip_slot(slot: String) -> void:
	## Cape always falls back to Travel Cape so the armor slot stays clear.
	var prev_id = equipped.get(slot)
	var prev_name := ""
	if prev_id != null and str(prev_id) != "":
		prev_name = str(ItemDB.get_item(str(prev_id)).get("name", str(prev_id)))
	if slot == "cape":
		equipped["cape"] = "default_cape"
		if prev_name != "" and str(prev_id) != "default_cape":
			toast.emit("Unequipped %s — Travel Cape restored." % prev_name)
		elif prev_name != "":
			toast.emit("Travel Cape already on.")
	else:
		equipped[slot] = null
		if prev_name != "":
			toast.emit("Unequipped %s." % prev_name)
	state_changed.emit()
	save_game()

func unequip_all_slots() -> void:
	## Wave 61: unequip all worn gear with Travel Cape fallback (PIN 1234; mastery ≥80% unchanged).
	var cleared: Array = []
	for slot in ["head", "cape", "accessory", "weapon", "belt"]:
		var cur = equipped.get(slot)
		if cur == null or str(cur) == "":
			continue
		if slot == "cape" and str(cur) == "default_cape":
			continue
		var nm := str(ItemDB.get_item(str(cur)).get("name", str(cur)))
		if slot == "cape":
			equipped["cape"] = "default_cape"
		else:
			equipped[slot] = null
		cleared.append(nm)
	if cleared.is_empty():
		toast.emit("Nothing to unequip — Travel Cape already on.")
	else:
		toast.emit("Unequipped all · %d item(s) · Travel Cape restored." % cleared.size())
	state_changed.emit()
	save_game()

func count_worn_gear() -> int:
	## Wave 68: count worn pieces for unequip-all confirm (Travel Cape default does not count). PIN 1234; mastery ≥80% unchanged.
	var n := 0
	for slot in ["head", "cape", "accessory", "weapon", "belt"]:
		var cur = equipped.get(slot)
		if cur == null or str(cur) == "":
			continue
		if slot == "cape" and str(cur) == "default_cape":
			continue
		n += 1
	return n

func get_weapon_stats() -> Dictionary:
	var wid = equipped.get("weapon")
	if wid == null:
		return {"damage": int(EnemyDB.base_combat.get("damage", 2)), "accuracy": float(EnemyDB.base_combat.get("accuracy", 0.7))}
	var item := ItemDB.get_item(str(wid))
	return {"damage": int(item.get("damage", 5)), "accuracy": float(item.get("accuracy", 0.8))}


func get_defense() -> int:
	## Light wholesome defense: a little from combat level + cape/head gear with defense.
	return int(get_defense_breakdown().get("total", 0))

func get_defense_breakdown() -> Dictionary:
	## Clear armor readout for inventory: level soft armor + gear by slot.
	var level_def: int = mini(2, int(maxi(0, combat_level - 1) / 3))
	var by_slot: Dictionary = {"head": 0, "cape": 0, "accessory": 0, "belt": 0}
	var gear: int = 0
	for slot in ["cape", "head", "accessory", "belt"]:
		var iid = equipped.get(slot)
		if iid == null:
			continue
		var it := ItemDB.get_item(str(iid))
		var d: int = int(it.get("defense", 0))
		by_slot[slot] = d
		gear += d
	# Soft cap 7 so late feast cloaks (+3) and crowns can matter together with
	# combat-level soft armor, without making hits vanish (damage still floors at 1).
	var raw: int = level_def + gear
	var total: int = clampi(raw, 0, 7)
	return {
		"level": level_def,
		"gear": gear,
		"raw": raw,
		"cap": 7,
		"total": total,
		"by_slot": by_slot,
	}

func mark_aggro_tutorial() -> void:
	if seen_aggro_tutorial:
		return
	seen_aggro_tutorial = true
	toast.emit("Yellow ring means a creature noticed you — walk away, or wait and it may approach.")
	save_game()

func mark_combat_tutorial(silent: bool = false) -> bool:
	## Returns true if this was the first fight tip.
	if seen_combat_tutorial:
		return false
	seen_combat_tutorial = true
	if not silent:
		toast.emit("First fight: auto-attacks tick softly. Click empty ground or walk away to leave.")
	save_game()
	return true


func has_landmark_discovered(landmark_id: String) -> bool:
	return landmark_id != "" and landmark_id in discovered_landmarks

func mark_landmark_discovered(landmark_id: String) -> bool:
	## Remember forever. Returns true if this was the first discovery.
	if landmark_id == "" or has_landmark_discovered(landmark_id):
		return false
	discovered_landmarks.append(landmark_id)
	save_game()
	return true


func note_last_travel(label: String) -> void:
	## Wave 34: remember last soft-travel destination for Travel menu mark.
	last_travel_label = str(label).strip_edges()
	save_game()

func has_landmark_greeted(landmark_id: String) -> bool:
	return landmark_id != "" and landmark_id in greeted_landmarks

func mark_landmark_greeted(landmark_id: String) -> void:
	## Remember this landmark was greeted for the current visit (saved across sessions).
	if landmark_id == "" or landmark_id in greeted_landmarks:
		return
	greeted_landmarks.append(landmark_id)
	save_game()

func clear_landmark_greeted(landmark_id: String) -> void:
	## Left the zone — next approach may greet again.
	if landmark_id == "" or landmark_id not in greeted_landmarks:
		return
	greeted_landmarks.erase(landmark_id)
	save_game()


func get_week_unlock_progress() -> Dictionary:
	## Week unlock bar: unlocked_week / 36.
	var uw: int = clampi(unlocked_week, 0, 36)
	var pct: int = int(round(float(uw) / 36.0 * 100.0)) if 36 > 0 else 0
	return {"current": uw, "total": 36, "percent": pct}


func get_quest_mastery_progress() -> Dictionary:
	## Quest mastery bar: completed_quests.size() / QuestDB.quests.size().
	var done: int = completed_quests.size()
	var total: int = QuestDB.quests.size()
	var pct: int = int(round(float(done) / float(total) * 100.0)) if total > 0 else 0
	return {"current": done, "total": total, "percent": pct}


func get_year_progress_note() -> String:
	## Combined parent/journal line: week unlock X% · quests mastered Y%.
	var w: Dictionary = get_week_unlock_progress()
	var q: Dictionary = get_quest_mastery_progress()
	return "Year: week unlock %d%% · quests mastered %d%%" % [int(w["percent"]), int(q["percent"])]


func get_parent_export_line() -> String:
	## Wave 30/44: one plain line for parents to copy (week unlock + year mastery % + needs-help count).
	var w: Dictionary = get_week_unlock_progress()
	var q: Dictionary = get_quest_mastery_progress()
	var help_n: int = needs_help_quests().size() if has_method("needs_help_quests") else 0
	var day: Dictionary = get_school_day() if has_method("get_school_day") else {}
	var today_bit := "Today %d/%d" % [int(day.get("done", 0)), int(day.get("goal", DAILY_LESSON_GOAL))]
	var next_bit := str(day.get("next_title", "")).strip_edges()
	if next_bit != "":
		today_bit += " · next %s" % next_bit
	return "Week unlock %d/36 (%d%%) · Year mastery %d%% · Needs help: %d · %s" % [
		int(w.get("current", unlocked_week)), int(w.get("percent", 0)), int(q.get("percent", 0)), help_n, today_bit
	]


func _maybe_once_toast(flag: String, message: String) -> bool:
	## Shared once-per-save toast gate (PIN stays 1234; mastery ≥80%).
	if bool(get(flag)):
		return false
	set(flag, true)
	toast.emit(message)
	save_game()
	return true


func maybe_wave_50_toast() -> void:
	## Wave 50: once-per-save toast celebrating polish tip (PIN stays 1234; mastery ≥80%).
	_maybe_once_toast("seen_wave_50_toast", "Wave 50 polish · soft-aggro names show a countdown · fountain mist + decade festival sparkles · Foes near the minimap.")


func maybe_wave_51_toast() -> void:
	## Wave 51: once-per-save toast (PIN stays 1234; mastery ≥80%).
	_maybe_once_toast("seen_wave_51_toast", "Wave 51 polish · pin a Travel ★ fav · rain soft-splashes on hall eaves · journal opens with a flourish · XP floats bloom by size.")


func maybe_wave_52_toast() -> void:
	## Wave 52: once-per-save toast (PIN stays 1234; mastery ≥80%).
	_maybe_once_toast("seen_wave_52_toast", "Wave 52 polish · soft wind chimes by the halls · soft-defeat camera settles gently · wardrobe colors pulse · journal Open-only + locked weeks.")


func maybe_wave_53_toast() -> void:
	## Wave 53: once-per-save toast (PIN stays 1234; mastery ≥80%).
	_maybe_once_toast("seen_wave_53_toast", "Wave 53 polish · denser fireflies at the Prayer Garden · mute plate soft-pulses · soft-pull ring warms as it nears · bag shows Def · Magnolia Beaver in the wilds.")


func maybe_wave_54_toast() -> void:
	## Wave 54: once-per-save toast (PIN stays 1234; mastery ≥80%).
	_maybe_once_toast("seen_wave_54_toast", "Wave 54 polish · soft brook sparkles by the water · Travel opens with a flourish · near-miss chime is softer · clearer wrong-PIN toast · Olive Owl in the wilds.")


func maybe_wave_55_toast() -> void:
	## Wave 55: once-per-save toast (PIN stays 1234; mastery ≥80%).
	_maybe_once_toast("seen_wave_55_toast", "Wave 55 polish · soft campfire ember pops · Year chip brightens on week unlock · soft-defeat mist lingers · save slot # beside nickname · Palm Pika in the wilds.")


func maybe_wave_56_toast() -> void:
	## Wave 56: once-per-save toast (PIN stays 1234; mastery ≥80%).
	_maybe_once_toast("seen_wave_56_toast", "Wave 56 polish · denser maple leaf fall at Maple Copse · compass tick pulses near landmarks · mastery toasts name the week · ★ fav sits atop Travel · Lemon Lemming in the wilds.")


func maybe_wave_57_toast() -> void:
	## Wave 57: once-per-save toast (PIN stays 1234; mastery ≥80%).
	_maybe_once_toast("seen_wave_57_toast", "Wave 57 polish · reeds sway soft at Reed Pool · clearer Ready mint-gold flash · soft-defeat names Fountain · Open-only count in journal · Cherry Chinchilla in the wilds.")


func maybe_wave_58_toast() -> void:
	## Wave 58: once-per-save toast (PIN stays 1234; mastery ≥80%).
	_maybe_once_toast("seen_wave_58_toast", "Wave 58 polish · thistles sway soft at Thistle Rise · clearer soft-aggro mid toast · stronger wardrobe equip sparkle · Parent year % on child line · Plum Porcupine in the wilds.")


func maybe_wave_59_toast() -> void:
	## Wave 59: once-per-save toast (PIN stays 1234; mastery ≥80%).
	_maybe_once_toast("seen_wave_59_toast", "Wave 59 polish · amber knoll glows soft at dusk · mute notes the weather · XP floats stack on multi-foe · ★ fav paces on HUD when far · Peach Puffin in the wilds.")


func maybe_wave_60_toast() -> bool:
	## Wave 60: once-per-save toast + soft festival confetti cue (PIN stays 1234; mastery ≥80%).
	## Returns true when newly shown so callers can play one-shot confetti.
	return _maybe_once_toast("seen_wave_60_toast", "Wave 60 polish · soft festival confetti on load · landmark approach names paces · journal shows total ★ · Fig Finch in the wilds.")


func maybe_wave_61_toast() -> bool:
	## Wave 61: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_61_toast", "Wave 61 polish · willows weep-sway at Willow Bend · clearer empty pantry H hint · Unequip all confirm · Grape Gecko in the wilds.")


func maybe_wave_62_toast() -> bool:
	## Wave 62: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_62_toast", "Wave 62 polish · ferns sway soft at Fern Dell · clearer soft-travel fade names the landmark · denser pull-back sparkle · Open-only remembers · Apricot Armadillo in the wilds.")


func maybe_wave_63_toast() -> bool:
	## Wave 63: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_63_toast", "Wave 63 polish · heather sways soft at Heather Heath · clearer Year chip shows mastery % · soft hall light dip · PIN last-4 hint · Blueberry Bunny in the wilds.")


func maybe_wave_64_toast() -> bool:
	## Wave 64: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_64_toast", "Wave 64 polish · Stone Arch glows soft at dusk · clearer soft-aggro ring when Def high · ★ fav chip short names · travel search remembers · Cranberry Capybara in the wilds.")


func maybe_wave_65_toast() -> bool:
	## Wave 65: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_65_toast", "Wave 65 polish · Quiet Cross lantern glows soft at dusk · clearer first-fight tip names the foe · Year chip shows weather letter · pantry Ready chimes · Raspberry Ram in the wilds.")


func maybe_wave_66_toast() -> bool:
	## Wave 66: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_66_toast", "Wave 66 polish · Birch Rest fireflies wink at dusk · clearer arrival toast with short name · softer victory sparkle · Open-only sticky shows count · Travel marks nearest · Strawberry Stoat in the wilds.")


func maybe_wave_67_toast() -> bool:
	## Wave 67: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_67_toast", "Wave 67 polish · Reed Pool ripple gleam at dusk · clearer low-HP toast · softer campfire smoke · Foes chip pulses when count rises · Needs Help shows days since last try · Blackberry Bear in the wilds.")

func maybe_wave_68_toast() -> bool:
	## Wave 68: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_68_toast", "Wave 68 polish · Willow Bend leaf drift at dusk · clearer near-miss toast with quest title · soft fountain-rest chime · Unequip-all confirm shows piece count · Year chip gold flash on mastery bump · Guava Goat in the wilds.")


func maybe_wave_69_toast() -> bool:
	## Wave 69: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_69_toast", "Wave 69 polish · Fern Dell frond drift at dusk · clearer ✦ landmark chip with paces · softer rain-canopy drip · Mastered ★ filter shows count · nickname chip pulses on save · Kiwi Koala in the wilds.")


func maybe_wave_70_toast() -> bool:
	## Wave 70: once-per-save polish tip (PIN stays 1234; mastery ≥80%). Milestone wave.
	return _maybe_once_toast("seen_wave_70_toast", "Wave 70 milestone · Heather Heath bloom drift + stronger dusk sway · Parent mastery bar shows ★ beside % · Mango Mongoose in the wilds.")


func maybe_wave_71_toast() -> bool:
	## Wave 71: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_71_toast", "Wave 71 polish · Thistle Rise bloom drift + stronger dusk sway · clearer daily checkpoint reminder · pantry Bread flashes when low · Papaya Panda in the wilds.")


func maybe_wave_72_toast() -> bool:
	## Wave 72: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_72_toast", "Wave 72 polish · Maple Copse leaf drift at dusk + softer edge fog · clearer Fountain rest toast · Open-only sticky shows weeks · Coconut Crab in the wilds.")


func maybe_wave_73_toast() -> bool:
	## Wave 73: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_73_toast", "Wave 73 polish · Amber Knoll amber-glow at dusk + brook/puddle hush · clearer quest complete toast · Parent empty-week warmer · Lime Llama in the wilds.")


func maybe_wave_74_toast() -> bool:
	## Wave 74: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_74_toast", "Wave 74 polish · Cedar Hollow needle drift at dusk + plaza lantern sync · clearer foe-fall sparkle · Year chip week of 36 · Melon Moose in the wilds.")


func maybe_wave_75_toast() -> bool:
	## Wave 75: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_75_toast", "Wave 75 polish · Stone Arch limestone dust at dusk + clearer first-discovery toast · soft wind leaf polish · Parent Needs Help oldest-first · Quince Quokka in the wilds.")


func maybe_wave_76_toast() -> bool:
	## Wave 76: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_76_toast", "Wave 76 polish · Quiet Cross lantern moths at dusk + soft night cricket hush · Def flash on new armor · Foes chip ↑ · Watermelon Wallaby in the wilds.")


func maybe_wave_77_toast() -> bool:
	## Wave 77: once-per-save polish tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_wave_77_toast", "Wave 77 polish · denser Birch Rest fireflies at dusk + Soft Travel arrival · ★ fav paces · Honeydew Hamster in the wilds.")


func maybe_refine_178_toast() -> bool:
	## v1.78 refine: once-per-save look / HUD / Parent tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_refine_178_toast", "Village look, HUD, and Parent screen refined — clearer people, plaza, and a quieter dashboard.")


func maybe_refine_181_toast() -> bool:
	## v1.81 UI: once-per-save menus / HUD / Parent tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_refine_181_toast", "Menus and Parent screen cleaned up — quieter HUD, clearer year and mastery, easier Parent PIN lock.")


func maybe_bugs_182_toast() -> bool:
	## v1.82 bugs: once-per-save tip (PIN stays 1234; mastery ≥80%).
	return _maybe_once_toast("seen_bugs_182_toast", "Tip: one menu at a time. Esc closes it.")


func maybe_curriculum_183_toast() -> bool:
	## v1.83 curriculum: first-session / next-lesson tip (PIN stays 1234; mastery ≥80%).
	var next: Dictionary = get_next_up()
	var msg := "Welcome! Journal (J) shows your next lesson. Walk to a guild mentor and press F."
	if str(next.get("quest_id", "")) != "":
		msg = "Next lesson: talk to %s — %s. Journal (J) keeps this list." % [
			str(next.get("mentor", "a guild mentor")), str(next.get("title", "your next lesson"))
		]
		if is_early_curriculum_save():
			msg = "Welcome! Start with %s at %s — “%s”. Press J anytime to see what’s next." % [
				str(next.get("mentor", "Steward Guide")),
				str(next.get("hall", "Word & Worship")),
				str(next.get("title", "The First Word")),
			]
	return _maybe_once_toast("seen_curriculum_183_toast", msg)


func quiet_legacy_polish_toasts() -> void:
	## New / early saves should not replay Wave 50–77 polish tips (first session stays about lessons).
	for f in ONCE_TOAST_FLAGS:
		if str(f) == "seen_curriculum_183_toast":
			continue
		set(f, true)


func is_early_curriculum_save() -> bool:
	return unlocked_week <= 1 and completed_quests.size() < 2


func mentor_name(guild: String) -> String:
	return str(MENTORS.get(guild, {}).get("name", GUILDS.get(guild, {}).get("name", "guild mentor")))


func mentor_hall(guild: String) -> String:
	return str(MENTORS.get(guild, {}).get("hall", GUILDS.get(guild, {}).get("name", "a guild hall")))


func _is_raid_quest(qid: String, title: String = "") -> bool:
	var idl := qid.to_lower()
	var tl := title.to_lower()
	return "raid" in idl or "feast" in idl or "supreme" in idl or "raid" in tl or "feast" in tl


func _guild_lesson_rank(guild: String, qid: String, title: String) -> int:
	if _is_raid_quest(qid, title):
		return 50
	match guild:
		"bible":
			return 0
		"math":
			return 1
		"la":
			return 2
		"science":
			return 3
		"history":
			return 4
		_:
			return 9


func _short_quest_title(title: String, qid: String = "") -> String:
	var t := title.strip_edges()
	if t == "":
		t = qid
	if t.length() > 32:
		return t.substr(0, 30) + "…"
	return t


func get_next_up() -> Dictionary:
	## Single "what to do next" pick for Journal, NPC, Parent, and toasts.
	var empty := {
		"quest_id": "", "title": "", "week": unlocked_week, "day": 0, "guild": "",
		"mentor": "", "hall": "", "status": "done", "percent": -1.0, "subject": "",
		"raid": false,
	}
	var rows: Array = []
	for q in QuestDB.all_quests():
		if typeof(q) != TYPE_DICTIONARY:
			continue
		var qid: String = str(q.get("id", ""))
		if qid == "":
			continue
		if qid in completed_quests:
			continue
		if not is_quest_unlocked(qid):
			continue
		var week_n: int = int(q.get("week", 1))
		var day_n: int = int(q.get("day", 1))
		var title_s: String = str(q.get("title", qid))
		var guild_s: String = str(q.get("guild", ""))
		var ap: float = get_latest_attempt_percent(qid) if has_method("get_latest_attempt_percent") else -1.0
		var attempted: bool = ap >= 0.0
		var raid: bool = _is_raid_quest(qid, title_s)
		var rank := 3
		if week_n == unlocked_week and attempted:
			rank = 0
		elif week_n == unlocked_week:
			rank = 1
		elif attempted:
			rank = 2
		if raid:
			rank += 1
		rows.append({
			"q": q, "qid": qid, "rank": rank, "day": day_n, "week": week_n,
			"gkey": _guild_lesson_rank(guild_s, qid, title_s), "pct": ap,
			"title": title_s, "guild": guild_s, "raid": raid, "subject": str(q.get("subject_label", "")),
		})
	if rows.is_empty():
		return empty
	rows.sort_custom(func(a, b):
		if int(a["rank"]) != int(b["rank"]):
			return int(a["rank"]) < int(b["rank"])
		if int(a["week"]) != int(b["week"]):
			return int(a["week"]) < int(b["week"])
		if int(a["day"]) != int(b["day"]):
			return int(a["day"]) < int(b["day"])
		if int(a["gkey"]) != int(b["gkey"]):
			return int(a["gkey"]) < int(b["gkey"])
		return str(a["title"]) < str(b["title"])
	)
	var pick: Dictionary = rows[0]
	var q: Dictionary = pick["q"]
	var guild_s: String = str(pick["guild"])
	var ap2: float = float(pick["pct"])
	var status := "practice" if ap2 >= 0.0 else "start"
	if bool(pick["raid"]):
		status = "raid"
	return {
		"quest_id": str(pick["qid"]),
		"title": str(q.get("title", pick["qid"])),
		"week": int(pick["week"]),
		"day": int(pick["day"]),
		"guild": guild_s,
		"mentor": mentor_name(guild_s),
		"hall": mentor_hall(guild_s),
		"status": status,
		"percent": ap2,
		"subject": str(q.get("subject_label", "")),
		"raid": bool(pick["raid"]),
	}


func get_next_up_line() -> String:
	var n: Dictionary = get_next_up()
	if str(n.get("quest_id", "")) == "":
		if unlocked_week >= 36:
			return "All open lessons mastered ★. Festival of Lumens awaits!"
		return "This week’s open lessons are mastered ★. The Friday Raid (or 4★) opens the next week."
	var title_s := _short_quest_title(str(n.get("title", "")), str(n.get("quest_id", "")))
	var mentor_s := str(n.get("mentor", "a guild mentor"))
	match str(n.get("status", "start")):
		"practice":
			var pct: int = percent_to_int(float(n.get("percent", 0.0)))
			return "Next: practice again with %s — %s (%d%%, need 80%%)." % [mentor_s, title_s, pct]
		"raid":
			return "Next: Friday Raid with %s — %s (80%% unlocks next week)." % [mentor_s, title_s]
		_:
			return "Next: talk to %s — %s" % [mentor_s, title_s]


func get_school_day() -> Dictionary:
	## Calendar-day lesson goal (usually 2) so a school sitting feels on track.
	_roll_daily_checkpoint()
	var week_n: int = clampi(unlocked_week, 1, 36)
	var open_n := 0
	var week_total := 0
	var week_mastered := 0
	var suggested_day := 99
	for q in QuestDB.quests_for_week(week_n) if QuestDB.has_method("quests_for_week") else []:
		week_total += 1
		var qid: String = str(q.get("id", ""))
		if qid in completed_quests:
			week_mastered += 1
		else:
			open_n += 1
			suggested_day = mini(suggested_day, int(q.get("day", 1)))
	if suggested_day == 99:
		suggested_day = 5
	var ids: Array = _mastered_today_ids()
	var done: int = ids.size()
	var goal: int = DAILY_LESSON_GOAL
	if open_n <= 0:
		goal = 0
	else:
		goal = clampi(mini(DAILY_LESSON_GOAL, open_n), 1, DAILY_LESSON_GOAL)
	var complete: bool = (open_n <= 0) or (done >= goal and goal > 0)
	var next: Dictionary = get_next_up()
	return {
		"week": week_n,
		"day": suggested_day,
		"done": done,
		"goal": goal,
		"open": open_n,
		"week_mastered": week_mastered,
		"week_total": week_total,
		"complete": complete,
		"next_id": str(next.get("quest_id", "")),
		"next_title": str(next.get("title", "")),
		"next_mentor": str(next.get("mentor", "")),
	}


func get_school_day_line() -> String:
	var d: Dictionary = get_school_day()
	var week_n: int = int(d.get("week", unlocked_week))
	var done: int = int(d.get("done", 0))
	var goal: int = int(d.get("goal", DAILY_LESSON_GOAL))
	if int(d.get("open", 1)) <= 0:
		return "Today’s school day ★ Week %d is mastered. Parent can see Needs Help." % week_n
	if bool(d.get("complete", false)):
		return "Today’s school day ★ %d/%d lessons — on track. Well done!" % [done, maxi(goal, done)]
	return "Today’s school day · Week %d · %d/%d lessons" % [week_n, done, maxi(1, goal)]


func format_needs_help_row(h: Dictionary) -> String:
	## Actionable parent line: week, subject, score, who to sit with.
	var q: Dictionary = QuestDB.get_quest(str(h.get("quest_id", "")))
	var week_n: int = int(q.get("week", h.get("week", 0)))
	var guild: String = str(q.get("guild", h.get("guild", "")))
	var guild_short: String = str(GUILDS.get(guild, {}).get("short", guild)).to_upper()
	var title_s := _short_quest_title(str(h.get("title", q.get("title", h.get("quest_id", "?")))), str(h.get("quest_id", "")))
	var pct: int = percent_to_int(float(h.get("percent", 0))) if has_method("percent_to_int") else int(round(float(h.get("percent", 0)) * 100.0))
	var mentor_s := mentor_name(guild)
	return "WEEK %d · %s — %s · %d%% (%d/%d) · Sit with %s" % [
		week_n, guild_short, title_s, pct, int(h.get("correct", 0)), int(h.get("total", 0)), mentor_s
	]


func _roll_daily_checkpoint() -> void:
	var today := Time.get_date_string_from_system()
	if checkpoint_date == today:
		if typeof(checkpoint_checks) != TYPE_DICTIONARY:
			checkpoint_checks = {}
		if not checkpoint_checks.has("mastered_ids"):
			checkpoint_checks["mastered_ids"] = []
		return
	checkpoint_date = today
	checkpoint_checks = {"mastered_ids": [], "week": unlocked_week}


func _mastered_today_ids() -> Array:
	if typeof(checkpoint_checks) != TYPE_DICTIONARY:
		return []
	var raw = checkpoint_checks.get("mastered_ids", [])
	var out: Array = []
	if typeof(raw) == TYPE_ARRAY:
		for v in raw:
			var s := str(v)
			if s != "" and s not in out:
				out.append(s)
	return out


func note_quest_for_checkpoint(quest_id: String, mastered: bool) -> Dictionary:
	_roll_daily_checkpoint()
	var ids: Array = _mastered_today_ids()
	var done_before: int = ids.size()
	if mastered and quest_id != "" and quest_id not in ids:
		ids.append(quest_id)
	checkpoint_checks["mastered_ids"] = ids
	checkpoint_checks["week"] = unlocked_week
	var after: Dictionary = get_school_day()
	var goal: int = int(after.get("goal", DAILY_LESSON_GOAL))
	if goal <= 0:
		goal = DAILY_LESSON_GOAL
	var done_after: int = ids.size()
	var crossed: bool = mastered and done_before < goal and done_after >= goal
	return {
		"crossed_goal": crossed,
		"complete": bool(after.get("complete", false)) or crossed,
		"done": done_after,
		"goal": goal,
	}


func set_favorite_landmark(label: String) -> void:
	## Wave 51: pin/favorite one landmark for Travel (T) ★ fav (PIN 1234; mastery ≥80%).
	var lab := str(label).strip_edges()
	if lab == "":
		return
	if favorite_landmark == lab:
		favorite_landmark = ""
		toast.emit("★ Fav cleared.")
	else:
		favorite_landmark = lab
		toast.emit("★ Fav pinned · %s" % lab)
	save_game()
	state_changed.emit()


func maybe_festival_decade(pct: int) -> bool:
	## Wave 50: soft festival when year % hits a multiple of 10. Returns true if newly celebrated.
	if pct < 10 or pct > 100:
		return false
	if pct % 10 != 0:
		return false
	var decade: int = pct
	if decade in festival_decades_seen:
		return false
	festival_decades_seen.append(decade)
	toast.emit("✦ Festival sparkle · Year · %d%% — a soft tenth-mark celebration!" % decade)
	save_game()
	return true


func maybe_daily_checkpoint_reminder() -> void:
	## Wave 71 / v1.83: once-per-calendar-day toast for the school-day checkpoint (PIN stays 1234).
	_roll_daily_checkpoint()
	var today := Time.get_date_string_from_system()
	if last_daily_reminder_date == today:
		return
	last_daily_reminder_date = today
	var day_line := get_school_day_line()
	var next_line := get_next_up_line()
	# Keep "Daily checkpoint · open Parent" so older smoke scans still pass.
	toast.emit("Daily checkpoint · open Parent or Journal (J). " + day_line + ". " + next_line)
	save_game()


func get_year_progress_percent() -> int:
	## Compact HUD chip: prefer quest mastery %, fall back to week unlock %.
	var q: Dictionary = get_quest_mastery_progress() if has_method("get_quest_mastery_progress") else {}
	if int(q.get("total", 0)) > 0:
		return int(q.get("percent", 0))
	var w: Dictionary = get_week_unlock_progress() if has_method("get_week_unlock_progress") else {}
	return int(w.get("percent", 0))


func set_combat_target(enemy: Node) -> void:
	combat_target = enemy
	combat_target_changed.emit(enemy)

func take_damage(amount: int) -> void:
	var dealt: int = maxi(0, amount)
	hp = maxi(0, hp - dealt)
	hp_changed.emit(hp, max_hp)
	if dealt > 0:
		hurt.emit(dealt)
		_maybe_low_hp_toast()
	if hp <= 0:
		_soft_defeat()

func _maybe_low_hp_toast() -> void:
	## Wave 67: clearer low-HP toast with plain wording (RuneScape-chunky, wholesome; no cheesy combat labels).
	if max_hp <= 0:
		return
	var frac: float = float(hp) / float(max_hp)
	if frac > 0.28:
		_low_hp_toast_armed = true
		return
	if hp <= 0:
		return
	if not _low_hp_toast_armed:
		return
	_low_hp_toast_armed = false
	toast.emit("HP low · press V to eat · H for Fountain rest")  # Wave 76: clearer low-HP toast with V/H hints

func heal_full() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	_low_hp_toast_armed = true  # Wave 67: re-arm low-HP toast after full heal

func heal(amount: int) -> int:
	var before: int = hp
	hp = mini(max_hp, hp + maxi(0, amount))
	hp_changed.emit(hp, max_hp)
	if max_hp > 0 and float(hp) / float(max_hp) > 0.28:
		_low_hp_toast_armed = true  # Wave 67: re-arm low-HP toast after recovery
	return hp - before

func _ensure_pantry_defaults() -> void:
	for id in ItemDB.starter_ids():
		var it: Dictionary = ItemDB.get_item(id)
		if str(it.get("slot", "")) != "consumable":
			continue
		var mx: int = int(it.get("max_stack", 5))
		if id not in consumable_charges:
			consumable_charges[id] = mx
		else:
			consumable_charges[id] = clampi(int(consumable_charges[id]), 0, mx)

func pantry_count(item_id: String) -> int:
	return int(consumable_charges.get(item_id, 0))

func pantry_max(item_id: String) -> int:
	var it: Dictionary = ItemDB.get_item(item_id)
	return int(it.get("max_stack", 5))

func refill_pantry(announce: bool = false) -> void:
	_ensure_pantry_defaults()
	var changed := false
	# Refill every unlocked consumable (starters + mid-game food like Trail Rations)
	var ids: Array = []
	for id in unlocked_items:
		ids.append(id)
	for id in ItemDB.starter_ids():
		if id not in ids:
			ids.append(id)
	for id in ids:
		var it: Dictionary = ItemDB.get_item(str(id))
		if str(it.get("slot", "")) != "consumable":
			continue
		var mx: int = int(it.get("max_stack", 5))
		if int(consumable_charges.get(id, 0)) < mx:
			consumable_charges[id] = mx
			changed = true
	if changed:
		if announce:
			toast.emit("Fountain pantry refilled — food and water restocked.")
		state_changed.emit()
		save_game()

func use_consumable(item_id: String) -> bool:
	var item: Dictionary = ItemDB.get_item(item_id)
	if item.is_empty() or str(item.get("slot", "")) != "consumable":
		return false
	if item_id not in unlocked_items:
		return false
	var heal_amt: int = int(item.get("heal", 0))
	if heal_amt <= 0:
		return false
	if hp >= max_hp:
		toast.emit("Already at full health — save your food.")
		return false
	_ensure_pantry_defaults()
	var left: int = int(consumable_charges.get(item_id, 0))
	if left <= 0:
		toast.emit("%s pantry empty — press H for Fountain to refill your stacks." % item.get("name", item_id))  # Wave 61: clearer food empty toast with H hint
		return false
	if consumable_cd > 0.05:
		toast.emit("Give it a moment (%.1fs)." % consumable_cd)
		return false
	var gained: int = heal(heal_amt)
	consumable_charges[item_id] = left - 1
	consumable_cd = float(item.get("cooldown", 1.5))
	if gained > 0:
		heal_tick.emit(gained)
	# Starter food stays unlocked; stacks refill at the fountain.
	toast.emit("Ate %s — healed +%d HP (now %d/%d) · %d left." % [item.get("name", item_id), gained, hp, max_hp, int(consumable_charges[item_id])])
	AudioBus.play_ui()
	state_changed.emit()
	save_game()
	return true


func use_best_consumable() -> bool:
	## Hotkey food: pick unlocked pantry item with charges, off cooldown, highest heal.
	if hp >= max_hp:
		toast.emit("Already at full health — save your food.")
		return false
	if consumable_cd > 0.05:
		toast.emit("Give it a moment (%.1fs)." % consumable_cd)
		return false
	_ensure_pantry_defaults()
	var best_id := ""
	var best_heal := -1
	for id in unlocked_items:
		var it: Dictionary = ItemDB.get_item(str(id))
		if str(it.get("slot", "")) != "consumable":
			continue
		var heal_amt: int = int(it.get("heal", 0))
		if heal_amt <= 0:
			continue
		if int(consumable_charges.get(id, 0)) <= 0:
			continue
		if heal_amt > best_heal:
			best_heal = heal_amt
			best_id = str(id)
	if best_id == "":
		toast.emit("Pantry empty — rest at the fountain (H) to refill food & water.")  # Wave 39: clearer empty pantry toast
		return false
	return use_consumable(best_id)

func peek_best_consumable() -> Dictionary:
	## HUD readout: best eatable food (highest heal with charges), plus cooldown.
	_ensure_pantry_defaults()
	var best_id := ""
	var best_heal := -1
	var stacks: Array = []
	for id in unlocked_items:
		var it: Dictionary = ItemDB.get_item(str(id))
		if str(it.get("slot", "")) != "consumable":
			continue
		var cnt: int = int(consumable_charges.get(id, 0))
		var heal_amt: int = int(it.get("heal", 0))
		if heal_amt <= 0:
			continue
		# Wave 48: include max so HUD can show clearer stack N/M counts
		stacks.append({"id": str(id), "name": str(it.get("name", id)), "count": cnt, "max": pantry_max(str(id)), "heal": heal_amt})
		if cnt <= 0:
			continue
		if heal_amt > best_heal:
			best_heal = heal_amt
			best_id = str(id)
	var best: Dictionary = {}
	if best_id != "":
		var bit: Dictionary = ItemDB.get_item(best_id)
		best = {
			"id": best_id,
			"name": str(bit.get("name", best_id)),
			"heal": int(bit.get("heal", 0)),
			"count": int(consumable_charges.get(best_id, 0)),
		}
	return {"best": best, "stacks": stacks, "cooldown": consumable_cd}

func clear_soft_combat(announce: bool = false) -> void:
	## Leave soft combat / yellow pull without a defeat.
	var had: bool = combat_target != null and is_instance_valid(combat_target)
	set_combat_target(null)
	soft_combat_cleared.emit()
	if announce and had:
		toast.emit("Combat calm — you are safe by the fountain.")

func rest_at_fountain(announce: bool = true) -> void:
	## Soft rest: clear combat status, refill pantry, brief HP regen ticks.
	## Wave 72: clearer Fountain rest toast (RuneScape-chunky, wholesome; no cheesy combat labels).
	## v1.82: debounce travel-to-fountain + Area3D body_entered so rest does not double-toast.
	var now_ms: int = Time.get_ticks_msec()
	if _fountain_rest_ms > 0 and now_ms - _fountain_rest_ms < 1800:
		return
	_fountain_rest_ms = now_ms
	clear_soft_combat(false)
	refill_pantry(announce)
	# Wave 68: soft fountain-rest chime (RuneScape-chunky, wholesome; respects mute)
	if AudioBus.has_method("play_fountain_rest_chime"):
		AudioBus.play_fountain_rest_chime()
	if hp < max_hp:
		_fountain_regen_left = 3
		_fountain_regen_timer = 0.05
		if announce:
			toast.emit("Fountain rest · HP returning gently · pantry topped up.")
	elif announce:
		# refill_pantry already toasted if stocks changed; still confirm calm
		toast.emit("Fountain rest · calm and ready.")

func _tick_fountain_regen(delta: float) -> void:
	if _fountain_regen_left <= 0:
		return
	_fountain_regen_timer -= delta
	if _fountain_regen_timer > 0.0:
		return
	_fountain_regen_timer = 0.45
	var gained: int = heal(3)
	_fountain_regen_left -= 1
	if gained > 0:
		heal_tick.emit(gained)
	if _fountain_regen_left <= 0 and hp >= max_hp:
		toast.emit("Fully rested.")

func _soft_defeat() -> void:
	# Wave 47: clearer soft-defeat HP restore numbers (toast + floating heal at fountain)
	var restored: int = maxi(1, max_hp - hp)
	# Wave 57: soft-defeat toast names Fountain landmark (RuneScape-chunky, wholesome; no cheesy combat labels)
	toast.emit("Soft defeat — rest safe at Fountain. +%d HP & pantry restored." % restored)
	position_xz = Vector2(0, 10)
	_fountain_regen_left = 0
	heal_full()
	refill_pantry(false)
	set_combat_target(null)
	soft_combat_cleared.emit()
	soft_defeated.emit()
	heal_tick.emit(restored)  # after soft_defeated so the float reads at the fountain
	state_changed.emit()
	save_game()

func record_quest_attempt(quest_id: String, correct: int, total: int) -> Dictionary:
	var safe_total: int = maxi(1, total)
	var pct: float = float(correct) / float(safe_total)
	# Integer ≥80% gate so 4/5 never misses mastery to float rounding (MASTERY_PCT stays 0.8).
	var mastered: bool = is_mastered_score(correct, total)
	var attempt: Dictionary = {
		"quest_id": quest_id,
		"correct": correct,
		"total": total,
		"percent": pct,
		"mastered": mastered,
		"timestamp": int(Time.get_unix_time_from_system()),
		"xp_awarded": 0,
		"lumens_awarded": 0,
	}
	quest_attempts.append(attempt)
	var quest: Dictionary = QuestDB.get_quest(quest_id)
	var base_xp: int = int(quest.get("xp_reward", 20))
	if mastered:
		if quest_id not in completed_quests:
			completed_quests.append(quest_id)
		# v1.84: denser mastery rewards — full XP + 2 guild lumens so every lesson feels worth finishing.
		add_xp(base_xp)
		attempt["xp_awarded"] = base_xp
		if quest.get("lumen_on_mastery", false):
			var g: String = quest.get("guild", "math")
			lumens[g] = int(lumens.get(g, 0)) + 2
			attempt["lumens_awarded"] = 2
		var unlock: String = str(quest.get("unlock_item_id", ""))
		if unlock != "":
			unlock_item(unlock)
		for bonus in quest.get("bonus_items", []):
			unlock_item(str(bonus))
		# Also grant any ItemDB entries keyed to this quest (mesh-variant weapons, etc.)
		# Consumables: quest alone unlocks (OR with combat-level path).
		# Weapons/gear with combat_level_req: both gates must pass (AND).
		for iid in ItemDB.items:
			var it: Dictionary = ItemDB.items[iid]
			if str(it.get("unlock_quest_id", "")) != quest_id:
				continue
			var is_food: bool = str(it.get("slot", "")) == "consumable"
			var req: int = int(it.get("combat_level_req", 0))
			if (not is_food) and req > 0 and combat_level < req:
				continue
			unlock_item(str(iid))
		# Wave 56/73 / v1.83: quest complete toast names the next lesson in plain words.
		var week_n: int = int(quest.get("week", unlocked_week))
		var short_title := _short_quest_title(str(quest.get("title", quest_id)), quest_id)
		var check: Dictionary = note_quest_for_checkpoint(quest_id, true)
		_recalc_unlocked_week()
		var next_line := get_next_up_line()
		toast.emit("Quest complete · %s · Week %d ★ · +%d XP. " % [short_title, week_n, base_xp] + next_line)
		if bool(check.get("crossed_goal", false)):
			toast.emit("School day on track ★ · %d lessons today. Open Parent to see Needs Help." % int(check.get("done", 0)))
		quest_mastered.emit(quest_id)
		AudioBus.play_quest_complete()
	else:
		# v1.84: progress XP on near-miss so attempting any lesson still pays (half of score share).
		var progress_xp: int = maxi(1, int(round(float(base_xp) * pct * 0.5)))
		add_xp(progress_xp)
		attempt["xp_awarded"] = progress_xp
		# Wave 68 / v1.83: near-miss toast + Needs Help pointer (Near miss — mastery smoke marker).
		var short_title := _short_quest_title(str(quest.get("title", quest_id)), quest_id)
		note_quest_for_checkpoint(quest_id, false)
		toast.emit("Near miss · %s · mastery %d%% (need ≥80%%) · +%d XP. Try the same mentor again — Parent shows Needs Help." % [short_title, percent_to_int(pct), progress_xp])
		if AudioBus.has_method("play_quest_near_miss"):
			AudioBus.play_quest_near_miss()  # Wave 54: softer than mastery chime
	save_game()
	state_changed.emit()
	return attempt

func get_latest_attempt_percent(quest_id: String) -> float:
	## Wave 36: latest attempt percent for journal QoL (−1 if never attempted). Mastery gate unchanged (≥80%).
	var found := false
	var latest := 0.0
	for a in quest_attempts:
		if str(a.get("quest_id", "")) != quest_id:
			continue
		found = true
		latest = float(a.get("percent", 0.0))
	return latest if found else -1.0


func percent_to_int(pct: float) -> int:
	## Rounded 0–100 so mastery 4/5 shows 80%, not 79%.
	return int(round(clampf(pct, 0.0, 1.0) * 100.0))


func mastery_percent_int(correct: int, total: int) -> int:
	return percent_to_int(float(correct) / float(maxi(1, total)))


func is_mastered_score(correct: int, total: int) -> bool:
	## Same ≥80% rule as MASTERY_PCT, without float truncation.
	return correct * 10 >= maxi(1, total) * 8


func needs_help_quests() -> Array:
	## Quests attempted but not mastered, or latest attempt < 80%
	var help: Array = []
	var latest: Dictionary = {}
	for a in quest_attempts:
		var qid: String = a["quest_id"]
		latest[qid] = a
	for qid in latest:
		var a = latest[qid]
		if not a.get("mastered", false):
			var q: Dictionary = QuestDB.get_quest(qid)
			var guild_s: String = str(q.get("guild", ""))
			help.append({
				"quest_id": qid,
				"title": q.get("title", qid),
				"percent": a.get("percent", 0),
				"correct": a.get("correct", 0),
				"total": a.get("total", 0),
				"timestamp": int(a.get("timestamp", 0)),
				"week": int(q.get("week", 0)),
				"guild": guild_s,
				"mentor": mentor_name(guild_s),
			})  # Wave 67: days-since for parent Needs Help
	return help

func verify_pin(pin: String) -> bool:
	return pin.strip_edges() == parent_pin


func _recalc_unlocked_week() -> void:
	## Progressive unlock: week N+1 opens after mastering week N raid review.
	## Full year Campaigns I–IV span weeks 1–36; clamp max unlock at 36.
	var week: int = 1
	var max_week: int = 36
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
	for w in range(1, max_week + 1):
		var raid_id: String = str(raid_gate.get(w, ""))
		if raid_id != "" and raid_id in completed_quests:
			week = maxi(week, mini(w + 1, max_week))
		else:
			## Soft fallback: 4+ quests mastered in week unlocks next
			var count := 0
			for qid in completed_quests:
				var q: Dictionary = QuestDB.get_quest(str(qid))
				if int(q.get("week", 1)) == w:
					count += 1
			if count >= 4:
				week = maxi(week, mini(w + 1, max_week))
	var prev: int = unlocked_week
	unlocked_week = clampi(maxi(unlocked_week, week), 1, max_week)
	if unlocked_week > prev:
		# Wave 23: include year progress % so the learning loop feels paced
		var year_pct: int = int(round(float(unlocked_week) / 36.0 * 100.0))
		toast.emit("Week %d is open! New lessons wait at the five guild halls (~%d%% of the year)." % [unlocked_week, year_pct])
		# Wave 40: soft milestone toast every 5 weeks unlocked (RuneScape-chunky, wholesome)
		if unlocked_week % 5 == 0 and unlocked_week < 36:
			toast.emit("✦ Milestone · Week %d unlocked — a soft fifth-mark (~%d%% of the year). Well done!" % [unlocked_week, year_pct])
		elif unlocked_week == 36:
			toast.emit("✦ Milestone · Full year unlocked — Week 36. What a faithful journey!")

func is_quest_unlocked(quest_id: String) -> bool:
	var q: Dictionary = QuestDB.get_quest(quest_id)
	if q.is_empty():
		return false
	return int(q.get("week", 1)) <= unlocked_week

func normalize_fill(answer: String) -> String:
	return answer.strip_edges().replace(",", "").replace(" ", "").to_lower()

func check_answer(challenge: Dictionary, response: String) -> bool:
	var expected = challenge.get("answer", "")
	var ctype: String = challenge.get("type", "multiple-choice")
	if ctype == "fill-blank":
		return normalize_fill(response) == normalize_fill(str(expected))
	return response == str(expected)
