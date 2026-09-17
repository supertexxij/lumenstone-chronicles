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
var _kill_flash_t: float = -1.0
var _hit_flash_t: float = -1.0
var _kill_flash_base: Dictionary = {}  # MeshInstance3D -> Color
var _dissolve_t: float = -1.0
var _base_scale: Vector3 = Vector3.ONE
var _aggro_pulse: float = 0.0
var _telegraph: MeshInstance3D = null
var _was_warning: bool = false
var _countdown_nudge: bool = false  # Wave 37: mid-telegraph countdown toast
var _target_reticle: MeshInstance3D = null  # Wave 31: soft cream combat target ring

@onready var mesh_root: Node3D = $MeshRoot
var label: Label3D
@onready var hp_bar: MeshInstance3D = $HpBar

func _ready() -> void:
	add_to_group("enemies")
	spawn_pos = global_position
	def = EnemyDB.get_def(kind)
	max_hp = int(def.get("max_hp", 10))
	hp = max_hp
	label = get_node_or_null("Label3D") as Label3D
	if HeadlessGuard.is_headless():
		if label:
			label.queue_free()
			label = null
	elif label:
		label.text = def.get("name", kind)
	if hp_bar and hp_bar.mesh == null:
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.12, 0.12)
		hp_bar.mesh = box
	if hp_bar:
		HeadlessGuard.guard_mesh(hp_bar)
	creature_bob = CreatureBuilder.build(kind, mesh_root)
	var primary := Color(def.get("color", "#888888"))
	var accent := Color(def.get("accent", "#aaaaaa"))
	CreatureBuilder.colorize(creature_bob, primary, accent)
	_base_scale = mesh_root.scale
	match kind:
		"dust_golem":
			if label: label.position.y = 2.4
			hp_bar.position.y = 2.1
		"briar_boar":
			if label: label.position.y = 1.6
			hp_bar.position.y = 1.35
		"moss_badger":
			if label: label.position.y = 1.55
			hp_bar.position.y = 1.3
		"cedar_stag":
			if label: label.position.y = 2.15
			hp_bar.position.y = 1.9
		"pine_fox":
			if label: label.position.y = 1.5
			hp_bar.position.y = 1.25
		"oak_hare":
			if label: label.position.y = 1.45
			hp_bar.position.y = 1.2
		"birch_squirrel":
			if label: label.position.y = 1.4
			hp_bar.position.y = 1.15
		"aspen_otter":
			if label: label.position.y = 1.35
			hp_bar.position.y = 1.1
		"elm_raccoon":
			if label: label.position.y = 1.4
			hp_bar.position.y = 1.15
		"shadow_moth":
			if label: label.position.y = 1.9
			hp_bar.position.y = 1.6
		"beech_chipmunk":
			if label: label.position.y = 1.35
			hp_bar.position.y = 1.1
		"alder_duck":
			if label: label.position.y = 1.3
			hp_bar.position.y = 1.05
		_:
			if label: label.position.y = 1.8
			hp_bar.position.y = 1.5
	_update_hp_bar()
	_ensure_telegraph()
	_ensure_target_reticle()
	_ensure_nav_obstacle()
	if GameState.has_signal("soft_combat_cleared") and not GameState.soft_combat_cleared.is_connected(clear_soft_aggro):
		GameState.soft_combat_cleared.connect(clear_soft_aggro)

func is_alive() -> bool:
	return alive

func clear_soft_aggro() -> void:
	_countdown_nudge = false
	## Called when player rests at the fountain — drop yellow pull / pulse.
	_aggro_pulse = 0.0
	_was_warning = false
	_set_warning(false)

func _ensure_nav_obstacle() -> void:
	if get_node_or_null("NavObstacle") != null:
		return
	var obs := NavigationObstacle3D.new()
	obs.name = "NavObstacle"
	obs.radius = 0.5
	obs.height = 1.5
	obs.avoidance_enabled = true
	add_child(obs)

func _physics_process(delta: float) -> void:
	if _dissolve_t >= 0.0:
		_tick_kill_flash(delta)
		_tick_hit_flash(delta)
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
	_update_target_reticle(delta)

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


func _ensure_target_reticle() -> void:
	## Wave 31: soft cream combat-target ring under the engaged foe (no combat labels).
	if _target_reticle != null:
		return
	_target_reticle = MeshInstance3D.new()
	_target_reticle.name = "TargetReticle"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.72
	ring.outer_radius = 0.92
	ring.rings = 10
	ring.ring_segments = 20
	_target_reticle.mesh = ring
	HeadlessGuard.guard_mesh(_target_reticle)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.98, 0.94, 0.82, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.9
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_target_reticle.material_override = mat
	_target_reticle.position = Vector3(0, 0.06, 0)
	_target_reticle.visible = false
	add_child(_target_reticle)


func _update_target_reticle(_delta: float) -> void:
	_ensure_target_reticle()
	var on := alive and GameState.combat_target == self
	_target_reticle.visible = on
	if not on:
		return
	# Soft steady cream breath — distinct from yellow soft-aggro telegraph
	var pulse: float = 0.48 + 0.14 * abs(sin(Time.get_ticks_msec() * 0.003))
	var s: float = 0.96 + 0.06 * abs(sin(Time.get_ticks_msec() * 0.0025))
	if _target_reticle.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = _target_reticle.material_override
		mat.albedo_color = Color(0.98, 0.94, 0.82, pulse)
	_target_reticle.scale = Vector3(s, 1.0, s)

func _ensure_telegraph() -> void:
	## Wave 23: chunkier RuneScape-style soft-aggro ring — bright torus rim + soft fill disc.
	if _telegraph != null:
		return
	_telegraph = MeshInstance3D.new()
	_telegraph.name = "AggroTelegraph"
	# Soft warm fill disc under the rim
	var disc := CylinderMesh.new()
	disc.top_radius = 1.42
	disc.bottom_radius = 1.42
	disc.height = 0.025
	_telegraph.mesh = disc
	HeadlessGuard.guard_mesh(_telegraph)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.98, 0.9, 0.28, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.95
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_telegraph.material_override = mat
	_telegraph.position = Vector3(0, 0.035, 0)
	_telegraph.visible = false
	add_child(_telegraph)
	# Bright outer rim (torus) — clearer at a glance than a flat disc alone
	var rim := MeshInstance3D.new()
	rim.name = "AggroRim"
	var torus := TorusMesh.new()
	torus.inner_radius = 1.28
	torus.outer_radius = 1.52
	torus.rings = 12
	torus.ring_segments = 24
	rim.mesh = torus
	HeadlessGuard.guard_mesh(rim)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(1.0, 0.94, 0.35, 0.55)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.roughness = 0.9
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rim.material_override = rmat
	rim.position = Vector3(0, 0.05, 0)
	rim.visible = false
	add_child(rim)

func _set_warning(on: bool) -> void:
	_ensure_telegraph()
	var rim: MeshInstance3D = get_node_or_null("AggroRim") as MeshInstance3D
	if _telegraph:
		_telegraph.visible = on
	if rim:
		rim.visible = on
	if on:
		# Gentle warm tint — not alarm-red
		if label:
			label.modulate = Color(1.0, 0.96, 0.72)
		# Wave 28: slightly stronger soft-pull breath so the yellow ring reads before a pull (no combat labels)
		var pulse: float = 0.26 + 0.22 * abs(sin(Time.get_ticks_msec() * 0.0042))
		var s: float = 0.92 + 0.14 * abs(sin(Time.get_ticks_msec() * 0.0038))
		if _telegraph and _telegraph.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = _telegraph.material_override
			mat.albedo_color = Color(0.99, 0.92, 0.32, pulse * 0.78)
			_telegraph.scale = Vector3(s, 1.0, s)
		if rim and rim.material_override is StandardMaterial3D:
			var rmat: StandardMaterial3D = rim.material_override
			rmat.albedo_color = Color(1.0, 0.96, 0.42, 0.48 + pulse * 0.4)
			rim.scale = Vector3(s, 1.0, s)
	else:
		if label:
			label.modulate = Color.WHITE
		if _telegraph:
			_telegraph.scale = Vector3.ONE
		if rim:
			rim.scale = Vector3.ONE

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
			var first_warn := not GameState.seen_aggro_tutorial
			GameState.mark_aggro_tutorial()
			_countdown_nudge = false
			# Wave 29: always name the foe on soft-aggro toast (first tip + later notices)
			# Wave 37: clearer soft-aggro countdown — remaining telegraph seconds
			var foe_name: String = str(def.get("name", "Foe"))
			var remain: float = maxf(0.1, telegraph_sec - _aggro_pulse)
			if first_warn:
				GameState.toast.emit("%s notices you — soft yellow ring · ~%.1fs to step back." % [foe_name, remain])
			else:
				GameState.toast.emit("%s notices you — ~%.1fs to step back…" % [foe_name, remain])
		elif warning and (not _countdown_nudge) and _aggro_pulse >= telegraph_sec * 0.55:
			_countdown_nudge = true
			var foe_mid: String = str(def.get("name", "Foe"))
			var remain_mid: float = maxf(0.1, telegraph_sec - _aggro_pulse)
			GameState.toast.emit("%s still watching — ~%.1fs…" % [foe_mid, remain_mid])
		_was_warning = warning
		if dist <= engage and _aggro_pulse > telegraph_sec:
			_set_warning(false)
			_was_warning = false
			_countdown_nudge = false
			GameState.set_combat_target(self)
			var first_fight := GameState.mark_combat_tutorial(true)
			if first_fight:
				# Wave 41: clearer first-fight tip — soft ticks + how to leave (RuneScape-chunky, wholesome)
				GameState.toast.emit("First fight: soft ticks (~0.7s). Walk away or click the ground to leave. %s approaches." % def.get("name", "Foe"))
			else:
				GameState.toast.emit("%s approaches — click away to leave." % def.get("name", "Foe"))
			_aggro_pulse = 0.0
	else:
		# Faster decay so stepping back clears warning quickly
		_aggro_pulse = move_toward(_aggro_pulse, 0.0, delta * 2.8)
		_set_warning(false)
		_was_warning = false
		_countdown_nudge = false

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
		"moss_badger":
			creature_bob.position.y = abs(sin(t * 0.55)) * 0.025
			creature_bob.rotation.y = sin(t * 0.35) * 0.1
		"cedar_stag":
			creature_bob.position.y = abs(sin(t * 0.4)) * 0.02
			creature_bob.rotation.y = sin(t * 0.22) * 0.12
			var head_n := creature_bob.get_node_or_null("Head")
			if head_n:
				head_n.rotation.x = sin(t * 0.5) * 0.12
			var neck_n := creature_bob.get_node_or_null("Neck")
			if neck_n:
				neck_n.rotation.x = deg_to_rad(28) + sin(t * 0.5) * 0.08
		"pine_fox":
			creature_bob.position.y = abs(sin(t * 0.65)) * 0.03
			creature_bob.rotation.y = sin(t * 0.4) * 0.14
			var tail_n := creature_bob.get_node_or_null("Tail")
			if tail_n:
				tail_n.rotation.y = sin(t * 0.9) * 0.25
				tail_n.rotation.x = deg_to_rad(-35) + sin(t * 0.7) * 0.08
		"oak_hare":
			# Soft hop bob — ears twitch gently
			creature_bob.position.y = abs(sin(t * 0.85)) * 0.04
			creature_bob.rotation.y = sin(t * 0.45) * 0.1
			var el := creature_bob.get_node_or_null("EarL")
			var er := creature_bob.get_node_or_null("EarR")
			if el:
				el.rotation.z = deg_to_rad(-12) + sin(t * 1.1) * 0.08
			if er:
				er.rotation.z = deg_to_rad(12) - sin(t * 1.1) * 0.08
		"birch_squirrel":
			# Quick sit-bob — bushy tail flicks
			creature_bob.position.y = abs(sin(t * 0.95)) * 0.035
			creature_bob.rotation.y = sin(t * 0.55) * 0.12
			var sq_tail := creature_bob.get_node_or_null("Tail")
			if sq_tail:
				sq_tail.rotation.y = sin(t * 1.2) * 0.22
				sq_tail.rotation.x = deg_to_rad(-55) + sin(t * 0.8) * 0.1
		"aspen_otter":
			# Soft glide bob — paddle tail sways
			creature_bob.position.y = abs(sin(t * 0.7)) * 0.03
			creature_bob.rotation.y = sin(t * 0.4) * 0.1
			var ot_tail := creature_bob.get_node_or_null("Tail")
			if ot_tail:
				ot_tail.rotation.y = sin(t * 0.85) * 0.18
				ot_tail.rotation.x = deg_to_rad(-18) + sin(t * 0.6) * 0.06
		"elm_raccoon":
			# Soft trundle bob — ringed tail sways (Wave 35)
			creature_bob.position.y = abs(sin(t * 0.75)) * 0.03
			creature_bob.rotation.y = sin(t * 0.42) * 0.11
			var rc_tail := creature_bob.get_node_or_null("Tail")
			if rc_tail:
				rc_tail.rotation.y = sin(t * 0.9) * 0.2
				rc_tail.rotation.x = deg_to_rad(-28) + sin(t * 0.65) * 0.07
		"willow_wren":
			# Soft hover bob — quick wing flutters (Wave 37)
			creature_bob.position.y = 0.08 + sin(t * 1.1) * 0.06
			creature_bob.rotation.y = sin(t * 0.5) * 0.12
			wing_phase += delta * 16.0
			var wlw := creature_bob.get_node_or_null("LWing")
			var wrw := creature_bob.get_node_or_null("RWing")
			var wflap := sin(wing_phase) * 0.4
			if wlw:
				wlw.rotation.z = deg_to_rad(28) + wflap
			if wrw:
				wrw.rotation.z = deg_to_rad(-28) - wflap
		"maple_mouse":
			# Soft sniff-bob — big ears twitch, thin tail sways (Wave 38)
			creature_bob.position.y = abs(sin(t * 0.9)) * 0.03
			creature_bob.rotation.y = sin(t * 0.48) * 0.12
			var mel := creature_bob.get_node_or_null("EarL")
			var mer := creature_bob.get_node_or_null("EarR")
			if mel:
				mel.rotation.z = deg_to_rad(-8) + sin(t * 1.2) * 0.1
			if mer:
				mer.rotation.z = deg_to_rad(8) - sin(t * 1.2) * 0.1
			var mtail := creature_bob.get_node_or_null("Tail")
			if mtail:
				mtail.rotation.y = sin(t * 1.0) * 0.28
				mtail.rotation.x = deg_to_rad(-20) + sin(t * 0.7) * 0.08
		"spruce_mole":
			# Soft dig-bob — snout dips, stubby body wiggles (Wave 39)
			creature_bob.position.y = abs(sin(t * 0.7)) * 0.02
			creature_bob.rotation.y = sin(t * 0.35) * 0.08
			var sn := creature_bob.get_node_or_null("Snout")
			if sn:
				sn.rotation.x = deg_to_rad(90) + sin(t * 1.1) * 0.08
			var nose := creature_bob.get_node_or_null("Nose")
			if nose:
				nose.position.y = 0.28 + sin(t * 1.1) * 0.01
		"beech_chipmunk":
			# Soft forage-bob — cheeks puff, stripe body wiggles, short tail flicks (Wave 40)
			creature_bob.position.y = abs(sin(t * 1.0)) * 0.035
			creature_bob.rotation.y = sin(t * 0.55) * 0.14
			var cl := creature_bob.get_node_or_null("CheekL")
			var cr := creature_bob.get_node_or_null("CheekR")
			if cl:
				cl.scale = Vector3.ONE * (1.0 + sin(t * 1.4) * 0.06)
			if cr:
				cr.scale = Vector3.ONE * (1.0 + sin(t * 1.4 + 0.4) * 0.06)
			var ctail := creature_bob.get_node_or_null("Tail")
			if ctail:
				ctail.rotation.y = sin(t * 1.3) * 0.22
				ctail.rotation.x = deg_to_rad(-35) + sin(t * 0.9) * 0.1
		"alder_duck":
			# Soft paddle-waddle — bill dips, wings tuck, tail flicks (Wave 41)
			creature_bob.position.y = abs(sin(t * 0.85)) * 0.025
			creature_bob.rotation.y = sin(t * 0.4) * 0.1
			var bill := creature_bob.get_node_or_null("Bill")
			if bill:
				bill.rotation.x = deg_to_rad(8) + sin(t * 1.0) * 0.06
			var dlw := creature_bob.get_node_or_null("LWing")
			var drw := creature_bob.get_node_or_null("RWing")
			if dlw:
				dlw.rotation.z = deg_to_rad(18) + sin(t * 1.2) * 0.05
			if drw:
				drw.rotation.z = deg_to_rad(-18) - sin(t * 1.2) * 0.05
			var dtail := creature_bob.get_node_or_null("Tail")
			if dtail:
				dtail.rotation.y = sin(t * 0.9) * 0.12
				dtail.rotation.x = deg_to_rad(-25) + sin(t * 0.7) * 0.06
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
		var base: int = int(wstats.get("damage", 2)) + maxi(0, GameState.combat_level - 1)
		# Light RuneScape-feel variance (±1) + occasional bright hit (wholesome, no gore)
		var dmg: int = maxi(1, base + randi_range(-1, 1))
		var bright: bool = randf() < 0.15
		if bright:
			dmg = maxi(dmg + 1, int(ceil(float(base) * 1.35)))
		# Soft "strong / bright hit" when damage is high vs foe max HP or absolute threshold
		var strong: bool = bright or dmg >= 8 or dmg >= int(ceil(float(max_hp) * 0.4))
		_take_hit(dmg)
		HitsplatUtil.spawn(self, dmg, true, 2.15, strong)
		AudioBus.play_hit()
	else:
		HitsplatUtil.spawn(self, 0, true)
		AudioBus.play_miss()
	if not alive:
		return
	if randf() < float(def.get("accuracy", 0.7)):
		var base_in: int = int(def.get("damage", 1))
		# Light incoming variance (±1) — wholesome RuneScape-feel numbers
		var edmg: int = maxi(1, base_in + randi_range(-1, 1))
		# Soft player defense from combat level + cape/head gear
		if GameState.has_method("get_defense"):
			edmg = maxi(1, edmg - GameState.get_defense())
		# Occasional slightly firmer poke (~10%)
		if randf() < 0.10:
			edmg += 1
		var strong_in: bool = edmg >= 4 or edmg >= base_in + 1
		GameState.take_damage(edmg)
		HitsplatUtil.spawn(player, edmg, false, 2.15, strong_in)
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
	if hp > 0:
		_begin_hit_flash()
	if hp <= 0:
		_defeat()

func _defeat() -> void:
	alive = false
	$CollisionShape3D.disabled = true
	GameState.set_combat_target(null)
	var cxp: int = int(def.get("combat_xp", 5))
	var prev_cl: int = GameState.combat_level
	GameState.combat_xp += cxp
	GameState.combat_level = GameState.combat_level_for_xp(GameState.combat_xp)
	GameState.check_combat_item_unlocks()
	# Wave 40: quiet soft XP float on foe (RuneScape-chunky, no cheesy combat labels)
	HitsplatUtil.spawn_xp(self, cxp, 2.35)
	GameState.toast.emit("%s %s (+%d combat XP)" % [def.get("name", "Foe"), def.get("defeat_verb", "cleared"), cxp])
	if GameState.combat_level > prev_cl:
		GameState.toast.emit("Combat level up! Now Combat Lv %d — well fought." % GameState.combat_level)
	GameState.save_game()
	GameState.state_changed.emit()
	_begin_kill_flash()
	_dissolve_t = 0.0
	respawn_timer = float(def.get("respawn_sec", 12))



func _begin_hit_flash() -> void:
	## Brief soft cream flash on a landed hit (Wave 21). Skips if kill flash running.
	if HeadlessGuard.is_headless():
		return
	if _kill_flash_t >= 0.0:
		return
	if _kill_flash_base.is_empty():
		_capture_mesh_colors(creature_bob)
	_hit_flash_t = 0.12
	_apply_kill_flash_color(Color(1.0, 0.92, 0.82, 1.0))


func _tick_hit_flash(delta: float) -> void:
	if _hit_flash_t < 0.0:
		return
	if _kill_flash_t >= 0.0:
		_hit_flash_t = -1.0
		return
	_hit_flash_t -= delta
	var u: float = clampf(1.0 - (_hit_flash_t / 0.12), 0.0, 1.0)
	var flash := Color(1.0, 0.92, 0.82, 1.0).lerp(Color(1, 1, 1, 1), u)
	# Restore toward base colors
	for mi in _kill_flash_base.keys():
		if not is_instance_valid(mi):
			continue
		if mi.material_override is StandardMaterial3D:
			var mat := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_color = flash.lerp(_kill_flash_base[mi], u)
			mi.material_override = mat
	if _hit_flash_t <= 0.0:
		_hit_flash_t = -1.0
		_restore_kill_flash_colors()


func _begin_kill_flash() -> void:
	## Brief soft gold wash before dissolve — wholesome clear, not gore.
	if HeadlessGuard.is_headless():
		return
	_kill_flash_t = 0.22
	_kill_flash_base.clear()
	_capture_mesh_colors(creature_bob)
	_apply_kill_flash_color(Color(1.0, 0.95, 0.65, 1.0))

func _capture_mesh_colors(n: Node) -> void:
	if n == null:
		return
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override is StandardMaterial3D:
			_kill_flash_base[mi] = (mi.material_override as StandardMaterial3D).albedo_color
	for c in n.get_children():
		_capture_mesh_colors(c)

func _apply_kill_flash_color(c: Color) -> void:
	for mi in _kill_flash_base.keys():
		if not is_instance_valid(mi):
			continue
		if mi.material_override is StandardMaterial3D:
			var mat := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_color = c
			mi.material_override = mat

func _tick_kill_flash(delta: float) -> void:
	if _kill_flash_t < 0.0:
		return
	_kill_flash_t -= delta
	var u: float = clampf(1.0 - (_kill_flash_t / 0.22), 0.0, 1.0)
	var flash := Color(1.0, 0.95, 0.65, 1.0).lerp(Color(1.0, 1.0, 1.0, 0.85), u)
	_apply_kill_flash_color(flash)
	if _kill_flash_t <= 0.0:
		_kill_flash_t = -1.0

func _respawn() -> void:
	alive = true
	visible = true
	$CollisionShape3D.disabled = false
	hp = max_hp
	global_position = spawn_pos
	mesh_root.scale = _base_scale
	modulate_meshes(1.0)
	_dissolve_t = -1.0
	# Restore original mesh colors after kill-flash wash (v1.14 bug fix)
	_restore_kill_flash_colors()
	_update_hp_bar()

func _restore_kill_flash_colors() -> void:
	for mi in _kill_flash_base.keys():
		if not is_instance_valid(mi):
			continue
		if mi.material_override is StandardMaterial3D:
			var mat := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_color = _kill_flash_base[mi]
			mi.material_override = mat
	_kill_flash_base.clear()
	_kill_flash_t = -1.0

func _update_hp_bar() -> void:
	var ratio := float(hp) / float(maxi(1, max_hp))
	hp_bar.scale.x = maxf(0.05, ratio)
	var mat := StandardMaterial3D.new()
	# Wave 29: soft 3-tier HP color — healthy green → amber → warm rose at low HP (wholesome, no harsh red)
	if ratio > 0.55:
		mat.albedo_color = Color(0.22, 0.86, 0.34)
	elif ratio > 0.28:
		mat.albedo_color = Color(0.92, 0.72, 0.22)
	else:
		mat.albedo_color = Color(0.88, 0.42, 0.38)
	hp_bar.material_override = mat
