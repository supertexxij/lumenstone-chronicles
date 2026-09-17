extends Node
## Persistent game state + save/load to user://

signal state_changed
signal hp_changed(current: int, maximum: int)
signal toast(msg: String)
signal quest_started(quest_id: String)
signal ui_open_requested(panel: String)
signal combat_target_changed(enemy: Node)
signal soft_defeated

const SAVE_PATH := "user://lumenstone_save_v1.json"
const PARENT_PIN := "1234"
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
var checkpoint_checks: Dictionary = {}
var checkpoint_date: String = ""
var created_at: int = 0
var last_played: int = 0
var unlocked_week: int = 1

var hp: int = 40
var max_hp: int = 40
var in_world: bool = false
var combat_target: Node = null

func _ready() -> void:
	await get_tree().process_frame
	if unlocked_items.is_empty():
		_apply_starters()

func _apply_starters() -> void:
	for id in ItemDB.starter_ids():
		if id not in unlocked_items:
			unlocked_items.append(id)
	if equipped.get("cape") == null:
		equipped["cape"] = "default_cape"

func new_game(p_name: String, appearance_in: Dictionary) -> void:
	child_name = p_name if p_name.strip_edges() != "" else "Apprentice"
	appearance = appearance_in.duplicate()
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
	created_at = int(Time.get_unix_time_from_system())
	unlocked_week = 1
	seen_aggro_tutorial = false
	seen_combat_tutorial = false
	hp = 40
	max_hp = 40
	_apply_starters()
	save_game()
	state_changed.emit()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

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
		"checkpoint_checks": checkpoint_checks,
		"checkpoint_date": checkpoint_date,
		"created_at": created_at,
		"last_played": last_played,
		"unlocked_week": unlocked_week,
	}
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func load_game() -> bool:
	if not has_save():
		return false
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
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
	checkpoint_checks = data.get("checkpoint_checks", {})
	checkpoint_date = data.get("checkpoint_date", "")
	created_at = int(data.get("created_at", 0))
	unlocked_week = int(data.get("unlocked_week", 1))
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
	toast.emit("Unlocked: %s" % ItemDB.get_item(id).get("name", id))
	state_changed.emit()


func check_combat_item_unlocks() -> void:
	## Grant weapons/items gated by combat_level_req once the threshold is met
	## (quest unlock_quest_id still required if set — both gates must pass).
	for iid in ItemDB.items:
		var it: Dictionary = ItemDB.items[iid]
		var req: int = int(it.get("combat_level_req", 0))
		if req <= 0:
			continue
		if combat_level < req:
			continue
		var qid: String = str(it.get("unlock_quest_id", ""))
		if qid != "" and qid not in completed_quests:
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
	if slot == "":
		return
	equipped[slot] = id
	state_changed.emit()
	save_game()

func unequip_slot(slot: String) -> void:
	equipped[slot] = null
	state_changed.emit()
	save_game()

func get_weapon_stats() -> Dictionary:
	var wid = equipped.get("weapon")
	if wid == null:
		return {"damage": int(EnemyDB.base_combat.get("damage", 2)), "accuracy": float(EnemyDB.base_combat.get("accuracy", 0.7))}
	var item := ItemDB.get_item(str(wid))
	return {"damage": int(item.get("damage", 5)), "accuracy": float(item.get("accuracy", 0.8))}


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

func set_combat_target(enemy: Node) -> void:
	combat_target = enemy
	combat_target_changed.emit(enemy)

func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		_soft_defeat()

func heal_full() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)

func _soft_defeat() -> void:
	toast.emit("You were restored at the village fountain.")
	position_xz = Vector2(0, 10)
	heal_full()
	set_combat_target(null)
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
		for iid in ItemDB.items:
			var it: Dictionary = ItemDB.items[iid]
			if str(it.get("unlock_quest_id", "")) == quest_id:
				unlock_item(str(iid))
		toast.emit("Quest mastered: %s" % quest.get("title", quest_id))
		AudioBus.play_quest_complete()
		_recalc_unlocked_week()
	else:
		toast.emit("Needs practice — score %d%% (need 80%%). Retry anytime!" % int(pct * 100))
	save_game()
	state_changed.emit()
	return attempt

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
	return pin == PARENT_PIN


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
		toast.emit("Campaign Week %d unlocked! Visit the guild halls." % unlocked_week)

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
