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

const LEGACY_SAVE_PATH := "user://lumenstone_save_v1.json"
const SAVE_SLOT_FMT := "user://lumenstone_save_slot_%d.json"
const PARENT_SETTINGS_PATH := "user://lumenstone_parent.json"
const SLOT_COUNT := 3
const DEFAULT_PIN := "1234"
const MASTERY_PCT := 0.8

const GUILDS := {
	"math": {"name": "Builder's Guild", "short": "Math", "color": Color("#d4a017"), "lumen": "Gold"},
	"la": {"name": "Scribe's Guild", "short": "LA", "color": Color("#3a6ea5"), "lumen": "Blue"},
	"science": {"name": "Stewards of Creation", "short": "Science", "color": Color("#2d6a4f"), "lumen": "Green"},
	"history": {"name": "Chronicle Keepers", "short": "History", "color": Color("#9b2226"), "lumen": "Crimson"},
	"bible": {"name": "Word & Worship", "short": "Bible", "color": Color("#c9b037"), "lumen": "Silver"},
}

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
## Landmark approach toasts already shown for the current visit (persisted so reload in-zone does not re-greet).
var greeted_landmarks: Array = []
## Landmarks ever visited (persists forever) — drives first-discovery vs return toast flavor.
var discovered_landmarks: Array = []
var last_travel_label: String = ""  # Wave 34: last soft-travel destination
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
	greeted_landmarks = []
	discovered_landmarks = []
	last_travel_label = ""
	hp = 40
	max_hp = 40
	_apply_starters()
	save_game()
	state_changed.emit()

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
		"greeted_landmarks": greeted_landmarks,
		"discovered_landmarks": discovered_landmarks,
		"last_travel_label": last_travel_label,
		"checkpoint_checks": checkpoint_checks,
		"checkpoint_date": checkpoint_date,
		"last_daily_reminder_date": last_daily_reminder_date,
		"created_at": created_at,
		"last_played": last_played,
		"unlocked_week": unlocked_week,
		"slot_label": slot_label,
		"consumable_charges": consumable_charges,
		"save_version": 3,
	}
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
	child_name = data.get("child_name", "Apprentice")
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
	if landmark_id == "":
		return false
	if landmark_id in discovered_landmarks:
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
	## Wave 30: one plain line for parents to copy (week unlock + year mastery %).
	var w: Dictionary = get_week_unlock_progress()
	var q: Dictionary = get_quest_mastery_progress()
	return "Week unlock %d/36 (%d%%) · Year mastery %d%%" % [
		int(w.get("current", unlocked_week)), int(w.get("percent", 0)), int(q.get("percent", 0))
	]



func maybe_daily_checkpoint_reminder() -> void:
	## Soft once-per-calendar-day toast pointing parents to the short checkpoint (PIN stays 1234).
	var today := Time.get_date_string_from_system()
	if last_daily_reminder_date == today:
		return
	last_daily_reminder_date = today
	toast.emit("Gentle reminder: when you have a moment, open Parent for today’s short checkpoint (PIN 1234 unless you changed it).")
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
	if hp <= 0:
		_soft_defeat()

func heal_full() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)

func heal(amount: int) -> int:
	var before: int = hp
	hp = mini(max_hp, hp + maxi(0, amount))
	hp_changed.emit(hp, max_hp)
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
		toast.emit("Already at full health.")
		return false
	_ensure_pantry_defaults()
	var left: int = int(consumable_charges.get(item_id, 0))
	if left <= 0:
		toast.emit("%s pantry empty — fountain (H) refills your stacks." % item.get("name", item_id))  # Wave 39
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
		toast.emit("Already at full health.")
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
		stacks.append({"id": str(id), "name": str(it.get("name", id)), "count": cnt, "heal": heal_amt})
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
	clear_soft_combat(false)
	refill_pantry(announce)
	if hp < max_hp:
		_fountain_regen_left = 3
		_fountain_regen_timer = 0.05
		if announce:
			toast.emit("Resting by the fountain — strength returns.")
	elif announce:
		# refill_pantry already toasted if stocks changed; still confirm calm
		pass

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
	toast.emit("Soft defeat — rest safe at the village fountain. HP & pantry restored.")  # Wave 33: clearer toast
	position_xz = Vector2(0, 10)
	_fountain_regen_left = 0
	heal_full()
	refill_pantry(false)
	set_combat_target(null)
	soft_combat_cleared.emit()
	soft_defeated.emit()
	state_changed.emit()
	save_game()

func record_quest_attempt(quest_id: String, correct: int, total: int) -> Dictionary:
	var pct: float = float(correct) / float(maxi(1, total))
	var mastered: bool = pct >= MASTERY_PCT
	var attempt: Dictionary = {
		"quest_id": quest_id,
		"correct": correct,
		"total": total,
		"percent": pct,
		"mastered": mastered,
		"timestamp": int(Time.get_unix_time_from_system()),
	}
	quest_attempts.append(attempt)
	var quest: Dictionary = QuestDB.get_quest(quest_id)
	if mastered:
		if quest_id not in completed_quests:
			completed_quests.append(quest_id)
		add_xp(int(quest.get("xp_reward", 10)))
		if quest.get("lumen_on_mastery", false):
			var g: String = quest.get("guild", "math")
			lumens[g] = int(lumens.get(g, 0)) + 1
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
		toast.emit("Quest mastered: %s" % quest.get("title", quest_id))
		quest_mastered.emit(quest_id)
		AudioBus.play_quest_complete()
		_recalc_unlocked_week()
	else:
		toast.emit("Near miss — mastery %d%% (need ≥80%%). Retry anytime!" % int(pct * 100))  # Wave 33
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
			help.append({"quest_id": qid, "title": q.get("title", qid), "percent": a.get("percent", 0), "correct": a.get("correct", 0), "total": a.get("total", 0)})
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
		toast.emit("Campaign Week %d unlocked! (~%d%% of the year). Visit the guild halls." % [unlocked_week, year_pct])
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
