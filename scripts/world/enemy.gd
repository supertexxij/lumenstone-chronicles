extends CharacterBody3D
const HitsplatUtil = preload("res://scripts/combat/hitsplat.gd")
## Soft RuneScape-style tick combat foe with limb-aware creature meshes,
## flinch, death dissolve, and soft aggro radius.

@export var kind: String = "dim_wisp"
@export var spawn_id: String = ""

var def: Dictionary = {}
var hp: int = 10
var max_hp: int = 10
var alive: bool = true
var tick_timer: float = 0.0
var respawn_timer: float = 0.0
var spawn_pos: Vector3
var creature_bob: Node3D = null
var wing_phase: float = 0.0
var _flinch_t: float = 0.0
var _dissolve_t: float = -1.0
var _base_scale: Vector3 = Vector3.ONE
var _aggro_pulse: float = 0.0
var _telegraph: MeshInstance3D = null
var _was_warning: bool = false

@onready var mesh_root: Node3D = $MeshRoot
@onready var label: Label3D = $Label3D
@onready var hp_bar: MeshInstance3D = $HpBar

func _ready() -> void:
	add_to_group("enemies")
	spawn_pos = global_position
	def = EnemyDB.get_def(kind)
	max_hp = int(def.get("max_hp", 10))
	hp = max_hp
	label.text = def.get("name", kind)
	if hp_bar.mesh == null:
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.12, 0.12)
		hp_bar.mesh = box
	creature_bob = CreatureBuilder.build(kind, mesh_root)
	var primary := Color(def.get("color", "#888888"))
	var accent := Color(def.get("accent", "#aaaaaa"))
	CreatureBuilder.colorize(creature_bob, primary, accent)
	_base_scale = mesh_root.scale
	match kind:
		"dust_golem":
			label.position.y = 2.4
			hp_bar.position.y = 2.1
		"briar_boar":
			label.position.y = 1.6
			hp_bar.position.y = 1.35
		"shadow_moth":
			label.position.y = 1.9
			hp_bar.position.y = 1.6
		_:
			label.position.y = 1.8
			hp_bar.position.y = 1.5
	_update_hp_bar()
	_ensure_telegraph()

func is_alive() -> bool:
	return alive

func _physics_process(delta: float) -> void:
	if _dissolve_t >= 0.0:
		_dissolve_t += delta
		var u := clampf(_dissolve_t / 0.7, 0.0, 1.0)
		mesh_root.scale = _base_scale * (1.0 - u)
		modulate_meshes(1.0 - u)
		if u >= 1.0:
			_dissolve_t = -1.0
			visible = false
			mesh_root.scale = _base_scale
			modulate_meshes(1.0)
		return

	if not alive:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_respawn()
		return

	_idle_anim(delta)
	_update_flinch(delta)
	_soft_aggro(delta)

	if GameState.combat_target == self:
		tick_timer -= delta
		if tick_timer <= 0:
			tick_timer = float(EnemyDB.base_combat.get("tick_sec", 0.7))
			_combat_tick()

func modulate_meshes(a: float) -> void:
	## Fade meshes during dissolve (alpha via albedo)
	if creature_bob == null:
		return
	_fade_node(creature_bob, a)

func _fade_node(n: Node, a: float) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = mi.material_override
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if a < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
			var c: Color = mat.albedo_color
			c.a = a
			mat.albedo_color = c
	for c in n.get_children():
		_fade_node(c, a)

func _ensure_telegraph() -> void:
	if _telegraph != null:
		return
	_telegraph = MeshInstance3D.new()
	_telegraph.name = "AggroTelegraph"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.35
	cyl.bottom_radius = 1.35
	cyl.height = 0.03
	_telegraph.mesh = cyl
	var mat := StandardMaterial3D.new()
	# Softer, more translucent ring — readable but less urgent
	mat.albedo_color = Color(0.98, 0.92, 0.35, 0.28)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.95
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_telegraph.material_override = mat
	_telegraph.position = Vector3(0, 0.04, 0)
	_telegraph.visible = false
	add_child(_telegraph)

func _set_warning(on: bool) -> void:
	_ensure_telegraph()
	if _telegraph:
		_telegraph.visible = on
	if on:
		# Gentle warm tint — not alarm-red
		label.modulate = Color(1.0, 0.96, 0.72)
		if _telegraph and _telegraph.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = _telegraph.material_override
			var pulse: float = 0.18 + 0.16 * abs(sin(Time.get_ticks_msec() * 0.004))
			mat.albedo_color = Color(0.98, 0.92, 0.4, pulse)
			var s: float = 0.92 + 0.12 * abs(sin(Time.get_ticks_msec() * 0.0035))
			_telegraph.scale = Vector3(s, 1.0, s)
	else:
		label.modulate = Color.WHITE
		if _telegraph:
			_telegraph.scale = Vector3.ONE

func _soft_aggro(delta: float) -> void:
	## Soft RuneScape-like pull: long yellow telegraph, easy escape, muted toast spam.
	if GameState.combat_target != null:
		_set_warning(false)
		_aggro_pulse = 0.0
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		_set_warning(false)
		return
	if player.get("ui_blocking"):
		_set_warning(false)
		return
	# Skip soft-aggro while player is inside guild halls
	if player.global_position.x >= 90.0:
		_set_warning(false)
		_aggro_pulse = 0.0
		return
	var engage: float = float(EnemyDB.base_combat.get("engage_range", 3.8))
	var warn_range: float = engage + 1.6
	var telegraph_sec: float = 1.15  # longer fair warning
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= warn_range:
		_aggro_pulse += delta
		var warning := _aggro_pulse > 0.08 and _aggro_pulse < telegraph_sec
		_set_warning(warning or (dist <= engage and _aggro_pulse < telegraph_sec))
		if not _was_warning and warning:
			GameState.toast.emit("%s notices you nearby…" % def.get("name", "Foe"))
		_was_warning = warning
		if dist <= engage and _aggro_pulse > telegraph_sec:
			_set_warning(false)
			_was_warning = false
			GameState.set_combat_target(self)
			GameState.toast.emit("%s approaches — click away to leave." % def.get("name", "Foe"))
			_aggro_pulse = 0.0
	else:
		# Faster decay so stepping back clears warning quickly
		_aggro_pulse = move_toward(_aggro_pulse, 0.0, delta * 2.8)
		_set_warning(false)
		_was_warning = false

func _idle_anim(delta: float) -> void:
	if creature_bob == null or _flinch_t > 0.0:
		return
	var t := Time.get_ticks_msec() * 0.004 + spawn_pos.x
	match kind:
		"dim_wisp":
			creature_bob.position.y = sin(t) * 0.12
			creature_bob.rotation.y = sin(t * 0.5) * 0.15
		"shadow_moth":
			creature_bob.position.y = 0.15 + sin(t) * 0.1
			wing_phase += delta * 14.0
			var lw := creature_bob.get_node_or_null("LWing")
			var rw := creature_bob.get_node_or_null("RWing")
			var flap := sin(wing_phase) * 0.35
			if lw:
				lw.rotation.z = deg_to_rad(25) + flap
			if rw:
				rw.rotation.z = deg_to_rad(-25) - flap
		"briar_boar":
			creature_bob.position.y = abs(sin(t * 0.5)) * 0.02
			creature_bob.rotation.y = sin(t * 0.3) * 0.08
		"dust_golem":
			creature_bob.position.y = sin(t * 0.6) * 0.03
			var la := creature_bob.get_node_or_null("LArm")
			var ra := creature_bob.get_node_or_null("RArm")
			if la:
				la.rotation.x = sin(t * 0.7) * 0.08
			if ra:
				ra.rotation.x = -sin(t * 0.7) * 0.08
		_:
			creature_bob.position.y = sin(t) * 0.06

func _update_flinch(delta: float) -> void:
	if _flinch_t <= 0.0:
		return
	_flinch_t -= delta
	if creature_bob:
		var kick := sin(_flinch_t * 40.0) * 0.08 * clampf(_flinch_t * 3.0, 0.0, 1.0)
		creature_bob.position.x = kick
		creature_bob.rotation.z = kick * 0.5
	if _flinch_t <= 0.0 and creature_bob:
		creature_bob.position.x = 0.0
		creature_bob.rotation.z = 0.0

func _combat_tick() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist > float(EnemyDB.base_combat.get("attack_range", 3.2)):
		return
	# Player swing telegraph
	if player.has_method("play_attack_swing"):
		player.play_attack_swing()
	var wstats: Dictionary = GameState.get_weapon_stats()
	if randf() < float(wstats.get("accuracy", 0.7)):
		var dmg: int = int(wstats.get("damage", 2))
		dmg += maxi(0, GameState.combat_level - 1)
		_take_hit(dmg)
		HitsplatUtil.spawn(self, dmg, true)
		AudioBus.play_hit()
	else:
		HitsplatUtil.spawn(self, 0, true)
		AudioBus.play_miss()
	if not alive:
		return
	if randf() < float(def.get("accuracy", 0.7)):
		var edmg: int = int(def.get("damage", 1))
		GameState.take_damage(edmg)
		HitsplatUtil.spawn(player, edmg, false)
		AudioBus.play_hit()
		if GameState.hp <= 0:
			GameState.set_combat_target(null)
			if player.has_method("soft_respawn"):
				player.soft_respawn()
	else:
		HitsplatUtil.spawn(player, 0, false)
		AudioBus.play_miss()

func _take_hit(dmg: int) -> void:
	hp = maxi(0, hp - dmg)
	_flinch_t = 0.28
	_update_hp_bar()
	if hp <= 0:
		_defeat()

func _defeat() -> void:
	alive = false
	$CollisionShape3D.disabled = true
	GameState.set_combat_target(null)
	var cxp: int = int(def.get("combat_xp", 5))
	GameState.combat_xp += cxp
	GameState.combat_level = GameState.combat_level_for_xp(GameState.combat_xp)
	GameState.check_combat_item_unlocks()
	GameState.toast.emit("%s %s (+%d combat XP)" % [def.get("name", "Foe"), def.get("defeat_verb", "cleared"), cxp])
	GameState.save_game()
	GameState.state_changed.emit()
	_dissolve_t = 0.0
	respawn_timer = float(def.get("respawn_sec", 12))

func _respawn() -> void:
	alive = true
	visible = true
	$CollisionShape3D.disabled = false
	hp = max_hp
	global_position = spawn_pos
	mesh_root.scale = _base_scale
	modulate_meshes(1.0)
	_dissolve_t = -1.0
	_update_hp_bar()

func _update_hp_bar() -> void:
	var ratio := float(hp) / float(maxi(1, max_hp))
	hp_bar.scale.x = maxf(0.05, ratio)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.85, 0.3) if ratio > 0.4 else Color(0.9, 0.2, 0.2)
	hp_bar.material_override = mat
